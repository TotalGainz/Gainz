/// MesocyclePlan.swift

import Foundation

/// A periodized training block (mesocycle) consisting of multiple weeks of planned workouts.
/// Summary of workouts and planned volume per week in a periodized training block (mesocycle).
public struct WeekPlan: Hashable, Codable, Sendable {
    /// Zero-based index of the week in the cycle.
    public let index: Int
    /// Total planned repetitions across all workouts in this week.
    public let totalPlannedReps: Int
}

/// A periodized training block (mesocycle) consisting of weekly summaries and workout blueprints.
public struct MesocyclePlan: Identifiable, Hashable, Codable, Sendable {
    // MARK: Core Fields

    public let id: UUID
    /// The primary objective of this mesocycle (e.g., hypertrophy or strength).
    public let objective: Objective
    /// Per-week summary data including planned reps.
    public let weeks: [WeekPlan]
    /// All planned workouts in this mesocycle.
    public let workouts: [WorkoutPlan]
    /// Free-form notes about the mesocycle.
    public let notes: String?

    // MARK: Derived Properties

    /// The total number of workouts in the mesocycle.
    public var totalWorkouts: Int { workouts.count }

    /// Flattened set of all planned exercise IDs in the cycle.
    public var allExerciseIDs: Set<UUID> {
        Set(workouts.flatMap { $0.exercises.map(\.exerciseId) })
    }

    // MARK: Initialization

    /// Create a new `MesocyclePlan` with weekly summaries and workouts.
    public init(
        id: UUID = UUID(),
        objective: Objective,
        weeks: [WeekPlan],
        workouts: [WorkoutPlan],
        notes: String? = nil
    ) {
        precondition(!weeks.isEmpty, "Mesocycle must contain at least one week.")
        let maxIndex = weeks.map(\.index).max() ?? -1
        precondition(maxIndex < weeks.count, "Week indexes must range from 0..<weeks.count.")
        self.id = id
        self.objective = objective
        self.weeks = weeks
        self.workouts = workouts
        self.notes = notes
    }
}

/// Objective of a training mesocycle.
/// Objective of a training mesocycle (defines primary adaptation focus).
public enum Objective: String, Codable, CaseIterable, Sendable {
    /// Emphasize muscle growth through higher repetition ranges.
    case hypertrophy
    /// Emphasize strength gains via lower reps and heavier loads.
    case strength
    /// Peaking phase for maximal performance taper (e.g., for competition).
    case peaking
    /// Deload or recovery-focused phase with reduced workload.
    case deload
}
