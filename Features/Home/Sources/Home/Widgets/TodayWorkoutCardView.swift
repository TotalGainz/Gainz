//
//  TodayWorkoutCardView.swift
//  HomeFeature • Widgets
//
//  Widget-sized card that previews today’s workout.
//  • Uses phoenix-gradient accent on headline.
//  • Taps route straight into WorkoutLogger (deep link).
//

import SwiftUI
import Domain
import CoreUI

struct TodayWorkoutCardView: View {

    // MARK: – Dependencies
    let plan: WorkoutSession?
    let action: () -> Void

    // MARK: – Body
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {

                // Header
                Text(plan?.title ?? "No Workout Planned")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Gradient.linearPhoenix)

                // Divider
                Rectangle()
                    .fill(Color.separator)
                    .frame(height: 1)
                    .opacity(0.15)

                // Stats row
                HStack(spacing: 16) {
                    statView(value: plan?.totalSets ?? 0, label: "Sets")
                    statView(value: plan?.totalReps ?? 0, label: "Reps")
                    statView(value: plan?.totalVolumeKg ?? 0, label: "kg",
                             formatter: .weight)
                }

                Spacer(minLength: 4)

                // CTA
                Text("Start")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Gradient.linearPhoenix)
                    .cornerRadius(12)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.25), radius: 8, y: 4) // modern card shadow  [oai_citation:4‡Stack Overflow](https://stackoverflow.com/questions/58933590/how-to-give-shadow-with-cornerradius-to-a-button-in-swiftui?utm_source=chatgpt.com)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Helpers
    @ViewBuilder
    private func statView(value: Int, label: String, formatter: NumberFormatter = .plain) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formatter.string(from: NSNumber(value: value)) ?? "-")
                .font(.title3.monospacedDigit().weight(.semibold))
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.secondaryLabel)
        }
    }
}

// MARK: – Preview
#Preview("Widget Card") {
    TodayWorkoutCardView(
        plan: .mockToday,
        action: {}
    )
    .frame(width: 320, height: 150)
    .padding()
    .background(Color.black)
}
