/// PlanMesocycleUseCase.swift

import Foundation

// MARK: - Use-Case Protocol

/// Builds a fully periodized `MesocyclePlan` based on high-level user goal input.
public protocol PlanMesocycleUseCase: Sendable {
    /// Generate a new `MesocyclePlan` from the given goal template.
    func execute(goal: GoalInput) async -> MesocyclePlan
}

// MARK: - Goal Input DTO

/// High-level description of the desired training cycle (user's goal template).
public struct GoalInput: Sendable {
    /// Predefined split template (e.g., full-body, push/pull/legs, upper/lower).
    public enum Split: CaseIterable, Sendable {
        case fullBody, pushPullLegs, upperLower
    }
    public let split: Split
    public let weeks: Int
    public let experienceLevel: ExperienceLevel

    public init(split: Split, weeks: Int, experienceLevel: ExperienceLevel) {
        precondition(weeks >= 1, "weeks must be at least 1.")
        self.split = split
        self.weeks = weeks
        self.experienceLevel = experienceLevel
    }
}

/// Default implementation of `PlanMesocycleUseCase`.
public final class PlanMesocycleUseCaseImpl: PlanMesocycleUseCase {
    // Dependencies
    private let planGenerator: PlanGenerating

    public init(planGenerator: PlanGenerating) {
        self.planGenerator = planGenerator
    }

    public func execute(goal: GoalInput) async -> MesocyclePlan {
        // Map GoalInput to PlanInput for the generator
        let daysPerWeek: Int = {
            switch goal.split {
            case .fullBody:     return 2
            case .pushPullLegs: return 3
            case .upperLower:   return 4
            }
        }()
        // Set default volume targets based on experience (novice, intermediate, advanced)
        let baseVolume = (goal.experienceLevel == .novice ? 10 :
                          goal.experienceLevel == .intermediate ? 14 : 18)
        // Assign baseVolume sets to each major muscle group (simplified uniform distribution)
        var volumeTargets: [MuscleGroup: Int] = [:]
        for muscle in MuscleGroup.allCases {
            volumeTargets[muscle] = baseVolume
        }
        // Pre-validated rep range for hypertrophy focus (8–12 reps)
        let repRange = try! RepRange(min: 8, max: 12)
        let planInput = PlanInput(
            weeks: goal.weeks,
            daysPerWeek: daysPerWeek,
            weeklyVolumeTargets: volumeTargets,
            defaultRepRange: repRange,
            weeklyVolumeRamp: 0.05
        )
        // Generate the plan using the provided PlanGenerator
        return await planGenerator.makePlan(from: planInput)
    }
}
