//  FeatureEntryPlanner.swift
//  FeatureInterfaces
//
//  Lightweight example entry point for unit tests. Allows verifying
//  navigation from the Planner feature without relying on its concrete
//  implementation.
//
//  Created for Gainz on 27 May 2025.

import Foundation

/// Minimal router contract used by tests.
public protocol NavigationRouting {
    func push(_ route: FeatureRoute, animated: Bool)
}

/// Simple enum representing app feature destinations.
public struct FeatureRoute: Hashable {
    public enum Kind {
        case workoutLogger
        // Other cases omitted for brevity
    }

    public var kind: Kind
    public var payload: [String: Any] = [:]

    public init(kind: Kind, payload: [String: Any] = [:]) {
        self.kind = kind
        self.payload = payload
    }
}

/// Convenience wrapper used in tests to drive navigation to the
/// Workout Logger from the Planner card.
public struct FeatureEntryPlanner {
    private let router: NavigationRouting

    /// Creates a new planner entry helper.
    /// - Parameter router: Destination router used for navigation.
    public init(router: NavigationRouting) {
        self.router = router
    }

    /// Simulates tapping "Start Workout" in the Planner overview.
    /// Pushes the Workout Logger route on the provided router.
    /// - Parameter animated: Whether to animate the transition.
    public func didSelectStartWorkout(animated: Bool = true) {
        router.push(FeatureRoute(kind: .workoutLogger), animated: animated)
    }
}

