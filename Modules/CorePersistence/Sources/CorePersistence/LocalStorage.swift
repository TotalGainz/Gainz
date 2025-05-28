//
//  LocalStorage.swift
//  CorePersistence
//
//  One-stop Core Data stack responsible for:
//
//  • Loading the persistent container (SQLite by default, in ~/Library)
//  • Exposing main-actor viewContext + backgroundContext for writes
//  • Auto-saving on app lifecycle notifications
//  • Lightweight migration + schema consistency checks
//
//  No UIKit / SwiftUI imports—Foundation + CoreData only.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import CoreData

// MARK: - LocalStorage

/// Thread-safe Core Data stack.
///
/// `LocalStorage` is **injected** wherever persistence is needed rather than
/// accessed via a global singleton—this keeps tests hermetic and reduces
/// hidden coupling. For top-level convenience, a shared instance is provided
/// via `LocalStorage.shared`, but DI frameworks (e.g., Factory) can swap in a
/// memory-only store during unit tests.
public final class LocalStorage {

    // MARK: Static convenience

    /// Lazily initialised shared container—safe for production use,
    /// mocked in tests by passing `.inMemory`.
    public static let shared = LocalStorage(storeType: .sqlite)

    // MARK: Store Type

    public enum StoreType {
        case sqlite
        case inMemory
    }

    // MARK: Init

    /// Designated initialiser—passes `modelName` for future modularisation.
    public init(storeType: StoreType, modelName: String = "Gainz") {
        self.storeType = storeType
        self.modelName = modelName
        container = NSPersistentContainer(name: modelName)
        configurePersistentStore()
    }

    // MARK: Public API

    /// Main-actor managed object context for UI reads.
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Background context for heavy writes; automatically merges changes
    /// back into `viewContext`.
    public lazy var backgroundContext: NSManagedObjectContext = {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }()

    /// Saves `viewContext` if there are unsaved changes.
    @MainActor
    public func saveViewContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            assertionFailure("⚠️ Core Data save failed: \(error)")
        }
    }

    // MARK: Private

    private let storeType: StoreType
    private let modelName: String
    private let container: NSPersistentContainer

    private func configurePersistentStore() {
        let description: NSPersistentStoreDescription

        switch storeType {
        case .sqlite:
            description = NSPersistentStoreDescription()
            description.type = NSSQLiteStoreType
            description.shouldInferMappingModelAutomatically = true
            description.shouldMigrateStoreAutomatically = true

        case .inMemory:
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
        }

        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("❌ Unresolved Core Data error \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.transactionAuthor = "viewContext"
    }
}

// MARK: - Auto-Save Hook

extension LocalStorage {

    /// Registers observers to auto-persist on app background / termination.
    ///
    /// Call from `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
    /// after setting up the shared `LocalStorage`.
    public func registerLifecycleObservers() {
        let center = NotificationCenter.default
        center.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveViewContext()
        }

        center.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveViewContext()
        }
    }
}
