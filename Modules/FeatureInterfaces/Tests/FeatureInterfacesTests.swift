//
//  FeatureInterfacesTests.swift
//  Gainz – FeatureInterfaces
//
//  Compile-time and behavioural tests for the public contracts that tie
//  feature modules together (routing, dependency injection, deep-link
//  parsing).  Runs fast with zero external dependencies.
//
//  Created on 27 May 2025.
//

import XCTest
@testable import FeatureInterfaces

final class FeatureInterfacesTests: XCTestCase {

    // MARK: – Compile-time Safety

    /// Ensures every `FeatureKind` case exposes a unique string identifier.
    /// Duplicate identifiers would break deep-link routing.
    func testFeatureKind_identifierUniqueness() {
        let identifiers = FeatureKind.allCases.map(\.identifier)
        let unique      = Set(identifiers)
        XCTAssertEqual(
            identifiers.count,
            unique.count,
            "Duplicate FeatureKind.identifier values found: \(identifiers)"
        )
    }

    /// Validates that each `FeatureRoute` can round-trip a deep-link URL.
    func testFeatureRoute_roundTripURL() throws {
        try FeatureKind.allCases.forEach { kind in
            // Given – a nominal payload for the feature
            let payload = ["foo": "bar"]

            // When – encode ➜ URL
            let url = try kind.makeURL(payload: payload)

            // Then – decode ➜ route
            let route = try FeatureRoute(url: url)

            // Verify round-trip fidelity
            XCTAssertEqual(route.kind, kind)
            XCTAssertEqual(route.payload["foo"] as? String, "bar")
        }
    }

    // MARK: – Dependency Injection

    /// Injects a mock NavigationRouter to assert that feature entry points
    /// call the correct navigation method.
    func testNavigationRouter_invokedWithExpectedRoute() throws {
        // Given
        let expectation = expectation(description: "push called")
        let mockRouter  = MockNavigationRouter { route in
            if case .workoutLogger = route.kind {
                expectation.fulfill()
            }
        }

        // When – simulate tapping the Planner card
        let planner = FeatureEntryPlanner(router: mockRouter)
        planner.didSelectStartWorkout()

        // Then
        wait(for: [expectation], timeout: 0.1)
    }
}

// MARK: – Mocks

private struct MockNavigationRouter: NavigationRouting {
    let onPush: (FeatureRoute) -> Void
    func push(_ route: FeatureRoute, animated: Bool) {
        onPush(route)
    }
}

// MARK: – Helpers (guard compile-time failures only)

/// Extend FeatureKind with a minimal fixture API expected in tests.
private extension FeatureKind {
    /// Example identifier string for deep-link matching.
    var identifier: String {
        switch self {
        case .home:           return "home"
        case .planner:        return "planner"
        case .workoutLogger:  return "workout_logger"
        case .analytics:      return "analytics"
        case .profile:        return "profile"
        case .settings:       return "settings"
        }
    }

    /// Serialises a payload into a deep-link URL.
    func makeURL(payload: [String: Any]) throws -> URL {
        var components       = URLComponents()
        components.scheme     = "gainz"
        components.host       = identifier
        components.queryItems = payload.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }
}
