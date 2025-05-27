//
//  Exercise.swift
//  Domain - Models
//
//  Immutable catalog descriptor for a resistance-training movement.
//  Pure value type: no UIKit/SwiftUI, no HealthKit, no persistence details.
//  Compiles on iOS, watchOS, macOS, visionOS, server-side Swift.
//
//  ───────────── Mission Invariants ─────────────
//  • Zero HRV, recovery-score, or bar-velocity fields.
//  • Must remain platform-agnostic; Foundation is the only import.
//  • Codable + Hashable for painless persistence & diffing.
//
//  Created by Gainz Core Team on 27 May 2025.
//

import Foundation

// MARK: - Exercise

/// Domain model representing a single exercise definition.
///
/// Examples:
/// ```swift
/// let bench = Exercise(
///     name: "Barbell Bench Press",
///     primaryMuscles: [.chest],
///     secondaryMuscles: [.triceps, .frontDelts],
///     mechanicalPattern: .horizontalPush,
///     equipment: .barbell
/// )
/// ```
///
/// - Note: `id` is generated once and stored with the exercise catalog.
///   DO **NOT** regenerate on every save, or historical logs will break.
public struct Exercise: Identifiable, Hashable, Codable {

    // Stable UUID for cross-feature referencing
    public let id: UUID

    /// Display name shown to the athlete (e.g., “Seated Cable Row”).
    public let name: String

    /// Muscle groups intended to receive the primary stimulus.
    public let primaryMuscles: Set<MuscleGroup>

    /// Secondary or synergist muscle groups (optional).
    public let secondaryMuscles: Set<MuscleGroup>

    /// Generalised biomechanical pattern (push, pull, squat, hinge, etc.).
    public let mechanicalPattern: MechanicalPattern

    /// Broad equipment category (barbell, dumbbell, machine…).
    public let equipment: Equipment

    /// `true` if performed one side at a time (e.g., DB Row), else `false`.
    public let isUnilateral: Bool

    // MARK: Derived

    /// Union of primary + secondary muscle groups.
    public var allTargetedMuscles: Set<MuscleGroup> {
        primaryMuscles.union(secondaryMuscles)
    }

    // MARK: Init

    public init(
        id: UUID = .init(),
        name: String,
        primaryMuscles: Set<MuscleGroup>,
        secondaryMuscles: Set<MuscleGroup> = [],
        mechanicalPattern: MechanicalPattern,
        equipment: Equipment,
        isUnilateral: Bool = false
    ) {
        precondition(!name.isEmpty, "Exercise name must not be empty")
        precondition(!primaryMuscles.isEmpty, "At least one primary muscle is required")
        precondition(primaryMuscles.isDisjoint(with: secondaryMuscles),
                     "Primary and secondary muscle sets must be disjoint")

        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.mechanicalPattern = mechanicalPattern
        self.equipment = equipment
        self.isUnilateral = isUnilateral
    }
}

// MARK: - Mechanical Pattern

/// Categorical description of an exercise’s movement arc.
public enum MechanicalPattern: String, Codable, CaseIterable {
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

// MARK: - Equipment

/// Coarse equipment taxonomy—kept intentionally simple for portability.
public enum Equipment: String, Codable, CaseIterable {
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
