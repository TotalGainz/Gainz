//
//  PlannerCoordinator.swift
//  PlannerFeature
//
//  Orchestrates all navigation flows inside the “Planner” feature:
//  • Calendar overview → WorkoutDetail → ExercisePlan editor
//  • Sheet modals for plan duplication / deletion
//  • Deep-link entry for “gainz://planner/{date}”
//
//  Pure coordination; contains no view code and no persistence logic.
//  Works with SwiftUI’s `NavigationStack` via a published `path` binding.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Domain            // MesocyclePlan, ExercisePlan
import CorePersistence   // PlanRepository

// MARK: - PlannerCoordinatorProtocol

public protocol PlannerCoordinatorProtocol: AnyObject {
    func pushWorkoutDetail(date: Date)
    func pushExerciseEditor(planID: UUID, exerciseID: UUID?)
    func presentDuplicationSheet(planID: UUID)
    func dismissSheet()
    func pop()
    func deepLink(to url: URL)
}

// MARK: - PlannerCoordinator

@MainActor
public final class PlannerCoordinator: ObservableObject, PlannerCoordinatorProtocol {

    // MARK: Navigation Enums

    public enum Route: Hashable, Identifiable {
        case workoutDetail(date: Date)
        case exerciseEditor(planID: UUID, exerciseID: UUID?)

        public var id: String {
            switch self {
            case let .workoutDetail(date):
                return "workout-\(date.timeIntervalSince1970)"
            case let .exerciseEditor(planID, exerciseID):
                return "editor-\(planID)-\(exerciseID?.uuidString ?? "new")"
            }
        }
    }

    public enum Sheet: Identifiable {
        case duplicatePlan(UUID)

        public var id: String {
            switch self {
            case let .duplicatePlan(id):
                return "duplicate-\(id.uuidString)"
            }
        }
    }

    // MARK: Published Navigation State

    @Published public var path: [Route] = []
    @Published public var activeSheet: Sheet?

    // MARK: Dependencies

    private let repository: PlanRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    public init(repository: PlanRepository) {
        self.repository = repository
    }

    // MARK: Route Pushes

    public func pushWorkoutDetail(date: Date) {
        // Append a workout detail destination onto the navigation path.
        path.append(.workoutDetail(date: date))
    }

    public func pushExerciseEditor(planID: UUID, exerciseID: UUID?) {
        // Append an exercise editor destination (for creating or editing an ExercisePlan).
        path.append(.exerciseEditor(planID: planID, exerciseID: exerciseID))
    }

    // MARK: Sheet Management

    public func presentDuplicationSheet(planID: UUID) {
        // Trigger presentation of a duplication confirmation sheet.
        activeSheet = .duplicatePlan(planID)
    }

    public func dismissSheet() {
        activeSheet = nil
    }

    // MARK: Navigation Helpers

    public func pop() {
        _ = path.popLast()
    }

    // MARK: Deep-link Handling

    public func deepLink(to url: URL) {
        guard url.scheme == "gainz", url.host == "planner" else { return }
        let components = url.pathComponents.filter { $0 != "/" }
        guard let dateString = components.first,
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return
        }
        // Deep link opens the Planner and pushes the specified date's workout detail.
        pushWorkoutDetail(date: date)
    }
}
