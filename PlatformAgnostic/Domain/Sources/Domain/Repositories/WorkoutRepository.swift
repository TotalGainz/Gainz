//
//  WorkoutRepository.swift
//  Domain – Repositories
//
//  Contract for persisting & querying WorkoutSession aggregates.
//  Pure protocol: no Combine, no third-party abstractions, portable to
//  iOS, watchOS, macOS, visionOS, and server-side Swift.
//
//  References:
//    • Repository design pattern in Swift – Vanderlee :contentReference[oaicite:2]{index=2}
–   • Modernizing the pattern with Swift Concurrency – Medium :contentReference[oaicite:3]{index=3}
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - WorkoutRepository

/// Abstraction over any data store that holds `WorkoutSession`s.
///
/// Concrete implementations live in CorePersistence (Core Data),
/// NetworkLayer (remote sync), or MemoryCache (unit-test stubs).
public protocol WorkoutRepository: Sendable {

    // MARK: Create / Update

    /// Persists or replaces a full session atomically.
    /// Implementations decide if this is an insert or update.
    func saveSession(_ session: WorkoutSession) async throws

    /// Adds or overwrites a single `SetRecord` inside a session.
    func saveSet(
        _ set: SetRecord,
        forSessionID sessionID: UUID
    ) async throws

    // MARK: Read

    /// Fetch a single session by ID; returns `nil` if not found.
    func session(id: UUID) async throws -> WorkoutSession?

    /// Returns all sessions whose startDate falls inside `range`,
    /// ordered ascending by startDate.
    func sessions(
        in range: ClosedRange<Date>
    ) async throws -> [WorkoutSession]

    // MARK: Delete

    /// Irreversibly removes a session and all nested sets.
    func deleteSession(id: UUID) async throws

    // MARK: Streaming

    /// Emits live mutations for the given session (e.g., set logged).
    /// Domain stays reactive without importing Combine by using
    /// Swift’s native async sequences.
    func events(
        forSessionID sessionID: UUID
    ) -> AsyncThrowingStream<WorkoutEvent, Error>
}

// MARK: - WorkoutEvent

/// Fine-grained domain events that downstream view-models can react to.
public enum WorkoutEvent: Sendable {
    case setAdded(SetRecord)
    case setUpdated(SetRecord)
    case setDeleted(UUID)          // SetRecord.id
    case sessionDeleted            // entire session removed
}
