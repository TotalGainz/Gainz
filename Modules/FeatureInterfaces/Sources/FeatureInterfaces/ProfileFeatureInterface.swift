//
//  ProfileFeatureInterface.swift
//  FeatureInterfaces
//
//  Public façade for the Profile feature so other modules
//  (e.g. Home tab, Settings, Onboarding) can present or link
//  to the profile stack without importing its internal files.
//
//  Rules
//  ─────
//  • Pure protocol + type-erased “entry point” builder.
//  • Depends only on SwiftUI and Domain models.
//  • No HRV, recovery, or velocity metrics.
//  • Zero references to concrete view, coordinator, or view-model
//    classes—implementation lives inside `ProfileFeature` module.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain            // UserProfile model, value types

// MARK: - ProfileFeatureBuilding

/// Dependency-injection surface for constructing a profile flow.
/// Conforming types live in the *implementation* target.
public protocol ProfileFeatureBuilding {

    /// Produces the root SwiftUI view for the athlete’s profile.
    ///
    /// - Parameters:
    ///   - userProfile:   Immutable snapshot at launch; the view-model will
    ///                    subscribe to live changes via repository.
    ///   - onDismiss:     Callback triggered when the user exits the flow.
    /// - Returns:         A fully configured SwiftUI view hierarchy,
    ///                    type-erased so callers don’t leak implementation.
    func makeProfileView(
        with userProfile: UserProfile,
        onDismiss: @escaping () -> Void
    ) -> AnyView
}

// MARK: - Service Locator Key

/// SwiftUI environment key so features can resolve the builder without
/// singletons. Inject in SceneDelegate or AppCoordinator.
private struct ProfileFeatureBuilderKey: EnvironmentKey {
    static let defaultValue: ProfileFeatureBuilding? = nil
}

public extension EnvironmentValues {

    /// Accessor for the DI builder.
    var profileFeatureBuilder: ProfileFeatureBuilding? {
        get { self[ProfileFeatureBuilderKey.self] }
        set { self[ProfileFeatureBuilderKey.self] = newValue }
    }
}

// MARK: - Convenience View Modifier

public extension View {

    /// Presents the profile sheet when `isPresented` toggles `true`.
    func profileSheet(
        isPresented: Binding<Bool>,
        userProfile: UserProfile
    ) -> some View {
        modifier(
            ProfileSheetModifier(
                isPresented: isPresented,
                userProfile: userProfile
            )
        )
    }
}

// MARK: - ProfileSheetModifier

private struct ProfileSheetModifier: ViewModifier {

    @Environment(\.profileFeatureBuilder) private var builder
    @Binding var isPresented: Bool
    let userProfile: UserProfile

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            if let builder {
                builder.makeProfileView(
                    with: userProfile,
                    onDismiss: { isPresented = false }
                )
            } else {
                Text("Profile feature unavailable")
                    .font(.headline)
                    .padding()
            }
        }
    }
}
