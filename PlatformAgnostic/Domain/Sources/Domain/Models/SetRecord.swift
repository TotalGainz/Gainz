/// SetRecord.swift

import Foundation

/// Represents one executed set within an `ExerciseLog`.
///
/// Captures weight, reps, and effort metrics for the set. Both RIR (reps in reserve)
/// and RPE (rate of perceived exertion) are optional; typically one or the other is used.
public struct SetRecord: Identifiable, Hashable, Codable, Sendable {
    // MARK: Identity
    public let id: UUID

    // MARK: Performance Data
    /// Load used in this set, in kilograms.
    public let weight: Double
    /// Number of repetitions completed.
    public let reps: Int
    /// Reps-in-Reserve after this set (0 = failure, 1–4 = stopped shy of failure). Optional.
    public let rir: Int?
    /// Rate of Perceived Exertion for this set (1–10 scale). Optional alternative to RIR.
    public let rpe: RPE?
    /// Tempo notation (e.g., "40X1" for 4-sec eccentric, 0 pause, explosive concentric, 1-sec pause). Optional.
    public let tempo: String?

    // MARK: Derived Metric
    /// Volume load of the set, defined as `weight * reps` (in kg·reps).
    public var volume: Double {
        weight * Double(reps)
    }

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        weight: Double,
        reps: Int,
        rir: Int? = nil,
        rpe: RPE? = nil,
        tempo: String? = nil
    ) {
        precondition(weight >= 0, "Weight must be non-negative (kg).")
        precondition(reps >= 0, "Reps must be non-negative.")
        if let rir = rir {
            precondition((0...5).contains(rir), "RIR must be between 0 and 5.")
        }
        if let rpe = rpe {
            precondition((1...10).contains(rpe.rawValue), "RPE must be between 1 and 10.")
        }
        self.id = id
        self.weight = weight
        self.reps = reps
        self.rir = rir
        self.rpe = rpe
        self.tempo = tempo
    }
}

/// Discrete values for RPE (Rate of Perceived Exertion) on a 1–10 scale.
/// Discrete values for RPE (Rate of Perceived Exertion) on a 1–10 scale.
public enum RPE: Int, Codable, CaseIterable, Sendable, CustomStringConvertible {
    case one = 1, two, three, four, five, six, seven, eight, nine, ten

    /// Textual description combining the acronym and numeric value (e.g. "RPE 9").
    public var description: String { "RPE \(rawValue)" }
}
