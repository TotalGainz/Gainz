//
//  WorkoutPlan.swift
//  Domain – Models
//
//  Blueprint for a single workout inside a MesocyclePlan.
//  Pure value type; no UIKit, Combine, or persistence logic.
//
//  ──────────────────── Design Invariants ────────────────────
//  • Immutable once created; every field is let-bound.
//  • No HRV, recovery metrics, or bar-velocity prescriptions.
//  • Codable + Hashable so plans round-trip via JSON / Core Data.
//  • Integrates cleanly with MesocyclePlan and WorkoutSession.
//
//  Created for Gainz by the Core Domain team on 27 May 2025.
//

import Foundation

// MARK: - WorkoutPlan

/// A forward-looking prescription that tells the athlete **what to do**
/// in a given session, before any weights are actually lifted.
///
/// At runtime, the UI shows the `ExercisePrescription`s in order and the
/// athlete logs real weights/reps into a `WorkoutSession`, referencing the
/// same `exerciseId`s. This keeps plan vs. actual data cleanly separated.
public struct WorkoutPlan: Identifiable, Hashable, Codable {

    // Stable identifier for cross-ref within a MesocyclePlan.
    public let id: UUID

    /// Human-readable name shown in the Planner (e.g., “Push A”).
    public let title: String

    /// Week index inside the mesocycle, 0-based.
    public let week: Int

    /// Day index within the week, 0 = Monday (ISO-8601).
    public let dayOfWeek: Int

    /// Ordered list of exercise prescriptions.
    public let exercises: [ExercisePrescription]

    // MARK: Derived Convenience

    public var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets }
    }

    // MARK: Init & Validation

    public init(
        id: UUID = .init(),
        title: String,
        week: Int,
        dayOfWeek: Int,
        exercises: [ExercisePrescription]
    ) {
        precondition(!title.isEmpty, "Workout title must not be empty.")
        precondition(week >= 0, "Week index must be non-negative.")
        precondition((0...6).contains(dayOfWeek), "dayOfWeek must be 0…6 (ISO weekday).")
        precondition(!exercises.isEmpty, "A workout needs at least one exercise.")

        self.id = id
        self.title = title
        self.week = week
        self.dayOfWeek = dayOfWeek
        self.exercises = exercises
    }
}

// MARK: - ExercisePrescription

/// Immutable instruction set for a single movement **before execution**.
public struct ExercisePrescription: Hashable, Codable {

    /// References an `Exercise.id` in the global catalog.
    public let exerciseId: UUID

    /// Planned number of sets to perform.
    public let sets: Int

    /// Planned rep target (e.g., 8-12). Use closed range for flexibility.
    public let repRange: ClosedRange<Int>

    /// Optional RIR target to guide subjective effort.
    public let targetRIR: Int?

    /// Optional %1RM guideline; mutually exclusive with RIR/RPE in UI.
    public let percent1RM: Double?

    public init(
        exerciseId: UUID,
        sets: Int,
        repRange: ClosedRange<Int>,
        targetRIR: Int? = nil,
        percent1RM: Double? = nil
    ) {
        precondition(sets > 0, "Sets must be greater than zero.")
        precondition(!repRange.isEmpty, "repRange must not be empty.")
        if let percent = percent1RM {
            precondition((0...100).contains(percent),
                         "percent1RM must be 0–100.")
        }
        self.exerciseId = exerciseId
        self.sets = sets
        self.repRange = repRange
        self.targetRIR = targetRIR
        self.percent1RM = percent1RM
    }
}
