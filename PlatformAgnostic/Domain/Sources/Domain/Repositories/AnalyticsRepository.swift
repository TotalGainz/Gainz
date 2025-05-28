//
//  AnalyticsRepository.swift
//  Domain – Repositories
//
//  Contract for ingesting workout logs and querying hypertrophy-centric
//  analytics. Pure protocol + simple value types so the Domain layer
//  remains platform-agnostic (Foundation-only import).
//
//  ❌  No HRV, recovery-score, or bar-velocity metrics.
//  ✅  Volume, tonnage, PR progression, estimated 1 RM.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - AnalyticsRepository

/// Facade through which Domain use-cases record new data points and
/// retrieve derived analytics.
///
/// Implementations live in CorePersistence or remote services; tests can
/// inject mocks or in-memory stubs.
public protocol AnalyticsRepository {

    /// Persist a newly completed set so aggregate metrics can update.
    func record(set: LoggedSet) async throws

    /// Weekly volume (sets × reps) for a muscle group across a date span.
    func fetchWeeklyVolume(
        muscle: MuscleGroup,
        within range: DateInterval
    ) async throws -> [WeeklyVolumeSample]

    /// Per-exercise personal records (heaviest load or most reps per load).
    func fetchPersonalRecords(
        exerciseId: UUID
    ) async throws -> [PersonalRecordSample]

    /// Estimated 1 RM progression curve for a given exercise.
    func fetchEstimatedOneRepMax(
        exerciseId: UUID,
        within range: DateInterval
    ) async throws -> [OneRepMaxSample]
}

// MARK: - Value Types

/// Minimal representation of a logged set (Domain aggregate).
public struct LoggedSet: Hashable, Codable {
    public let date: Date
    public let exerciseId: UUID
    public let weight: Double     // in kilograms
    public let reps: Int
    public let rpe: RPE?

    public init(date: Date, exerciseId: UUID, weight: Double, reps: Int, rpe: RPE? = nil) {
        self.date = date
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
    }
}

/// Time-series sample representing weekly volume for one muscle group.
public struct WeeklyVolumeSample: Hashable, Codable {
    public let weekStart: Date          // ISO week Monday
    public let totalReps: Int
}

/// Snapshot of a personal record event.
public struct PersonalRecordSample: Hashable, Codable {
    public let date: Date
    public let weight: Double           // kg
    public let reps: Int
}

/// Data point for estimated 1 RM over time.
public struct OneRepMaxSample: Hashable, Codable {
    public let date: Date
    public let estimatedOneRM: Double   // kg
}

// MARK: - AnalyticsRepositoryError

public enum AnalyticsRepositoryError: Error {
    case dataCorrupted
    case notFound
    case underlying(Error)
}
