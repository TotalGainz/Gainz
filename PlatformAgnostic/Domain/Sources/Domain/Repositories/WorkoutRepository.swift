// WorkoutRepository.swift
// Domain layer – Gainz
//
// High‑level persistence gateway for workout sessions and performed sets.
// This abstraction deliberately avoids leaking any storage‑specific types so
// that Domain remains platform‑agnostic (SwiftData, CoreData, SQLite, CloudKit, etc.).
//
// © 2025 Gainz Labs. MIT License.

import Foundation

// MARK: – Repository Protocol

/// Async interface for fetching and persisting `WorkoutSession` records.
///
/// The repository is also responsible for low‑level mutation conveniences such
/// as appending individual `SetRecord`s during live logging.  Keeping those
/// writes inside the repository guarantees that invariants on
/// `WorkoutSession` / `ExerciseLog` are enforced consistently, regardless of
/// the concrete storage backend.
public protocol WorkoutRepository: Sendable {
    /// Fetch a previously stored session.
    /// - Parameter id: Stable identifier of the desired session.
    /// - Returns: The matching `WorkoutSession`, or `nil` if it does not exist.
    func session(id: UUID) async throws -> WorkoutSession?

    /// Upsert a whole session. Callers supply a fully‑formed immutable object
    /// (e.g. when importing history or finalising a live log).
    func saveSession(_ session: WorkoutSession) async throws

    /// Append a *performed* set to an existing session. The repository will
    /// either extend an existing exercise log or create one if it is the first
    /// set for that exercise in the session.
    func saveSet(
        _ set: SetRecord,
        forExercise exerciseId: UUID,
        inSession sessionId: UUID
    ) async throws
}

// MARK: – Error Namespace

/// Domain errors surfaced by `WorkoutRepository` implementations.
public enum WorkoutRepositoryError: Error, Equatable, Sendable {
    /// Underlying persistence failed (I/O, validation, corruption, etc.).
    case persistenceFailed(underlying: Error)
    /// No session with the supplied identifier exists.
    case sessionNotFound
    /// Catch‑all for unrecoverable, unidentified failures.
    case unknown

    // Manual `Equatable` ignoring non‑equatable `Error` associated values.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.sessionNotFound, .sessionNotFound), (.unknown, .unknown):
            return true
        case let (.persistenceFailed(lhsErr), .persistenceFailed(rhsErr)):
            // Compare textual descriptions – sufficient for test equality.
            return String(describing: lhsErr) == String(describing: rhsErr)
        default:
            return false
        }
    }
}

#if DEBUG
// MARK: – Reference In‑Memory Implementation (DEBUG only)

/// Non‑persisted store backed by a Swift `actor` for thread‑safety.
/// Useful for unit tests, SwiftUI previews, and rapid prototyping. Swap this
/// with a real database implementation for production builds.
public final class InMemoryWorkoutRepository: WorkoutRepository {
    // MARK: Actor Storage

    private actor Storage {
        private var sessions: [UUID: WorkoutSession] = [:]

        func get(id: UUID) -> WorkoutSession? { sessions[id] }
        func put(_ session: WorkoutSession) { sessions[session.id] = session }

        func appendSet(
            _ set: SetRecord,
            exerciseId: UUID,
            toSession sessionId: UUID
        ) throws {
            guard let existing = sessions[sessionId] else {
                throw WorkoutRepositoryError.sessionNotFound
            }

            // Build a *new* immutable session because `WorkoutSession` fields
            // have `private(set)` accessors. This avoids sneaky alias mutation
            // and stays value‑semantic.
            var updatedLogs = existing.exerciseLogs
            if let index = updatedLogs.firstIndex(where: { $0.exerciseId == exerciseId }) {
                var log = updatedLogs[index]
                log.addSet(set)
                updatedLogs[index] = log
            } else {
                let firstLog = ExerciseLog(
                    exerciseId: exerciseId,
                    performedSets: [set],
                    perceivedExertion: nil,
                    notes: nil,
                    startTime: Date(),
                    endTime: Date()
                )
                updatedLogs.append(firstLog)
            }

            let updatedSession = WorkoutSession(
                id: existing.id,
                date: existing.date,
                exerciseLogs: updatedLogs,
                startTime: existing.startTime,
                endTime: Date(),
                notes: existing.notes,
                planId: existing.planId
            )

            sessions[sessionId] = updatedSession
        }
    }

    // MARK: Life‑cycle

    private let storage = Storage()

    /// - Parameter seed: Optional seed data for previews/tests.
    public init(seed: [WorkoutSession] = []) {
        Task.detached { [storage] in
            for s in seed { await storage.put(s) }
        }
    }

    // MARK: WorkoutRepository

    public func session(id: UUID) async throws -> WorkoutSession? {
        await storage.get(id: id)
    }

    public func saveSession(_ session: WorkoutSession) async throws {
        await storage.put(session)
    }

    public func saveSet(
        _ set: SetRecord,
        forExercise exerciseId: UUID,
        inSession sessionId: UUID
    ) async throws {
        try await storage.appendSet(set, exerciseId: exerciseId, toSession: sessionId)
    }
}
#endif
