//
//  HomeCoordinator.swift
//  HomeFeature
//
//  Root navigation orchestration for the Home tab.
//  Owns the ViewModel, injects dependencies, and exposes a SwiftUI
//  entry‐point that the AppCoordinator can embed in a TabView.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain
import FeatureSupport

// MARK: - HomeCoordinator

public struct HomeCoordinator: View {

    // MARK: Dependencies
    private let planner: PlanRepository
    private let workoutRepo: WorkoutRepository
    private let analytics: AnalyticsService

    // MARK: State
    @StateObject
    private var viewModel: HomeViewModel

    // MARK: Init
    public init(planner: PlanRepository,
                workoutRepo: WorkoutRepository,
                analytics: AnalyticsService) {
        self.planner     = planner
        self.workoutRepo = workoutRepo
        self.analytics   = analytics

        // _StateObject_ requires creation in init, not property list.
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                planner: planner,
                workoutRepo: workoutRepo,
                analytics: analytics
            )
        )
    }

    // MARK: Body
    public var body: some View {
        HomeView(state: $viewModel.state) { intent in
            viewModel.send(intent)
        }
        .onAppear { viewModel.send(.onAppear) }
    }
}
