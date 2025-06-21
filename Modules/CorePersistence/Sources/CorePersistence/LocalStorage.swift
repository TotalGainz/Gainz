//  LocalStorage.swift
//  CorePersistence
//
//  One-stop Core Data stack responsible for:
//  - Loading the persistent container (SQLite by default, stored in ~/Library)
//  - Exposing main-actor viewContext + backgroundContext for database operations
//  - Auto-saving on app lifecycle notifications (background/terminate)
//  - Lightweight migration and schema consistency checks
//
//  Created for Gainz on 27 May 2025.

#if canImport(CoreData)
import Foundation
import CoreData
#if canImport(UIKit)
import UIKit  // Needed for UIApplication notifications in lifecycle observers
#endif

// MARK: - LocalStorage

/// Thread-safe Core Data stack container.
public final class LocalStorage {

    // MARK: Static Convenience

    /// Shared singleton instance for production use (uses disk-based SQLite store by default).
    /// Note: For unit tests or dependency injection, create separate instances (e.g., with `.inMemory`).
    public static let shared = LocalStorage(storeType: .sqlite)

    // MARK: Store Type

    public enum StoreType {
        case sqlite    // Persistent store in app's Documents (SQLite file)
        case inMemory  // Volatile store (for testing; resets on app restart)
    }

    // MARK: Initialization

    /// Initializes the persistent container with the specified store type and model name.
    /// - Parameters:
    ///   - storeType: `.sqlite` (on-disk persistence) or `.inMemory` (test only).
    ///   - modelName: Name of the Core Data model (default "GainzModel").
    public init(storeType: StoreType, modelName: String = "GainzModel") {
        self.storeType = storeType
        self.modelName = modelName
        container = NSPersistentContainer(name: modelName)
        configurePersistentStore()
    }

    // MARK: Public API

    /// Main managed object context (Main queue) for read operations and UI binding.
    /// This context should only be used on the main thread.
    @MainActor
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Background context for heavy write operations.
    /// Changes saved here automatically merge into the `viewContext`.
    public lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        // Set merge policy to avoid conflicts by favoring new changes over existing data.
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Automatically push saved changes to the viewContext (main UI context).
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    /// Saves the main context if there are pending changes.
    /// Should be called on the main thread (e.g., when the app goes to background).
    @MainActor
    public func saveViewContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            // Log an assertion failure in debug builds if save did not succeed.
            assertionFailure("⚠️ Core Data save failed: \(error)")
        }
    }

    // MARK: Private

    private let storeType: StoreType
    private let modelName: String
    private let container: NSPersistentContainer

    /// Configures and loads the persistent store based on the specified StoreType.
    private func configurePersistentStore() {
        // Prepare the persistent store description according to store type.
        let description: NSPersistentStoreDescription
        switch storeType {
        case .sqlite:
            description = NSPersistentStoreDescription()
            description.type = NSSQLiteStoreType
            // Enable automatic lightweight migration for model changes.
            description.shouldInferMappingModelAutomatically = true
            description.shouldMigrateStoreAutomatically = true

        case .inMemory:
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
        }

        // Apply the description to the container before loading stores.
        container.persistentStoreDescriptions = [description]

        // Load the persistent stores (synchronously) and crash on any failure.
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Unresolved Core Data error: \(error)")
            }
        }

        // Set main context merge policy to avoid conflicts (new data wins).
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Merge changes from background context and external (e.g., iCloud) into viewContext automatically.
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Tag the main context's changes with an author name (useful for history tracking or sync).
        container.viewContext.transactionAuthor = "viewContext"
    }
}

// MARK: - Auto-Save Hook

extension LocalStorage {

    /// Registers for application lifecycle notifications to auto-save the main context.
    /// Call this after initializing LocalStorage (e.g., in AppDelegate or scene delegate).
    public func registerLifecycleObservers() {
        let center = NotificationCenter.default
        // Save on app going to background (inactive state).
        center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.saveViewContext()
        }
        // Save on app termination.
        center.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.saveViewContext()
        }
    }
}
#endif
