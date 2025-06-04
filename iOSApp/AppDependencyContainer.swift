//
//  AppDependencyContainer.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Mission: Advanced, logical, intelligently designed, world-class DI container.
//

import Foundation
import Combine

// MARK: - Service Locator / Dependency Container
/// Thread-safe, type-erased store for app-wide singletons.
/// Pattern inspired by Swinject / Factory while remaining lightweight.
/// Registers concrete instances at launch and resolves them on demand.
@MainActor
final class AppDependencyContainer: ObservableObject {

    // MARK: Singleton
    static let shared = AppDependencyContainer()

    // MARK: Storage
    private var services: [ObjectIdentifier: Any] = [:]

    // MARK: Registration
    /// Register a concrete instance for its protocol/type.
    func register<Service>(_ instance: Service) {
        let key = ObjectIdentifier(Service.self)
        services[key] = instance
    }

    // MARK: Resolution
    /// Resolve a concrete instance for the requested protocol/type.
    /// Crashes early if dependency is missing, surfacing mis-configuration fast.
    func resolve<Service>() -> Service {
        let key = ObjectIdentifier(Service.self)
        guard let service = services[key] as? Service else {
            fatalError("🟥 Missing dependency for \(Service.self)")
        }
        return service
    }

    // MARK: Bootstrap
    /// Pre-populate required dependencies; called from `AppContainer.bootstrap()`.
    func bootstrap() {
        register(WorkoutRepository.live as WorkoutRepositoryType)
        register(SettingsStore.live      as SettingsStoreType)
        // 🔒 Add further registrations here…
    }

    // MARK: Reset (Tests)
    /// Clears all services, enabling isolated unit test scenarios.
    func reset() {
        services.removeAll()
    }
}

// MARK: - Protocol Abstractions
/// Prefer protocol-first design so implementations can be swapped for mocks.
protocol WorkoutRepositoryType {
    func preload()
    // add async CRUD funcs…
}

protocol SettingsStoreType: ObservableObject {
    // settings getters/setters…
}

// MARK: - Live Implementations (Examples)
extension WorkoutRepository {
    /// Concrete live repository injected at runtime.
    static var live: WorkoutRepository { .init() }
}

extension SettingsStore {
    /// Concrete live store injected at runtime.
    static var live: SettingsStore { .init() }
}
