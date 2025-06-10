/// LogWorkoutUseCase.swift

import Foundation

// MARK: - Use-Case Protocol

/// Coordinates the process of logging a live workout session.
public protocol LogWorkoutUseCase: Sendable {
    /// Begin a new workout session (optionally based on a plan).
    @discardableResult
    func beginSession(planId: UUID?, date: Date) async throws -> WorkoutSession

    /// Log a new set into an existing session.
    func logSet(_ set: SetRecord, toSessionWithID sessionId: UUID) async throws

    /// Mark a session as ended (completed or abandoned) and finalize it.
    func endSession(_ sessionId: UUID, didAbandon: Bool) async throws
}

// MARK: - Default Implementation

public final class DefaultLogWorkoutUseCase: LogWorkoutUseCase {
    // Dependencies (protocol abstractions for persistence and analytics)
    private let workoutRepository: WorkoutRepository
    private let analyticsService: AnalyticsService

    public init(workoutRepository: WorkoutRepository,
                analyticsService: AnalyticsService) {
        self.workoutRepository = workoutRepository
        self.analyticsService = analyticsService
    }

    public func beginSession(planId: UUID?, date: Date = Date()) async throws -> WorkoutSession {
        // Create a new session object (empty for now or could incorporate the plan if given)
        let session = WorkoutSession(id: UUID(),
                                     date: date,
                                     exerciseLogs: [],
                                     startTime: date,
                                     notes: nil,
                                     planId: planId)
        try await workoutRepository.saveSession(session)
        // Track analytics event for starting a workout
        analyticsService.track(.workoutStarted(session.id, date))
        return session
    }

    public func logSet(_ set: SetRecord, toSessionWithID sessionId: UUID) async throws {
        guard let session = try await workoutRepository.session(id: sessionId) else {
            throw Error.sessionNotFound
        }
        // Ensure session is still in progress if such a status is tracked (not explicitly modeled here).
        // Append set via repository (which will handle grouping within the session).
        try await workoutRepository.saveSet(set, forSessionID: sessionId)
        // Track analytics event for a set being logged
        analyticsService.track(.setLogged(sessionId, set))
    }

    public func endSession(_ sessionId: UUID, didAbandon: Bool) async throws {
        guard var session = try await workoutRepository.session(id: sessionId) else {
            throw Error.sessionNotFound
        }
        // Finalize session end time and (if we tracked a status) mark it completed/abandoned.
        session = WorkoutSession(id: session.id,
                                 date: session.date,
                                 exerciseLogs: session.exerciseLogs,
                                 startTime: session.startTime,
                                 endTime: Date(),
                                 notes: session.notes,
                                 planId: session.planId)
        try await workoutRepository.saveSession(session)
        // Track analytics event for completing or abandoning the workout
        if didAbandon {
            analyticsService.track(.workoutAbandoned(sessionId))
        } else {
            analyticsService.track(.workoutCompleted(sessionId))
        }
    }
}

// MARK: - Errors

extension DefaultLogWorkoutUseCase {
    public enum Error: Swift.Error, Equatable {
        case sessionNotFound
        case sessionNotActive
    }
}

// MARK: - Supporting Protocols

/// Minimal persistence interface required by the log use-case (subset of WorkoutRepository).
public protocol AnalyticsService: Sendable {
    func track(_ event: AnalyticsEvent)
}

/// Analytics events that can be emitted by the logging use-case.
public enum AnalyticsEvent: Sendable {
    case workoutStarted(UUID, Date)
    case setLogged(UUID, SetRecord)
    case workoutCompleted(UUID)
    case workoutAbandoned(UUID)
}
