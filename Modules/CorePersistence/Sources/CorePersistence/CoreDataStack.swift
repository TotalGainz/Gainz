//  CoreDataStack.swift
//  CorePersistence
//
//  Thread-safe, actor-wrapped Core Data facade with optional CloudKit sync.
//  Zero UI; lives in Core Services, consumed by repositories.
//
//  ───────────────────────────────────────────────────────────
//  • Swift-concurrency friendly (`actor` protects the container).
//  • Automatic iCloud sync if `useCloudKit == true`.
//  • Lightweight seeding hook for exercises.json on first launch.
//  • In-memory store option for unit tests.
//  • No HRV, recovery, or bar-velocity tables—hypertrophy only.
//
//  Created for Gainz on 27 May 2025.
//
#if canImport(CoreData)
import Foundation
import CoreData

public actor CoreDataStack {

    // MARK: - Public API

    /// Singleton for production use. Tests may create isolated instances.
    public static let shared = CoreDataStack()

    /// Read-only main-thread context for UI (writes must use context.perform).
    public var viewContext: NSManagedObjectContext {
        // The view context is a main queue context (tie UI work to the main thread).
        container.viewContext
    }

    /// Creates a new private queue context for background work (e.g., bulk writes).
    public func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        // Use a merge policy that prefers incoming changes over existing (avoids conflicts).
        ctx.mergePolicy = Self.mergePolicy
        return ctx
    }

    /// Saves any pending changes in the given context, or the main viewContext if none provided.
    /// - Throws: Propagates any Core Data errors during save.
    public func save(context: NSManagedObjectContext? = nil) async throws {
        let ctx = context ?? viewContext
        guard ctx.hasChanges else { return }
        // Perform save on the context's proper queue.
        try await ctx.perform {
            try ctx.save()
        }
    }

    /// Deletes all persistent stores (for debugging or testing purposes only).
    /// Completely resets the underlying database by destroying and reloading the stores.
    public func resetStore() async throws {
        // Destroy stores on a background context to avoid blocking the main thread.
        try await withCheckedThrowingContinuation { cont in
            container.performBackgroundTask { ctx in
                do {
                    let coordinator = ctx.persistentStoreCoordinator
                    for store in coordinator.persistentStores {
                        if let url = store.url {
                            try coordinator.destroyPersistentStore(at: url, ofType: store.type, options: nil)
                        }
                    }
                    cont.resume()  // success
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
        // After destruction, reload the persistent stores to re-initialize the stack.
        try await reloadPersistentStores()
    }

    // MARK: - Initialisation

    /// Initializes the Core Data stack with the given model name and options.
    /// - Parameters:
    ///   - modelName: Name of the .xcdatamodel (defaults to "GainzModel").
    ///   - inMemory: If true, uses an in-memory store (for tests; data not persisted to disk).
    ///   - useCloudKit: If true (default), configures an iCloud-backed store for sync.
    public init(
        modelName: String = "GainzModel",
        inMemory: Bool = false,
        useCloudKit: Bool = true
    ) {
        // Choose CloudKit container or standard container based on options.
        let container: NSPersistentContainer
        if useCloudKit && !inMemory {
            container = NSPersistentCloudKitContainer(name: modelName)
        } else {
            container = NSPersistentContainer(name: modelName)
        }

        // Configure persistent store descriptions before loading stores.
        if inMemory {
            // Use an in-memory store (no file, resets on app quit).
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        } else if useCloudKit {
            // If using CloudKit, enable CloudKit sync and history tracking on the default store.
            if let desc = container.persistentStoreDescriptions.first {
                desc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.gainzapp")
                // Enable persistent history tracking for iCloud sync merge.
                desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            }
        }

        self.container = container
        // Load persistent stores asynchronously after initialization to avoid blocking.
        Task { await configureContainer() }
    }

    // MARK: - Private

    /// Kicks off loading of persistent stores and handles post-load configuration.
    private func configureContainer() {
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                // Crash on Core Data load failure (critical for app operation).
                fatalError("⛔️ CoreData load error: \(error)")
            }
            // Complete setup after successful store load.
            self?.postLoadSetup()
        }
    }

    /// Finalizes setup after stores are loaded: merges context changes and seeds initial data.
    private func postLoadSetup() {
        // Ensure the main context merges changes from background contexts and CloudKit.
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Set merge policy to avoid data inconsistency (new data overrides old on conflict).
        container.viewContext.mergePolicy = Self.mergePolicy
        // Perform initial data seeding on first launch (if not already done).
        if UserDefaults.standard.bool(forKey: "seeded") == false {
            // Run seeding asynchronously to avoid blocking UI.
            Task { try? await seedInitialData() }
        }
    }

    /// Synchronously reloads all persistent stores (used after a reset).
    private func reloadPersistentStores() async throws {
        try await withCheckedThrowingContinuation { continuation in
            container.loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Seeds the database with initial data from bundled JSON (runs only once on first launch).
    private func seedInitialData() async throws {
        // Locate the bundled "exercises.json" file (contains preset exercise definitions).
        guard let url = Bundle.module.url(forResource: "exercises", withExtension: "json") else {
            return  // No seed data available.
        }
        // Load and decode the JSON data into an array of ExerciseSeed DTOs.
        let data = try Data(contentsOf: url)
        let seedList = try JSONDecoder().decode([ExerciseSeed].self, from: data)

        // Insert all seed exercises on a background context to avoid blocking the UI.
        try await container.performBackgroundTask { context in
            for item in seedList {
                // Create a new Core Data ExerciseEntity for each item.
                let entity = ExerciseEntity(context: context)
                entity.id = item.id
                entity.name = item.name
                entity.primaryMuscles = item.primary  // array of primary muscle names
                entity.secondaryMuscles = item.secondary  // array of secondary muscle names
                entity.mechanicalPattern = item.pattern  // exercise movement pattern
                entity.equipment = item.equipment
                entity.isUnilateral = item.isUnilateral
            }
            // Save the background context to persist the new objects.
            try context.save()
        }
        // Mark that initial seeding has completed to avoid re-running on next launch.
        UserDefaults.standard.set(true, forKey: "seeded")
    }

    // MARK: - Constants

    /// Merge policy: on conflict, prefer property values of the current (in-memory) version.
    private static let mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
}

// MARK: - ExerciseSeed DTO

/// Data Transfer Object for initial exercise seeding (matches the JSON structure).
private struct ExerciseSeed: Decodable {
    let id: UUID
    let name: String
    let primary: [String]
    let secondary: [String]
    let pattern: String
    let equipment: String
    let isUnilateral: Bool
}
#endif
