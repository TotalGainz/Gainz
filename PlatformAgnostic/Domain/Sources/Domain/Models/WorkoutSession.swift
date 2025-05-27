//
//  WorkoutSession.swift
//  Domain – Models
//
//  Aggregate root representing a full workout event.
//  Holds ordered logs for each exercise performed, timestamps,
//  and convenience analytics (total volume, duration, etc.).
//
//  ─────────────────── Design Invariants ───────────────────
//  • Pure value-type (struct) — platform-agnostic, no UIKit/SwiftUI.
//  • Encodes only hypertrophy-centric data; no HRV or bar-velocity.
//  • Immutable public API; mutations occur via copy-on-write builders.
//  • Codable + Hashable for seamless persistence & diffing.
//
//  Created for Gainz by the Core Domain team on 27 May 2025.
//

import Foundation

// MARK: - WorkoutSession

/// A complete training session from first warm-up to final cooldown.
///
/// The session is immutable once finalised; during live logging, the Logger
/// produces a mutable `WorkoutSessionBuilder` that assembles logs before
/// returning this struct when the athlete taps **Finish**.
public struct WorkoutSession: Identifiable, Hashable, Codable {

    // MARK: Core Fields

    /// Stable identifier for the session.
    public let id: UUID

    /// Calendar day the session belongs to (local time zone).
    public let date: Date

    /// Ordered exercise logs in the sequence they were performed.
    public let exerciseLogs: [ExerciseLog]

    /// Timestamp when the athlete pressed **Start Workout**.
    public let startTime: Date

    /// Timestamp when **Finish** was pressed (or auto-filled on timeout).
    public let endTime: Date

    /// Free-form notes about the overall workout (energy, mood, injuries).
    public let notes: String?

    // MARK: – Derived Metrics

    /// Total kilogram-reps across all exercises.
    public var totalVolume: Double {
        exerciseLogs.reduce(0) { $0 + $1.totalVolume }
    }

    /// Count of logged sets across the workout.
    public var totalSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.totalSets }
    }

    /// Duration in seconds between `startTime` and `endTime`.
    public var duration: TimeInterval { endTime.timeIntervalSince(startTime) }

    /// Distinct muscles hit (union of all exercise targets).
    public var musclesTrained: Set<MuscleGroup> {
        exerciseLogs.reduce(into: Set<MuscleGroup>()) { acc, log in
            acc.formUnion(log.allTargetedMuscles)
        }
    }

    // MARK: – Init & Validation

    public init(
        id: UUID = .init(),
        date: Date = .init(),
        exerciseLogs: [ExerciseLog],
        startTime: Date,
        endTime: Date,
        notes: String? = nil
    ) {
        precondition(!exerciseLogs.isEmpty, "A session requires at least one exercise log.")
        precondition(endTime >= startTime, "endTime must not precede startTime.")

        self.id = id
        self.date = date
        self.exerciseLogs = exerciseLogs
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
}
