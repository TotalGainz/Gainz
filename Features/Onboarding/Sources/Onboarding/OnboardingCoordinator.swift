// OnboardingCoordinator.swift
//
//  OnboardingCoordinator.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI
import Combine

// MARK: - Coordinator Route
/// Top-level routes for controlling the app's root content.
public enum RootRoute: Equatable {
    case onboarding
    case mainApp
}

// MARK: - OnboardingCoordinator
@MainActor
@Observable
/// Coordinates the display of the onboarding flow versus the main app.
public final class OnboardingCoordinator {

    // MARK: Published State
    @Published public private(set) var route: RootRoute

    // Child ViewModel is exposed for injection into the view tree
    public let onboardingViewModel: OnboardingViewModel

    // MARK: Init
    public init(onboardingViewModel: OnboardingViewModel = .init()) {
        self.onboardingViewModel = onboardingViewModel
        // Determine initial route based on onboarding completion status.
        self.route = onboardingViewModel.shouldPresentOnboarding ? .onboarding : .mainApp

        // Listen for onboarding completion from the ViewModel
        onboardingViewModel.objectWillChange
            .sink { [weak self] in
                guard let self else { return }
                // Onboarding just finished
                if !self.onboardingViewModel.shouldPresentOnboarding {
                    self.route = .mainApp
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Intent
    /// Reset the onboarding flow (for testing or if user logs out).
    public func resetOnboarding() {
        onboardingViewModel.reset()
        route = .onboarding
    }

    // MARK: Private
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - RootCoordinatorView
/// Root view that dynamically switches between onboarding and main app based on state.
public struct RootCoordinatorView: View {
    @StateObject private var coordinator = OnboardingCoordinator()

    public init() {}

    public var body: some View {
        Group {
            switch coordinator.route {
            case .onboarding:
                // Launch the onboarding flow
                OnboardingView()
                    .environment(coordinator.onboardingViewModel)
                    .transition(.opacity)
            case .mainApp:
                // Show the main application interface
                // TODO: Replace `MainTabView()` with your actual main-app entry point.
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: coordinator.route)
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    RootCoordinatorView()
        .preferredColorScheme(.dark)
}
#endif

// MARK: - MainApp Placeholder (Debug Only)
#if DEBUG
private struct MainTabView: View {
    var body: some View {
        Text("Main App Screen")
            .font(.title)
            .foregroundStyle(.secondary)
    }
}
#endif

// MARK: - Color & Gradient Helpers
extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex & 0xFF0000) >> 16) / 255.0,
            green: Double((hex & 0x00FF00) >> 8) / 255.0,
            blue: Double(hex & 0x0000FF) / 255.0,
            opacity: opacity
        )
    }
    static let brandPurpleStart = Color(hex: 0x8C3DFF)
    static let brandPurpleEnd   = Color(hex: 0x4925D6)
}
extension LinearGradient {
    static let brandGradient = LinearGradient(
        colors: [Color.brandPurpleStart, Color.brandPurpleEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
