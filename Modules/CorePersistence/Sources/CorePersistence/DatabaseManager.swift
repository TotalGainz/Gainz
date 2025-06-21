//  DatabaseManager.swift
//  CorePersistence
//
//  High-level facade providing fetch/update APIs while hiding Core Data details.
//  Uses a background context for thread safety and can integrate with CloudKit via CoreDataStack.
//  Created for Gainz on 27 May 2025.
//

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
            entity.primaryMuscles = exercise.primaryMuscles.map { $0.rawValue }  // store as array of raw strings
            entity.mechanicalPattern = exercise.mechanicalPattern.rawValue      // store enum as raw value
            // (Note: Any other properties like secondaryMuscles, equipment, etc., would be set here if present in domain model.)

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
            let mechRaw = entity.mechanicalPattern,
            let mech = MechanicalPattern(rawValue: mechRaw)
        else {
            return nil  // Abort if any field is missing or if mechanicalPattern is unrecognized
        }

        // Map primaryRaw [String] to [MuscleGroup] enum values.
        let primaryMuscles = primaryRaw.compactMap(MuscleGroup.init(rawValue:))
        // Initialize the Exercise struct with these values.
        self.init(id: id, name: name, primaryMuscles: primaryMuscles, mechanicalPattern: mech)
    }
}

private extension Exercise {
    /// Convenience initializer to create an Exercise from a managed entity. Wraps the failable init.
    init?(from managedObject: ExerciseEntity) {
        self.init(entity: managedObject)
    }
}

// MARK: - Synchronous API used in tests

extension DatabaseManager {
    /// Seed bundled exercise data using a custom bundle if the database is empty.
    /// - Parameter bundle: Bundle containing the `exercises.json` resource.
    public func seedInitialDataIfNeeded(bundle: Bundle) throws {
        if try exerciseCount() > 0 { return }
        guard let url = bundle.url(forResource: "exercises", withExtension: "json") else {
            throw NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Seed file missing"])
        }
        let data = try Data(contentsOf: url)
        let library = try decoder.decode([Exercise].self, from: data)
        for exercise in library {
            try saveExercise(exercise)
        }
    }

    /// Current number of Exercise records in the store.
    public func exerciseCount() throws -> Int {
        try backgroundContext.performAndWait {
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            return try backgroundContext.count(for: request)
        }
    }

    /// Persist or update a single `Exercise`.
    public func saveExercise(_ exercise: Exercise) throws {
        try backgroundContext.performAndWait {
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", exercise.id as CVarArg)
            let entity = try backgroundContext.fetch(request).first ?? ExerciseEntity(context: backgroundContext)
            entity.id = exercise.id
            entity.name = exercise.name
            entity.primaryMuscles = exercise.primaryMuscles.map { $0.rawValue }
            entity.secondaryMuscles = exercise.secondaryMuscles.map { $0.rawValue }
            entity.mechanicalPattern = exercise.mechanicalPattern.rawValue
            entity.equipment = exercise.equipment.rawValue
            entity.isUnilateral = exercise.isUnilateral
            try backgroundContext.saveIfNeeded()
        }
    }

    /// Fetch a single exercise by identifier.
    public func fetchExercise(id: UUID) throws -> Exercise? {
        try backgroundContext.performAndWait {
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try backgroundContext.fetch(request).first else { return nil }
            return Exercise(entity: entity)
        }
    }

    /// Remove an exercise by identifier.
    public func deleteExercise(id: UUID) throws {
        try backgroundContext.performAndWait {
            let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            if let entity = try backgroundContext.fetch(request).first {
                backgroundContext.delete(entity)
                try backgroundContext.saveIfNeeded()
            }
        }
    }

    // MARK: Workout Sessions

