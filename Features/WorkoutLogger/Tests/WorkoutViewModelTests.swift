//
//  WorkoutViewModelTests.swift
//  Gainz • WorkoutLogger feature
//
//  Verifies that WorkoutViewModel
//  1) suspends & resumes its rest-timer with app‐lifecycle events
//  2) surfaces progressive-overload load suggestions based on prior RIR
//
//  Dependencies injected so the test runs deterministically with a
//  virtual time-source; no HRV or velocity tracking involved.
//

import XCTest
import Combine
import CombineSchedulers
@testable import WorkoutLogger
@testable import Domain       // ← models (ExerciseLog, SetRecord, etc.)

// MARK: - Helper Mocks
private struct StubExercise: Identifiable {
    let id = UUID()
    let name: String
}

private final class MockAnalyticsManager: AnalyticsManaging {
    func log(_ event: AnalyticsEvent) { /* no-op for test */ }
}

private final class MockWorkoutRepository: WorkoutRepository {
    func save(_ session: WorkoutSession) async throws { }
}

// MARK: - System-under-test factory
private func makeSUT(
    scheduler: TestSchedulerOf<DispatchQueue> = DispatchQueue.test
) -> WorkoutViewModel {
    let exercise = StubExercise(name: "Bench Press")
    let session  = WorkoutSession(id: UUID(),
                                  startedAt: .now,
                                  exerciseOrder: [exercise.id])
    return WorkoutViewModel(
        session: session,
        exercises: [exercise.id: ExerciseLog(exerciseId: exercise.id,
                                             performedSets: [])],
        restDuration: 30,            // default rest
        timerScheduler: scheduler,
        workoutRepository: MockWorkoutRepository(),
        analytics: MockAnalyticsManager()
    )
}

// MARK: - Tests
final class WorkoutViewModelTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    // 1️⃣ rest-timer suspends and resumes with lifecycle events
    func test_restTimerPausesAndResumesWithAppLifecycle() {
        let scheduler = DispatchQueue.test
        let vm = makeSUT(scheduler: scheduler)

        // start a rest phase
        vm.startRest()
        XCTAssertEqual(vm.restRemaining, 30, "timer must initialise full")

        // advance 5 s
        scheduler.advance(by: .seconds(5))
        XCTAssertEqual(vm.restRemaining, 25)

        // simulate background entry
        vm.handleLifecycle(.willResignActive)
        scheduler.advance(by: .seconds(10))   // time passes while paused
        XCTAssertEqual(vm.restRemaining, 25, "timer must freeze in background")

        // foreground resume
        vm.handleLifecycle(.didBecomeActive)
        scheduler.advance(by: .seconds(10))
        XCTAssertEqual(vm.restRemaining, 15, accuracy: 0.1, "timer resumes on foreground")
    }

    // 2️⃣ load suggestion bumps by +5 lb when prior set had high RIR
    func test_loadSuggestionIncreasesWhenPreviousSetEasy() {
        let vm = makeSUT()

        // log an easy set (RIR ≥ 3)
        vm.completeSet(weight: 100, reps: 8, rir: 3)

        // fetch suggestion for next set
        let suggested = vm.suggestedLoad(forExercise: vm.currentExerciseId!)

        XCTAssertEqual(suggested, 105,
                       "expected +5 lb overload after easy prior set (RIR ≥ 3)")
    }

    // 3️⃣ no suggestion change when prior set was near failure
    func test_noLoadSuggestionWhenPriorSetHard() {
        let vm = makeSUT()

        vm.completeSet(weight: 100, reps: 8, rir: 0)   // near-failure
        let suggested = vm.suggestedLoad(forExercise: vm.currentExerciseId!)

        XCTAssertNil(suggested, "no load bump when prior set RIR < 3")
    }
}
