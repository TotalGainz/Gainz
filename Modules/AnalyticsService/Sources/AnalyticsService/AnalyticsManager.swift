//  AnalyticsManager.swift
//  AnalyticsService
//
//  Central hub for emitting, buffering, and uploading analytics events.
//  ⟡ Pure Swift (Foundation + Combine + Crypto) – no UIKit dependencies.
//  ⟡ No HRV, recovery-score, or velocity metrics are ever logged.
//  ⟡ Thread-safe via a private serial dispatch queue.
//  ⟡ Respects user opt-out (uploadEnabled flag). Batches are HMAC-SHA256 signed.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Crypto
import Domain              // Domain models: MesocyclePlan, WorkoutSession, AnalyticsEvent, etc.
import CorePersistence     // e.g., ExerciseRepository, WorkoutRepository for local usage

// MARK: - AnalyticsManager

public final class AnalyticsManager {

    // MARK: Singleton Instance (Convenience)
    public static let shared = AnalyticsManager()
    // By default this uses the default configuration (with no secret key provided).
    // Make sure to configure the shared instance with a secret key for uploads if needed.

    // MARK: Public API

    /// Logs an analytics event: appends it to the buffer and broadcasts it via Combine.
    /// - Parameter event: A value-type `AnalyticsEvent` (defined in Domain).
    public func log(_ event: AnalyticsEvent) {
        accessQueue.async {
            guard self.uploadEnabledInternal else {
                // If uploads are disabled, do not buffer or broadcast the event.
                return
            }
            self.eventBuffer.append(event)
            self.eventPublisher.send(event)
            // Auto-flush if batch size hits threshold
            if self.eventBuffer.count >= self.flushThreshold {
                self.flush()  // trigger upload when buffer is full
            }
        }
    }

    /// Forces an upload of any queued events to the remote ingestion endpoint.
    /// Upload occurs on a background thread; the optional completion is invoked on the callbackQueue.
    public func flush(completion: ((Result<Void, Error>) -> Void)? = nil) {
        accessQueue.async {
            guard !self.eventBuffer.isEmpty else {
                // Nothing to upload; immediately signal success.
                completion?(.success(()))
                return
            }
            // If uploads are disabled (user opt-out or missing config), drop events without uploading.
            if !self.uploadEnabledInternal {
                self.eventBuffer.removeAll()
                completion?(.success(()))
                return
            }

            // Prepare batch and clear buffer before upload (to accept new events during network call).
            let batch = self.eventBuffer
            self.eventBuffer.removeAll()

            // Initiate the network upload on the uploader's publisher.
            var subscription: AnyCancellable? = nil
            subscription = self.uploader.upload(batch)
                .receive(on: self.callbackQueue)
                .sink(
                    receiveCompletion: { [weak self] result in
                        guard let self = self else { return }
                        // Notify completion result
                        if case .failure(let error) = result {
                            completion?(.failure(error))
                        } else {
                            completion?(.success(()))
                        }
                        // Clean up subscription to avoid memory accumulation
                        if let sub = subscription {
                            self.cancellables.remove(sub)
                        }
                    },
                    receiveValue: { _ in
                        // We don't expect a value (just completion), ignore any response body.
                    }
                )
            if let sub = subscription {
                self.cancellables.insert(sub)
            }
        }
    }

    // MARK: Configuration and Initialization

    /// Configuration parameters for AnalyticsManager. Allows dependency injection and runtime configuration.
    public struct Configuration {
        /// Custom uploader strategy (for tests or alternative endpoints). If nil, uses default HTTPS uploader.
        public var uploader: (any AnalyticsUploading)? = nil
        /// DispatchQueue for invoking flush completions and Combine outputs (defaults to main thread).
        public var callbackQueue: DispatchQueue = .main
        /// Number of events to accumulate before automatically flushing (batch size threshold).
        public var flushThreshold: Int = 20
        /// Endpoint URL for analytics ingestion (can be overridden per environment).
        public var endpointURL: URL = URL(string: "https://api.gainz.app/v1/analytics")!
        /// HMAC signing key data for request verification (e.g., retrieved from secure Keychain storage).
        /// If not provided, remote uploads will be disabled for safety.
        public var secretKey: Data? = nil
        /// Initial flag indicating whether uploading is enabled (user opt-in for analytics).
        public var uploadEnabled: Bool = true

        public init() {}
    }

