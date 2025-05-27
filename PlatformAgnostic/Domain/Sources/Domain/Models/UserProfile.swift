//
//  UserProfile.swift
//  Domain – Models
//
//  Immutable profile descriptor for the athlete who owns the local Gainz account.
//  Pure value type; no UIKit, HealthKit, or persistence concerns.
//
//  ─────────────────── Design Invariants ───────────────────
//  • Codable & Hashable for CoreData / JSON sync.
//  • No HRV, recovery metrics, or velocity data.
//  • Uses SI units (centimetres, kilograms) for portability.
//  • Enums kept lightweight to avoid over-civilisation.
//
//  Created for Gainz by the Core Domain team on 27 May 2025.
//

import Foundation

// MARK: - UserProfile

/// Athlete identity and baseline physical data.
///
/// The struct is intentionally minimal; any sensitive or
/// change-frequent attributes (email, auth tokens) live in
/// the `AuthUser` entity of the Persistence layer.
public struct UserProfile: Identifiable, Hashable, Codable {

    // MARK: Core Fields

    /// Stable user UUID (generated on first app launch).
    public let id: UUID

    /// Preferred display name shown throughout the app.
    public let givenName: String

    /// ISO-8601 birth date (used to derive age).
    public let dateOfBirth: Date

    /// Biological sex for TDEE / strength-norm analytics.
    public let biologicalSex: BiologicalSex

    /// Standing height in centimetres.
    public let heightCm: Double

    /// Current body mass in kilograms.
    public let bodyWeightKg: Double

    /// Training experience tier (novice → advanced).
    public let experienceLevel: ExperienceLevel

    /// Primary goal guiding mesocycle generation.
    public let primaryGoal: TrainingGoal

    // MARK: Derived Helpers

    /// Age in years (integer truncation).
    public var ageInYears: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    /// Body-mass index – informational only.
    public var bmi: Double {
        bodyWeightKg / pow(heightCm / 100, 2)
    }

    // MARK: Init & Validation

    public init(
        id: UUID = .init(),
        givenName: String,
        dateOfBirth: Date,
        biologicalSex: BiologicalSex,
        heightCm: Double,
        bodyWeightKg: Double,
        experienceLevel: ExperienceLevel = .novice,
        primaryGoal: TrainingGoal = .hypertrophy
    ) {
        precondition(!givenName.isEmpty, "givenName must not be empty")
        precondition(heightCm > 0, "heightCm must be positive")
        precondition(bodyWeightKg > 0, "bodyWeightKg must be positive")

        self.id = id
        self.givenName = givenName
        self.dateOfBirth = dateOfBirth
        self.biologicalSex = biologicalSex
        self.heightCm = heightCm
        self.bodyWeightKg = bodyWeightKg
        self.experienceLevel = experienceLevel
        self.primaryGoal = primaryGoal
    }
}

// MARK: - Supporting Enums

public enum BiologicalSex: String, Codable, CaseIterable {
    case male
    case female
    case other
    case preferNotToSay
}

public enum ExperienceLevel: String, Codable, CaseIterable {
    case novice
    case intermediate
    case advanced
}

public enum TrainingGoal: String, Codable, CaseIterable {
    case hypertrophy
    case strength
    case fatLoss
    case maintenance
    case generalFitness
}
