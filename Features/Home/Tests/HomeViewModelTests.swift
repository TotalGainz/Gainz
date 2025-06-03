//
//  HomeViewModelTests.swift
//  HomeFeatureTests
//
//  Unit tests for HomeViewModel.
//  Mocks out PlanRepository, WorkoutRepository, and AnalyticsService
//  so logic stays pure and deterministic.
//
//  Created for Gainz on 27 May 2025.
//

import XCTest
@testable import HomeFeature
@testable import Domain      // WorkoutSession, ExerciseLog, SetRecord

// MARK: - Test Doubles

final class MockPlanRepository: PlanRepository {
    var todayWorkoutPlanStub: WorkoutSession?
    var plannedWeeklyVolumeStub: Int = 0

    func todayWorkoutPlan() async -> WorkoutSession? {
        todayWorkoutPlanStub
    }

    func plannedWeeklyVolume() async -> Int {
        plannedWeeklyVolumeStub
    }
}

final class MockWorkoutRepository: WorkoutRepository {
    // Empty ‒ not used by HomeViewModel yet
}

final class MockAnalyticsService: AnalyticsService {
    var bodyWeightTrendStub: Double?
    var personalRecordCountStub: Int = 0

    func bodyWeightTrend(days: Int) async -> Double? {
        bodyWeightTrendStub
    }

    func personalRecordCount(monthsBack: Int) async -> Int {
        personalRecordCountStub
    }
}

// MARK: - Tests

@MainActor
final class HomeViewModelTests: XCTestCase {

    private var sut: HomeViewModel!
    private var mockPlan: MockPlanRepository!
    private var mockWorkoutRepo: MockWorkoutRepository!
    private var mockAnalytics: MockAnalyticsService!

    override func setUp() {
        super.setUp()
        mockPlan        = MockPlanRepository()
        mockWorkoutRepo = MockWorkoutRepository()
        mockAnalytics   = MockAnalyticsService()

        sut = HomeViewModel(planner: mockPlan,
                            workoutRepo: mockWorkoutRepo,
                            analytics: mockAnalytics)
    }

    override func tearDown() {
        sut            = nil
        mockPlan       = nil
        mockAnalytics  = nil
        super.tearDown()
    }

    /// Verifies greeting generator for a deterministic morning hour.
    func testMakeGreeting_returnsMorning() {
        // Given 06:00
        let components = DateComponents(calendar: .current,
                                        year: 2025, month: 5, day: 27, hour: 6)
        let morning    = components.date!

        // When
        let greeting = HomeViewModel.makeGreeting(date: morning)

        // Then
        XCTAssertEqual(greeting, "Good morning")
    }

    /// Ensures dashboard state populates with injected mock values.
    func testLoadDashboard_populatesState() async {
        // Given
        mockPlan.todayWorkoutPlanStub = WorkoutSession(id: .init(),
                                                       date: .now,
                                                       exerciseLogs: [])
        mockPlan.plannedWeeklyVolumeStub = 420
        mockAnalytics.bodyWeightTrendStub = 0.8
        mockAnalytics.personalRecordCountStub = 3

        // When
        await sut.send(.onAppear)

        // Then
        let state = sut.state
        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.todayWorkout?.id, mockPlan.todayWorkoutPlanStub?.id)
        XCTAssertEqual(state.weeklyVolume, 420)
        XCTAssertEqual(state.bodyWeightTrend, 0.8)
        XCTAssertEqual(state.personalRecords, 3)
    }
}
