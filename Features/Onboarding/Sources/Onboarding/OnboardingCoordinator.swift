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
public enum RootRoute: Equatable {
    case onboarding
    case mainApp
}

// MARK: - OnboardingCoordinator
@MainActor
@Observable
public final class OnboardingCoordinator {

    // MARK: Published State
    @Published public private(set) var route: RootRoute

    // Child ViewModel is exposed for injection into the view tree
    public let onboardingViewModel: OnboardingViewModel

    // MARK: Init
    public init(onboardingViewModel: OnboardingViewModel = .init()) {
        self.onboardingViewModel = onboardingViewModel
        self.route = onboardingViewModel.shouldPresentOnboarding ? .onboarding : .mainApp

        // Listen for onboarding completion from the ViewModel
        onboardingViewModel.objectWillChange
            .sink { [weak self] in
                guard let self else { return }
                if self.onboardingViewModel.shouldPresentOnboarding == false {
                    self.route = .mainApp
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Intent
    public func resetOnboarding() {
        onboardingViewModel.reset()
        route = .onboarding
    }

    // MARK: Private
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - RootCoordinatorView
/// Inject this as the root of `@main` App to automatically switch between flows.
public struct RootCoordinatorView: View {
    @StateObject private var coordinator = OnboardingCoordinator()

    public init() {}

    public var body: some View {
        Group {
            switch coordinator.route {
            case .onboarding:
                OnboardingView()
                    .environment(coordinator.onboardingViewModel)
                    .transition(.opacity)
            case .mainApp:
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
