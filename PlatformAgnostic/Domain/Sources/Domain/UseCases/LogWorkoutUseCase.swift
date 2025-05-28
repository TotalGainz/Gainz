//
//  LogWorkoutUseCase.swift
//  Domain – Use-Cases
//
//  Handles the full lifecycle of recording a workout:
//  1. Create a new WorkoutSession from a WorkoutPlan or blank template.
//  2. Append SetRecord events as the athlete logs sets.
//  3. Finalise (or abandon) the session and publish analytics.
//
//  Pure Domain. No UIKit / SwiftUI / Combine / HealthKit dependencies.
//  Repositories are injected via protocol to keep this layer platform-agnostic.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - Interface

/// Abstract contract consumed by ViewModels or higher-level Coordinators.
public protocol LogWorkoutUseCase {

    /// Creates and returns a new `WorkoutSession` instance.
    @discardableResult
    func beginSession(
        planId: UUID?,
        date: Date
    ) async throws -> WorkoutSession

    /// Records a single working set inside an existing session.
    func logSet(
        _ set: SetRecord,
        toSessionWithID sessionId: UUID
    ) async throws

    /// Marks the session as completed (or abandoned) and commits the final state.
    func endSession(
        _ sessionId: UUID,
        didAbandon: Bool
    ) async throws
}

// MARK: - Default Implementation

public final class DefaultLogWorkoutUseCase: LogWorkoutUseCase {

    // Dependencies are protocols; concrete types injected from Core layer.
    private let workoutRepository: WorkoutRepository
    private let analyticsService: AnalyticsService

    public init(
        workoutRepository: WorkoutRepository,
        analyticsService: AnalyticsService
    ) {
        self.workoutRepository = workoutRepository
        self.analyticsService = analyticsService
    }

    // MARK: Session Start

    public func beginSession(
        planId: UUID?,
        date: Date = .init()
    ) async throws -> WorkoutSession {

        let session = WorkoutSession(
            id: .init(),
            planId: planId,
            startedAt: date,
            status: .inProgress,
            setRecords: []
        )

        try await workoutRepository.save(session)
        analyticsService.track(.workoutStarted(session.id, date))

        return session
    }

    // MARK: Log Set

    public func logSet(
        _ set: SetRecord,
        toSessionWithID sessionId: UUID
    ) async throws {
        var session = try await workoutRepository.session(id: sessionId)
        guard session.status == .inProgress else {
            throw Error.sessionNotActive
        }

        session.setRecords.append(set)
        try await workoutRepository.save(session)
        analyticsService.track(.setLogged(session.id, set))
    }

    // MARK: End Session

    public func endSession(
        _ sessionId: UUID,
        didAbandon: Bool
    ) async throws {

        var session = try await workoutRepository.session(id: sessionId)
        guard session.status == .inProgress else {
            throw Error.sessionNotActive
        }

        session.status = didAbandon ? .abandoned : .completed
        session.endedAt = Date()

        try await workoutRepository.save(session)

        if !didAbandon {
            analyticsService.track(.workoutCompleted(session.id))
        }
    }
}

// MARK: - Error

extension DefaultLogWorkoutUseCase {
    public enum Error: Swift.Error, Equatable {
        case sessionNotFound
        case sessionNotActive
    }
}

// MARK: - Supporting Protocols

/// Injected port for data persistence.
public protocol WorkoutRepository {
    func save(_ session: WorkoutSession) async throws
    func session(id: UUID) async throws -> WorkoutSession
}

/// Injected port for analytics events. _No HRV, recovery, or velocity metrics._
public protocol AnalyticsService {
    func track(_ event: AnalyticsEvent)
}
