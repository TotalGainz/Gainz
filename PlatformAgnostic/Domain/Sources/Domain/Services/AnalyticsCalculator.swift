//
//  AnalyticsCalculator.swift
//  Domain – Repositories
//
//  Pure-Swift hypertrophy analytics engine.
//  Computes volume, tonnage, PRs, and training frequency per muscle
//  without touching HRV, recovery scores, or bar-speed velocity.
//
//  ────────────────────────────────────────────────────────────
//  • Platform-agnostic   (Foundation-only import)
//  • Side-effect-free    (deterministic, cacheable results)
//  • Codable outputs     (portable across iOS / watchOS / server)
//  • Designed for unit-testability (no static singletons)
//  • Zero UI / persistence knowledge
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - Interfaces

/// Domain-layer contract for computing hypertrophy analytics.
public protocol AnalyticsCalculating {
    /// Returns session-level metrics (volume, tonnage, PR flags).
    func sessionMetrics(
        for session: WorkoutSession,
        exerciseResolver: (UUID) -> Exercise?
    ) -> SessionMetrics

    /// Aggregates metrics over many sessions (e.g., weekly dashboard).
    func aggregateMetrics(
        sessions: [WorkoutSession],
        exerciseResolver: (UUID) -> Exercise?
    ) -> AggregateMetrics
}

/// Stateless, functional implementation.
public struct AnalyticsCalculator: AnalyticsCalculating {

    public init() {}

    // MARK: Session

    public func sessionMetrics(
        for session: WorkoutSession,
        exerciseResolver: (UUID) -> Exercise?
    ) -> SessionMetrics {

        var muscleTonnage: [MuscleGroup: Double] = [:]
        var exercisePRs: [UUID: PRKind] = [:]

        for set in session.loggedSets {
            guard let exercise = exerciseResolver(set.exerciseId) else { continue }

            let tonnage = set.weight * Double(set.reps)
            for muscle in exercise.allTargetedMuscles {
                muscleTonnage[muscle, default: .zero] += tonnage
            }

            if set.isPR { exercisePRs[exercise.id] = set.prKind }
        }

        return SessionMetrics(
            date: session.date,
            muscleTonnage: muscleTonnage,
            exercisePRs: exercisePRs
        )
    }

    // MARK: Aggregate

    public func aggregateMetrics(
        sessions: [WorkoutSession],
        exerciseResolver: (UUID) -> Exercise?
    ) -> AggregateMetrics {

        var mergedTonnage: [MuscleGroup: Double] = [:]
        var prCount: Int = 0
        var lastTrained: [MuscleGroup: Date] = [:]

        for s in sessions {
            let metrics = sessionMetrics(for: s, exerciseResolver: exerciseResolver)

            // Merge tonnage
            for (muscle, value) in metrics.muscleTonnage {
                mergedTonnage[muscle, default: .zero] += value
                lastTrained[muscle] = [lastTrained[muscle] ?? .distantPast, s.date].max()
            }

            prCount += metrics.exercisePRs.count
        }

        let frequency: [MuscleGroup: Int] = sessions.reduce(into: [:]) { dict, session in
            let muscles = session.loggedSets.compactMap { exerciseResolver($0.exerciseId)?.allTargetedMuscles }
                                             .flatMap { $0 }
            for m in Set(muscles) { dict[m, default: 0] += 1 }
        }

        return AggregateMetrics(
            period: .init(start: sessions.first?.date ?? .distantPast,
                          end: sessions.last?.date ?? .distantFuture),
            totalTonnage: mergedTonnage,
            trainingFrequency: frequency,
            personalRecords: prCount,
            lastTrained: lastTrained
        )
    }
}

// MARK: - Output DTOs

public struct SessionMetrics: Codable, Equatable {
    public let date: Date
    public let muscleTonnage: [MuscleGroup: Double]     // kg-reps
    public let exercisePRs: [UUID: PRKind]              // exerciseId → PR type
}

public struct AggregateMetrics: Codable, Equatable {
    public let period: DateInterval
    public let totalTonnage: [MuscleGroup: Double]
    public let trainingFrequency: [MuscleGroup: Int]    // sessions per period
    public let personalRecords: Int
    public let lastTrained: [MuscleGroup: Date]
}

// MARK: - PR Kind

public enum PRKind: String, Codable {
    case weight     // heaviest load
    case reps       // max reps at given load
    case volume     // load × reps
}

// MARK: - WorkoutSession + helpers (light extension)

extension WorkoutSession {
    /// All sets logged in the session.
    var loggedSets: [SetRecord] { exercises.flatMap { $0.sets } }
}

// MARK: - SetRecord minimal stub (compile-time placeholder)

/// Replace with your real `SetRecord` struct; kept here so this file
/// compiles in isolation during code generation.
public struct SetRecord: Hashable, Codable {
    public let exerciseId: UUID
    public let reps: Int
    public let weight: Double       // kilograms
    public let isPR: Bool
    public let prKind: PRKind?
}

// MARK: - Compile-time imports
// NB: `MuscleGroup`, `WorkoutSession`, `Exercise` are defined elsewhere
// in the Domain layer and referenced here without explicit import.
