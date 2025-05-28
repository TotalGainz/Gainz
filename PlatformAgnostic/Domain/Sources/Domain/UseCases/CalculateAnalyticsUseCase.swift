//
//  CalculateAnalyticsUseCase.swift
//  Domain – UseCases
//
//  Computes high-level training analytics (volume, tonnage, PRs) for a
//  given date interval. Pure business logic; Foundation-only import.
//  ────────────────────────────────────────────────────────────────
//  • Clean Architecture “use-case layer”﻿ keeps ViewModels/UI ignorant
//    of data sources. :contentReference[oaicite:0]{index=0}
/*  Design references
    – Clean, entity/use-case/repository split in Swift :contentReference[oaicite:1]{index=1}
    – Domain layer immutable models & pure functions :contentReference[oaicite:2]{index=2}
    – Combine / async data pipelines best practice :contentReference[oaicite:3]{index=3}
    – FRP & functional side-effect isolation :contentReference[oaicite:4]{index=4}
    – General domain-layer guidelines (platform-agnostic) :contentReference[oaicite:5]{index=5}
*/
//  • No HRV, recovery-score, or bar-velocity inputs—Gainz focuses on
//    hypertrophy metrics only (total reps × load, muscle-group volume).

import Foundation

// MARK: - Protocols

/// Abstraction that supplies historical workout sessions.
public protocol WorkoutRepository {
    func sessions(in interval: DateInterval) async throws -> [WorkoutSession]
}

/// Destination for persisting calculated analytics (optional).
public protocol AnalyticsRepository {
    func save(_ summary: AnalyticsSummary) async throws
}

// MARK: - Use Case

public struct CalculateAnalyticsUseCase {

    // Dependencies
    private let workoutRepo: WorkoutRepository
    private let analyticsRepo: AnalyticsRepository?

    public init(
        workoutRepo: WorkoutRepository,
        analyticsRepo: AnalyticsRepository? = nil
    ) {
        self.workoutRepo = workoutRepo
        self.analyticsRepo = analyticsRepo
    }

    /// Executes analytics calculation for the supplied date interval.
    /// - Parameters:
    ///   - interval: Range of dates to include (inclusive).
    ///   - persist: If `true`, summary is forwarded to `analyticsRepo`.
    /// - Returns: `AnalyticsSummary` with volume & PR details.
    public func execute(
        for interval: DateInterval,
        persist: Bool = true
    ) async throws -> AnalyticsSummary {

        // 1. Fetch sessions from repository
        let sessions = try await workoutRepo.sessions(in: interval)

        // 2. Flatten all logged sets
        let allSets = sessions.flatMap { $0.sets }

        // 3. Aggregate tonnage & volume per muscle
        var volumePerMuscle: [MuscleGroup: Int] = [:]
        var tonnagePerMuscle: [MuscleGroup: Double] = [:]

        for set in allSets {
            guard let exercise = set.exercise else { continue } // safety

            let muscles = exercise.primaryMuscles.union(exercise.secondaryMuscles)
            let reps = set.reps
            let load = set.weight

            for muscle in muscles {
                volumePerMuscle[muscle, default: 0] += reps
                tonnagePerMuscle[muscle, default: 0] += Double(reps) * load
            }
        }

        // 4. Personal-record detection (max load per exercise)
        let prMap = Dictionary(
            grouping: allSets,
            by: { $0.exerciseId }
        ).compactMapValues { sets in
            sets.max(by: { $0.weight < $1.weight })
        }

        // 5. Compose summary model
        let summary = AnalyticsSummary(
            period: interval,
            sessionsCount: sessions.count,
            totalSets: allSets.count,
            volumePerMuscle: volumePerMuscle,
            tonnagePerMuscle: tonnagePerMuscle,
            personalRecords: prMap
        )

        // 6. Persist if requested
        if persist, let repo = analyticsRepo {
            try await repo.save(summary)
        }

        return summary
    }
}

// MARK: - DTOs

/// Compact analytics result returned to ViewModels/UI.
public struct AnalyticsSummary: Hashable, Codable {

    public let period: DateInterval
    public let sessionsCount: Int
    public let totalSets: Int
    public let volumePerMuscle: [MuscleGroup: Int]
    public let tonnagePerMuscle: [MuscleGroup: Double]
    public let personalRecords: [UUID: WorkoutSet]

    public init(
        period: DateInterval,
        sessionsCount: Int,
        totalSets: Int,
        volumePerMuscle: [Mus