    /// Initializes the AnalyticsManager with a given configuration.
    /// - Parameter configuration: Configuration for uploader, endpoint, keys, etc.
    public init(configuration: Configuration = .init()) {
        // Determine uploader strategy
        if let customUploader = configuration.uploader {
            // Use the custom uploader provided (e.g., a test stub or alternative implementation).
            self.uploader = customUploader
        } else if let keyData = configuration.secretKey, !keyData.isEmpty {
            // Use default HTTPS uploader with provided secret key and optional custom endpoint.
            let key = SymmetricKey(data: keyData)
            self.uploader = AnalyticsHTTPSUploader(endpointURL: configuration.endpointURL, secretKey: key)
        } else {
            // No secret key provided: disable remote uploads by using a no-op uploader.
            self.uploader = NoOpUploader()
            internalUploadEnabled = false  // force uploads off if no key
        }
        self.callbackQueue = configuration.callbackQueue
        self.flushThreshold = configuration.flushThreshold
        self.internalUploadEnabled = configuration.uploadEnabled
    }

    // MARK: Internals

    private let accessQueue = DispatchQueue(label: "ai.gainz.analytics.buffer", qos: .utility)
    private var eventBuffer: [AnalyticsEvent] = []
    private var cancellables = Set<AnyCancellable>()

    // Upload handling
    private let uploader: any AnalyticsUploading
    private let callbackQueue: DispatchQueue
    private let flushThreshold: Int

    // Combine publisher for broadcasting logged events within the app (never fails)
    private let eventPublisher = PassthroughSubject<AnalyticsEvent, Never>()
    public var events: AnyPublisher<AnalyticsEvent, Never> {
        eventPublisher.eraseToAnyPublisher()
    }

    // Upload opt-in flag (set via config or at runtime). Backed by thread-safe access.
    private var internalUploadEnabled: Bool = true
    public var uploadEnabled: Bool {
        get {
            accessQueue.sync { internalUploadEnabled }
        }
        set {
            accessQueue.async { self.internalUploadEnabled = newValue }
        }
    }
}

// MARK: - AnalyticsUploading Protocol

/// Strategy pattern for sending batches of analytics events. Default implementation uses HTTPS.
public protocol AnalyticsUploading {
    func upload(_ events: [AnalyticsEvent]) -> AnyPublisher<Void, Error>
}

// MARK: - Default HTTPS Uploader

struct AnalyticsHTTPSUploader: AnalyticsUploading {

    // Endpoint is configurable (injected via config or remote settings).
    private let endpointURL: URL
    // Symmetric key for HMAC signing (device-scoped secret from secure storage).
    private let secretKey: SymmetricKey
    private let session: URLSession

    /// Creates an HTTPS uploader for analytics events.
    /// - Parameters:
    ///   - endpointURL: The URL to which event batches are posted.
    ///   - secretKey: Symmetric key used to sign request payloads (HMAC-SHA256).
    ///   - session: URLSession to use (defaults to `.shared`).
    init(endpointURL: URL, secretKey: SymmetricKey, session: URLSession = .shared) {
        self.endpointURL = endpointURL
        self.secretKey = secretKey
        self.session = session
    }

    func upload(_ events: [AnalyticsEvent]) -> AnyPublisher<Void, Error> {
        do {
            // JSON-encode the batch of events. Use ISO-8601 date format for consistency.
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payloadData = try encoder.encode(events)
            // Prepare the URL request
            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.httpBody = payloadData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(hmac(for: payloadData), forHTTPHeaderField: "X-Signature")
            // Perform network upload as a Combine publisher
            return session.dataTaskPublisher(for: request)
                .tryMap { result -> Void in
                    // Ensure HTTP 2xx response
                    if let httpResponse = result.response as? HTTPURLResponse,
                       200..<300 ~= httpResponse.statusCode {
                        return ()  // success (Void)
                    } else {
                        throw URLError(.badServerResponse)
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            // If encoding fails, return a failed publisher immediately.
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    /// Generates an HMAC-SHA256 signature for the given data, using the secret key.
    /// - Returns: Base64-encoded signature string for inclusion in the request headers.
    private func hmac(for data: Data) -> String {
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: secretKey)
        return Data(signature).base64EncodedString()
    }
}

// MARK: - No-Op Uploader (for disabled analytics)

/// A no-operation uploader that drops events (used when analytics upload is disabled).
private struct NoOpUploader: AnalyticsUploading {
    func upload(_ events: [AnalyticsEvent]) -> AnyPublisher<Void, Error> {
        // Immediately succeed without doing anything.
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
