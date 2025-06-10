/// Exercise.swift

import Foundation

/// Immutable catalog descriptor for a resistance training exercise.
public struct Exercise: Identifiable, Hashable, Codable, Sendable {
    // MARK: Core Fields

    /// Stable unique identifier for this exercise.
    public let id: UUID

    /// Display name of the exercise (e.g., "Barbell Bench Press").
    public let name: String

    /// Primary muscle groups that this exercise is intended to train.
    public let primaryMuscles: Set<MuscleGroup>

    /// Secondary or synergist muscle groups (if any).
    public let secondaryMuscles: Set<MuscleGroup>

    /// General biomechanical movement pattern of the exercise.
    public let mechanicalPattern: MechanicalPattern

    /// Equipment category used for this exercise.
    public let equipment: Equipment

    /// Indicates if the exercise is performed unilaterally (one side at a time).
    public let isUnilateral: Bool

    // MARK: Derived Property

    /// Union of `primaryMuscles` and `secondaryMuscles` for quick reference.
    public var allTargetedMuscles: Set<MuscleGroup> {
        primaryMuscles.union(secondaryMuscles)
    }

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        primaryMuscles: Set<MuscleGroup>,
        secondaryMuscles: Set<MuscleGroup> = [],
        mechanicalPattern: MechanicalPattern,
        equipment: Equipment,
        isUnilateral: Bool = false
    ) {
        precondition(!name.isEmpty, "Exercise name must not be empty.")
        precondition(!primaryMuscles.isEmpty, "At least one primary muscle is required.")
        precondition(primaryMuscles.isDisjoint(with: secondaryMuscles),
                     "Primary and secondary muscle groups must be disjoint.")

        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.mechanicalPattern = mechanicalPattern
        self.equipment = equipment
        self.isUnilateral = isUnilateral
    }
}

/// Categorical description of an exercise’s movement pattern.
public enum MechanicalPattern: String, Codable, CaseIterable, Sendable {
    case horizontalPush
    case horizontalPull
    case verticalPush
    case verticalPull
    case squat
    case hinge
    case carry
    case coreAntiExtension
    case coreAntiRotation
    case isolation
}

/// Coarse equipment taxonomy for exercises (kept simple for portability).
public enum Equipment: String, Codable, CaseIterable, Sendable {
    case barbell
    case dumbbell
    case kettlebell
    case cable
    case machine
    case smithMachine
    case bodyweight
    case band
    case other
}
