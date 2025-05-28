//
//  DatabaseManager.swift
//  CorePersistence
//
//  High-level façade exposing fetch/update APIs while hiding Core Data details.
//  References: repo explanation for o3 (UPDATED) :contentReference[oaicite:0]{index=0},
//              CorePersistence module description :contentReference[oaicite:1]{index=1}.
//

import Foundation
import CoreData
import Combine
import Domain            // Swift-PM target that owns Exercise, WorkoutPlan, etc.

public protocol DatabaseManaging {
    // MARK: Exercise
    func fetchAllExercises() async throws -> [Exercise]
    @discardableResult func upsertExercise(_ exercise: Exercise) async throws -> Exercise
    func deleteExercise(withId id: UUID) async throws

    // MARK: Seeding
    /// Loads bundled JSON library only when the database is empty.
    func seedExercisesIfNeeded() async
}

/// Thread-safe, CloudKit-ready persistence layer.
public final class DatabaseManager: DatabaseManaging {

    // MARK: Singleton
    public static let shared = DatabaseManager()

    // MARK: Private
    private let stack: CoreDataStack
    private let backgroundContext: NSManagedObjectContext
    private let decoder = JSONDecoder()

    // Dependency-injected initializer keeps unit tests flexible.
    public init(stack: CoreDataStack = .shared) {
        self.stack = stack
        self.backgroundContext = stack.newBackgroundContext()
        self.backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: – Exercise

    public func fetchAllExercises() async throws -> [Exercise] {
        try await backgroundContext.perform {
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            return try backgroundContext.fetch(request).compactMap(Exercise.init)
        }
    }

    @discardableResult
    public func upsertExercise(_ exercise: Exercise) async throws -> Exercise {
        try await backgroundContext.perform {
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", exercise.id as CVarArg)
            request.fetchLimit = 1

            let entity = try backgroundContext.fetch(request).first ?? ExerciseEntity(context: backgroundContext)
            entity.id = exercise.id
            entity.name = exercise.name
            entity.primaryMuscles = exercise.primaryMuscles.map(\.rawValue)
            entity.mechanicalPattern = exercise.mechanicalPattern.rawValue

            try backgroundContext.saveIfNeeded()
            return exercise
        }
    }

    public func deleteExercise(withId id: UUID) async throws {
        try await backgroundContext.perform {
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            if let entity = try backgroundContext.fetch(request).first {
                backgroundContext.delete(entity)
                try backgroundContext.saveIfNeeded()
            }
        }
    }

    // MARK: – Seed Data

    public func seedExercisesIfNeeded() async {
        guard (try? await fetchAllExercises().isEmpty) == true else { return }
        guard let url = Bundle.module.url(forResource: "exercises", withExtension: "json") else {
            assertionFailure("⚠️ SeedData/exercises.json missing from bundle.")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let library = try decoder.decode([Exercise].self, from: data)
            try await withThrowingTaskGroup(of: Void.self) { group in
                for ex in library {
                    group.addTask { _ = try await self.upsertExercise(ex) }
                }
                try await group.waitForAll()
            }
        } catch {
            // Non-fatal: log for diagnostics, continue app execution.
            print("❌ Exercise seeding failed:", error)
        }
    }
}

// MARK: – Helpers & Mappers

private extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}

private extension Exercise {
    /// Failable init that maps from Core Data entity → Domain model.
    init?(entity: ExerciseEntity) {
        guard
            let id = entity.id,
            let name = entity.name,
            let primaryRaw = entity.primaryMuscles as? [String],
            let mechRaw = entity.mechanicalPattern,
            let mech = MechanicalPattern(rawValue: mechRaw)
        else { return nil }

        self.init(
            id: id,
            name: name,
            primaryMuscles: primaryRaw.compactMap(MuscleGroup.init(rawValue:)),
            mechanicalPattern: mech
        )
    }
}

private extension Exercise {
    /// Convenience wrapper so `Exercise.init` can be used in compactMap above.
    init?(from managed: ExerciseEntity) { self.init(entity: managed) }
}
