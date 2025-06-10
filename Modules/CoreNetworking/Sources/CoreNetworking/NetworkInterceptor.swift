// NetworkInterceptor.swift
// CoreNetworking
//
// Injects cross-cutting concerns—auth headers, tracing, and resiliency—
// into every outbound URLRequest before CoreNetworking fires it.
// Platform-agnostic (Foundation-based; Combine optional) so the same code runs
// on iOS, watchOS, macOS, visionOS, and server-side Swift.
//
// ───────────── Mission Invariants ─────────────
// • No UI dependencies, no HealthKit, no HRV/recovery metrics.
// • Pure SwiftPM module; suitable for unit tests and Swift Concurrency.
//
// Created for Gainz on 27 May 2025.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - RequestInterceptor Protocol

/// Protocol that individual request interceptors conform to, allowing modification of URLRequests.
public protocol RequestInterceptor: Sendable {
    func intercept(_ request: URLRequest) throws -> URLRequest
}

// MARK: - NetworkInterceptor (Composite)

/// An interceptor that composes multiple `RequestInterceptor`s in order.
public struct NetworkInterceptor: RequestInterceptor {
    private let interceptors: [RequestInterceptor]
    
    public init(_ interceptors: [RequestInterceptor]) {
        self.interceptors = interceptors
    }
    
    public func intercept(_ request: URLRequest) throws -> URLRequest {
        // Apply each interceptor in sequence to the request
        return try interceptors.reduce(request) { req, interceptor in
            try interceptor.intercept(req)
        }
    }
}

// MARK: - Built-in Interceptors

/// 1. Authentication: Adds a Bearer token to the Authorization header if available.
public struct AuthInterceptor: RequestInterceptor {
    private let tokenProvider: @Sendable () -> String?
    
    public init(tokenProvider: @escaping @Sendable () -> String?) {
        self.tokenProvider = tokenProvider
    }
    
    public func intercept(_ request: URLRequest) throws -> URLRequest {
        var req = request
        if let token = tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }
}

/// 2. Default Headers: Ensures JSON Content-Type, Accept, and User-Agent headers are present.
public struct DefaultHeadersInterceptor: RequestInterceptor {
    private let appVersion: String
    
    public init(appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0") {
        self.appVersion = appVersion
    }
    
    public func intercept(_ request: URLRequest) throws -> URLRequest {
        var req = request
        // Set default Content-Type and Accept for JSON (overrides any existing values)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        // Only set User-Agent if not already specified
        if req.value(forHTTPHeaderField: "User-Agent") == nil {
            req.setValue("Gainz/\(appVersion) (Apple Platform)", forHTTPHeaderField: "User-Agent")
        }
        return req
    }
}

/// 3. Debug Logger (only active in DEBUG builds): Prints each request's method and URL to console.
#if DEBUG
public struct DebugLogInterceptor: RequestInterceptor {
    public init() {}
    public func intercept(_ request: URLRequest) throws -> URLRequest {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<nil>"
        print("🌐 [\(method)] \(url)")
        return request
    }
}
#endif

// MARK: - Convenience Factory

public extension NetworkInterceptor {
    /// Returns a default interceptor stack including JSON headers and auth token injection.
    /// In debug builds, a logging interceptor is also added. Useful for most Gainz API requests.
    static func `default`(tokenProvider: @escaping @Sendable () -> String?) -> NetworkInterceptor {
        var stack: [RequestInterceptor] = [
            DefaultHeadersInterceptor(),
            AuthInterceptor(tokenProvider: tokenProvider)
        ]
        #if DEBUG
        stack.append(DebugLogInterceptor())
        #endif
        return NetworkInterceptor(stack)
    }
}

// MARK: - Usage Example
/*
 let session = URLSession(configuration: .default)
 let client = APIClient(
     configuration: .init(baseURL: NetworkingEnvironment.baseURL),
     interceptor: .default { Keychain.currentAuthToken }
 )
 // Now use client.send(request) to perform API calls with default headers and auth.
 */
