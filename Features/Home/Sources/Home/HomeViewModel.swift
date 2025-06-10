// MARK: - HomeViewModel.swift

import Foundation
import Combine
import Domain                // MesocyclePlan, WorkoutSession, etc.
import FeatureSupport        // UnitConversion, etc.

@MainActor
public final class HomeViewModel: ObservableObject {
    // MARK: - State and Actions

    public struct State: Equatable {
        public var greeting: String = ""
        public var todayWorkout: WorkoutSession? = nil
        public var weeklyVolume: Int = 0
        public var lastWeight: Double? = nil
        public var bodyWeightTrend: Double? = nil   // weight change over last 7 days (kg)
        public var personalRecords: Int = 0        // count of PRs this month
        public var streakCount: Int = 0            // consecutive-day workout streak
        public var sessionsCompleted: Int = 0      // sessions completed this week
        public var sessionsPlanned: Int = 0        // sessions planned for this week
        public var isLoading: Bool = true
    }

    public enum Action {
        case onAppear
        case refreshTapped
        // Navigation actions (e.g., openNextWorkout) are handled via deep links in the View.
    }

    // MARK: - Published Properties

    @Published public private(set) var state = State()
    @Published public var error: HomeError? = nil  // binds to alert in UI

    // MARK: - Dependencies

    private let planner: PlanRepository
    private let workoutRepo: WorkoutRepository
    private let analytics: AnalyticsService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(planner: PlanRepository,
                workoutRepo: WorkoutRepository,
                analytics: AnalyticsService) {
        self.planner = planner
        self.workoutRepo = workoutRepo
        self.analytics = analytics
    }

    // MARK: - Event Handling

    public func send(_ action: Action) {
        switch action {
        case .onAppear, .refreshTapped:
            Task { await loadDashboard() }
        }
    }

    // Optionally expose an async refresh (for pull-to-refresh control)
    public func refresh() async {
        await loadDashboard()
    }

    // MARK: - Data Loading

    /// Fetches all data for the Home dashboard and updates state.
    private func loadDashboard() async {
        // Reset error and indicate loading state
        error = nil
        state.isLoading = true

        do {
            // Fetch each piece of data (sequentially for simplicity and error handling)
            state.greeting        = Self.makeGreeting()
            state.todayWorkout    = try await planner.todayWorkoutPlan()
            state.weeklyVolume    = try await planner.plannedWeeklyVolume()
            state.lastWeight      = try await analytics.lastLoggedWeight()
            state.bodyWeightTrend = try await analytics.bodyWeightTrend(days: 7)
            state.personalRecords = try await analytics.personalRecordCount(monthsBack: 1)
            state.streakCount     = try await analytics.currentStreak()
            state.sessionsPlanned = try await planner.plannedWeeklySessions()
            state.sessionsCompleted = try await workoutRepo.completedWeeklySessions()
            state.isLoading       = false
        } catch {
            // On failure, stop loading and surface an error message
            state.isLoading = false
            error = HomeError("Failed to load data. Please try again.")
        }
    }

    /// Generates a greeting based on the time of day.
    private static func makeGreeting(date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:  return NSLocalizedString("Good morning", comment: "Morning greeting")
        case 12..<17: return NSLocalizedString("Good afternoon", comment: "Afternoon greeting")
        case 17..<22: return NSLocalizedString("Good evening", comment: "Evening greeting")
        default:      return NSLocalizedString("Still grinding?", comment: "Late-night greeting")
        }
    }
}

// MARK: - HomeError (for user-facing errors)

public struct HomeError: Error, Identifiable {
    public let id = UUID()
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}
