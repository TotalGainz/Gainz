//
//  APIEndpoint.swift
//  CoreNetworking
//
//  Foundation-only abstraction for Gainz REST endpoints.
//  ─────────────────────────────────────────────────────────
//  • Pure value types, thread-safe, test-friendly.
//  • No Alamofire; zero third-party dependencies.
//  • Pulls BASE URL from Info.plist key “GAINZ_API_BASE_URL”
//    injected by each xcconfig (Debug, Release, etc.).
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - HTTP Method

/// Minimal set of verbs supported by the Gainz backend.
public enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
}

// MARK: - APIEndpoint

/// Contract every endpoint descriptor must fulfil.
///
/// Conforming types are lightweight structs/enums that declare:
/// • `path`: URL-relative string without leading “/”.
/// • `method`: HTTP verb.
/// • `query`: URLQueryItems (optional).
/// • `body`: raw Data payload (optional).
/// • `headers`: extra key/values merged into standard JSON headers.
/// • `Response`: Decodable type produced on success.
public protocol APIEndpoint {

    associatedtype Response: Decodable

    var path: String { get }
    var method: HTTPMethod { get }
    var query: [URLQueryItem]? { get }
    var body: Data? { get }
    var headers: [String: String] { get }

    /// Builds a fully-formed URLRequest.
    func makeRequest(baseURL: URL) throws -> URLRequest
}

// MARK: Default Implementations

public extension APIEndpoint {

    // Sensible defaults reduce boilerplate for simple GETs.
    var query: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var headers: [String: String] { [:] }

    func makeRequest(baseURL: URL) throws -> URLRequest {
        // Compose URL
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(path),
                                        resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        comps.queryItems = query?.isEmpty == false ? query : nil
        guard let url = comps.url else { throw URLError(.badURL) }

        // Assemble request
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.httpBody   = body
        req.allHTTPHeaderFields = ["Accept": "application/json",
                                   "Content-Type": "application/json"]
            .merging(headers) { _, new in new }
        return req
    }
}

// MARK: - Environment Helper

/// Reads the base API URL from Info.plist injected via xcconfig.
public enum NetworkingEnvironment {

    /// Example: https://api.dev.gainz.app
    public static var baseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "GAINZ_API_BASE_URL") as? String,
            let url = URL(string: raw)
        else {
            preconditionFailure("Missing or malformed GAINZ_API_BASE_URL")
        }
        return url
    }
}
