//
//  PlannerAnalyticsIntegrationTests.swift
//  GainzIntegrationTests
//
//  Created by AI on 2025-06-06.
//  Mission: advanced, logical, intelligently-designed, world-class code.
//
//  Integration scope:
//  • Planner → generates a MesocyclePlan
//  • WorkoutLogger → logs a WorkoutSession
//  • AnalyticsService → aggregates via CalculateAnalyticsUseCase
//  • Assert AnalyticsDashboard receives expected chest metrics
//
//  Dependencies are injected with in-memory stub repositories.
//

import XCTest
@testable import Domain
@testable import Planner
@testable import WorkoutLogger
@testable import AnalyticsService

final class PlannerAnalyticsIntegrationTests: XCTestCase {

    private var exerciseRepo: InMemoryExerciseRepository!
    private var workoutRepo: InMemoryWorkoutRepository!
    private var analyticsRepo: InMemoryAnalyticsRepository!

    private var planMesocycle: PlanMesocycleUseCase!
    private var logWorkout: LogWorkoutUseCase!
    private var calcAnalytics: CalculateAnalyticsUseCase!

    override func setUpWithError() throws {
        exerciseRepo  = .demo()          // seeded with canonical lifts
        workoutRepo   = .init()
        analyticsRepo = .init()

        planMesocycle = PlanMesocycleUseCase(
            exerciseRepository: exerciseRepo,
            workoutRepository: workoutRepo
        )

        logWorkout = LogWorkoutUseCase(
            workoutRepository: workoutRepo,
            exerciseRepository: exerciseRepo
        )

        calcAnalytics = CalculateAnalyticsUseCase(
            workoutRepository: workoutRepo,
            analyticsRepository: analyticsRepo
        )
    }

    /// End-to-end flow:
    /// 1. Generate a 4-week push/pull/legs mesocycle.
    /// 2. Simulate logging Day-1 workout with three bench-press sets.
    /// 3. Recalculate analytics.
    /// 4. Verify chest weeklyVolume == 3 sets and tier ≥ Beginner.
    func testPlanLogAnalyzeFlow() throws {
        // Step 1 – Plan mesocycle for a beginner focused on hypertrophy.
        let profile = UserProfile.demoBeginner()
        let meso = try XCTUnwrap(
            planMesocycle.execute(
                goal: .buildMuscle,
                experience: .beginner,
                frequencyPerWeek: 6,
                userProfile: profile)
        )
        XCTAssertEqual(meso.weeks.count, 4)

        // Step 2 – Log first workout (bench press 3 × 8 @ 60 kg).
        let workoutId = meso.weeks.first!.days.first!.workoutPlan.id
        var session = WorkoutSession.from(plan: meso, workoutID: workoutId)
        session.sets = [
            .init(exerciseId: "bench_press", load: 60, reps: 8),
            .init(exerciseId: "bench_press", load: 60, reps: 8),
            .init(exerciseId: "bench_press", load: 60, reps: 8)
        ]
        try logWorkout.execute(session: session)

        // Step 3 – Calculate analytics snapshot.
        let dashboard = try calcAnalytics.execute(for: profile.id)

        // Step 4 – Assertions on chest metrics.
        let chest = try XCTUnwrap(dashboard.muscleMetrics[.chest])
        XCTAssertEqual(chest.weeklyVolumeSets, 3)
        XCTAssertGreaterThanOrEqual(
            chest.tier.rawValue,
            MuscleTier.beginner.rawValue)
    }
}
