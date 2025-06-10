// OnboardingView.swift
//
//  OnboardingView.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI

// MARK: - OnboardingView
@MainActor
public struct OnboardingView: View {
    // MARK: State
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var path: [OnboardingStep] = []

    /// Navigation steps in the onboarding flow
    private enum OnboardingStep: Hashable {
        case goal, experience, frequency, preferences, planPreview
    }

    public var body: some View {
        NavigationStack(path: $path) {
            // Intro pages carousel as the initial screen
            OnboardingIntroView(currentPage: $viewModel.currentPage, pages: viewModel.pages) {
                // When intro pages are completed, proceed to goal selection
                path.append(.goal)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .goal:
                    OnboardingGoalView { goal in
                        // Store selected goal and navigate to next step
                        viewModel.selectedGoal = goal
                        path.append(.experience)
                    }
                case .experience:
                    OnboardingExperienceView { experience in
                        viewModel.selectedExperience = experience
                        path.append(.frequency)
                    }
                case .frequency:
                    OnboardingFrequencyView { frequency in
                        viewModel.selectedFrequency = frequency
                        path.append(.preferences)
                    }
                case .preferences:
                    OnboardingPreferencesView { preferences in
                        viewModel.selectedPreferences = preferences
                        path.append(.planPreview)
                    }
                case .planPreview:
                    // All data collected, create plan preview model
                    let preview = PlanPreview(goal: viewModel.selectedGoal!,
                                               experience: viewModel.selectedExperience!,
                                               frequency: viewModel.selectedFrequency!,
                                               preferences: viewModel.selectedPreferences!)
                    OnboardingPlanPreviewView(preview: preview) {
                        // Mark onboarding complete and transition to main app
                        viewModel.skip()
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// MARK: - OnboardingIntroView
/// The introductory onboarding carousel with welcome pages.
private struct OnboardingIntroView: View {
    @Binding var currentPage: Int
    let pages: [OnboardingPage]
    let onFinishIntro: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                        .accessibilityElement(children: .contain)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            PageControl(numberOfPages: pages.count, currentPage: $currentPage)
                .padding(.vertical, 12)

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onFinishIntro()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.system(.headline, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(LinearGradient.brandGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel(currentPage < pages.count - 1 ? "Next" : "Get Started")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - OnboardingPageView
/// A single page in the intro carousel (image and text).
private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 260)
                .accessibilityHidden(true) // Decorative image

            Text(page.title)
                .font(.system(.title, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .accessibilityAddTraits(.isHeader)

            Text(page.subtitle)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PageControl
/// Page indicator dots for the intro carousel.
private struct PageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { i in
                Circle()
                    .fill(i == currentPage ? Color.brandPurpleStart : Color.gray.opacity(0.4))
                    .frame(width: i == currentPage ? 10 : 8, height: i == currentPage ? 10 : 8)
                    .scaleEffect(i == currentPage ? 1.2 : 1)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }
}
