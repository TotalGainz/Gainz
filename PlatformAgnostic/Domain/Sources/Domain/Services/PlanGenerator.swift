/// PlanGenerator.swift

import Foundation

/// Input parameters for generating a new training plan (mesocycle).
public struct PlanInput: Hashable, Sendable {
    /// Length of the mesocycle in weeks (typically 4–6).
    public let weeks: Int
    /// Training days per week.
    public let daysPerWeek: Int
    /// Target weekly volume (effective sets) per muscle group.
    /// e.g. `[.chest: 16, .back: 18, .quads: 14]`
    public let weeklyVolumeTargets: [MuscleGroup: Int]
    /// Default repetition range to assign for exercises.
    public let defaultRepRange: RepRange
    /// Weekly volume ramp-up factor (e.g., 0.05 for +5% volume each week).
    public let weeklyVolumeRamp: Double

    public init(
        weeks: Int,
        daysPerWeek: Int,
        weeklyVolumeTargets: [MuscleGroup: Int],
        defaultRepRange: RepRange = RepRange(min: 8, max: 12),
        weeklyVolumeRamp: Double = 0.05
    ) {
        precondition(weeks > 0 && weeks <= 12, "weeks must be between 1 and 12.")
        precondition(daysPerWeek > 0 && daysPerWeek <= 7, "daysPerWeek must be 1–7.")
        self.weeks = weeks
        self.daysPerWeek = daysPerWeek
        self.weeklyVolumeTargets = weeklyVolumeTargets
        self.defaultRepRange = defaultRepRange
        self.weeklyVolumeRamp = weeklyVolumeRamp
    }
}

/// Protocol allowing different plan generation algorithms to be used.
public protocol PlanGenerating: Sendable {
    /// Generate a fully populated `MesocyclePlan` from the given input parameters.
    func makePlan(from input: PlanInput) async -> MesocyclePlan
}

/// Default implementation of the plan generator.
public struct DefaultPlanGenerator: PlanGenerating {
    private let exerciseRepo: ExerciseRepository

    /// Initialize with an `ExerciseRepository` to pull available exercises.
    public init(exerciseRepo: ExerciseRepository) {
        self.exerciseRepo = exerciseRepo
    }

    /// Generate a `MesocyclePlan` from the provided input.
    public func makePlan(from input: PlanInput) async -> MesocyclePlan {
        // 1. Build skeletal weeks and distribute volume across days
        var generatedWorkouts: [WorkoutPlan] = []
        for weekIndex in 0..<input.weeks {
            // Calculate volume allocation for this week (progressively overload until last week which might be deload)
            let weekFactor = (weekIndex == input.weeks - 1) ? 0.6 : (1.0 + input.weeklyVolumeRamp * Double(weekIndex))
            // Adjust target sets for this week
            let weekTargets = input.weeklyVolumeTargets.mapValues { baseSets in
                Int(Double(baseSets) * weekFactor / Double(input.daysPerWeek))
            }
            // Create each day for the week
            for dayIndex in 0..<input.daysPerWeek {
                if let workout = await makeWorkout(week: weekIndex, day: dayIndex, dailyTargets: weekTargets, defaultRepRange: input.defaultRepRange) {
                    generatedWorkouts.append(workout)
                }
            }
        }
        // 2. Assemble MesocyclePlan
        return MesocyclePlan(
            objective: .hypertrophy,
            weeks: input.weeks,
            workouts: generatedWorkouts
        )
    }

    // MARK: - Helper to build a single day's workout

    private func makeWorkout(week: Int,
                              day: Int,
                              dailyTargets: [MuscleGroup: Int],
                              defaultRepRange: RepRange) async -> WorkoutPlan? {
        var prescriptions: [ExercisePrescription] = []
        for (muscle, setsNeeded) in dailyTargets {
            guard setsNeeded > 0 else { continue }
            // Pick a random exercise for this muscle group
            let exercises = try? await exerciseRepo.fetchAll()
            let candidates = exercises?.filter { $0.primaryMuscles.contains(muscle) } ?? []
            guard let exercise = candidates.randomElement() else { continue }
            let prescription = ExercisePrescription(
                exerciseId: exercise.id,
                sets: setsNeeded,
                repRange: defaultRepRange,
                targetRIR: 1,    // e.g., leave 1 rep in reserve by default
                percent1RM: nil
            )
            prescriptions.append(prescription)
        }
        guard !prescriptions.isEmpty else {
            return nil
        }
        let name = "Week \(week+1) Day \(day+1)"
        return WorkoutPlan(id: UUID(), name: name, week: week, dayOfWeek: day, exercises: prescriptions)
    }
}
