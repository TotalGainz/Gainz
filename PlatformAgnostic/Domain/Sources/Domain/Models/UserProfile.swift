/// UserProfile.swift

import Foundation

/// Immutable profile of the athlete using the app.
public struct UserProfile: Identifiable, Hashable, Codable, Sendable {
    // MARK: Core Fields

    /// Unique user identifier (generated on first app use).
    public let id: UUID
    /// The athlete's display name or nickname.
    public let givenName: String
    /// Date of birth (used to compute age).
    public let dateOfBirth: Date
    /// Biological sex (may influence calculations like calorie needs or strength standards).
    public let biologicalSex: BiologicalSex
    /// Height in centimeters.
    public let heightCm: Double
    /// Current body weight in kilograms.
    public let bodyWeightKg: Double
    /// Self-reported training experience level.
    public let experienceLevel: ExperienceLevel
    /// Primary training goal for the athlete.
    public let primaryGoal: TrainingGoal

    // MARK: Derived Helpers

    /// Age in years (based on `dateOfBirth` and current date).
    public var ageInYears: Int {
        let years = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year
        return years ?? 0
    }

    /// Body Mass Index (BMI) calculated from height and weight.
    public var bmi: Double {
        // BMI = weight (kg) / [height (m)]^2
        let heightM = heightCm / 100.0
        return bodyWeightKg / (heightM * heightM)
    }

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        givenName: String,
        dateOfBirth: Date,
        biologicalSex: BiologicalSex,
        heightCm: Double,
        bodyWeightKg: Double,
        experienceLevel: ExperienceLevel = .novice,
        primaryGoal: TrainingGoal = .hypertrophy
    ) {
        precondition(!givenName.isEmpty, "givenName must not be empty.")
        precondition(heightCm > 0, "heightCm must be positive.")
        precondition(bodyWeightKg > 0, "bodyWeightKg must be positive.")
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

/// Biological sex options.
public enum BiologicalSex: String, Codable, CaseIterable, Sendable {
    case male, female, other, preferNotToSay
}

/// Experience levels for training.
public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case novice, intermediate, advanced
}

/// Primary training goal guiding programming.
public enum TrainingGoal: String, Codable, CaseIterable, Sendable {
    case hypertrophy
    case strength
    case fatLoss
    case maintenance
    case generalFitness
}
