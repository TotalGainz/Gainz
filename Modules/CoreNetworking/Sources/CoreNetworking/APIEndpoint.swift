// APIEndpoint.swift
// CoreNetworking
//
// Foundation-only abstraction for Gainz REST endpoints.
// ─────────────────────────────────────────────────────────
// • Pure value types, thread-safe, test-friendly.
// • No Alamofire; zero third-party dependencies.
// • Pulls base URL from Info.plist key "GAINZ_API_BASE_URL"
//   injected by each build configuration (Debug, Release, etc.).
//
// Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - APIEndpoint Protocol

/// Contract that every endpoint descriptor must fulfill.
///
/// Conforming types (usually simple structs or enums) declare:
/// • `path`: URL-relative string (no leading "/").
/// • `method`: HTTP verb (see `HTTPMethod`).
/// • `query`: URL query parameters (optional).
/// • `body`: raw Data payload (optional).
/// • `headers`: extra headers merged into standard JSON headers.
/// • `Response`: the Decodable type returned on success.
public protocol APIEndpoint {
    associatedtype Response: Decodable
    
    var path: String { get }
    var method: HTTPMethod { get }
    var query: [URLQueryItem]? { get }
    var body: Data? { get }
    var headers: [String: String] { get }
    
    /// Builds a fully-formed URLRequest for this endpoint, given a base URL.
    func makeRequest(baseURL: URL) throws -> URLRequest
}

// MARK: - Default Implementations

public extension APIEndpoint {
    // Sensible defaults to reduce boilerplate for simple GET requests.
    var query: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var headers: [String: String] { [:] }
    
    func makeRequest(baseURL: URL) throws -> URLRequest {
        // Compose URL components
        guard var comps = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw URLError(.badURL)
        }
        comps.queryItems = (query?.isEmpty == false) ? query : nil
        guard let url = comps.url else {
            throw URLError(.badURL)
        }
        
        // Assemble URLRequest
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.httpBody   = body
        // Merge default JSON headers with any custom headers (custom overrides defaults)
        req.allHTTPHeaderFields = NetworkingEnvironment.defaultHeaders.merging(headers) { _, new in new }
        return req
    }
}

// MARK: - Environment Helper

/// Provides environment-specific configuration values from the app's Info.plist.
public enum NetworkingEnvironment {
    /// Base API URL string from Info.plist (key: "GAINZ_API_BASE_URL").
    /// - Returns: Base URL for API requests (e.g., `https://api.dev.gainz.app`).
    public static var baseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "GAINZ_API_BASE_URL") as? String,
            let url = URL(string: raw)
        else {
            preconditionFailure("Missing or malformed GAINZ_API_BASE_URL in Info.plist")
        }
        return url
    }
    
    /// Standard HTTP headers for JSON requests, including User-Agent with app version.
    public static var defaultHeaders: [String: String] {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "Gainz-iOS/\(version)"
        ]
    }
}
