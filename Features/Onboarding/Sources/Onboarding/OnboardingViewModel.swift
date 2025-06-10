// OnboardingViewModel.swift
//
//  OnboardingViewModel.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI
import Combine

// MARK: - OnboardingViewModel
@MainActor
@Observable
/// Observable state and logic for the onboarding flow.
public final class OnboardingViewModel {

    // MARK: Published State
    /// Persisted flag for whether onboarding was completed on a prior run.
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding: Bool = false {
        didSet { objectWillChange.send() }
    }

    /// Current index of the onboarding intro page carousel.
    @Published public private(set) var currentPage: Int = 0

    /// The list of intro pages to display.
    public let pages: [OnboardingPage]

    // User selections across onboarding steps
    public private(set) var selectedGoal: TrainingGoal?
    public private(set) var selectedExperience: TrainingExperience?
    public private(set) var selectedFrequency: TrainingFrequency?
    public private(set) var selectedPreferences: UserPreferences?

    // Combine support for manual observers (optional)
    public let objectWillChange = PassthroughSubject<Void, Never>()

    // MARK: Init
    public init(pages: [OnboardingPage] = OnboardingPage.samplePages) {
        self.pages = pages
    }

    // MARK: Intent
    /// Advance to the next intro page, or finish if at end.
    public func advance() {
        guard currentPage < pages.count - 1 else {
            return // if already at last page, do nothing (handled by UI)
        }
        currentPage += 1
    }

    /// Skip the entire onboarding flow and mark as completed.
    public func skip() {
        completeOnboarding()
    }

    /// Reset onboarding completion and restart intro.
    public func reset() {
        hasCompletedOnboarding = false
        currentPage = 0
    }

    // MARK: Helpers
    /// Mark onboarding as completed (sets persistent flag).
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    // MARK: Routing Convenience
    /// Indicates if onboarding should be shown (i.e. not completed yet).
    public var shouldPresentOnboarding: Bool {
        !hasCompletedOnboarding
    }
}

// MARK: - OnboardingPage Model (Shared)
public struct OnboardingPage: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let imageName: String
    public let title: String
    public let subtitle: String

    public static let samplePages: [OnboardingPage] = [
        .init(imageName: "Phoenix-Logo",
              title: "Rise Stronger",
              subtitle: "Smarter training plans driven by cutting-edge sports science."),
        .init(imageName: "Chart-Progress",
              title: "Track Everything",
              subtitle: "Lift logs, nutrition, sleep and recovery in one seamless hub."),
        .init(imageName: "Community",
              title: "Beat Your Best",
              subtitle: "Compete with friends and climb the leaderboards.")
    ]
}
