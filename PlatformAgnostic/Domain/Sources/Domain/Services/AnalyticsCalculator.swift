/// AnalyticsCalculator.swift

import Foundation

/// Protocol defining analytics computation functions on workout data.
public protocol AnalyticsCalculating: Sendable {
    /// Compute per-session metrics (volume per muscle group, PRs) for a workout session.
    func sessionMetrics(for session: WorkoutSession,
                        exerciseResolver: (UUID) -> Exercise?) -> SessionMetrics

    /// Aggregate metrics across multiple sessions (e.g., for a date range or multi-week view).
    func aggregateMetrics(for sessions: [WorkoutSession],
                          exerciseResolver: (UUID) -> Exercise?) -> AggregateMetrics
}

/// Functional implementation of analytics calculations.
public struct AnalyticsCalculator: AnalyticsCalculating {
    public init() {}

    public func sessionMetrics(for session: WorkoutSession,
                               exerciseResolver: (UUID) -> Exercise?) -> SessionMetrics {
        var muscleTonnage: [MuscleGroup: Double] = [:]
        var exercisePRs: [UUID: PRKind] = [:]

        // Compute total tonnage per muscle group
        for log in session.exerciseLogs {
            guard let exercise = exerciseResolver(log.exerciseId) else { continue }
            let exerciseVolume = log.totalVolume
            for muscle in exercise.allTargetedMuscles {
                muscleTonnage[muscle, default: 0.0] += exerciseVolume
            }
            // Check for PRs within this session (not implemented; placeholder)
            // e.g., if any set in log is heaviest ever for that exercise, mark PR.
            // (This would normally require historical comparison.)
        }

        return SessionMetrics(date: session.date,
                              muscleTonnage: muscleTonnage,
                              exercisePRs: exercisePRs)
    }

    public func aggregateMetrics(for sessions: [WorkoutSession],
                                 exerciseResolver: (UUID) -> Exercise?) -> AggregateMetrics {
        var combinedTonnage: [MuscleGroup: Double] = [:]
        for session in sessions {
            let metrics = sessionMetrics(for: session, exerciseResolver: exerciseResolver)
            for (muscle, tonnage) in metrics.muscleTonnage {
                combinedTonnage[muscle, default: 0.0] += tonnage
            }
        }
        let period = DateInterval(start: sessions.first?.date ?? Date(),
                                  end: sessions.last?.date ?? Date())
        return AggregateMetrics(period: period, muscleTonnage: combinedTonnage)
    }
}

/// Metrics computed for a single workout session.
public struct SessionMetrics: Hashable, Sendable {
    /// The date of the session.
    public let date: Date
    /// Total tonnage per muscle group in this session (kilogram-volume).
    public let muscleTonnage: [MuscleGroup: Double]
    /// Any personal records achieved in this session (by exercise ID and type of PR).
    public let exercisePRs: [UUID: PRKind]
}

/// Aggregated metrics computed over multiple sessions.
public struct AggregateMetrics: Hashable, Sendable {
    /// The date interval covering all sessions aggregated.
    public let period: DateInterval
    /// Total tonnage per muscle group over the period.
    public let muscleTonnage: [MuscleGroup: Double]
}

/// Kinds of personal record that can be achieved.
public enum PRKind: Sendable {
    case weight      // Heaviest weight lifted
    case repetitions // Most reps performed at a given weight
}
