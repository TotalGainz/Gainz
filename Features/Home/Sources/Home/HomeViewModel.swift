//
//  HomeViewModel.swift
//  HomeFeature
//
//  Drives the Home tab: greets the athlete, shows today’s workout
//  (if any), and surfaces headline metrics (last-7-day volume,
//  body-weight trend, PR streak).  Pure MVVM: no SwiftUI imports.
//
//  ▸ Injected dependencies are *protocols* so the ViewModel
//    remains unit-testable and detached from persistence details.
//  ▸ All publishers are delivered on the main actor for UI safety.
//  ▸ Zero HRV, recovery, or bar-velocity logic—hypertrophy-centric.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Domain                // MesocyclePlan, WorkoutSession
import FeatureSupport        // UnitConversion

// MARK: - HomeViewModel

@MainActor
public final class HomeViewModel: ObservableObject {

    // MARK: Nested types

    /// State consumed by `HomeView`.
    public struct State: Equatable {
        public var greeting: String = ""
        public var todayWorkout: WorkoutSession?
        public var weeklyVolume: Int = 0       // total planned reps this week
        public var bodyWeightTrend: Double?    // kg Δ over last 7 days
        public var personalRecords: Int = 0    // count of PRs this month
        public var isLoading: Bool = true
    }

    public enum Action {
        case onAppear
        case refreshTapped
    }

    // MARK: Publishers

    @Published public private(set) var state = State()

    // MARK: Dependencies

    private let planner: PlanRepository
    private let workoutRepo: WorkoutRepository
    private let analytics: AnalyticsService
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    public init(planner: PlanRepository,
                workoutRepo: WorkoutRepository,
                analytics: AnalyticsService) {
        self.planner = planner
        self.workoutRepo = workoutRepo
        self.analytics = analytics
    }

    // MARK: Interface

    /// Handle view intents.
    public func send(_ action: Action) {
        switch action {
        case .onAppear, .refreshTapped:
            Task { await loadDashboard() }
        }
    }

    // MARK: Private helpers

    private func loadDashboard() async {
        state.isLoading = true

        async let greeting     = Self.makeGreeting()
        async let todayPlan    = planner.todayWorkoutPlan()
        async let volume       = planner.plannedWeeklyVolume()
        async let bwTrend      = analytics.bodyWeightTrend(days: 7)
        async let prCount      = analytics.personalRecordCount(monthsBack: 1)

        state.greeting        = await greeting
        state.todayWorkout    = await todayPlan
        state.weeklyVolume    = await volume
        state.bodyWeightTrend = await bwTrend
        state.personalRecords = await prCount
        state.isLoading       = false
    }

    private static func makeGreeting(date: Date = .init()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Still grinding?"
        }
    }
}
