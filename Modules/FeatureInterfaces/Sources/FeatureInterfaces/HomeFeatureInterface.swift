//
//  HomeFeatureInterface.swift
//  FeatureInterfaces
//
//  Public façade for the Home feature—exposes a factory that any layer
//  (AppCoordinator, deep-link handler, unit tests) can invoke without
//  importing the full `HomeFeature` implementation target.
//
//  Design goals
//  ─────────────
//  • Decouples feature consumers from its internal dependencies.
//  • Keeps the interface small: a single async factory + deeplink route enum.
//  • SwiftUI-agnostic callers can still host the View via `AnyView`.
//  • Forward-compatible: new routes can be appended with default cases.
//
//  NOTE: Do **not** import SwiftUI in callers; rely on `HomeViewRepresentable`.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Domain

// MARK: - HomeFeatureFactory

/// A type that can vend the Home root view and handle Home-specific deep links.
///
/// Implemented inside `HomeFeature` and injected into the App Layer via
/// `Environment(\.homeFeature)` for loose coupling.
public protocol HomeFeatureFactory: AnyObject {

    /// Returns a type-erased `HomeRootRepresentable` for hosting inside any
    /// SwiftUI hierarchy—without exposing Home’s internal view structs.
    func makeHomeRoot() -> HomeRootRepresentable

    /// Handles deep-link routes specific to Home (e.g., notifications,
    /// universal links). Returns `true` if the route was recognised.
    func handle(route: HomeRoute) async -> Bool
}

// MARK: - HomeRoute

/// Declarative routing surface for everything the Home tab can display.
///
/// Feel free to extend with new cases; provide a default `unknown(_:)`
/// to ensure forward compatibility when older clients receive newer links.
public enum HomeRoute: Hashable {
    case dashboard               // default landing aggregate
    case todaysWorkout(Date)     // direct jump into today’s planned workout
    case progress(metric: ProgressMetric)
    case unknown(raw: String)

    /// Subset of high-level progress metrics we visualise.
    public enum ProgressMetric: String, Codable, Hashable, CaseIterable {
        case strength
        case volume
        case bodyweight
    }
}

// MARK: - HomeRootRepresentable

/// Minimal wrapper so consumers can host the view without importing SwiftUI.
/// The Home feature conforms via `struct HomeRoot: View`.
public protocol HomeRootRepresentable { /* marker protocol */ }
