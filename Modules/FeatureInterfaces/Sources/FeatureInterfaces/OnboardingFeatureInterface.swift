//  OnboardingFeatureInterface.swift
//  FeatureInterfaces
//
//  Decoupled interface for the Onboarding feature.
//
//  Goals
//  ─────
//  • Keep the App layer and other modules free of concrete Onboarding deps.
//  • Allow multiple platform-specific implementations (iOS, watchOS, visionOS)
//    to satisfy the same contract.
//  • Surface only two responsibilities:
//      1. Determining if onboarding is still required.
//      2. Producing a fully composed SwiftUI view to run the flow.
//  • Remain Foundation-only (except optional SwiftUI environment key) so this
//    interface can compile on server-side Swift if needed.
//
//  Created for Gainz on 27 May 2025.
//  Revised for public release on 8 Jun 2025.
//
import Foundation

// MARK: - OnboardingFeatureHosting

/// Receives callbacks when onboarding finishes.
/// Adopted by AppCoordinator (or SceneDelegate on visionOS, watchOS extension).
public protocol OnboardingFeatureHosting: AnyObject {
    /// Called exactly once after the user completes the entire onboarding flow.
    func onboardingDidFinish()
}

// MARK: - OnboardingFeatureInterface

/// Public surface of the Onboarding feature.
/// Concrete implementations live in platform-specific feature targets.
public protocol OnboardingFeatureInterface: AnyObject {

    /// Returns a type-erased SwiftUI view that renders the full onboarding flow.
    ///
    /// - Parameter host: Object to receive completion events.
    /// - Returns: `Any` so UIKit, AppKit, and Combine-only callers compile
    ///            without importing SwiftUI (cast to `AnyView` where available).
    func makeOnboardingView(host: OnboardingFeatureHosting) -> Any

    /// Indicates whether the user must still complete onboarding.
    /// The AppCoordinator uses this to decide if the flow should launch.
    func needsOnboarding() -> Bool
}

#if canImport(SwiftUI)
import SwiftUI

// MARK: - SwiftUI Environment Integration

private struct OnboardingFeatureKey: EnvironmentKey {
    static let defaultValue: OnboardingFeatureInterface? = nil
}

public extension EnvironmentValues {
    /// Dependency-injection hook for the Onboarding feature.
    /// Example:
    /// ```swift
    /// @Environment(\.onboardingFeature) private var onboarding
    /// ```
    var onboardingFeature: OnboardingFeatureInterface? {
        get { self[OnboardingFeatureKey.self] }
        set { self[OnboardingFeatureKey.self] = newValue }
    }
}

// MARK: - Convenience Helper

public extension OnboardingFeatureInterface {
    /// Provides a safe cast to `AnyView` for SwiftUI call-sites.
    func makeOnboardingAnyView(host: OnboardingFeatureHosting) -> AnyView {
        let root = makeOnboardingView(host: host)
        if let v = root as? any View {
            return AnyView(v)
        } else {
            return AnyView(EmptyView())
        }
    }
}
#endif
