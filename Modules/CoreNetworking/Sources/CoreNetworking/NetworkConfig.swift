// NetworkConfig.swift
// CoreNetworking
//
// Centralized switchboard for every outbound HTTP call in Gainz.
// • Pure Foundation; no SwiftUI, Combine, or AsyncHTTPClient.
// • Thread-safe, Sendable, test-friendly.
// • Reads base URL & headers from Info.plist at runtime, so each
//   build scheme (Debug / Staging / Release) can inject its own values via xcconfig.
//
// Created on 27 May 2025.
//

import Foundation

// MARK: - NetworkConfig

/// Immutable, thread-safe configuration object that every
/// `APIRequest` & `APIClient` instance can rely on.
public struct NetworkConfig: Sendable, Hashable {
    
    // MARK: Public Properties
    
    /// API host URL, e.g. `https://api.dev.gainz.app`.
    public let baseURL: URL
    /// Default headers appended to every outbound request (e.g., User-Agent, Content-Type).
    public let defaultHeaders: [String: String]
    /// URLSession timeout interval (per request, in seconds).
    public let timeout: TimeInterval
    /// Whether to log verbose request/response bodies to the console.
    public let isVerboseLoggingEnabled: Bool
    
    // MARK: Singleton Instance
    
    /// Current network configuration loaded from the app's Info.plist.
    /// - Note: This will crash during startup if critical keys are missing or invalid,
    ///   ensuring misconfigurations are caught early in development.
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
            isVerboseLoggingEnabled: plist["GAINZ_VERBOSE_HTTP"] as? Bool ?? false
        )
    }()
    
    // MARK: Initializer
    
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

// MARK: - App Version Helper

private enum AppVersion {
    static let short: String =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
}
