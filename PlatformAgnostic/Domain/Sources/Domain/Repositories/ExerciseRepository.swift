//
//  ExerciseRepository.swift
//  Domain – Repositories
//
//  Source-of-truth abstraction for reading/writing Exercise data.
//  Lives in the Domain layer ⇒ Foundation-only, no Combine, no CoreData.
//  Implementations (SQLite, CoreData, CloudKit, etc.) reside in
//  CorePersistence and conform to this protocol.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - ExerciseRepository

/// Async interface for fetching, persisting, and observing `Exercise` entities.
///
/// > **Concurrency model**
/// > • All functions are `async` and `Sendable`.
/// > • Observations stream via `AsyncThrowingStream`, which is
/// >   available on every Apple platform and server-side Swift.
///
/// The Domain layer depends only on this protocol, enabling injection of
/// in-memory, local, or remote data sources without code changes upstream.
public protocol ExerciseRepository: Sendable {

    // MARK: Create / Update

    /// Persist or overwrite the provided exercises.
    ///
    /// - Throws: `ExerciseRepositoryError.persistenceFailed`
    func save(_ exercises: [Exercise]) async throws

    // MARK: Read

    /// Fetch the full catalog, ordered alphabetically by `name`.
    func fetchAll() async throws -> [Exercise]

    /// Fetch a single exercise by ID.
    func fetch(byId id: UUID) async throws -> Exercise?

    // MARK: Observability

    /// Live stream that emits whenever any exercise CRUD operation succeeds.
    ///
    /// Implementations should coalesce bursts and avoid emitting
    /// duplicates when underlying data haven’t changed.
    func observeCatalog() -> AsyncThrowingStream<[Exercise], Error>
}

// MARK: - Repository Errors

public enum ExerciseRepositoryError: Error, Equatable {
    case persistenceFailed(underlying: Error)
    case notFound
    case unknown
}

// MARK: - Mock (for Unit Tests)

#if DEBUG
/// Lightweight in-memory repository useful for Domain tests.
public final class InMemoryExerciseRepository: ExerciseRepository {

    private actor Storage {
        var items: [UUID: Exercise] = [:]
    }

    private let storage = Storage()

    public init(seed: [Exercise] = []) {
        Task { [storage] in
            for ex in seed { storage.items[ex.id] = ex }
        }
    }

    // MARK: Create / Update

    public func save(_ exercises: [Exercise]) async throws {
        await storage.items.merge(
            exercises.reduce(into: [:]) { $0[$1.id] = $1 },
            uniquingKeysWith: { _, new in new }
        )
        continuation?.yield(await currentSnapshot())
    }

    // MARK: Read

    public func fetchAll() async throws -> [Exercise] {
        await currentSnapshot()
    }

    public func fetch(byId id: UUID) async throws -> Exercise? {
        await storage.items[id]
    }

    // MARK: Observability

    public func observeCatalog() -> AsyncThrowingStream<[Exercise], Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
            continuation.yield(await currentSnapshot())
        }
    }

    // MARK: Private

    private var continuation: AsyncThrowingStream<[Exercise], Error>.Continuation?

    private func currentSnapshot() async -> [Exercise] {
        await storage.items.values.sorted { $0.name < $1.name }
    }
}
#endif
