//  FeatureEntryPlanner.swift
//  FeatureInterfaces
//
//  Lightweight example entry point for unit tests. Allows verifying
//  navigation from the Planner feature without relying on its concrete
//  implementation.
//
//  Created for Gainz on 27 May 2025.

import Foundation

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

