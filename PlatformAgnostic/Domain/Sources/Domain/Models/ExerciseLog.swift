/// ExerciseLog.swift

import Foundation

/// A log of all sets performed for a single exercise during a `WorkoutSession`.
///
/// Each exercise log holds an ordered list of `SetRecord`s. Convenience metrics are provided
/// to summarize the volume and effort for the exercise without recalculating each time.
public struct ExerciseLog: Identifiable, Hashable, Codable, Sendable {
    // MARK: Core Fields

    /// Stable identifier for this exercise log.
    public let id: UUID
    /// Identifier of the `Exercise` that was performed.
    public let exerciseId: UUID
    /// Ordered list of sets completed for this exercise.
    public private(set) var performedSets: [SetRecord]
    /// Optional overall RPE (1–10) the athlete reported for this exercise after the final set.
    public let perceivedExertion: Int?
    /// Free-form notes about performance or technique for this exercise.
    public let notes: String?
    /// Timestamp when the first set of this exercise started.
    public let startTime: Date
    /// Timestamp when the final set ended. `nil` if the exercise is still in progress.
    public private(set) var endTime: Date?

    // MARK: Derived Metrics

    /// Total volume for this exercise (sum of `weight * reps` over all sets).
    public var totalVolume: Double {
        performedSets.reduce(0) { $0 + $1.volume }
    }

    /// Total number of sets performed.
    public var totalSets: Int {
        performedSets.count
    }

    /// Average RIR across all sets (if every set has an RIR value).
    public var averageRIR: Double? {
        let rirValues = performedSets.compactMap { $0.rir }
        guard !rirValues.isEmpty else {
            return nil
        }
        let sum = rirValues.reduce(0, +)
        return Double(sum) / Double(rirValues.count)
    }

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        performedSets: [SetRecord],
        perceivedExertion: Int? = nil,
        notes: String? = nil,
        startTime: Date = Date(),
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

    // MARK: Mutation (for logging additional sets)

    /// Append a new `SetRecord` to the exercise log. Updates the end time to now.
    /// - Parameter set: The set record to add.
    public mutating func addSet(_ set: SetRecord) {
        performedSets.append(set)
        endTime = Date()
    }
}
