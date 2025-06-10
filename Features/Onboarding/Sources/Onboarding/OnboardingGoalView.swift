// OnboardingGoalView.swift
//
//  OnboardingGoalView.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI

// MARK: - TrainingGoal
/// Primary objective the user selects during onboarding.
public enum TrainingGoal: String, CaseIterable, Identifiable, Sendable {
    case hypertrophy = "Build Muscle"
    case fatLoss     = "Lose Fat"
    case strength    = "Increase Strength"
    case endurance   = "Improve Endurance"
    case wellness    = "Optimize Health"

    public var id: String { rawValue }

    /// SF Symbols for each goal (replace with custom assets if desired).
    var iconName: String {
        switch self {
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .fatLoss:     return "scalemass"
        case .strength:    return "hare.fill"
        case .endurance:   return "figure.walk"
        case .wellness:    return "heart.text.square"
        }
    }
}

// MARK: - OnboardingGoalView
/// Onboarding step for selecting primary training goal.
@MainActor
public struct OnboardingGoalView: View {

    // MARK: State
    @State private var selectedGoal: TrainingGoal?
    var onContinue: (TrainingGoal) -> Void

    // MARK: Body
    public var body: some View {
        VStack(spacing: 32) {
            header

            goalGrid

            continueButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Subviews
    private var header: some View {
        VStack(spacing: 12) {
            Text("What’s your primary goal?")
                .font(.system(.title, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("Choose the focus that best matches what you’d like to achieve first.")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
    }

    private var goalGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 20) {
            ForEach(TrainingGoal.allCases) { goal in
                goalCard(for: goal)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedGoal = goal
                        }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    }
            }
        }
    }

    private func goalCard(for goal: TrainingGoal) -> some View {
        let isSelected = goal == selectedGoal
        return VStack(spacing: 8) {
            Image(systemName: goal.iconName)
                .font(.system(size: 28, weight: .medium))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(isSelected
                              ? LinearGradient(colors: [Color.brandPurpleStart,
                                                        Color.brandPurpleEnd],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                              : Color.gray.opacity(0.2))
                )
                .foregroundStyle(.white)

            Text(goal.rawValue)
                .font(.system(.subheadline, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected
                      ? Color.brandPurpleStart.opacity(0.15)
                      : Color.gray.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected
                        ? LinearGradient(colors: [Color.brandPurpleStart,
                                                  Color.brandPurpleEnd],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                        : Color.clear,
                        lineWidth: 2)
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var continueButton: some View {
        Button {
            guard let goal = selectedGoal else { return }
            onContinue(goal)
        } label: {
            Text("Continue")
                .font(.system(.headline, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    LinearGradient(
                        colors: selectedGoal == nil
                        ? [Color.gray, Color.gray]
                        : [Color.brandPurpleStart, Color.brandPurpleEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(selectedGoal == nil)
        .accessibilityHint("Proceed to the next step of onboarding")
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    OnboardingGoalView { _ in }
        .preferredColorScheme(.dark)
}
#endif