    /// Persist a complete workout session and its child objects.
    public func saveWorkoutSession(_ session: WorkoutSession) throws {
        try backgroundContext.performAndWait {
            let request: NSFetchRequest<WorkoutSessionEntity> = WorkoutSessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
            let sessionEntity = try backgroundContext.fetch(request).first ?? WorkoutSessionEntity(context: backgroundContext)
            sessionEntity.id = session.id
            sessionEntity.date = session.date
            sessionEntity.startTime = session.startTime
            sessionEntity.endTime = session.endTime
            sessionEntity.notes = session.notes
            sessionEntity.planId = session.planId

            // Remove existing logs before re-inserting to keep things simple.
            if let existingLogs = sessionEntity.exerciseLogs as? Set<ExerciseLogEntity> {
                for log in existingLogs { backgroundContext.delete(log) }
            }

            for log in session.exerciseLogs {
                let logEntity = ExerciseLogEntity(context: backgroundContext)
                logEntity.id = log.id
                logEntity.exerciseId = log.exerciseId
                logEntity.startTime = log.startTime
                logEntity.endTime = log.endTime
                logEntity.perceivedExertion = log.perceivedExertion as NSNumber?
                logEntity.notes = log.notes
                logEntity.session = sessionEntity

                for set in log.performedSets {
                    let setEntity = SetRecordEntity(context: backgroundContext)
                    setEntity.id = set.id
                    setEntity.weight = set.weight
                    setEntity.reps = Int16(set.reps)
                    setEntity.rir = set.rir as NSNumber?
                    setEntity.rpe = set.rpe?.rawValue as NSNumber?
                    setEntity.tempo = set.tempo
                    setEntity.log = logEntity
                }
            }

            try backgroundContext.saveIfNeeded()
        }
    }

    /// Fetch a workout session by identifier.
    public func fetchWorkoutSession(id: UUID) throws -> WorkoutSession? {
        try backgroundContext.performAndWait {
            let request: NSFetchRequest<WorkoutSessionEntity> = WorkoutSessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try backgroundContext.fetch(request).first else { return nil }
            return WorkoutSession(entity: entity)
        }
    }

    /// Delete a workout session and its children.
    public func deleteWorkoutSession(id: UUID) throws {
        try backgroundContext.performAndWait {
            let request: NSFetchRequest<WorkoutSessionEntity> = WorkoutSessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            if let entity = try backgroundContext.fetch(request).first {
                backgroundContext.delete(entity)
                try backgroundContext.saveIfNeeded()
            }
        }
    }

    /// Fetch a single exercise log.
    public func fetchExerciseLog(id: UUID) throws -> ExerciseLog? {
        try backgroundContext.performAndWait {
            let request: NSFetchRequest<ExerciseLogEntity> = ExerciseLogEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try backgroundContext.fetch(request).first else { return nil }
            return ExerciseLog(entity: entity)
        }
    }
}

// MARK: - Entity Mappers

private extension WorkoutSession {
    init?(entity: WorkoutSessionEntity) {
        guard
            let id = entity.id,
            let date = entity.date,
            let startTime = entity.startTime,
            let logs = entity.exerciseLogs as? Set<ExerciseLogEntity>
        else { return nil }

        let mappedLogs = logs.compactMap(ExerciseLog.init(entity:))
        self.init(id: id,
                  date: date,
                  exerciseLogs: mappedLogs.sorted { $0.startTime < $1.startTime },
                  startTime: startTime,
                  endTime: entity.endTime,
                  notes: entity.notes,
                  planId: entity.planId)
    }
}

private extension ExerciseLog {
    init?(entity: ExerciseLogEntity) {
        guard
            let id = entity.id,
            let exerciseId = entity.exerciseId,
            let sets = entity.sets as? Set<SetRecordEntity>,
            let start = entity.startTime
        else { return nil }

        let mappedSets = sets.compactMap(SetRecord.init(entity:))
        self.init(id: id,
                  exerciseId: exerciseId,
                  performedSets: mappedSets.sorted { $0.weight < $1.weight },
                  perceivedExertion: entity.perceivedExertion as? Int,
                  notes: entity.notes,
                  startTime: start,
                  endTime: entity.endTime)
    }
}

private extension SetRecord {
    init?(entity: SetRecordEntity) {
        guard
            let id = entity.id
        else { return nil }

        self.init(id: id,
                  weight: entity.weight,
                  reps: Int(entity.reps),
                  rir: entity.rir as? Int,
                  rpe: entity.rpe.flatMap { RPE(rawValue: $0.intValue) },
                  tempo: entity.tempo)
    }
}
