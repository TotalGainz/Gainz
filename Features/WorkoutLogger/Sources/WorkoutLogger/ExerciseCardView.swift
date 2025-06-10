// ExerciseCardView.swift

import SwiftUI
import Domain               // ExercisePlan, Exercise, MuscleGroup
import CoreUI               // Design tokens (colors, typography)

// MARK: - ExerciseCardView

/// A styled card view presenting a single ExercisePlan in the workout planner grid.
public struct ExerciseCardView: View {
    // MARK: Input
    public let plan: ExercisePlan
    public let exercise: Exercise

    // MARK: Body
    public var body: some View {
        ZStack(alignment: .leading) {
            // Background card surface
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.surfaceElevated)
                .shadow(color: Color.black.opacity(0.6), radius: 4, y: 2)

            // Gradient accent strip along the left edge
            LinearGradient(
                colors: [Color.phoenixStart, Color.phoenixEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 6)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            // Content stack (exercise name, set/rep info, muscle tags)
            VStack(alignment: .leading, spacing: 4) {
                // Exercise name
                Text(exercise.name)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(Color.onSurfacePrimary)
                    .lineLimit(2)
                    .accessibility(addTraits: .isHeader)

                // Set × rep range
                HStack(spacing: 4) {
                    Text("\(plan.sets) sets")
                    Text("•")
                    Text("\(plan.repRange.min)-\(plan.repRange.max) reps")
                }
                .font(.footnote.weight(.medium))
                .foregroundColor(Color.onSurfacePrimary.opacity(0.8))

                // Primary muscle group tags
                muscleChipStack(for: exercise.primaryMuscles)
                    .padding(.top, 2)
            }
            .padding(.leading, 14)  // space for accent strip
            .padding(.vertical, 12)
            .padding(.trailing, 16)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Helpers

    @ViewBuilder
    private func muscleChipStack(for muscles: Set<MuscleGroup>) -> some View {
        LazyHStack(spacing: 4) {
            ForEach(muscles.sorted(by: { $0.displayName < $1.displayName }), id: \.self) { group in
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
import SwiftUI

struct ExerciseCardView_Previews: PreviewProvider {
    static let sampleExercise = Exercise(
        id: UUID(),
        name: "Flat Barbell Bench Press",
        primaryMuscles: [.chest],
        mechanicalPattern: .horizontalPush,
        equipment: .barbell
    )
    static let samplePlan = ExercisePlan(
        exerciseId: sampleExercise.id,
        sets: 3,
        repRange: RepRange(min: 8, max: 12)
    )

    static var previews: some View {
        ExerciseCardView(plan: samplePlan, exercise: sampleExercise)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}
#endif
