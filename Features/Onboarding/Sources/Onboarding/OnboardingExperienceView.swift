// OnboardingExperienceView.swift
//
//  OnboardingExperienceView.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI

// MARK: - TrainingExperience
/// User-declared lifting experience bracket.
public enum TrainingExperience: String, CaseIterable, Identifiable, Sendable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"

    public var id: String { rawValue }

    /// Friendly one-liner shown below the main title.
    var subtitle: String {
        switch self {
        case .beginner:     return "〈 < 1 year training 〉"
        case .intermediate: return "〈 1-3 years training 〉"
        case .advanced:     return "〈 3 + years training 〉"
        }
    }

    /// SF Symbol fallback if custom art isn’t provided yet.
    var iconName: String {
        switch self {
        case .beginner:     return "star"
        case .intermediate: return "star.leadinghalf.filled"
        case .advanced:     return "star.fill"
        }
    }
}

// MARK: - OnboardingExperienceView
/// Onboarding step for selecting training experience level.
@MainActor
public struct OnboardingExperienceView: View {

    // MARK: State
    @State private var selection: TrainingExperience?
    var onContinue: (TrainingExperience) -> Void

    // MARK: Body
    public var body: some View {
        VStack(spacing: 32) {
            header

            segmentedPicker

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
            Text("How experienced are you?")
                .font(.system(.title, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("This helps us tailor your first program.")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
    }

    private var segmentedPicker: some View {
        Picker("Experience level", selection: $selection) {
            ForEach(TrainingExperience.allCases) { level in
                HStack(spacing: 6) {
                    Image(systemName: level.iconName)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(level.rawValue)
                            .font(.system(.subheadline, weight: .semibold))
                        Text(level.subtitle)
                            .font(.system(.caption2))
                    }
                }
                .tag(Optional(level))
                .accessibilityLabel(level.rawValue)
                .accessibilityHint(level.subtitle)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.brandPurpleStart)
        .padding(.top, 8)
    }

    private var continueButton: some View {
        Button {
            guard let level = selection else { return }
            onContinue(level)
        } label: {
            Text("Continue")
                .font(.system(.headline, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    LinearGradient(
                        colors: selection == nil
                        ? [Color.gray, Color.gray]
                        : [Color(hex: 0x8C3DFF), Color(hex: 0x4925D6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(selection == nil)
        .accessibilityHint("Save your experience level and continue")
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    OnboardingExperienceView { _ in }
        .preferredColorScheme(.dark)
}
#endif
