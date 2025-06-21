//  DatabaseManager.swift
//  CorePersistence
//
//  High-level facade providing fetch/update APIs while hiding Core Data details.
//  Uses a background context for thread safety and can integrate with CloudKit via CoreDataStack.
//  Created for Gainz on 27 May 2025.
//

#if canImport(CoreData)
import Foundation
import CoreData
import Domain  // Import domain models (Exercise, etc.)

public protocol DatabaseManaging {
    // MARK: Exercise Management
    func fetchAllExercises() async throws -> [Exercise]
    @discardableResult func upsertExercise(_ exercise: Exercise) async throws -> Exercise
    func deleteExercise(withId id: UUID) async throws

    // MARK: Seeding
    /// Loads bundled JSON exercise library only if the database is empty.
    func seedExercisesIfNeeded() async
}

/// Thread-safe persistence layer (with optional CloudKit sync).
/// Provides high-level operations on the data model, backed by Core Data.
public final class DatabaseManager: DatabaseManaging {

    // MARK: Singleton
    public static let shared = DatabaseManager()

    // MARK: Dependencies
    private let stack: CoreDataStack
    private let backgroundContext: NSManagedObjectContext
    private let decoder = JSONDecoder()

    /// Initializes the DatabaseManager with an optional CoreDataStack (useful for testing with in-memory stack).
    public init(stack: CoreDataStack = .shared) {
        self.stack = stack
        // Obtain a background context from the Core Data stack for performing operations.
        self.backgroundContext = stack.newBackgroundContext()
        // The new background context already has mergePolicy set (ensuring new data wins on conflicts).
        // Changes saved in this context will be merged into the viewContext automatically (via CoreDataStack configuration).
    }

    // MARK: - Exercise CRUD Operations

    /// Fetches all Exercise records from the database.
    /// - Returns: An array of `Exercise` domain models.
    /// - Throws: Any Core Data fetch error.
    public func fetchAllExercises() async throws -> [Exercise] {
        try await backgroundContext.perform {
            // Create a fetch request for all ExerciseEntity objects.
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            // Execute fetch on the background context and map results to domain model instances.
            let results = try backgroundContext.fetch(request)
            return results.compactMap(Exercise.init)  // Use failable initializer to map each entity to an Exercise
        }
    }

    /// Inserts or updates the given Exercise in the database.
    /// - Returns: The same `Exercise` passed in (after successful save).
    /// - Throws: If the operation fails (e.g., save error).
    @discardableResult
    public func upsertExercise(_ exercise: Exercise) async throws -> Exercise {
        try await backgroundContext.perform {
            // Try to find an existing entity with matching id.
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", exercise.id as CVarArg)
            request.fetchLimit = 1

            // Either get the existing entity or create a new one if not found.
            let entity = try backgroundContext.fetch(request).first ?? ExerciseEntity(context: backgroundContext)
            // Update the entity's fields with the latest data.
            entity.id = exercise.id
            entity.name = exercise.name
            entity.primaryMuscles = exercise.primaryMuscles.map { $0.rawValue }
            entity.secondaryMuscles = exercise.secondaryMuscles.map { $0.rawValue }
            entity.mechanicalPattern = exercise.mechanicalPattern.rawValue
            entity.equipment = exercise.equipment.rawValue
            entity.isUnilateral = exercise.isUnilateral

            // Save changes if any fields were modified.
            try backgroundContext.saveIfNeeded()
            return exercise
        }
    }

    /// Deletes the Exercise with the specified id from the database.
    /// - Throws: If the fetch or delete operation fails.
    public func deleteExercise(withId id: UUID) async throws {
        try await backgroundContext.perform {
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            // Fetch the entity to delete (if it exists).
            if let entity = try backgroundContext.fetch(request).first {
                backgroundContext.delete(entity)
                // Persist the deletion to the store.
                try backgroundContext.saveIfNeeded()
            }
        }
    }

    // MARK: - Seeding Initial Data

    /// Seeds the database with exercises from bundled JSON, if no exercises currently exist.
    /// This is safe to call on every launch; it will only insert data the first time (when the database is empty).
    public func seedExercisesIfNeeded() async {
        // Only proceed if the exercises table is empty (or fetch failed).
        guard (try? await fetchAllExercises().isEmpty) == true else { return }
        // Locate the bundled "exercises.json" resource.
        guard let url = Bundle.module.url(forResource: "exercises", withExtension: "json") else {
            assertionFailure("⚠️ Seed data JSON (exercises.json) not found in bundle.")
            return
        }
        do {
            // Decode the JSON file into an array of Exercise domain objects.
            let data = try Data(contentsOf: url)
            let library = try decoder.decode([Exercise].self, from: data)
            // Use a task group to insert all exercises in parallel.
            try await withThrowingTaskGroup(of: Void.self) { group in
                for exercise in library {
                    group.addTask {
                        // Insert each exercise into Core Data (ignore returned value).
                        _ = try await self.upsertExercise(exercise)
                    }
                }
                // Wait for all insert tasks to complete.
                try await group.waitForAll()
            }
        } catch {
            // Log any failure during seeding (non-fatal, app continues without preloaded data).
            print("❌ Exercise seeding failed:", error)
        }
    }
}

// MARK: - Helpers & Mappers

private extension NSManagedObjectContext {
    /// Saves the context only if there are changes, to avoid unnecessary disk I/O.
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        try save()
    }
}

private extension Exercise {
    /// Initializes a domain Exercise from a Core Data ExerciseEntity.
    /// Returns nil if required fields are missing or invalid.
    init?(entity: ExerciseEntity) {
        // Unwrap required fields from the Core Data entity.
        guard
            let id = entity.id,
            let name = entity.name,
            let primaryRaw = entity.primaryMuscles as? [String],
            let secondaryRaw = entity.secondaryMuscles as? [String],
            let mechRaw = entity.mechanicalPattern,
            let equipRaw = entity.equipment,
            let mech = MechanicalPattern(rawValue: mechRaw),
            let equip = Equipment(rawValue: equipRaw)
        else {
            return nil  // Abort if any field is missing or if mechanicalPattern is unrecognized
        }

        // Map string arrays to enum sets.
        let primaryMuscles = Set(primaryRaw.compactMap(MuscleGroup.init(rawValue:)))
        let secondaryMuscles = Set(secondaryRaw.compactMap(MuscleGroup.init(rawValue:)))

        self.init(
            id: id,
            name: name,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            mechanicalPattern: mech,
            equipment: equip,
            isUnilateral: entity.isUnilateral
        )
    }
}

private extension Exercise {
    /// Convenience initializer to create an Exercise from a managed entity. Wraps the failable init.
    init?(from managedObject: ExerciseEntity) {
        self.init(entity: managedObject)
    }
}
#endif
