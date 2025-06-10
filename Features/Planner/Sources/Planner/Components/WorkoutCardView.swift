//
//  WorkoutCardView.swift
//  Features ▸ Planner ▸ Components
//
//  Small, tappable card that surfaces a single planned workout.
//  • Dark slate background with 24-pt corners and subtle shadow.
//  • 2-pt “phoenix” gradient stroke (Indigo → Violet) around the card.
//  • Auto-scales with Dynamic Type; fully VoiceOver accessible.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain   // WorkoutPlan, ExercisePlan models
import CoreUI   // Design tokens (colors, fonts)

// MARK: - WorkoutCardView

public struct WorkoutCardView: View {
    // MARK: Input
    public let plan: WorkoutPlan
    public var onTap: (() -> Void)?

    // MARK: Body
    public var body: some View {
        Button(action: { onTap?() }) {
            cardContent
                .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.backgroundPrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(phoenixGradient, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Sub-views

    /// The inner content of the workout card.
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title of the workout
            Text(plan.title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            // Date of the workout
            Text(plan.date, style: .date)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            Divider().background(Color.border)
            // Stats row: duration, sets, exercise count
            HStack(spacing: 16) {
                statView(icon: "clock.fill",
                         value: plan.estimatedDuration.string,
                         label: "min")
                statView(icon: "flame.fill",
                         value: "\(plan.totalSets)",
                         label: "sets")
                statView(icon: "repeat",
                         value: "\(plan.exercises.count)",
                         label: "moves")
            }
            .font(.caption)
            .foregroundColor(.textSecondary)
        }
    }

    /// A small view for an individual stat with SF Symbol icon, value, and label.
    private func statView(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
            Text(value)
                .fontWeight(.semibold)
            Text(label)
        }
    }

    // MARK: Styling Helpers

    /// The purple “Phoenix” gradient used for the card border.
    private var phoenixGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.accentStart, Color.accentEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Accessibility label combining key info.
    private var accessibilityLabel: String {
        "\(plan.title), \(plan.totalSets) sets, \(plan.exercises.count) exercises"
    }
}

// MARK: - Preview

#if DEBUG
struct WorkoutCardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockPlan = WorkoutPlan.mock
        Group {
            WorkoutCardView(plan: mockPlan)
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
