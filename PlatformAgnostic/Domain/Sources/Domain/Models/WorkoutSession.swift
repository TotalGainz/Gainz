/// WorkoutSession.swift

import Foundation

/// Aggregate root representing a completed (or in-progress) workout session.
///
/// A `WorkoutSession` contains all exercise logs performed on a given day, along with
/// timestamps and summary metrics. It is immutable once finalized; during live logging,
/// use a mutable builder or the `LogWorkoutUseCase` to construct it incrementally.
public struct WorkoutSession: Identifiable, Hashable, Codable, Sendable {
    // MARK: Core Fields

    /// Unique identifier for the session.
    public let id: UUID
    /// Calendar date of the session (local time zone).
    public let date: Date
    /// Ordered logs for each exercise performed in this session.
    public private(set) var exerciseLogs: [ExerciseLog]
    /// Timestamp when the session was started.
    public let startTime: Date
    /// Timestamp when the session was finished (or marked as ended).
    public private(set) var endTime: Date?
    /// Optional notes about the entire session (e.g., energy level, injuries).
    public let notes: String?
    /// Optional identifier of the `WorkoutPlan` this session was based on (if any).
    public let planId: UUID?

    // MARK: Derived Metrics

    /// Total volume (kg·reps) across all exercises in this session.
    public var totalVolume: Double {
        exerciseLogs.reduce(0) { $0 + $1.totalVolume }
    }

    /// Total number of sets logged in this session.
    public var totalSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.totalSets }
    }

    /// Total duration of the session in seconds.
    public var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }

    /// Set of all muscle groups trained in this session.
    ///
    /// Derived from resolved `Exercise` entities via the `_exerciseResolver` hook.
    /// Access to this property is actor-isolated to ensure thread-safety when using the resolver.
    @MainActor
    public var musclesTrained: Set<MuscleGroup> {
        exerciseLogs.reduce(into: Set<MuscleGroup>()) { result, log in
            if let exercise = WorkoutSession._exerciseResolver?(log.exerciseId) {
                result.formUnion(exercise.allTargetedMuscles)
            }
        }
    }

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseLogs: [ExerciseLog],
        startTime: Date,
        endTime: Date? = nil,
        notes: String? = nil,
        planId: UUID? = nil
    ) {
        precondition(!exerciseLogs.isEmpty, "A session requires at least one exercise log.")
        if let endTime = endTime {
            precondition(endTime >= startTime, "endTime must not precede startTime.")
        }
        self.id = id
        self.date = date
        self.exerciseLogs = exerciseLogs
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.planId = planId
    }

    // MARK: Internal (for Analytics support)

    /// Internal hook to resolve `Exercise` definitions from IDs when computing derived data.
@MainActor
internal static var _exerciseResolver: ((UUID) -> Exercise?)? = nil
}

extension WorkoutSession {
    /// Convenience access to all `SetRecord`s in the session (flattened across exercises).
    public var sets: [SetRecord] {
        exerciseLogs.flatMap { $0.performedSets }
    }
}
