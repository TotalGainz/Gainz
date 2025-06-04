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
public final class OnboardingViewModel {

    // MARK: Published State
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding: Bool = false {
        didSet { objectWillChange.send() }
    }

    @Published public private(set) var currentPage: Int = 0

    public let pages: [OnboardingPage]

    // Combine support for manual observers (optional)
    public let objectWillChange = PassthroughSubject<Void, Never>()

    // MARK: Init
    public init(pages: [OnboardingPage] = OnboardingPage.samplePages) {
        self.pages = pages
    }

    // MARK: Intent
    public func advance() {
        guard currentPage < pages.count - 1 else {
            completeOnboarding()
            return
        }
        currentPage += 1
    }

    public func skip() {
        completeOnboarding()
    }

    public func reset() {
        hasCompletedOnboarding = false
        currentPage = 0
    }

    // MARK: Helpers
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    // MARK: Routing Convenience
    public var shouldPresentOnboarding: Bool {
        !hasCompletedOnboarding
    }
}

// MARK: - OnboardingPage Model (Shared)
public struct OnboardingPage: Identifiable, Hashable {
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
