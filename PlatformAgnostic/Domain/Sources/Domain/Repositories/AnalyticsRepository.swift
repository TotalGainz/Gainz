/// AnalyticsRepository.swift

import Foundation

// MARK: - AnalyticsRepository Protocol

/// Interface for recording new training data points and retrieving derived analytics.
public protocol AnalyticsRepository: Sendable {
    /// Record a newly completed set (for use in analytics aggregation).
    func record(set: LoggedSet) async throws

    /// Fetch weekly volume (total reps) for a given muscle group within a date interval.
    func fetchWeeklyVolume(muscle: MuscleGroup, within range: DateInterval) async throws -> [WeeklyVolumeSample]

    /// Fetch personal record entries (e.g., heaviest set) for a given exercise.
    func fetchPersonalRecords(exerciseId: UUID) async throws -> [PersonalRecordSample]

    /// Fetch estimated 1RM samples for a given exercise over time.
    func fetchEstimatedOneRepMax(exerciseId: UUID, within range: DateInterval) async throws -> [OneRepMaxSample]
}

/// A minimal representation of a logged set for analytics purposes.
public struct LoggedSet: Hashable, Codable, Sendable {
    public let date: Date
    public let exerciseId: UUID
    public let weight: Double
    public let reps: Int
    public let rpe: RPE?

    public init(date: Date, exerciseId: UUID, weight: Double, reps: Int, rpe: RPE? = nil) {
        self.date = date
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
    }
}

/// A sample data point for weekly volume (total reps) of a muscle group.
public struct WeeklyVolumeSample: Hashable, Codable, Sendable {
    public let weekStart: Date      // The starting Monday of the week
    public let totalReps: Int

    public init(weekStart: Date, totalReps: Int) {
        self.weekStart = weekStart
        self.totalReps = totalReps
    }
}

/// A record of a personal best for an exercise (either heaviest weight or most reps at a weight).
public struct PersonalRecordSample: Hashable, Codable, Sendable {
    public let date: Date
    public let weight: Double
    public let reps: Int

    public init(date: Date, weight: Double, reps: Int) {
        self.date = date
        self.weight = weight
        self.reps = reps
    }
}

/// A data point for an estimated one-rep-max on a certain date.
public struct OneRepMaxSample: Hashable, Codable, Sendable {
    public let date: Date
    public let estimatedOneRM: Double

    public init(date: Date, estimatedOneRM: Double) {
        self.date = date
        self.estimatedOneRM = estimatedOneRM
    }
}
