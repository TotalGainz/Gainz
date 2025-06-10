// MARK: - HomeCoordinator.swift

import SwiftUI
import Domain
import FeatureSupport

public struct HomeCoordinator: View {
    // MARK: Dependencies

    private let planner: PlanRepository
    private let workoutRepo: WorkoutRepository
    private let analytics: AnalyticsService

    // MARK: State

    @StateObject private var viewModel: HomeViewModel

    // MARK: Initialization

    public init(planner: PlanRepository,
                workoutRepo: WorkoutRepository,
                analytics: AnalyticsService) {
        self.planner     = planner
        self.workoutRepo = workoutRepo
        self.analytics   = analytics
        // Instantiate the ViewModel with injected dependencies
        _viewModel = StateObject(wrappedValue: HomeViewModel(planner: planner,
                                                             workoutRepo: workoutRepo,
                                                             analytics: analytics))
    }

    // MARK: View Construction

    public var body: some View {
        HomeView(state: $viewModel.state) { intent in
            viewModel.send(intent)
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
        .refreshable {
            // Pull-to-refresh triggers an async reload
            await viewModel.refresh()
        }
        .alert(item: $viewModel.error) { err in
            Alert(title: Text("Oops"),
                  message: Text(err.message),
                  dismissButton: .default(Text("OK")))
        }
    }
}
