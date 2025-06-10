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
//  • Keeps the interface small: a single factory + deep-link route enum.
//  • SwiftUI-agnostic callers can still host the View via `AnyView`.
//  • Forward-compatible: new routes can be appended with default cases.
//
//  NOTE: Do **not** import SwiftUI in callers; rely on `HomeRootRepresentable`.
//
//  Created for Gainz on 27 May 2025.
//
import Foundation
import Combine
import Domain

// MARK: - HomeFeatureFactory

/// A type that can vend the Home root view and handle Home-specific deep links.
///
/// Implemented inside `HomeFeature` and injected into the App layer via
/// `Environment(\.homeFeature)` for loose coupling.
public protocol HomeFeatureFactory: AnyObject {

    /// Returns a type-erased `HomeRootRepresentable` for hosting inside any
    /// SwiftUI hierarchy—without exposing Home’s internal view structs.
    func makeHomeRoot() -> HomeRootRepresentable

    /// Handles deep-link routes specific to Home (e.g., notifications,
    /// universal links). Returns `true` if the route was recognized.
    func handle(route: HomeRoute) async -> Bool
}

// MARK: - HomeRoute

/// Declarative routing surface for everything the Home tab can display.
///
/// Extend with new cases as needed; include a default `unknown(_:)` to ensure
/// forward compatibility when older clients receive newer links.
public enum HomeRoute: Hashable {
    case dashboard               // default landing aggregate
    case todaysWorkout(Date)     // jump directly into today’s planned workout
    case progress(metric: ProgressMetric)
    case unknown(raw: String)

    /// Subset of high-level progress metrics we visualize.
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

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Environment Key

private struct HomeFeatureKey: EnvironmentKey {
    static let defaultValue: HomeFeatureFactory? = nil
}

public extension EnvironmentValues {
    /// Dependency-injection hook for the Home feature.
    /// ```swift
    /// @Environment(\.homeFeature) private var homeFeature
    /// ```
    var homeFeature: HomeFeatureFactory? {
        get { self[HomeFeatureKey.self] }
        set { self[HomeFeatureKey.self] = newValue }
    }
}

// MARK: - SwiftUI Integration

public extension HomeFeatureFactory {
    /// Provides a type-erased SwiftUI view for the Home feature's root.
    func makeHomeRootView() -> AnyView {
        let root = makeHomeRoot()
        if let view = root as? any View {
            return AnyView(view)
        } else {
            return AnyView(EmptyView())
        }
    }
}
#endif
