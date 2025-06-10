// MARK: - TodayWorkoutCardView.swift

import SwiftUI
import Domain            // WorkoutSession model
import CoreUI            // Brand colors, gradients, typography tokens

/// A card that previews today’s workout plan.
/// • Uses the phoenix gradient for branding.
/// • Taps route to either start the workout or open the planner.
struct TodayWorkoutCardView: View {
    // MARK: - Input
    let plan: WorkoutSession?
    let action: () -> Void

    // MARK: - Body
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {

                // Workout title (or placeholder)
                Text(plan?.title ?? NSLocalizedString("No Workout Planned",
                                                      comment: "Placeholder when no workout today"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Gradient.linearPhoenix)

                Divider()
                    .overlay(Color.separator.opacity(0.15))

                // Stats row
                HStack(spacing: 16) {
                    statView(value: plan?.totalSets ?? 0,
                             label: NSLocalizedString("Sets", comment: "Sets count"))
                    statView(value: plan?.totalReps ?? 0,
                             label: NSLocalizedString("Reps", comment: "Reps count"))
                    statView(value: plan?.totalVolumeKg ?? 0,
                             label: "kg",
                             formatter: .weight)
                }

                Spacer(minLength: 4)

                // CTA
                Text(NSLocalizedString("Start", comment: "Start workout button"))
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Gradient.linearPhoenix)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .accessibilityHidden(plan == nil)      // hide CTA when not actionable
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.cardBackground)
            )
            .shadow(color: Color.black.opacity(0.25),
                    radius: 8, y: 4)                     // elevated card shadow
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabelText)
    }

    // MARK: - Helpers
    @ViewBuilder
    private func statView(value: Int,
                          label: String,
                          formatter: NumberFormatter = .plain) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formatter.string(from: NSNumber(value: value)) ?? "-")
                .font(.title3.monospacedDigit().weight(.semibold))
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(Color.secondaryLabel)
        }
    }

    /// Dynamic a11y label describing workout card details.
    private var accessibilityLabelText: Text {
        if let plan {
            let stats = "\(plan.totalSets) sets, " +
                        "\(plan.totalReps) reps, " +
                        "\(plan.totalVolumeKg) kilograms."
            return Text("Today's workout: \(plan.title), \(stats) Tap to start.")
        } else {
            return Text("No workout planned. Tap to plan your next session.")
        }
    }
}
