//
//  OnboardingFeatureInterface.swift
//  FeatureInterfaces
//
//  Abstract interface that lets AppCoordinator talk to the Onboarding
//  feature without importing its concrete implementation.  Using a protocol-
//  + factory pattern keeps compile-time dependencies pointed one way only
//  (App → FeatureInterfaces → OnboardingFeature), so other modules are never
//  forced to rebuild when the feature’s internals change.
//
//  No HRV, recovery, or velocity concepts are referenced here—onboarding
//  is purely about first-run setup (permissions, profile, preferences).
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Combine

// MARK: - OnboardingFeatureHosting

/// Anything that can present Onboarding adopts this to receive completion events.
public protocol OnboardingFeatureHosting: AnyObject {
    /// Called once the user finishes the full onboarding flow.
    func onboardingDidFinish()
}

// MARK: - OnboardingFeatureInterface

/// Public surface of the Onboarding bundle.
/// The concrete implementation lives in Modules/OnboardingFeature.
public protocol OnboardingFeatureInterface {

    /// A SwiftUI view that renders the entire onboarding flow.
    ///
    /// - Parameter host: The object that will receive completion callbacks.
    /// - Returns: A type-erased `AnyView` the coordinator can present.
    func makeOnboardingView(host: OnboardingFeatureHosting) -> AnyView

    /// Returns `true` if the user must still complete onboarding.
    /// This allows AppCoordinator to decide whether to present the flow.
    func needsOnboarding() -> Bool
}

// MARK: - DependencyKey / Environment Injection (optional)

private struct OnboardingFeatureKey: EnvironmentKey {
    static let defaultValue: OnboardingFeatureInterface? = nil
}

public extension EnvironmentValues {
    var onboardingFeature: OnboardingFeatureInterface? {
        get { self[OnboardingFeatureKey.self] }
        set { self[OnboardingFeatureKey.self] = newValue }
    }
}
