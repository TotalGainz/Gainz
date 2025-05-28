//
//  CoreNetworkingTests.swift
//  Gainz – CoreNetworkingTests
//
//  Verifies APIClient’s request lifecycle, decoding fidelity, and error
//  surfacing. Uses URLProtocol stubbing for fully deterministic tests.
//  No network traffic leaves the process.
//
//  Created for Gainz on 27 May 2025.
//

import XCTest
@testable import CoreNetworking

// MARK: - Test Fixtures

private struct DummyDTO: Codable, Equatable {
    let id: Int
    let name: String
}

private enum TestError: Error { case boom }

final class CoreNetworkingTests: XCTestCase {

    // System Under Test
    private var api: APIClient!

    // Stub
    private var stubProtocol: URLSessionStubProtocol.Type!

    override func setUp() {
        super.setUp()
        stubProtocol = URLSessionStubProtocol.self
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [stubProtocol]
        api = DefaultAPIClient(session: URLSession(configuration: config),
                               decoder: .init(),
                               baseURL: URL(string: "https://test.gainz.app")!)
    }

    override func tearDown() {
        stubProtocol.clean()
        api = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_successfulJSONDecoding() async throws {
        // Given
        let expected = DummyDTO(id: 1, name: "Bench Press")
        try stubProtocol.stub(json: expected, statusCode: 200)

        // When
        let result: DummyDTO = try await api.request(.get(path: "/dummy"))

        // Then
        XCTAssertEqual(result, expected)
    }

    func test_httpErrorIsSurfaced() async {
        // Given
        try? stubProtocol.stubEmpty(statusCode: 404)

        // When / Then
        await XCTAssertThrowsErrorAsync {
            _ = try await api.request(DummyDTO.self, .get(path: "/missing"))
        } verify: { error in
            guard case NetworkError.http(let status, _) = error else {
                XCTFail("Expected http error, got \(error)"); return
            }
            XCTAssertEqual(status, 404)
        }
    }

    func test_decodingErrorIsMapped() async {
        // Given – send invalid JSON (missing `name`)
        let payload = ["id": 42]
        try? stubProtocol.stub(jsonObject: payload, statusCode: 200)

        // When / Then
        await XCTAssertThrowsErrorAsync {
            _ = try await api.request(DummyDTO.self, .get(path: "/badjson"))
        } verify: { error in
            guard case NetworkError.decoding = error else {
                XCTFail("Expected decoding error, got \(error)"); return
            }
        }
    }

    func test_cancellationPropagates() async {
        // Given – long-running stub (1 s)
        try? stubProtocol.stub(json: DummyDTO(id: 0, name: "…"), statusCode: 200, delay: 1)

        // When
        let task = Task {
            try await api.request(DummyDTO.self, .get(path: "/slow"))
        }
        // Cancel almost immediately
        task.cancel()

        // Then
        await XCTAssertThrowsCancellationErrorAsync {
            _ = try await task.value
        }
    }
}

// MARK: - URLSessionStubProtocol

/// Simple URLProtocol replacement that returns canned responses.
private final class URLSessionStubProtocol: URLProtocol {

    private struct Stub {
        let data: Data
        let response: HTTPURLResponse
        let delay: TimeInterval
    }

    private static var stub: Stub?

    static func stub<T: Encodable>(
        json value: T,
        statusCode: Int,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) throws {
        let data = try JSONEncoder().encode(value)
        stub(data: data, statusCode: statusCode, headers: headers, delay: delay)
    }

    static func stub(
        jsonObject: Any,
        statusCode: Int,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) throws {
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        stub(data: data, statusCode: statusCode, headers: headers, delay: delay)
    }

    static func stubEmpty(statusCode: Int, headers: [String: String] = [:]) throws {
        stub(data: Data(), statusCode: statusCode, headers: headers)
    }

    private static func stub(
        data: Data,
        statusCode: Int,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        let url = URL(string: "https://test.gainz.app")!
        let response = HTTPURLResponse(url: url,
                                       statusCode: statusCode,
                                       httpVersion: nil,
                                       headerFields: headers)!
        stub = Stub(data: data, response: response, delay: delay)
    }

    static func clean() {
        stub = nil
    }

    // MARK: URLProtocol overrides

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let stub = Self.stub else {
            client?.urlProtocol(self, didFailWithError: TestError.boom)
            return
        }

        if stub.delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + stub.delay) {
                self.finish(with: stub)
            }
        } else {
            finish(with: stub)
        }
    }

    override func stopLoading() {}

    private func finish(with stub: Stub) {
        client?.urlProtocol(self, didReceive: stub.response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

// MARK: - Async XCTAssert helpers

private func XCTAssertThrowsErrorAsync(
    _ block: @escaping () async throws -> Void,
    verify: (Error) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await block()
        XCTFail("Expected error", file: file, line: line)
    } catch {
        verify(error)
    }
}

private func XCTAssertThrowsCancellationErrorAsync(
    _ block: @escaping () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await block()
        XCTFail("Expected cancellation", file: file, line: line)
    } catch is CancellationError {
        // success
    } catch {
        XCTFail("Expected CancellationError, got \(error)", file: file, line: line)
    }
}
