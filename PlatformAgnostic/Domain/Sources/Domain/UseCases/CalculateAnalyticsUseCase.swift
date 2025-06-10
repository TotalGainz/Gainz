/// CalculateAnalyticsUseCase.swift

import Foundation

// MARK: - Use-Case Protocols

/// Abstraction providing historical workout sessions for analytics.
public protocol HistorySource: Sendable {
    func sessions(in interval: DateInterval) async throws -> [WorkoutSession]
}

/// Abstraction for saving computed analytics summaries.
public protocol AnalyticsSink: Sendable {
    func save(_ summary: AnalyticsSummary) async throws
}

// MARK: - Use Case Implementation

/// Use case for computing training analytics (volume, tonnage, PRs) over a specified time interval.
public struct CalculateAnalyticsUseCase {
    // Dependencies
    private let historySource: HistorySource
    private let analyticsSink: AnalyticsSink?

    public init(historySource: HistorySource, analyticsSink: AnalyticsSink? = nil) {
        self.historySource = historySource
        self.analyticsSink = analyticsSink
    }

    /// Calculate the analytics summary for all sessions in the given date interval.
    /// - Parameters:
    ///   - interval: The date range to include.
    ///   - persist: If `true`, the resulting summary is saved via `AnalyticsSink`.
    /// - Returns: An `AnalyticsSummary` containing aggregate volume and PR information.
    public func execute(for interval: DateInterval, persist: Bool = true) async throws -> AnalyticsSummary {
        // 1. Fetch relevant sessions from history
        let sessions = try await historySource.sessions(in: interval)
        // 2. Flatten all sets from these sessions
        let allSets = sessions.flatMap { $0.sets }
        // 3. Aggregate volume and tonnage per muscle group
        var volumePerMuscle: [MuscleGroup: Int] = [:]
        var tonnagePerMuscle: [MuscleGroup: Double] = [:]
        for set in allSets {
            // Resolve exercise and its muscle groups
            // (We'll use the WorkoutSession's internal resolver if set.exerciseId can map to an Exercise)
            if let exercise = WorkoutSession._exerciseResolver?(set.id) {
                let muscles = exercise.allTargetedMuscles
                let reps = set.reps
                let load = set.weight
                for muscle in muscles {
                    volumePerMuscle[muscle, default: 0] += reps
                    tonnagePerMuscle[muscle, default: 0] += Double(reps) * load
                }
            }
        }
        // 4. Identify personal record sets (heaviest set per exercise in this interval)
        let prMap = Dictionary(grouping: allSets, by: { _ in UUID() })  // Not implemented: placeholder grouping by exercise
            .compactMapValues { sets in sets.max(by: { $0.weight < $1.weight }) }
        // 5. Compose the summary model
        let summary = AnalyticsSummary(
            period: interval,
            sessionsCount: sessions.count,
            totalSets: allSets.count,
            volumePerMuscle: volumePerMuscle,
            tonnagePerMuscle: tonnagePerMuscle,
            personalRecords: prMap
        )
        // 6. Persist if required
        if persist, let sink = analyticsSink {
            try await sink.save(summary)
        }
        return summary
    }
}

// MARK: - DTO for Analytics Summary

/// Summarized analytics results over a time period.
public struct AnalyticsSummary: Hashable, Codable, Sendable {
    public let period: DateInterval
    public let sessionsCount: Int
    public let totalSets: Int
    public let volumePerMuscle: [MuscleGroup: Int]
    public let tonnagePerMuscle: [MuscleGroup: Double]
    /// Map of Exercise ID to the SetRecord representing the personal record (heaviest set) in this period.
    public let personalRecords: [UUID: SetRecord]
}
