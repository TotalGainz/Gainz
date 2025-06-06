//
//  WorkoutPlanIntegrationTests.swift
//  GainzIntegrationTests
//
//  Created by AI on 2025-06-06.
//  Mission: advanced, logical, intelligently-designed, world-class code.
//
//  Flow under test
//  ───────────────
//  1. GenerateInitialPlanUseCase → beginner 4-day hypertrophy template
//  2. Persist MesocyclePlan + WorkoutPlans in WorkoutRepository
//  3. Simulate logging Day-1 workout via LogWorkoutUseCase
//  4. Verify repository links WorkoutSession → originating WorkoutPlan
//     and marks plan day as completed.
//

import XCTest
@testable import Domain
@testable import Planner        // package exposing GenerateInitialPlanUseCase
@testable import WorkoutLogger  // package exposing LogWorkoutUseCase

final class WorkoutPlanIntegrationTests: XCTestCase {

    private var exerciseRepo: InMemoryExerciseRepository!
    private var workoutRepo: InMemoryWorkoutRepository!

    private var generatePlan: GenerateInitialPlanUseCase!
    private var logWorkout: LogWorkoutUseCase!

    override func setUpWithError() throws {
        exerciseRepo = .demo()       // seeded canonical lifts
        workoutRepo  = .init()

        generatePlan = GenerateInitialPlanUseCase(
            exerciseRepository: exerciseRepo,
            workoutRepository: workoutRepo
        )

        logWorkout = LogWorkoutUseCase(
            workoutRepository: workoutRepo,
            exerciseRepository: exerciseRepo
        )
    }

    /// End-to-end: plan → log → verify linkage.
    func testPlanGenerationAndCompletionFlow() throws {
        // 1. Beginner profile planning four training days/week.
        let profile = UserProfile.demoBeginner()
        let meso = try generatePlan.execute(
            goal: .buildMuscle,
            experience: .beginner,
            frequencyPerWeek: 4,
            userProfile: profile
        )

        // Basic sanity on generated structure.
        XCTAssertEqual(meso.weeks.count, 4)
        XCTAssertGreaterThan(meso.workoutPlans.count, 0)

        // 2. Select first WorkoutPlan.
        let firstPlan = try XCTUnwrap(meso.workoutPlans.first)

        // 3. Log corresponding session (bench press placeholder).
        var session = WorkoutSession.from(plan: meso, workoutID: firstPlan.id)
        session.sets = [
            .init(exerciseId: "bench_press", load: 50, reps: 10),
            .init(exerciseId: "bench_press", load: 50, reps: 10),
            .init(exerciseId: "bench_press", load: 50, reps: 10)
        ]
        try logWorkout.execute(session: session)

        // 4a. Repository contains a session linked to plan.
        let sessions = workoutRepo.sessions(forPlanID: firstPlan.id)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.id, session.id)

        // 4b. WorkoutPlan marked completed.
        let updatedPlan = try XCTUnwrap(workoutRepo.fetchWorkoutPlan(id: firstPlan.id))
        XCTAssertTrue(updatedPlan.isCompleted)
    }
}
