//
//  NetworkInterceptor.swift
//  CoreNetworking
//
//  Injects cross-cutting concerns—auth headers, tracing, and resiliency—
//  into every outbound URLRequest before CoreNetworking fires it.
//  Platform-agnostic (Foundation & Combine only) so the same code runs
//  on iOS, watchOS, macOS, visionOS, and server-side Swift.
//
//  ───────────── Mission Invariants ─────────────
//  • No UI dependencies, no HealthKit, no HRV/recovery metrics.
//  • Pure SPM module; suitable for unit tests and Swift Concurrency.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine

// MARK: - RequestInterceptor

/// Protocol that individual interceptors conform to.
public protocol RequestInterceptor {
    func intercept(_ request: URLRequest) throws -> URLRequest
}

// MARK: - NetworkInterceptor (composite)

/// Composes multiple `RequestInterceptor`s in array order.
public struct NetworkInterceptor: RequestInterceptor {

    private let interceptors: [RequestInterceptor]

    public init(_ interceptors: [RequestInterceptor]) {
        self.interceptors = interceptors
    }

    public func intercept(_ request: URLRequest) throws -> URLRequest {
        try interceptors.reduce(request) { try $1.intercept($0) }
    }
}

// MARK: - Built-in Interceptors

// 1. Authentication

public struct AuthInterceptor: RequestInterceptor {

    private let tokenProvider: () -> String?

    public init(tokenProvider: @escaping () -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func intercept(_ request: URLRequest) throws -> URLRequest {
        var req = request
        if let token = tokenProvider() {
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }
}

// 2. Default Headers (JSON + User-Agent)

public struct DefaultHeadersInterceptor: RequestInterceptor {

    private let appVersion: String

    public init(appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0") {
        self.appVersion = appVersion
    }

    public func intercept(_ request: URLRequest) throws -> URLRequest {
        var req = request
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        if req.value(forHTTPHeaderField: "User-Agent") == nil {
            req.addValue("Gainz/\(appVersion) (Apple Platform)", forHTTPHeaderField: "User-Agent")
        }
        return req
    }
}

// 3. Debug Logger (only compiled in DEBUG)

#if DEBUG
public struct DebugLogInterceptor: RequestInterceptor {

    public func intercept(_ request: URLRequest) throws -> URLRequest {
        #if DEBUG
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<nil>"
        print("🌐 [\(method)] \(url)")
        #endif
        return request
    }
}
#endif

// MARK: - Convenience Factory

extension NetworkInterceptor {

    /// Default interceptor stack used by `NetworkClient`.
    public static func `default`(
        tokenProvider: @escaping () -> String?
    ) -> NetworkInterceptor {
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
 let client = NetworkClient(
     session: session,
     interceptor: .default { Keychain.currentAuthToken }
 )
*/
