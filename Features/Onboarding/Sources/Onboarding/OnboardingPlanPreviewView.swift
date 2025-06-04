//
//  OnboardingPlanPreviewView.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI

// MARK: - PlanPreview Model
public struct PlanPreview: Identifiable {
    public let id = UUID()
    public let goal: TrainingGoal
    public let experience: TrainingExperience
    public let frequency: TrainingFrequency
    public let preferences: UserPreferences
}

// MARK: - OnboardingPlanPreviewView
@MainActor
public struct OnboardingPlanPreviewView: View {

    // MARK: Inputs
    public let preview: PlanPreview
    public var onConfirm: () -> Void

    // Derived trainer-recommended sets per compound lift
    private var recommendedSets: Int {
        switch (preview.experience, preview.frequency) {
        case (.beginner, .two), (.beginner, .three):               return 9
        case (.beginner, _), (.intermediate, .two):                return 12
        case (.intermediate, .three), (.intermediate, .four):      return 15
        case (.intermediate, _), (.advanced, .two):                return 18
        case (.advanced, .three):                                  return 20
        case (.advanced, _):                                       return 22
        }
    }

    // Which weekdays are training days
    private var trainingDays: [String] {
        let allDays = Calendar.current.weekdaySymbols // ["Sunday", …]
        let start = Calendar.current.firstWeekday - 1 // 0-based index
        let rotated = Array(allDays[start...] + allDays[..<start])
        return Array(rotated.prefix(preview.frequency.rawValue))
    }

    // MARK: Body
    public var body: some View {
        VStack(spacing: 32) {
            header

            summaryCard

            scheduleCard

            confirmButton
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
            Text("Your Personalized Plan")
                .font(.system(.title, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text("Review the details before we generate your first mesocycle.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(label: "Goal", value: preview.goal.rawValue)
            row(label: "Experience", value: preview.experience.rawValue)
            row(label: "Training Days / wk", value: "\(preview.frequency.rawValue)")
            row(label: "Sets / major lift", value: "\(recommendedSets)")
            row(label: "Notifications", value: preview.preferences.notifications ? "Enabled" : "Off")
            row(label: "Health Sync", value: preview.preferences.healthSync ? "Enabled" : "Off")
            row(label: "Units", value: preview.preferences.metricUnits ? "Metric" : "Imperial")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.gray.opacity(0.15))
        )
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(.subheadline, weight: .medium))
        }
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Schedule")
                .font(.system(.headline, weight: .semibold))

            ForEach(trainingDays, id: \.self) { day in
                HStack(spacing: 8) {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: 0x8C3DFF),
                                                      Color(hex: 0x4925D6)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 10, height: 10)
                    Text(day)
                        .font(.system(.body, design: .rounded))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.gray.opacity(0.15))
        )
    }

    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text("Looks Great • Start Training")
                .font(.system(.headline, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    LinearGradient(colors: [Color(hex: 0x8C3DFF), Color(hex: 0x4925D6)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityHint("Confirm your plan and enter the main app")
    }
}

// MARK: - Color Helper
private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex & 0xFF0000) >> 16) / 255,
                  green: Double((hex & 0x00FF00) >> 8) / 255,
                  blue: Double(hex & 0x0000FF) / 255,
                  opacity: opacity)
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    let prefs = UserPreferences(notifications: true,
                                healthSync: true,
                                metricUnits: false,
                                newsletter: true)
    let preview = PlanPreview(goal: .hypertrophy,
                              experience: .intermediate,
                              frequency: .five,
                              preferences: prefs)
    OnboardingPlanPreviewView(preview: preview) { }
        .preferredColorScheme(.dark)
}
#endif
