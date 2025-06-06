//
//  WorkoutFlowIntegrationTests.swift
//  Gainz • WorkoutLogger • Integration
//
//  End-to-end tests that:
//
//  • Walk through a two-exercise session
//  • Verify set-completion propagates to repository & analytics
//  • Assert rest-timer counts down only while app is active
//
//  Inspired by best practices for testing Combine pipelines  [oai_citation:0‡swiftbysundell.com](https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code?utm_source=chatgpt.com)
//  and virtual-time schedulers from CombineSchedulers  [oai_citation:1‡github.com](https://github.com/pointfreeco/combine-schedulers?utm_source=chatgpt.com).
//

import XCTest
import Combine
import CombineSchedulers
@testable import WorkoutLogger
@testable import Domain

// MARK: - Integration Test Double Implementations
private final class SpyWorkoutRepository: WorkoutRepository {
    private(set) var savedSessions: [WorkoutSession] = []
    func save(_ session: WorkoutSession) async throws { savedSessions.append(session) }
}

private final class SpyAnalytics: AnalyticsManaging {
    private(set) var events: [AnalyticsEvent] = []
    func log(_ event: AnalyticsEvent) { events.append(event) }
}

// MARK: - Test
final class WorkoutFlowIntegrationTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func test_fullWorkoutFlow_savesSession_andLogsAnalytics() {
        // GIVEN
        let scheduler = DispatchQueue.test                        // deterministic time-control  [oai_citation:2‡forums.swift.org](https://forums.swift.org/t/is-there-an-easy-way-to-inject-a-combine-scheduler/35756?utm_source=chatgpt.com)
        let repository = SpyWorkoutRepository()
        let analytics  = SpyAnalytics()

        // Two exercises stub
        let squats   = Exercise(id: UUID(), name: "Squat", measurementUnit: .weightReps)
        let benches  = Exercise(id: UUID(), name: "Bench Press", measurementUnit: .weightReps)

        var session = WorkoutSession(
            id: UUID(),
            startedAt: .now,
            exerciseOrder: [squats.id, benches.id]
        )

        // System-under-test
        let vm = WorkoutViewModel(
            session: session,
            exercises: [
                squats.id: ExerciseLog(exerciseId: squats.id, performedSets: []),
                benches.id: ExerciseLog(exerciseId: benches.id, performedSets: [])
            ],
            restDuration: 60,
            timerScheduler: scheduler,
            workoutRepository: repository,
            analytics: analytics
        )

        // WHEN — user records two sets of squats, then switches exercise
        vm.completeSet(weight: 225, reps: 5, rir: 1)              // first set
        vm.startRest()
        scheduler.advance(by: .seconds(60))                       // rest counts down
        vm.completeSet(weight: 225, reps: 5, rir: 2)              // second set

        vm.selectExercise(benches.id)                             // move to bench
        vm.completeSet(weight: 185, reps: 8, rir: 2)

        // Finish workout
        let exp = expectation(description: "session saved")
        Task {
            try await vm.finishWorkout()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        // THEN — repository contains fully populated session
        XCTAssertEqual(repository.savedSessions.count, 1)
        let saved = repository.savedSessions.first!
        XCTAssertEqual(saved.exerciseOrder, [squats.id, benches.id])
        XCTAssertEqual(saved.sets.count, 3, "all performed sets persisted")

        // AND analytics emitted expected events
        XCTAssertTrue(analytics.events.contains { $0.name == "workout_finished" })
        XCTAssertTrue(analytics.events.contains { $0.name == "set_logged" && $0.parameters["exercise"] as? String == "Squat" })
    }

    func test_restTimer_stopsWhenAppEntersBackground() {
        // GIVEN
        let scheduler   = DispatchQueue.test
        let vm          = WorkoutViewModel(
            session: .init(id: UUID(), startedAt: .now, exerciseOrder: []),
            exercises: [:],
            restDuration: 30,
            timerScheduler: scheduler,
            workoutRepository: SpyWorkoutRepository(),
            analytics: SpyAnalytics()
        )

        vm.startRest()
        scheduler.advance(by: .seconds(10))
        XCTAssertEqual(vm.restRemaining, 20)

        // WHEN app goes to background
        vm.handleLifecycle(.willResignActive)
        scheduler.advance(by: .seconds(10))

        // THEN timer frozen
        XCTAssertEqual(vm.restRemaining, 20, accuracy: 0.1)

        // WHEN back to foreground
        vm.handleLifecycle(.didBecomeActive)
        scheduler.advance(by: .seconds(10))

        // THEN countdown resumes
        XCTAssertEqual(vm.restRemaining, 10, accuracy: 0.1)
    }
}
