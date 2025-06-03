//
//  HomeViewSnapshotTests.swift
//  HomeFeatureTests
//
//  Snapshot regressions for HomeView in light / dark mode
//  across the most common form-factor (iPhone 15 Pro).
//
//  Uses @pointfreeco’s SnapshotTesting.  Run via `make test-snapshots`
//  or the Xcode test navigator.
//
//  Created for Gainz on 27 May 2025.
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import HomeFeature
@testable import Domain

final class HomeViewSnapshotTests: XCTestCase {

    // MARK: Device & precision
    private static let deviceConfig = ViewImageConfig.iPhone15Pro
    private static let tolerance: Float = 0.01   // 1 % pixel variance

    // MARK: Dependencies (mocks)

    private struct MockPlanRepo: PlanRepository {
        func todayWorkoutPlan() async -> WorkoutSession? {
            WorkoutSession.fixture(date: .now)
        }
        func plannedWeeklyVolume() async -> Int { 1_540 }
    }

    private struct MockWorkoutRepo: WorkoutRepository { /* Unused for Home */ }

    private struct MockAnalytics: AnalyticsService {
        func bodyWeightTrend(days: Int) async -> Double? { 0.8 }
        func personalRecordCount(monthsBack: Int) async -> Int { 3 }
    }

    // MARK: Tests

    func testHomeView_lightMode() {
        let vm = HomeViewModel(
            planner: MockPlanRepo(),
            workoutRepo: MockWorkoutRepo(),
            analytics: MockAnalytics()
        )
        let view = HomeView(viewModel: vm)
        assertSnapshot(
            matching: view,
            as: .image(layout: .device(Self.deviceConfig)),
            named: "Home_light",
            record: false,
            file: #file,
            testName: #function,
            line: #line,
            timeout: 5,
            precision: Self.tolerance
        )
    }

    func testHomeView_darkMode() {
        let vm = HomeViewModel(
            planner: MockPlanRepo(),
            workoutRepo: MockWorkoutRepo(),
            analytics: MockAnalytics()
        )
        let view = HomeView(viewModel: vm)
            .environment(\.colorScheme, .dark)
        assertSnapshot(
            matching: view,
            as: .image(layout: .device(Self.deviceConfig)),
            named: "Home_dark",
            record: false,
            file: #file,
            testName: #function,
            line: #line,
            timeout: 5,
            precision: Self.tolerance
        )
    }
}

// MARK: - Fixtures

private extension WorkoutSession {
    static func fixture(date: Date) -> WorkoutSession {
        let set = SetRecord(id: .init(), weight: 100, reps: 8, rpe: .eight)
        let log = ExerciseLog(id: .init(),
                              exerciseId: UUID(),   // placeholder
                              sets: [set])
        return WorkoutSession(id: .init(),
                              date: date,
                              exerciseLogs: [log])
    }
}
