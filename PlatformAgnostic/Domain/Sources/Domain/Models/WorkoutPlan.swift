/// WorkoutPlan.swift

import Foundation

/// A forward-looking prescription for a single workout session.
///
/// A `WorkoutPlan` outlines all exercises (with sets and reps targets) that the athlete should perform on a given day.
/// It is typically part of a larger `MesocyclePlan`.
public struct WorkoutPlan: Identifiable, Hashable, Codable, Sendable {
    // MARK: Core Fields

    /// Unique identifier for this workout plan.
    public let id: UUID
    /// Descriptive name of the workout (e.g., "Push Day A").
    public let name: String
    /// Week index (0-based) within the mesocycle when this workout occurs.
    public let week: Int
    /// Day index within the week (0 = Monday, 6 = Sunday, if applicable).
    public let dayOfWeek: Int
    /// Ordered list of exercise prescriptions for this workout.
    public let exercises: [ExercisePrescription]

    // MARK: Derived

    /// Total number of planned sets in this workout (summing all exercises).
    public var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets }
    }

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        week: Int,
        dayOfWeek: Int,
        exercises: [ExercisePrescription]
    ) {
        precondition(!name.isEmpty, "WorkoutPlan name must not be empty.")
        precondition(week >= 0, "Week index must be non-negative.")
        precondition((0...6).contains(dayOfWeek), "dayOfWeek must be 0–6 (0 = Monday).")
        precondition(!exercises.isEmpty, "WorkoutPlan must contain at least one exercise.")
        self.id = id
        self.name = name
        self.week = week
        self.dayOfWeek = dayOfWeek
        self.exercises = exercises
    }
}

/// Immutable instruction set for a single exercise within a `WorkoutPlan` (prior to execution).
public struct ExercisePrescription: Hashable, Codable, Sendable {
    /// Identifier of the `Exercise` to perform.
    public let exerciseId: UUID
    /// Planned number of sets to perform for this exercise in the workout.
    public let sets: Int
    /// Target repetition range for each set (inclusive range).
    public let repRange: RepRange
    /// Target Reps-in-Reserve (RIR) for each set (guiding effort level). Optional.
    public let targetRIR: Int?
    /// Target percentage of 1RM for each set. Optional (mutually exclusive with RIR/RPE targets).
    public let percent1RM: Double?

    public init(
        exerciseId: UUID,
        sets: Int,
        repRange: RepRange,
        targetRIR: Int? = nil,
        percent1RM: Double? = nil
    ) {
        precondition(sets > 0, "Sets must be > 0.")
        if let rir = targetRIR {
            precondition((0...4).contains(rir), "targetRIR must be between 0 and 4.")
        }
        if let percent = percent1RM {
            precondition((0...100).contains(percent), "percent1RM must be between 0 and 100.")
        }
        self.exerciseId = exerciseId
        self.sets = sets
        self.repRange = repRange
        self.targetRIR = targetRIR
        self.percent1RM = percent1RM
    }
}
