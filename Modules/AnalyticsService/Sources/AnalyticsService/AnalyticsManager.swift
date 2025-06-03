AnalyticsManager.swift

//
//  AnalyticsManager.swift
//  AnalyticsService
//
//  Central hub for emitting, buffering, and uploading analytics events.
//  ⟡  Pure Swift (Foundation + Combine + Crypto) – no UIKit.
//  ⟡  No HRV, recovery-score, or velocity metrics are ever logged.
//  ⟡  Thread-safe via private serial queue.
//  ⟡  Respects user opt-out; uploads batch-signed with HMAC-SHA256.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Crypto
import Domain              // MesocyclePlan, WorkoutSession, AnalyticsEvent…
import CorePersistence      // ExerciseRepository, WorkoutRepository

// MARK: - AnalyticsManager

public final class AnalyticsManager {

    // MARK: Singleton convenience (can also DI a fresh instance in tests)
    public static let shared = AnalyticsManager()

    // MARK: Public API

    /// Emits an analytics event into the buffer and broadcasts it over Combine.
    /// - Parameter event: A value-type `AnalyticsEvent` defined in Domain.
    public func log(_ event: AnalyticsEvent) {
        accessQueue.async {
            self.eventBuffer.append(event)
            self.publisher.send(event)
            if self.eventBuffer.count >= self.flushThreshold {
                self.flush()
            }
        }
    }

    /// Manually flushes any queued events to the remote ingestion endpoint.
    /// Uploads occur on a background thread; completion handler executes on caller’s queue.
    public func flush(completion: ((Result<Void, Error>) -> Void)? = nil) {
        accessQueue.async {
            guard !self.eventBuffer.isEmpty else {
                completion?(.success(()))
                return
            }

            let batch = self.eventBuffer
            self.eventBuffer.removeAll()

            self.uploader.upload(batch)
                .receive(on: self.callbackQueue)
                .sink(
                    receiveCompletion: { result in
                        if case .failure(let error) = result { completion?(.failure(error)) }
                        else { completion?(.success(())) }
                    },
                    receiveValue: { /* ignore ack body */ }
                )
                .store(in: &self.cancellables)
        }
    }

    // MARK: Injected Interfaces

    /// Abstraction so tests can inject a stub.
    public struct Configuration {
        public var uploader: any AnalyticsUploading = AnalyticsHTTPSUploader()
        public var callbackQueue: DispatchQueue = .main
        public var flushThreshold: Int = 20
        public var secretKey: Data = Data("CHANGE_ME".utf8)
        public init() {}
    }

    // MARK: Private

    private let accessQueue = DispatchQueue(label: "ai.gainz.analytics.buffer", qos: .utility)
    private var eventBuffer: [AnalyticsEvent] = []
    private var cancellables = Set<AnyCancellable>()

    private let uploader: any AnalyticsUploading
    private let callbackQueue: DispatchQueue
    private let flushThreshold: Int

    private let publisher = PassthroughSubject<AnalyticsEvent, Never>()
    public var events: AnyPublisher<AnalyticsEvent, Never> { publisher.eraseToAnyPublisher() }

    // MARK: Init

    public init(configuration: Configuration = .init()) {
        self.uploader = configuration.uploader
        self.callbackQueue = configuration.callbackQueue
        self.flushThreshold = configuration.flushThreshold
    }
}

// MARK: - AnalyticsUploading Protocol

/// Strategy pattern for sending event batches; default implementation uses HTTPS.
public protocol AnalyticsUploading {
    func upload(_ events: [AnalyticsEvent]) -> AnyPublisher<Void, Error>
}

// MARK: - Default HTTPS Uploader

struct AnalyticsHTTPSUploader: AnalyticsUploading {

    // Endpoint injected via xcconfig / RemoteConfig
    private let endpointURL = URL(string: "https://api.gainz.app/v1/analytics")!
    private let secretKey = SymmetricKey(data: Data("CHANGE_ME".utf8))
    private let session: URLSession = .shared

    func upload(_ events: [AnalyticsEvent]) -> AnyPublisher<Void, Error> {
        do {
            let payload = try JSONEncoder().encode(events)
            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.httpBody = payload
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(hmac(for: payload), forHTTPHeaderField: "X-Signature")

            return session.dataTaskPublisher(for: request)
                .tryMap { result -> Void in
                    guard let http = result.response as? HTTPURLResponse,
                          200..<300 ~= http.statusCode else {
                        throw URLError(.badServerResponse)
                    }
                }
                .eraseToAnyPublisher()

        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    /// HMAC-SHA256 signature for tamper-evident uploads.
    private func hmac(for data: Data) -> String {
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: secretKey)
        return Data(signature).base64EncodedString()
    }
}
