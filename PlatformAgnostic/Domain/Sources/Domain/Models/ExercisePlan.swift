/// ExercisePlan.swift

import Foundation

/// Describes a progression plan for a single exercise across a mesocycle.
///
/// An `ExercisePlan` defines the target sets and progression strategy for one exercise
/// in a training plan. This is used to generate week-by-week prescriptions.
public struct ExercisePlan: Identifiable, Hashable, Codable, Sendable {
    // MARK: Core Fields

    /// Unique identifier for this exercise plan element.
    public let id: UUID
    /// Reference to the `Exercise` being planned.
    public let exerciseId: UUID
    /// Target number of working sets per session for this exercise.
    public let sets: Int
    /// Target effort indicator (in RIR or RPE terms) to aim for.
    public let targetRIR: Int?
    /// Optional target RPE (if using RPE instead of RIR).
    public let targetRPE: RPE?
    /// Desired repetition range for each set.
    public let repRange: RepRange
    /// Progression model dictating how load or reps increase over weeks.
    public let progression: ProgressionStrategy
    /// Optional coaching or technique notes for this exercise.
    public let coachingNotes: String?

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        sets: Int,
        targetRIR: Int? = nil,
        targetRPE: RPE? = nil,
        repRange: RepRange,
        progression: ProgressionStrategy,
        coachingNotes: String? = nil
    ) {
        precondition(sets > 0, "Target sets must be > 0.")
        if let rir = targetRIR {
            precondition((0...4).contains(rir), "targetRIR must be between 0 and 4.")
        }
        if let rpe = targetRPE {
            precondition((1...10).contains(rpe.rawValue), "targetRPE must be between 1 and 10.")
        }
        self.id = id
        self.exerciseId = exerciseId
        self.sets = sets
        self.targetRIR = targetRIR
        self.targetRPE = targetRPE
        self.repRange = repRange
        self.progression = progression
        self.coachingNotes = coachingNotes
    }
}

/// Defines a range of repetitions (e.g., 8–12 reps).
public struct RepRange: Hashable, Codable, Sendable {
    public let min: Int
    public let max: Int

    public init(min: Int, max: Int) {
        precondition(min > 0 && max >= min, "RepRange must have min > 0 and max >= min.")
        self.min = min
        self.max = max
    }

    /// Returns a `ClosedRange<Int>` representing this rep range.
    public var range: ClosedRange<Int> {
        return min...max
    }
}

/// Protocol for a progression strategy that dictates how an exercise progresses week-to-week.
public protocol ProgressionStrategy: Sendable {
    /// Optionally, progression strategies could define methods to compute next week targets.
    /// For simplicity, this protocol serves as a marker for Codable strategies.
}

/// A progression strategy where both reps and load increase across the mesocycle (double progression).
public struct DoubleProgression: ProgressionStrategy, Codable, Sendable {
    /// Target rep range to cycle within (e.g., 8–12).
    public let repRange: RepRange
    /// Increment to add to the load (weight) once top of rep range is exceeded.
    public let loadIncrement: WeightIncrement

    public init(repRange: RepRange, loadIncrement: WeightIncrement) {
        self.repRange = repRange
        self.loadIncrement = loadIncrement
    }
}

/// Represents a weight increment in a specified unit.
public struct WeightIncrement: Hashable, Codable, Sendable {
    public enum Unit: String, Codable, Sendable { case kilograms, pounds }
    public let value: Double
    public let unit: Unit

    public init(value: Double, unit: Unit) {
        precondition(value >= 0, "WeightIncrement value must be non-negative.")
        self.value = value
        self.unit = unit
    }

    public static func kilograms(_ value: Double) -> WeightIncrement {
        WeightIncrement(value: value, unit: .kilograms)
    }
    public static func pounds(_ value: Double) -> WeightIncrement {
        WeightIncrement(value: value, unit: .pounds)
    }
}
