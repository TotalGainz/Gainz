//
//  AnalyticsDashboardFeatureInterface.swift
//  FeatureInterfaces
//
//  Public interface for the AnalyticsDashboard feature module.
//  The goal is to decouple feature creation from the App layer so that
//  coordinators can inject a concrete implementation at runtime without
//  importing AnalyticsDashboard directly.
//
//  • Pure protocol + factory – no SwiftUI/AppKit imports here.
//  • Avoids circular deps: Feature → Interface → App → Feature.
//  • Async/await support for pre-loading heavy ML models if needed.
//  • Platform-agnostic (Foundation-only) so the same interface can be
//    consumed by iOS, watchOS, visionOS, and unit tests.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - AnalyticsDashboardFeatureInterface

/// Abstract factory + router contract for the Analytics Dashboard.
///
/// The AppCoordinator holds a reference to an object that conforms to this
/// protocol (provided via DI). When the user taps “Analytics” in the tab bar,
/// the coordinator calls `makeDashboardView()` to obtain the fully composed
/// SwiftUI view. This keeps the feature isolated and testable.
public protocol AnalyticsDashboardFeatureInterface: AnyObject {

    /// Performs any heavy or async setup (e.g. loading ML models or
    /// validating caches) before the view is presented.
    /// Call this early in app launch to avoid stutter.
    func preload() async throws

    /// Factory method that returns the dashboard’s root view.
    /// The concrete type is opaque (`Any`/`AnyObject`) so the interface
    /// remains UIKit/SwiftUI-agnostic. The App layer decides how to cast.
    func makeDashboardView() -> Any
}

// MARK: - Extension Helpers (Optional)

public extension AnalyticsDashboardFeatureInterface {

    /// Synchronous wrapper for fire-and-forget preloading.
    func preloadIfNeeded() {
        Task { try? await preload() }
    }
}
