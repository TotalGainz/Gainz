// OnboardingFrequencyView.swift
//
//  OnboardingFrequencyView.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI

// MARK: - TrainingFrequency
public enum TrainingFrequency: Int, CaseIterable, Identifiable, Sendable {
    case two = 2, three, four, five, six, seven

    public var id: Int { rawValue }

    var label: String { "\(rawValue) days" }
}

// MARK: - OnboardingFrequencyView
/// Onboarding step for selecting weekly training frequency.
@MainActor
public struct OnboardingFrequencyView: View {

    // MARK: State
    @State private var selected: TrainingFrequency?
    var onContinue: (TrainingFrequency) -> Void

    // MARK: Body
    public var body: some View {
        VStack(spacing: 32) {
            header

            frequencyGrid

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
            Text("How many days per week can you train?")
                .font(.system(.title, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("We’ll build your plan around this commitment.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    private var frequencyGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 20) {
            ForEach(TrainingFrequency.allCases) { freq in
                dayButton(for: freq)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selected = freq
                        }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func dayButton(for freq: TrainingFrequency) -> some View {
        let isSelected = freq == selected
        return Text(freq.label)
            .font(.system(.subheadline, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected
                          ? LinearGradient(colors: [Color(hex: 0x8C3DFF),
                                                    Color(hex: 0x4925D6)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                          : Color.gray.opacity(0.15))
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? .clear : Color.gray.opacity(0.4), lineWidth: 1)
            )
            .accessibilityLabel("\(freq.rawValue) days per week")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var continueButton: some View {
        Button {
            guard let freq = selected else { return }
            onContinue(freq)
        } label: {
            Text("Continue")
                .font(.system(.headline, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    LinearGradient(
                        colors: selected == nil
                        ? [Color.gray, Color.gray]
                        : [Color.brandPurpleStart, Color.brandPurpleEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(selected == nil)
        .accessibilityHint("Save your weekly training frequency and continue")
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    OnboardingFrequencyView { _ in }
        .preferredColorScheme(.dark)
}
#endif
