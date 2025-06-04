//
//  WorkoutCoordinator.swift
//  Planner ▸ Components
//
//  Drives navigation for the “plan → log → summary” funnel.
//  • Pure SwiftUI + Combine; no UIKit
//  • @MainActor for UI-safe mutations
//  • Uses NavigationStack + NavigationPath (iOS 16+)
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain          // MesocyclePlan, WorkoutPlan, WorkoutSession
import CorePersistence  // WorkoutRepository

// MARK: - Coordinator

@MainActor
public final class WorkoutCoordinator: ObservableObject {

    // Publicly bindable navigation path
    @Published public var path: NavigationPath = .init()

    /// All possible navigation targets reachable from Planner.
    public enum Route: Hashable {
        case workoutBuilder(template: MesocyclePlan)
        case workoutSession(id: UUID)
        case workoutSummary(id: UUID)
    }

    // MARK: Dependencies

    private let workoutRepo: WorkoutRepository

    // MARK: Init

    public init(workoutRepo: WorkoutRepository = WorkoutRepositoryImpl.shared) {
        self.workoutRepo = workoutRepo
    }

    // MARK: Navigation API (called by Views)

    /// Show the builder UI pre-populated with a mesocycle template.
    public func pushBuilder(for template: MesocyclePlan) {
        path.append(Route.workoutBuilder(template: template))
    }

    /// Persist a new session from `plan`, then navigate to its live logger.
    public func startSession(from plan: WorkoutPlan) async throws {
        let sessionId = try await workoutRepo.createSession(from: plan)
        path.append(Route.workoutSession(id: sessionId))
    }

    /// Move to the post-workout summary screen.
    public func finishSession(_ id: UUID) {
        path.append(Route.workoutSummary(id: id))
    }

    /// Return to the planner root.
    public func popToRoot() {
        path.removeLast(path.count)
    }

    // MARK: Destination Factory

    /// Centralised factory so all destinations live in one place.
    @ViewBuilder
    public func destination(for route: Route) -> some View {
        switch route {
        case .workoutBuilder(let template):
            WorkoutBuilderView(template: template, coordinator: self)

        case .workoutSession(let id):
            WorkoutSessionView(sessionId: id, coordinator: self)

        case .workoutSummary(let id):
            WorkoutSummaryView(sessionId: id, coordinator: self)
        }
    }
}

// MARK: - The Navigation Stack Wrapper

/// Wraps any “root” planner view in a NavigationStack driven by `WorkoutCoordinator`.
public struct WorkoutCoordinatorView<Root: View>: View {

    @StateObject private var coordinator: WorkoutCoordinator
    private let root: Root

    public init(
        root: Root,
        coordinator: @autoclosure @escaping () -> WorkoutCoordinator = WorkoutCoordinator()
    ) {
        _coordinator = StateObject(wrappedValue: coordinator())
        self.root = root
    }

    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            root
                .navigationDestination(for: WorkoutCoordinator.Route.self) { route in
                    coordinator
                        .destination(for: route)
                        .transition(.move(edge: .trailing))
                        .animation(.easeInOut(duration: 0.25), value: coordinator.path)
                }
        }
        .environmentObject(coordinator)
    }
}
