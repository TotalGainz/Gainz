// OnboardingPreferencesView.swift
//
//  OnboardingPreferencesView.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI

// MARK: - OnboardingPreferencesView
/// Onboarding step for setting user preferences (notifications, units, etc.).
@MainActor
public struct OnboardingPreferencesView: View {

    // MARK: State
    @State private var enableReminders: Bool       = true
    @State private var syncHealthKit: Bool         = true
    @State private var useMetricUnits: Bool        = false
    @State private var subscribeNewsletter: Bool   = true

    var onFinish: (UserPreferences) -> Void

    // MARK: Body
    public var body: some View {
        VStack(spacing: 32) {
            header

            preferencesForm

            finishButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Header
    private var header: some View {
        VStack(spacing: 12) {
            Text("Fine-tune your experience")
                .font(.system(.title, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("You can change these anytime in Settings.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    // MARK: Preferences
    private var preferencesForm: some View {
        Form {
            Section {
                preferenceToggle(
                    title: "Workout Reminders",
                    subtitle: "Receive push notifications when it's time to train.",
                    systemImage: "bell.badge.fill",
                    isOn: $enableReminders
                )

                preferenceToggle(
                    title: "Sync with Apple Health",
                    subtitle: "Keep all your metrics in one place.",
                    systemImage: "heart.fill",
                    isOn: $syncHealthKit
                )

                preferenceToggle(
                    title: "Use Metric Units",
                    subtitle: "Kilograms and centimeters instead of pounds and inches.",
                    systemImage: "ruler.fill",
                    isOn: $useMetricUnits
                )

                preferenceToggle(
                    title: "Training Tips Newsletter",
                    subtitle: "Occasional emails with evidence-based guidance.",
                    systemImage: "envelope.fill",
                    isOn: $subscribeNewsletter
                )
            }
            .listRowSeparator(.hidden)
        }
        .scrollContentBackground(.hidden)
        .frame(maxHeight: 320)
    }

    private func preferenceToggle(
        title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient.brandGradient
                            .clipShape(Circle())
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, weight: .semibold, design: .rounded))
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 4)
    }

    // MARK: Finish
    private var finishButton: some View {
        Button {
            let prefs = UserPreferences(notifications: enableReminders,
                                        healthSync: syncHealthKit,
                                        metricUnits: useMetricUnits,
                                        newsletter: subscribeNewsletter)
            onFinish(prefs)
        } label: {
            Text("Finish")
                .font(.system(.headline, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x8C3DFF), Color(hex: 0x4925D6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityHint("Save your preferences and finish onboarding")
    }
}

// MARK: - Preferences Model
public struct UserPreferences: Codable, Sendable {
    public let notifications: Bool
    public let healthSync: Bool
    public let metricUnits: Bool
    public let newsletter: Bool
}

// MARK: - Preview
#if DEBUG
#Preview {
    OnboardingPreferencesView { _ in }
        .preferredColorScheme(.dark)
}
#endif
