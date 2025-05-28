//
//  APIClient.swift
//  CoreNetworking
//
//  Universal HTTP layer (Swift Concurrency-first) powering every
//  feature that touches the Gainz backend.
//
//  • Async/await as the primary surface; Combine wrapper for legacy callers.
//  • Pure Foundation—no SwiftUI, no UIKit, no persistence.
//  • No HRV, recovery-score, or bar-velocity endpoints are ever called here.
//  • Built for testability: injectable URLSession + JSON coders.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - Protocol

public protocol APIClientProtocol {
    func send<R: APIRequest>(_ request: R) async throws -> R.Response
    #if canImport(Combine)
    func publisher<R: APIRequest>(for request: R) -> AnyPublisher<R.Response, APIError>
    #endif
}

// MARK: - Implementation

public struct APIClient: APIClientProtocol {

    // MARK: Nested

    public struct Configuration {
        public var baseURL: URL
        public var timeout: TimeInterval
        public var defaultHeaders: [String: String]

        public init(
            baseURL: URL,
            timeout: TimeInterval = 30,
            defaultHeaders: [String: String] = [:]
        ) {
            self.baseURL = baseURL
            self.timeout = timeout
            self.defaultHeaders = defaultHeaders
        }
    }

    // MARK: Stored

    private let session: URLSession
    private let config: Configuration
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: Init

    public init(
        configuration: Configuration,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.config = configuration
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    // MARK: Async / Await

    public func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        let urlRequest = try makeURLRequest(for: request)
        let (data, response) = try await session.data(for: urlRequest)
        return try process(data: data, response: response, type: R.Response.self)
    }

    // MARK: Combine (optional wrapper)

    #if canImport(Combine)
    public func publisher<R: APIRequest>(
        for request: R
    ) -> AnyPublisher<R.Response, APIError> {
        do {
            let urlReq = try makeURLRequest(for: request)
            return session.dataTaskPublisher(for: urlReq)
                .tryMap { try process(data: $0.data, response: $0.response, type: R.Response.self) }
                .mapError { $0 as? APIError ?? .underlying($0) }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error as? APIError ?? .underlying(error))
                .eraseToAnyPublisher()
        }
    }
    #endif

    // MARK: Request Builder

    private func makeURLRequest<R: APIRequest>(for request: R) throws -> URLRequest {
        guard var comps = URLComponents(
            url: config.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidURL }

        comps.queryItems = request.queryItems
        guard let url = comps.url else { throw APIError.invalidURL }

        var req = URLRequest(url: url, timeoutInterval: config.timeout)
        req.httpMethod = request.method.rawValue
        req.allHTTPHeaderFields = config.defaultHeaders.merging(request.headers) { $1 }

        if let body = request.body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return req
    }

    // MARK: Response Processor

    private func process<T: Decodable>(
        data: Data,
        response: URLResponse,
        type: T.Type
    ) throws -> T {

        guard let http = response as? HTTPURLResponse else { throw APIError.nonHTTP }

        guard (200..<300).contains(http.statusCode) else {
            if let payload = try? decoder.decode(APIErrorPayload.self, from: data) {
                throw APIError.server(statusCode: http.statusCode, payload: payload)
            }
            throw APIError.status(http.statusCode)
        }

        if T.self == EmptyResponse.self { return EmptyResponse() as! T }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIError.decoding(error) }
    }
}

// MARK: - Request Abstractions

public protocol APIRequest {
    associatedtype Response: Decodable
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String] { get }
    var body: Encodable? { get }
}

public extension APIRequest {
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String] { [:] }
    var body: Encodable? { nil }
}

public enum HTTPMethod: String { case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE" }

// MARK: - Error Types

public enum APIError: Error, LocalizedError {
    case invalidURL
    case nonHTTP
    case status(Int)
    case server(statusCode: Int, payload: APIErrorPayload)
    case decoding(Error)
    case underlying(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:                     return "Invalid URL"
        case .nonHTTP:                        return "Non-HTTP response"
        case .status(let code):               return "HTTP \(code)"
        case .server(_, let payload):         return payload.message
        case .decoding(let err),
             .underlying(let err):            return err.localizedDescription
        }
    }
}

// MARK: - Support

/// Basic JSON error payload expected from Gainz backend.
public struct APIErrorPayload: Decodable { public let message: String }

/// Sentinel for 204 No Content.
public struct EmptyResponse: Decodable { public init() {} }

/// Type-erases `Encodable` so we can stash it in `body`.
private struct AnyEncodable: Encodable {
    private let enc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { enc = wrapped.encode }
    func encode(to encoder: Encoder) throws { try enc(encoder) }
}
