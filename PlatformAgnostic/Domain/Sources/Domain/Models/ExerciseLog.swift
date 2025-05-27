//
//  ExerciseLog.swift
//  Domain – Models
//
//  Captures a single exercise performed within a workout session.
//  Pure data object -- free of UI, HealthKit, or persistence details.
//
//  ──────────────────── Design Invariants ────────────────────
//  • Immutable value-type; all properties are let-bound.
//  • No HRV, recovery-score, or velocity-badge data.
//  • Codable + Hashable so logs round-trip cleanly through JSON / CoreData.
//  • Computed helpers expose volume and effort aggregates for analytics.
//
//  Created for Gainz by the Core Domain team on 27 May 2025.
//

import Foundation

/// A log entry representing one exercise performed during a `WorkoutSession`.
///
/// Each `ExerciseLog` owns an ordered list of `SetRecord`s—one per set executed.
/// The struct exposes convenience metrics (total volume, average RPE, etc.)
/// that higher-level analytics can consume without re-scanning the set array.
///
/// ```swift
/// let log = ExerciseLog(
///     exerciseId: bench.id,
///     performedSets: [
///         .init(weight: 100, reps: 10, rir: 2),
///         .init(weight: 100, reps: 9,  rir: 1)
///     ],
///     perceivedExertion: 9,
///     notes: "Felt strong; could micro-load next week."
/// )
/// print(log.totalVolume) // 1900 kg•reps
/// ```
public struct ExerciseLog: Identifiable, Hashable, Codable {

    // MARK: Core Fields

    /// Stable identifier for the log entry.
    public let id: UUID

    /// The exercise definition this log references.
    public let exerciseId: UUID

    /// Ordered set records as they occurred in the session.
    public let performedSets: [SetRecord]

    /// Optional whole-exercise RPE (1–10) the athlete felt after final set.
    public let perceivedExertion: Int?

    /// Free-form notes (form cues, pain flags, etc.).
    public let notes: String?

    /// Timestamp when the first set started; defaults to `Date()`.
    public let startTime: Date

    /// Timestamp when the final set ended; `nil` until auto-filled on finishing.
    public let endTime: Date?

    // MARK: – Derived Metrics

    /// Sum of `weight × reps` across all sets (kilogram-reps).
    public var totalVolume: Double {
        performedSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    /// Count of completed sets.
    public var totalSets: Int { performedSets.count }

    /// Mean RIR across sets, if every set has an RIR.
    public var averageRIR: Double? {
        let riRs = performedSets.compactMap(\.rir)
        guard !riRs.isEmpty else { return nil }
        return Double(riRs.reduce(0, +)) / Double(riRs.count)
    }

    // MARK: – Init & Validation

    public init(
        id: UUID = .init(),
        exerciseId: UUID,
        performedSets: [SetRecord],
        perceivedExertion: Int? = nil,
        notes: String? = nil,
        startTime: Date = .init(),
        endTime: Date? = nil
    ) {
        precondition(!performedSets.isEmpty, "performedSets must not be empty.")
        self.id = id
        self.exerciseId = exerciseId
        self.performedSets = performedSets
        self.perceivedExertion = perceivedExertion
        self.notes = notes
        self.startTime = startTime
        self.endTime = endTime
    }
}
