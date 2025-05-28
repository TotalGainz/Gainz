//
//  PlanGenerator.swift
//  Domain – Services
//
//  Pure-Swift engine that converts user-supplied training goals
//  into a periodised MesocyclePlan. 100 % UI-free and platform-
//  agnostic so it can run on iOS, watchOS, macOS, Android (via
//  KMP), or server-side Swift.
//
//  Design notes:
//  • Follows the point model described in Mesocycle Builder spec
//    (1 pt primary, 0.5 pt secondary). :contentReference[oaicite:0]{index=0}
//  • Computes set distribution per muscle so weekly volume hits
//    evidence-based hypertrophy ranges (10–20 sets). :contentReference[oaicite:1]{index=1}
//  • No HRV/recovery/velocity inputs—hypertrophy only. :contentReference[oaicite:2]{index=2}
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - Public API

/// Input contract for generating a mesocycle.
public struct PlanInput: Hashable {

    /// Number of weeks in the cycle (4–6 typical).
    public let weeks: Int

    /// Training days per week (e.g., 4 = upper/lower split).
    public let daysPerWeek: Int

    /// Muscle-group → weekly target effective sets.
    /// Example: [.chest: 16, .back: 18, .quads: 14]
    public let weeklyVolumeTargets: [MuscleGroup: Int]

    /// Default rep range to assign to each ExercisePlan.
    public let defaultRepRange: RepRange

    /// Optional progression curve (percentage increase each week).
    public let weeklyVolumeRamp: Double

    public init(
        weeks: Int = 4,
        daysPerWeek: Int = 4,
        weeklyVolumeTargets: [MuscleGroup: Int],
        defaultRepRange: RepRange = .init(min: 8, max: 12),
        weeklyVolumeRamp: Double = 0.05 // +5 % each week
    ) {
        precondition(weeks > 0 && weeks <= 12, "Cycle length must be 1–12 weeks")
        precondition(daysPerWeek > 0 && daysPerWeek <= 7, "Days/week 1–7")
        self.weeks = weeks
        self.daysPerWeek = daysPerWeek
        self.weeklyVolumeTargets = weeklyVolumeTargets
        self.defaultRepRange = defaultRepRange
        self.weeklyVolumeRamp = weeklyVolumeRamp
    }
}

/// Protocol allows swapping different generators in tests.
public protocol PlanGenerating {
    func makePlan(from input: PlanInput) -> MesocyclePlan
}

// MARK: - Default Implementation

public struct DefaultPlanGenerator: PlanGenerating {

    private let exerciseRepo: ExerciseRepository

    /// Inject repositories so we can fetch catalog exercises.
    public init(exerciseRepo: ExerciseRepository) {
        self.exerciseRepo = exerciseRepo
    }

    // Entrypoint
    public func makePlan(from input: PlanInput) -> MesocyclePlan {

        // 1. Build skeleton weeks and workouts
        let weeks = (0..<input.weeks).map { weekIndex in
            makeWeek(index: weekIndex,
                     input: input,
                     progressionMultiplier: pow(1 + input.weeklyVolumeRamp,
                                                Double(weekIndex)))
        }

        return MesocyclePlan(
            id: UUID(),
            name: "Hypertrophy \(input.weeks)-Week Block",
            weeks: weeks,
            createdDate: Date()
        )
    }

    // MARK: Helpers

    /// Generates one Week with evenly spread volume across days.
    private func makeWeek(index: Int,
                          input: PlanInput,
                          progressionMultiplier: Double) -> MesocyclePlan.Week {

        // Calculate per-day effective set targets
        let perDayTargets = input.weeklyVolumeTargets.mapValues { volume in
            Int( Double(volume) * progressionMultiplier / Double(input.daysPerWeek) )
        }

        // Create day slots
        let days = (0..<input.daysPerWeek).map { dayIndex in
            MesocyclePlan.Day(
                date: nil, // planner fills actual dates later
                workout: makeWorkout(
                    week: index,
                    day: dayIndex,
                    perDayTargets: perDayTargets,
                    defaultRepRange: input.defaultRepRange
                )
            )
        }

        return .init(index: index, days: days)
    }

    /// Builds a WorkoutPlan hitting per-day muscle targets.
    private func makeWorkout(week: Int,
                             day: Int,
                             perDayTargets: [MuscleGroup: Int],
                             defaultRepRange: RepRange) -> WorkoutPlan {

        // Naïve algorithm: for each target muscle, pick one catalog exercise
        // whose primary muscle matches, assign required sets.
        var exercisePlans: [ExercisePlan] = []

        for (muscle, setsNeeded) in perDayTargets {
            guard let exercise = exerciseRepo.random(byPrimary: muscle) else { continue }

            let plan = ExercisePlan(
                exerciseId: exercise.id,
                sets: setsNeeded,
                repRange: defaultRepRange,
                targetRPE: .eight,
                restInterval: 90
            )
            exercisePlans.append(plan)
        }

        return WorkoutPlan(
            id: UUID(),
            name: "Week \(week + 1) Day \(day + 1)",
            exercises: exercisePlans
        )
    }
}

// MARK: - ExerciseRepository Helper

/// Minimal subset of the repository protocol needed by the generator.
public protocol ExerciseRepository {
    /// Returns a random exercise whose primary muscle matches.
    func random(byPrimary muscle: MuscleGroup) -> Exercise?
}
