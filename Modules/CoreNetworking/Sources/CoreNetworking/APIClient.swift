// APIClient.swift
// CoreNetworking
//
// Universal HTTP layer (Swift Concurrency-first) powering every
// feature that touches the Gainz backend.
//
// • Async/await as the primary surface; Combine wrapper for legacy callers.
// • Pure Foundation—no SwiftUI, no UIKit, no persistence.
// • No HRV, recovery-score, or bar-velocity endpoints are ever called here.
// • Built for testability: injectable URLSession + JSON coders.
// • Supports interceptors for injecting auth headers, debugging, etc.
//
// Created for Gainz on 27 May 2025.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - Protocol

public protocol APIClientProtocol {
    /// Sends an APIRequest and returns its decoded Response.
    func send<R: APIRequest>(_ request: R) async throws -> R.Response
    #if canImport(Combine)
    /// Provides a Combine publisher that will send the decoded Response or an APIError.
    func publisher<R: APIRequest>(for request: R) -> AnyPublisher<R.Response, APIError>
    #endif
}

// MARK: - Implementation

public struct APIClient: APIClientProtocol {
    
    // MARK: Nested Types
    
    public struct Configuration {
        /// Base URL for API endpoints (e.g., https://api.dev.gainz.app).
        public var baseURL: URL
        /// Timeout interval for requests (seconds).
        public var timeout: TimeInterval
        /// Default headers applied to every request (e.g., Content-Type, User-Agent).
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
    
    // MARK: Stored Properties
    
    private let session: URLSession
    private let config: Configuration
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let interceptor: RequestInterceptor?
    
    // MARK: Initializers
    
    public init(
        configuration: Configuration,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        interceptor: RequestInterceptor? = nil
    ) {
        self.config = configuration
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.interceptor = interceptor
    }
    
    /// Convenience initializer using a NetworkConfig.
    public init(
        config: NetworkConfig,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        interceptor: RequestInterceptor? = nil
    ) {
        self.init(
            configuration: Configuration(
                baseURL: config.baseURL,
                timeout: config.timeout,
                defaultHeaders: config.defaultHeaders
            ),
            session: session,
            decoder: decoder,
            encoder: encoder,
            interceptor: interceptor
        )
    }
    
    // MARK: Async/Await usage
    
    public func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        let urlRequest = try makeURLRequest(for: request)
        do {
            let (data, response) = try await session.data(for: urlRequest)
            return try process(data: data, response: response, type: R.Response.self)
        } catch {
            // Wrap unknown errors in APIError for consistency
            throw (error as? APIError) ?? APIError.underlying(error)
        }
    }
    
    // MARK: Combine (optional wrapper)
    
    #if canImport(Combine)
    public func publisher<R: APIRequest>(
        for request: R
    ) -> AnyPublisher<R.Response, APIError> {
        do {
            let urlReq = try makeURLRequest(for: request)
            return session.dataTaskPublisher(for: urlReq)
                .tryMap { output in
                    try process(data: output.data, response: output.response, type: R.Response.self)
                }
                .mapError { $0 as? APIError ?? .underlying($0) }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error as? APIError ?? .underlying(error))
                .eraseToAnyPublisher()
        }
    }
    #endif
    
    // MARK: Request Builder
    
    /// Constructs a URLRequest from an APIRequest, applying baseURL, query items, headers, body, and interceptor.
    private func makeURLRequest<R: APIRequest>(for request: R) throws -> URLRequest {
        // Compose URL components
        guard var comps = URLComponents(
            url: config.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        comps.queryItems = request.queryItems
        guard let url = comps.url else {
            throw APIError.invalidURL
        }
        
        // Build the URLRequest with method, headers, and body
        var req = URLRequest(url: url, timeoutInterval: config.timeout)
        req.httpMethod = request.method.rawValue
        // Merge global default headers with request-specific headers (request headers override defaults)
        req.allHTTPHeaderFields = config.defaultHeaders.merging(request.headers) { _, new in new }
        if let body = request.body {
            // Encode Encodable body to JSON data
            req.httpBody = try encoder.encode(AnyEncodable(body))
            // Ensure content type is set for JSON payload
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Apply interceptor pipeline if provided (e.g., attach auth token, logging)
        if let interceptor = interceptor {
            req = try interceptor.intercept(req)
        }
        return req
    }
    
    // MARK: Response Processor
    
    /// Processes raw Data/URLResponse into a Decodable type T, or throws an APIError.
    private func process<T: Decodable>(
        data: Data,
        response: URLResponse,
        type: T.Type
    ) throws -> T {
        // Ensure we received an HTTPURLResponse
        guard let http = response as? HTTPURLResponse else {
            throw APIError.nonHTTP
        }
        // Check for HTTP success status (2xx), otherwise throw an error
        guard (200..<300).contains(http.statusCode) else {
            // If backend provided a JSON error payload, decode it for details
            if let payload = try? decoder.decode(APIErrorPayload.self, from: data) {
                throw APIError.server(statusCode: http.statusCode, payload: payload)
            }
            // No payload or decoding failed - throw generic status error
            throw APIError.status(http.statusCode)
        }
        // If expecting an empty response body (204 No Content), return an EmptyResponse
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        // Attempt to decode the data into the expected response type
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

// MARK: - Request Abstractions

/// Defines an API request with associated response type. Conforming types describe the endpoint and how to decode its response.
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
        case .invalidURL:
            return "Invalid URL"
        case .nonHTTP:
            return "Non-HTTP response"
        case .status(let code):
            return "HTTP \(code)"
        case .server(_, let payload):
            return payload.message
        case .decoding(let err),
             .underlying(let err):
            return err.localizedDescription
        }
    }
}

// MARK: - Support Types

/// Basic JSON error payload expected from the Gainz backend (usually contains a message).
public struct APIErrorPayload: Decodable {
    public let message: String
}

/// Sentinel type for endpoints that return no content (HTTP 204).
public struct EmptyResponse: Decodable {
    public init() {}
}

/// Type-erases an `Encodable` value, allowing it to be encoded without knowing its concrete type.
private struct AnyEncodable: Encodable {
    private let encodeFunction: (Encoder) throws -> Void
    init(_ wrapped: Encodable) {
        self.encodeFunction = { encoder in try wrapped.encode(to: encoder) }
    }
    func encode(to encoder: Encoder) throws {
        try encodeFunction(encoder)
    }
}
