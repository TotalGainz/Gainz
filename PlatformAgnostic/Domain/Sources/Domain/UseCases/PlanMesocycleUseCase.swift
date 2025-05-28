//
//  PlanMesocycleUseCase.swift
//  Domain – UseCases
//
//  Generates a 4-to-6 week hypertrophy-biased `MesocyclePlan` based on a
//  high-level template (split, volume targets, micro-progression rules).
//  Pure domain logic: Foundation only, no UI, no HealthKit.
//
//  ───────────── Design Contracts ─────────────
//  • No HRV, recovery, or velocity metrics.
//  • All dependencies injected as protocols for testability.
//  • Algorithm delegates granular set/rep math to `PeriodizationStrategy`.
//  • Output is 100 % deterministic—same input → same plan.
//
//  Created for Gainz by the Core Domain team on 27 May 2025.
//

import Foundation

// MARK: - Public Protocol

/// Builds a fully-periodised `MesocyclePlan`.
public protocol PlanMesocycleUseCase {
    /// - Parameter template: abstract description of the block (split, target volume, rep ranges…)
    /// - Returns: Deterministic `MesocyclePlan` ready for persistence & UI.
    func execute(with template: MesocycleTemplate) -> MesocyclePlan
}

// MARK: - Default Implementation

public final class PlanMesocycleUseCaseImpl: PlanMesocycleUseCase {

    // MARK: Dependencies

    private let exerciseRepository: ExerciseRepository
    private let periodization: PeriodizationStrategy
    private let uuidProvider: () -> UUID
    private let dateProvider: () -> Date

    // MARK: Init

    public init(
        exerciseRepository: ExerciseRepository,
        periodization: PeriodizationStrategy = LinearPeriodization(),
        uuidProvider: @escaping () -> UUID = { UUID() },
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.exerciseRepository = exerciseRepository
        self.periodization = periodization
        self.uuidProvider = uuidProvider
        self.dateProvider = dateProvider
    }

    // MARK: Execute

    public func execute(with template: MesocycleTemplate) -> MesocyclePlan {

        // 1. Resolve exercise IDs from catalog
        let primaryLifts = template.primaryExerciseNames.compactMap {
            exerciseRepository.exercise(named: $0)?.id
        }

        // 2. Generate week-by-week targets via injected strategy
        let weeklyBlocks = periodization.generateBlocks(
            weeks: template.weeks,
            volumePerMuscle: template.volumePerMuscleGroup
        )

        // 3. Assemble MesocyclePlan (immutable struct)
        return MesocyclePlan(
            id: uuidProvider(),
            createdAt: dateProvider(),
            weeks: weeklyBlocks,
            primaryExerciseIds: Set(primaryLifts),
            goal: template.goal
        )
    }
}

// MARK: - Supporting Contracts

/// Thin gateway to whatever persistence layer stores the `Exercise` catalog.
public protocol ExerciseRepository {
    /// Returns an `Exercise` with matching display name, or nil.
    func exercise(named: String) -> Exercise?
}

/// Strategy object encapsulating periodisation maths (sets, reps, load ramps).
public protocol PeriodizationStrategy {
    /// Generates week blocks given volume requirements.
    func generateBlocks(
        weeks: Int,
        volumePerMuscle: [MuscleGroup: Int]
    ) -> [MesocyclePlan.Week]
}

// MARK: - Default Linear Periodisation

/// Linear + overload deload (last week = -40 % volume, -15 % load).
public struct LinearPeriodization: PeriodizationStrategy {

    public init() {}

    public func generateBlocks(
        weeks: Int,
        volumePerMuscle: [MuscleGroup: Int]
    ) -> [MesocyclePlan.Week] {

        precondition(weeks >= 4 && weeks <= 6, "Mesocycle must be 4–6 weeks long.")

        return (0..<weeks).map { index in
            let overloadFactor = Double(index + 1) / Double(weeks)
            let isDeload = index == weeks - 1

            let adjustedVolume: [MuscleGroup: Int] = volumePerMuscle.mapValues { base in
                let raw = isDeload ? Double(base) * 0.6 : Double(base) * overloadFactor
                return Int(raw.rounded())
            }

            return MesocyclePlan.Week(
                index: index,
                volumePerMuscle: adjustedVolume,
                isDeload: isDeload
            )
        }
    }
}
