//
//  ExerciseCardView.swift
//  Planner – Components
//
//  Presents a single ExercisePlan in the workout-planner grid.
//  Brand-aligned visuals: deep-black card, 24 pt radius, subtle
//  shadow, and a phoenix-gradient accent bar. Dynamic Type ready.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain               // ExercisePlan, Exercise, MuscleGroup

// MARK: - ExerciseCardView

public struct ExerciseCardView: View {

    // MARK: Input

    public let plan: ExercisePlan
    public let exercise: Exercise

    // MARK: Body

    public var body: some View {
        ZStack(alignment: .leading) {
            // Background card
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.95))
                .shadow(color: Color.black.opacity(0.6), radius: 4, y: 2)

            // Gradient accent strip (left edge)
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 6)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Exercise name
                Text(exercise.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .accessibility(addTraits: .isHeader)

                // Set × rep range
                HStack(spacing: 4) {
                    Text("\(plan.sets) sets")
                    Text("•")
                    Text("\(plan.repRange.min)-\(plan.repRange.max) reps")
                }
                .font(.footnote.weight(.medium))
                .foregroundColor(.white.opacity(0.8))

                // Primary muscle chips
                muscleChipStack(for: exercise.primaryMuscles)
                    .padding(.top, 2)
            }
            .padding(.leading, 14) // leaves space for accent strip
            .padding(.vertical, 12)
            .padding(.trailing, 16)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Helpers

    @ViewBuilder
    private func muscleChipStack(for muscles: Set<MuscleGroup>) -> some View {
        LazyHStack(spacing: 4) {
            ForEach(muscles.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { group in
                Text(group.displayName)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
                    .foregroundColor(.white)
                    .accessibilityLabel(group.displayName)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
import CoreUI    // Design tokens (colors)

struct ExerciseCardView_Previews: PreviewProvider {
    static let sampleExercise = Exercise(
        name: "Flat Barbell Bench Press",
        primaryMuscles: [.chest],
        mechanicalPattern: .horizontalPush,
        equipment: .barbell
    )

    static let samplePlan = ExercisePlan(
        exerciseId: sampleExercise.id,
        sets: 3,
        repRange: .init(min: 8, max: 12)
    )

    static var previews: some View {
        ExerciseCardView(plan: samplePlan, exercise: sampleExercise)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
#endif
