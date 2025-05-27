//
//  ExercisePlan.swift
//  Domain – Models
//
//  Declarative prescription for a single exercise inside a MesocyclePlan.
//  Defines the *target stimuli* the athlete should achieve before logging.
//
//  ──────────────────── Design Invariants ────────────────────
//  • Pure value-type (Codable + Hashable); no UIKit / SwiftUI imports.
//  • Lives in Domain, so it cannot reference CoreData or HealthKit.
//  • No HRV, recovery-score, or bar-velocity fields.
//  • Accepts flexible progression models (linear %, double, RIR-driven).
//
//  Created for Gainz by the Core Domain team on 27 May 2025.
//

import Foundation

/// **ExercisePlan** describes how an exercise should be performed across one
/// or more sessions in the upcoming mesocycle. The WorkoutLogger reconciles
/// these targets against real-world `ExerciseLog` data to determine progress.
///
/// Example — double-progression dumbbell row:
/// ```swift
/// let rowPlan = ExercisePlan(
///     exerciseId: row.id,
///     progression: .doubleProgression(
///         repRange: 8...12,
///         loadIncrement: .kilograms(2.5)
///     ),
///     targetSets: 4,
///     targetRIR: 1
/// )
/// ```
public struct ExercisePlan: Identifiable, Hashable, Codable {

    // MARK: Core Fields

    /// Stable identifier for the plan element.
    public let id: UUID

    /// FK to `Exercise` definition in catalog.
    public let exerciseId: UUID

    /// Desired number of working sets per session.
    public let targetSets: Int

    /// Target proximity-to-failure (RIR or RPE proxy).
    public let targetRIR: Int

    /// Algorithm that dictates load / rep progression week-to-week.
    public let progression: ProgressionStrategy

    /// Optional notes to surface in the UI (form cues, tempo, etc.).
    public let coachingNotes: String?

    // MARK: Initialiser

    public init(
        id: UUID = .init(),
        exerciseId: UUID,
        targetSets: Int,
        targetRIR: Int,
        progression: ProgressionStrategy,
        coachingNotes: String? = nil
    ) {
        precondition(targetSets > 0, "targetSets must be > 0")
        precondition((0...4).contains(targetRIR), "targetRIR must be 0–4")
        self.id = id
        self.exerciseId = exerciseId
        self.targetSets = targetSets
        self.targetRIR = targetRIR
        self.progression = progression
        self.coachingNotes = coachingNotes
    }
}

// MARK: - Progression Strategy

/// Encapsulates the overload model for the exercise.
/// The Planner chooses one; the WorkoutLogger references it to compute
/// the next session’s load & rep targets.
public enum ProgressionStrategy: Codable, Hashable {

    /// Linear percentage-based loading (common for compounds).
    /// e.g. Start at 70 % 1RM week 1 → +2.5 % per week.
    case linearPercentage(startPercent1RM: Double, weeklyIncrement: Double)

    /// Double progression: fill the rep range at fixed load, then bump load.
    case doubleProgression(repRange: ClosedRange<Int>, loadIncrement: LoadIncrement)

    /// Rep-only progression: add reps within a predefined range week-to-week.
    case repProgression(repRange: ClosedRange<Int>)

    /// RIR-based auto-regulation: athlete selects load to meet target RIR each week.
    case rirAutoregulated

    // Codable boilerplate for associated enums
    private enum CodingKeys: String, CodingKey { case kind, data }

    private enum Kind: String, Codable {
        case linearPercentage
        case doubleProgression
        case repProgression
        case rirAutoregulated
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .linearPercentage(start, inc):
            try container.encode(Kind.linearPercentage, forKey: .kind)
            try container.encode([start, inc], forKey: .data)
        case let .doubleProgression(range, inc):
            try container.encode(Kind.doubleProgression, forKey: .kind)
            try container.encode([range.lowerBound, range.upperBound, inc], forKey: .data)
        case let .repProgression(range):
            try container.encode(Kind.repProgression, forKey: .kind)
            try container.encode([range.lowerBound, range.upperBound], forKey: .data)
        case .rirAutoregulated:
            try container.encode(Kind.rirAutoregulated, forKey: .kind)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .linearPercentage:
            let values = try container.decode([Double].self, forKey: .data)
            self = .linearPercentage(startPercent1RM: values[0], weeklyIncrement: values[1])
        case .doubleProgression:
            let values = try container.decode([Double].self, forKey: .data)
            let range = Int(values[0])...Int(values[1])
            self = .doubleProgression(repRange: range, loadIncrement: .kilograms(values[2]))
        case .repProgression:
            let values = try container.decode([Double].self, forKey: .data)
            let range = Int(values[0])...Int(values[1])
            self = .repProgression(repRange: range)
        case .rirAutoregulated:
            self = .rirAutoregulated
        }
    }
}

// MARK: - Load Increment Helper

/// Describes how much to increase load when a progression step is triggered.
public enum LoadIncrement: Codable, Hashable {
    case kilograms(Double)
    case pounds(Double)
}
