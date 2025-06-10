/// MesocyclePlan.swift

import Foundation

/// A periodized training block (mesocycle) consisting of multiple weeks of planned workouts.
public struct MesocyclePlan: Identifiable, Hashable, Codable, Sendable {
    // MARK: Core Fields

    public let id: UUID
    /// The primary objective of this mesocycle (e.g., hypertrophy or strength).
    public let objective: Objective
    /// Number of weeks in this mesocycle.
    public let weeks: Int
    /// All planned workouts in this mesocycle.
    public let workouts: [WorkoutPlan]
    /// Free-form notes about the mesocycle.
    public let notes: String?

    // MARK: Derived

    /// The total number of workouts in the mesocycle.
    public var totalWorkouts: Int {
        workouts.count
    }

    /// Total volume (kg·reps) planned across the entire mesocycle (sum of all workouts).
    public var totalVolume: Double {
        workouts.reduce(0) { total, plan in
            total + plan.exercises.reduce(0) { $0 + (Double($1.sets) * ($1.percent1RM ?? 0)) }
        }
    }

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        objective: Objective,
        weeks: Int,
        workouts: [WorkoutPlan],
        notes: String? = nil
    ) {
        precondition((1...12).contains(weeks), "MesocyclePlan weeks must be between 1 and 12.")
        // Ensure that workout plans align with the specified number of weeks
        let maxWeekIndex = workouts.map(\.week).max() ?? -1
        precondition(maxWeekIndex < weeks, "Workout plan has week index out of range for this mesocycle.")
        self.id = id
        self.objective = objective
        self.weeks = weeks
        self.workouts = workouts
        self.notes = notes
    }
}

/// Objective of a training mesocycle.
public enum Objective: String, Codable, CaseIterable, Sendable {
    case hypertrophy
    case strength
    case peaking
    case deload
}
