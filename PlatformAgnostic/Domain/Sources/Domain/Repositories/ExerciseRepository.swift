/// ExerciseRepository.swift

import Foundation

// MARK: - ExerciseRepository Protocol

/// Async interface for fetching and persisting `Exercise` entities.
public protocol ExerciseRepository: Sendable {
    // MARK: Create/Update

    /// Save or update the given exercises in the catalog.
    /// - Throws: `ExerciseRepositoryError.persistenceFailed` on failure.
    func save(_ exercises: [Exercise]) async throws

    // MARK: Read

    /// Fetch the entire exercise catalog, sorted alphabetically by name.
    func fetchAll() async throws -> [Exercise]

    /// Fetch a single exercise by its unique ID.
    func fetch(byId id: UUID) async throws -> Exercise?

    // MARK: Observe

    /// Provide a live stream of the exercise catalog. Emits whenever the catalog changes.
    func observeCatalog() -> AsyncThrowingStream<[Exercise], Error>
}

/// Errors that an `ExerciseRepository` can throw.
public enum ExerciseRepositoryError: Error, Equatable {
    case persistenceFailed(underlying: Error)
    case notFound
    case unknown
}

// MARK: - In-Memory Implementation (for tests/debug)

#if DEBUG
/// In-memory implementation of `ExerciseRepository` for unit testing and debug builds.
/// Uses an `actor` for thread-safe storage of exercise data.
public final class InMemoryExerciseRepository: ExerciseRepository {
    private actor Storage {
        var items: [UUID: Exercise] = [:]

        func insert(_ exercises: [Exercise]) {
            for ex in exercises {
                items[ex.id] = ex
            }
        }

        func all() -> [Exercise] {
            // Return exercises sorted by name
            return items.values.sorted { $0.name < $1.name }
        }

        func get(id: UUID) -> Exercise? {
            return items[id]
        }
    }

    private let storage = Storage()
    private var continuation: AsyncThrowingStream<[Exercise], Error>.Continuation?

    public init(seed: [Exercise] = []) {
        // Seed initial data in the actor
        Task.detached { [storage] in
            await storage.insert(seed)
        }
    }

    public func save(_ exercises: [Exercise]) async throws {
        await storage.insert(exercises)
        // Notify observers of updated catalog
        continuation?.yield(await storage.all())
    }

    public func fetchAll() async throws -> [Exercise] {
        return await storage.all()
    }

    public func fetch(byId id: UUID) async throws -> Exercise? {
        return await storage.get(id: id)
    }

    public func observeCatalog() -> AsyncThrowingStream<[Exercise], Error> {
        return AsyncThrowingStream { continuation in
            self.continuation = continuation
            // Emit current state immediately
            Task {
                continuation.yield(await storage.all())
            }
        }
    }
}
#endif
