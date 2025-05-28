//
//  GenerateInitialPlanUseCase.swift
//  Domain – Use-Cases
//
//  Constructs the athlete’s very first MesocyclePlan from zero.
//  Platform-agnostic, synchronous, pure deterministic logic.
//
//  ────────────────────────────────────────────────────────────
//  • No HRV, recovery-score, or velocity dependencies.
//  • Injects repositories as protocols → 100 % unit-testable.
//  • Stateless: all randomness is seeded so results are reproducible.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - Use-Case Protocol

/// Generates the athlete’s initial 4-week hypertrophy mesocycle.
public protocol GenerateInitialPlanUseCase {

    /// Builds a MesocyclePlan based on the onboarding survey.
    ///
    /// - Parameter request: struct holding onboarding answers.
    /// - Returns: A fully populated `MesocyclePlan`.
    func execute(_ request: GenerateInitialPlanRequest) throws -> MesocyclePlan
}

// MARK: - Request DTO

/// Immutable value that captures the onboarding choices.
public struct GenerateInitialPlanRequest: Hashable {

    public enum ExperienceLevel: String, Codable {
        case novice, intermediate, advanced
    }

    /// Available training days per week (3–6 recommended).
    public let weeklyFrequency: Int

    /// True → user has barbell & plates; false → DB / bodyweight only.
    public let ownsBarbell: Bool

    /// Trainee’s self-reported experience.
    public let experience: ExperienceLevel

    /// Seed for deterministic exercise selection (testing).
    public let randomSeed: UInt64?

    public init(
        weeklyFrequency: Int,
        ownsBarbell: Bool,
        experience: ExperienceLevel,
        randomSeed: UInt64? = nil
    ) {
        precondition((2...7).contains(weeklyFrequency), "Frequency must be 2–7")
        self.weeklyFrequency = weeklyFrequency
        self.ownsBarbell = ownsBarbell
        self.experience = experience
        self.randomSeed = randomSeed
    }
}

// MARK: - Default Implementation

public final class GenerateInitialPlanUseCaseImpl: GenerateInitialPlanUseCase {

    // Dependencies
    private let exerciseRepo: ExerciseRepository
    private let uuid: () -> UUID
    private let rng: RandomNumberGenerator

    // MARK: Init

    public init(
        exerciseRepo: ExerciseRepository,
        uuid: @escaping () -> UUID = UUID.init,
        randomSeed: UInt64? = nil
    ) {
        self.exerciseRepo = exerciseRepo
        if let seed = randomSeed {
            self.rng = SeededGenerator(seed: seed)
        } else {
            self.rng = SystemRandomNumberGenerator()
        }
        self.uuid = uuid
    }

    // MARK: Execute

    public func execute(_ request: GenerateInitialPlanRequest) throws -> MesocyclePlan {

        // 1. Pull eligible exercises from repo
        let catalog = try exerciseRepo.fetchAll()

        // 2. Decide split (simple heuristic)
        let split = SplitPlanner.chooseSplit(
            frequency: request.weeklyFrequency,
            experience: request.experience
        )

        // 3. Draft one WorkoutPlan per split day
        var workouts: [WorkoutPlan] = []
        for (index, focus) in split.enumerated() {
            let exercises = ExerciseSelector.select(
                focus: focus,
                catalog: catalog,
                ownsBarbell: request.ownsBarbell,
                rng: rng
            )
            workouts.append(
                WorkoutPlan(
                    id: uuid(),
                    dayIndex: index,
                    focus: focus,
                    exercises: exercises
                )
            )
        }

        // 4. Assemble MesocyclePlan (4 weeks default)
        return MesocyclePlan(
            id: uuid(),
            weeks: 4,
            workouts: workouts
        )
    }
}

// MARK: - Small Helpers

private enum SplitPlanner {

    static func chooseSplit(
        frequency: Int,
        experience: GenerateInitialPlanRequest.ExperienceLevel
    ) -> [MuscleFocus] {
        switch (frequency, experience) {
        case (2, _):
            return [.fullBody, .fullBody]
        case (3, _):
            return [.push, .pull, .legs]
        case (4, .novice):
            return [.upper, .lower, .upper, .lower]
        case (4, _):
            return [.push, .pull, .legs, .accessory]
        case (5...7, _):
            return [.push, .pull, .legs, .upper, .lower]
        default:
            return [.fullBody, .fullBody]
        }
    }
}

private enum ExerciseSelector {

    static func select(
        focus: MuscleFocus,
        catalog: [Exercise],
        ownsBarbell: Bool,
        rng: RandomNumberGenerator
    ) -> [ExercisePlan] {

        let filtered = catalog.filter { exercise in
            focus.matches(exercise: exercise) &&
            (ownsBarbell || exercise.equipment != .barbell)
        }

        let chosen = Array(filtered.shuffled(using: rng).prefix(5))

        return chosen.map {
            ExercisePlan(
                exerciseId: $0.id,
                sets: 3,
                repRange: RepRange(min: 8, max: 12),
                targetRPE: .eight
            )
        }
    }
}

// MARK: - Seeded RNG (for deterministic tests)

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}
