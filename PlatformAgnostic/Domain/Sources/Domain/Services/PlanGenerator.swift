/// PlanGenerator.swift

import Foundation
import Dispatch

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
        defaultRepRange: RepRange,
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

// MARK: - Synchronous Facade

/// High-level synchronous API for generating training plans (mesocycle and daily workouts).
/// Internally wraps the async `DefaultPlanGenerator` for ease of use in non-async contexts.
/// Synchronous facade over async plan generation, wrapping a `PlanGenerating` implementation.
/// Conforms to `Sendable` to support usage in concurrent contexts.
public struct PlanGenerator: Sendable {
    private let generator: PlanGenerating
    private let defaultRepRange: RepRange

    /// Supported weekly split templates.
    public enum SplitTemplate {
        case fullBody, pushPullLegs, upperLower
    }

    /// Specifies a given day within a mesocycle for single-workout generation.
    public enum WorkoutDay {
        case monday(ofWeek: Int), tuesday(ofWeek: Int), wednesday(ofWeek: Int)
        case thursday(ofWeek: Int), friday(ofWeek: Int), saturday(ofWeek: Int), sunday(ofWeek: Int)
    }

    /// Initialize with an exercise repository to draw from for plan generation.
    public init(exerciseRepository: ExerciseRepository) {
        self.generator = DefaultPlanGenerator(exerciseRepo: exerciseRepository)
        // Default rep range bounds chosen for hypertrophy context (5–30 reps)
        self.defaultRepRange = try! RepRange(min: 5, max: 30)
    }

    /// Generate a multi-week mesocycle plan summary, blocking until completion.
    public func generateMesocycle(
        goal: Objective,
        lengthInWeeks: Int,
        splitTemplate: SplitTemplate
    ) throws -> MesocyclePlan {
        let days = splitTemplate.daysPerWeek
        let targets = splitTemplate.baseVolumeTargets(for: goal)
        let input = PlanInput(
            weeks: lengthInWeeks,
            daysPerWeek: days,
            weeklyVolumeTargets: targets,
            defaultRepRange: defaultRepRange
        )
        return try runSynchronously { await generator.makePlan(from: input) }
    }

    /// Generate a single workout plan for a specified day in the cycle.
    public func generateWorkout(
        for day: WorkoutDay,
        goal: Objective,
        splitTemplate: SplitTemplate
    ) throws -> WorkoutPlan {
        // Derive the full cycle plan first
        let cycle = try generateMesocycle(goal: goal, lengthInWeeks: day.weekCount, splitTemplate: splitTemplate)
        // Match the requested day
        return cycle.workouts.first {
            $0.week == day.week && $0.dayOfWeek == day.weekday
        }!
    }
}

// MARK: - Helpers & Extensions

/// Block on an async call, synchronously waiting for its result.
private func runSynchronously<T>(_ task: @escaping @Sendable () async -> T) throws -> T {
    let group = DispatchGroup()
    group.enter()
    var result: T! = nil
    Task {
        result = await task()
        group.leave()
    }
    group.wait()
    return result
}

private extension PlanGenerator.SplitTemplate {
    var daysPerWeek: Int {
        switch self {
        case .fullBody: return 2
        case .pushPullLegs: return 3
        case .upperLower: return 4
        }
    }
    func baseVolumeTargets(for goal: Objective) -> [MuscleGroup: Int] {
        // Uniform base sets per muscle based on goal
        let base = (goal == .hypertrophy ? 14 : 18)
        return Dictionary(uniqueKeysWithValues: MuscleGroup.allCases.map { ($0, base) })
    }
}

private extension PlanGenerator.WorkoutDay {
    var week: Int {
        switch self {
        case .monday(ofWeek: let w), .tuesday(ofWeek: let w), .wednesday(ofWeek: let w),
             .thursday(ofWeek: let w), .friday(ofWeek: let w), .saturday(ofWeek: let w), .sunday(ofWeek: let w):
            return w
        }
    }
    var weekday: Int {
        switch self {
        case .monday:    return 0
        case .tuesday:   return 1
        case .wednesday: return 2
        case .thursday:  return 3
        case .friday:    return 4
        case .saturday:  return 5
        case .sunday:    return 6
        }
    }
    var weekCount: Int { week + 1 }
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
            // Calculate weekly ramp factor (progressive overload, deload at final week)
            let weekFactor = (weekIndex == input.weeks - 1)
                ? 0.6
                : (1.0 + input.weeklyVolumeRamp * Double(weekIndex))
            // Determine sets per muscle group for this week, rounding down but enforcing strict growth
            let weekTargets: [MuscleGroup: Int] = input.weeklyVolumeTargets.mapValues { baseSets in
                let rawSets = Double(baseSets) * weekFactor / Double(input.daysPerWeek)
                let current = Int(rawSets)
                // Enforce strict monotonic increase before deload: if same as previous, bump by one
                if weekIndex > 0 && weekIndex < input.weeks - 1 {
                    let prevFactor = 1.0 + input.weeklyVolumeRamp * Double(weekIndex - 1)
                    let prev = Int(Double(baseSets) * prevFactor / Double(input.daysPerWeek))
                    if prev == current {
                        return current + 1
                    }
                }
                return current
            }
            // Create each day for the week
            for dayIndex in 0..<input.daysPerWeek {
                if let workout = await makeWorkout(week: weekIndex, day: dayIndex, dailyTargets: weekTargets, defaultRepRange: input.defaultRepRange) {
                    generatedWorkouts.append(workout)
                }
            }
        }
        // 2. Assemble per-week summaries for the mesocycle
        var weekPlans: [WeekPlan] = []
        for weekIndex in 0..<input.weeks {
            let wkWorkouts = generatedWorkouts.filter { $0.week == weekIndex }
            let totalReps = wkWorkouts.reduce(0) { sum, wk in
                sum + wk.exercises.reduce(0) { acc, pres in
                    // Use midpoint rep count × sets to estimate volume per week
                    acc + Int((Double(pres.repRange.min + pres.repRange.max) / 2.0) * Double(pres.sets))
                }
            }
            weekPlans.append(WeekPlan(index: weekIndex, totalPlannedReps: totalReps))
        }
        return MesocyclePlan(
            objective: .hypertrophy,
            weeks: weekPlans,
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
