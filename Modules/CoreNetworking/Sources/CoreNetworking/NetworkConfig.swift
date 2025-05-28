//
//  NetworkConfig.swift
//  CoreNetworking
//
//  Centralised switchboard for every outbound HTTP call in Gainz.
//  • Pure Foundation; no SwiftUI, Combine, or AsyncHTTPClient.
//  • Thread-safe, Sendable, test-friendly.
//  • Reads base URL & headers from Info.plist at runtime, so each
//    scheme (Debug / Staging / Release) can inject its own values
//    via xcconfig.
//
//  Created on 27 May 2025.
//

import Foundation

// MARK: - NetworkConfig

/// Immutable, thread-safe configuration object that every
/// `APIRequest` & `APIClient` instance relies on.
public struct NetworkConfig: Sendable, Hashable {

    // MARK: Public

    /// API host, e.g., `https://api.dev.gainz.app`.
    public let baseURL: URL

    /// Default headers appended to every outbound request.
    public let defaultHeaders: [String: String]

    /// URLSession timeout (per-request).
    public let timeout: TimeInterval

    /// Whether to log verbose request/response bodies to the console.
    public let isVerboseLoggingEnabled: Bool

    // MARK: Singleton

    /// Lazily initialised with the info-dict of the current bundle.
    /// - Warning: Crashes fast if critical keys are missing—fail-loud
    ///   during development so misconfigs don’t leak to prod.
    public static let current: NetworkConfig = {
        guard
            let plist = Bundle.main.infoDictionary,
            let baseURLString = plist["GAINZ_API_BASE_URL"] as? String,
            let baseURL = URL(string: baseURLString)
        else {
            fatalError("Missing or invalid GAINZ_API_BASE_URL in Info.plist")
        }

        return NetworkConfig(
            baseURL: baseURL,
            defaultHeaders: [
                "User-Agent": "Gainz-iOS/\(AppVersion.short)",
                "Content-Type": "application/json"
            ],
            timeout: plist["GAINZ_API_TIMEOUT"] as? TimeInterval ?? 30,
            isVerboseLoggingEnabled: (plist["GAINZ_VERBOSE_HTTP"] as? Bool) ?? false
        )
    }()

    // MARK: Init

    public init(
        baseURL: URL,
        defaultHeaders: [String: String] = [:],
        timeout: TimeInterval = 30,
        isVerboseLoggingEnabled: Bool = false
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.isVerboseLoggingEnabled = isVerboseLoggingEnabled
    }
}

// MARK: - AppVersion Helper

private enum AppVersion {
    static let short: String =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
}
