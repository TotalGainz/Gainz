//
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

import Foundation
import CoreData

public actor CoreDataStack {

    // MARK: - Public API

    /// Singleton for production use. Tests may create isolated instances.
    public static let shared = CoreDataStack()

    /// Read-only main-thread context (use `.perform` for writes).
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Spawn a private-queue context for background writes.
    public func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = Self.mergePolicy
        return ctx
    }

    /// Persist pending changes on the supplied context—or `viewContext` by default.
    public func save(context: NSManagedObjectContext? = nil) async throws {
        let ctx = context ?? viewContext
        guard ctx.hasChanges else { return }
        try await ctx.perform {
            try ctx.save()
        }
    }

    /// Nukes every store (debug/testing only).
    public func resetStore() async throws {
        try await container.performBackgroundTask { ctx in
            let coordinator = self.container.persistentStoreCoordinator
            for store in coordinator.persistentStores {
                guard let url = store.url else { continue }
                try coordinator.destroyPersistentStore(at: url, ofType: store.type, options: nil)
            }
        }
        try await reloadPersistentStores()
    }

    // MARK: - Initialisation

    /// Designated initialiser—allows injection of store type for tests.
    public init(
        modelName: String = "GainzModel",
        inMemory: Bool = false,
        useCloudKit: Bool = true
    ) {
        let container: NSPersistentContainer
        if useCloudKit && !inMemory {
            container = NSPersistentCloudKitContainer(name: modelName)
        } else {
            container = NSPersistentContainer(name: modelName)
        }

        // Configure store description
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        } else if useCloudKit {
            if let desc = container.persistentStoreDescriptions.first {
                desc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.gainzapp")
                desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            }
        }

        self.container = container
        Task { await self.configureContainer() }
    }

    // MARK: - Private

    private func configureContainer() {
        container.loadPersistentStores { [weak self] _, error in
            if let error { fatalError("⛔️ CoreData load error: \(error)") }
            self?.postLoadSetup()
        }
    }

    private func postLoadSetup() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = Self.mergePolicy
        // Seed catalog if first run
        if UserDefaults.standard.bool(forKey: "seeded") == false {
            Task { try? await seedInitialData() }
        }
    }

    private func reloadPersistentStores() async throws {
        try await withCheckedThrowingContinuation { cont in
            container.loadPersistentStores { _, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume() }
            }
        }
    }

    private func seedInitialData() async throws {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else { return }
        let data = try Data(contentsOf: url)
        let seed = try JSONDecoder().decode([ExerciseSeed].self, from: data)

        try await container.performBackgroundTask { ctx in
            for item in seed {
                let entity = CDExercise(context: ctx)
                entity.id = item.id
                entity.name = item.name
                entity.primaryMuscles = item.primary
                entity.secondaryMuscles = item.secondary
                entity.pattern = item.pattern
                entity.equipment = item.equipment
                entity.isUnilateral = item.isUnilateral
            }
            try ctx.save()
        }
        UserDefaults.standard.set(true, forKey: "seeded")
    }

    // MARK: - Constants

    private static let mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
}

// MARK: - ExerciseSeed DTO (private)

private struct ExerciseSeed: Decodable {
    let id: UUID
    let name: String
    let primary: [String]
    let secondary: [String]
    let pattern: String
    let equipment: String
    let isUnilateral: Bool
}
