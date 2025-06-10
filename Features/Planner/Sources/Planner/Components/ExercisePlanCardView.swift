//
//  ExercisePlanCardView.swift
//  Features • Planner • Components
//
//  A single card row inside the Planner that previews one ExercisePlan.
//  Uses design system tokens for color, typography, and corner radius.
//  No HRV / velocity metrics—just hypertrophy-centric data.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain                     // ExercisePlan & Exercise models
import CoreUI                     // Color & typography tokens
import Combine

// MARK: - View

public struct ExercisePlanCardView: View {
    // MARK: Dependencies
    private let exercise: Exercise
    private let plan: ExercisePlan

    // MARK: Init
    public init(exercise: Exercise, plan: ExercisePlan) {
        self.exercise = exercise
        self.plan = plan
    }

    // MARK: Body
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            // Leading muscle group avatar or fallback icon
            MuscleGroupAvatar(muscleGroup: exercise.primaryMuscles.first!)
            // Textual data (exercise name, volume, target RPE if any)
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)                      // SF Pro Rounded default
                    .foregroundStyle(Color.primary)
                Text(volumeString)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                if let rpe = plan.targetRPE {
                    Text("Target \(rpe.description)")
                        .font(.caption)
                        .foregroundStyle(Color.accent)
                }
            }
            Spacer(minLength: 0)
            // Chevron icon indicating navigable detail
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.cardBackground)              // deep black surface
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        )
        .overlay(GradientEdgeMask())                     // subtle phoenix gradient edge highlight
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }
}

// MARK: - Derived Helpers

private extension ExercisePlanCardView {
    /// e.g. "3 × 8-12" for sets × rep range.
    var volumeString: String {
        "\(plan.sets) × \(plan.repRange.min)-\(plan.repRange.max)"
    }
    /// Combined text for VoiceOver (exercise name, sets/reps, target RPE if present).
    var accessibilitySummary: String {
        var parts: [String] = []
        parts.append(exercise.name)
        parts.append("\(plan.sets) sets of \(plan.repRange.min)-\(plan.repRange.max) reps")
        if let rpe = plan.targetRPE {
            parts.append("Target \(rpe.description)")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#if DEBUG
import SwiftDataMocks   // convenience fixtures in dev target

#Preview("Exercise Plan Card") {
    ExercisePlanCardView(
        exercise: .mockBenchPress,
        plan: .mockBenchPlan
    )
    .padding()
    .background(Color.black)
}
#endif
