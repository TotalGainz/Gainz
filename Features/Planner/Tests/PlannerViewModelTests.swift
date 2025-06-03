//
//  PlannerViewModelTests.swift
//  Gainz – Planner Feature
//
//  Unit tests for PlannerViewModel’s state machine.
//  • Uses in-memory MockPlannerRepository to isolate CorePersistence.
//  • Combine publisher expectations ensure async → sync determinism.
//  • Validates idempotent loading, exercise insertion, and error flow.
//
//  Created on 27 May 2025.
//

import XCTest
import Combine
@testable import Planner          // Feature target
@testable import Domain          // MesocyclePlan, ExercisePlan
@testable import CorePersistence // For protocol types only

final class PlannerViewModelTests: XCTestCase {

    // MARK: - Properties
    private var vm: PlannerViewModel!
    private var repo: MockPlannerRepository!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup / Teardown
    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = MockPlannerRepository()
        vm   = PlannerViewModel(repository: repo)
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        vm = nil
        repo = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests

    /// ViewModel should publish `.loading` immediately on `onAppear()`.
    func testInitialState_isLoading() {
        // Given
        let exp = expectation(description: "State switches to loading")
        vm.$state
            .dropFirst() // Ignore initial .idle
            .sink { state in
                if case .loading = state { exp.fulfill() }
            }
            .store(in: &cancellables)

        // When
        vm.onAppear()

        // Then
        wait(for: [exp], timeout: 0.1)
    }

    /// Successful repository load must transition to `.loaded(plan)`.
    func testLoadSuccess_populatesPlan() {
        // Given
        repo.stubPlan = MesocyclePlan.fixture() // prebuilt factory
        let exp = expectation(description: "Loaded plan published")
        vm.$state
            .drop(while: { $0 != .loaded(repo.stubPlan!) })
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        // When
        vm.onAppear()

        // Then
        wait(for: [exp], timeout: 0.1)
    }

    /// Adding an exercise should mutate the plan and publish new state.
    func testAddExercise_updatesPlan() throws {
        // Given
        let basePlan  = MesocyclePlan.fixture()
        let newBench  = ExercisePlan.fixture(name: "Test Bench")
        repo.stubPlan = basePlan
        vm.onAppear() // prime

        let exp = expectation(description: "Plan updated with bench")
        vm.$state
            .drop(while: { !$0.containsExercise(named: "Test Bench") })
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        // When
        vm.addExercise(newBench)

        // Then
        wait(for: [exp], timeout: 0.1)
    }

    /// Repository load failure must transition to `.error` with message.
    func testLoadFailure_publishesError() {
        // Given
        repo.error = PlannerRepositoryError.failedToLoad
        let exp = expectation(description: "Error state emitted")
        vm.$state
            .drop(while: { if case .error = $0 { return false }; return true })
            .sink { state in
                if case .error(let msg) = state, msg.contains("failed") {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        vm.onAppear()

        // Then
        wait(for: [exp], timeout: 0.1)
    }
}

// MARK: - Helpers & Mocks

/// Simple in-memory fake that conforms to PlannerRepository.
private final class MockPlannerRepository: PlannerRepository {

    var stubPlan: MesocyclePlan?
    var error: PlannerRepositoryError?

    func fetchActiveMesocycle() -> AnyPublisher<MesocyclePlan, PlannerRepositoryError> {
        if let error { return Fail(outputType: MesocyclePlan.self, failure: error).eraseToAnyPublisher() }
        return Just(stubPlan ?? .fixture())
            .setFailureType(to: PlannerRepositoryError.self)
            .eraseToAnyPublisher()
    }

    func save(plan: MesocyclePlan) -> AnyPublisher<Void, PlannerRepositoryError> {
        stubPlan = plan
        return Just(()).setFailureType(to: PlannerRepositoryError.self).eraseToAnyPublisher()
    }
}

// MARK: - Model Fixtures

extension MesocyclePlan {
    static func fixture(id: UUID = .init()) -> MesocyclePlan {
        MesocyclePlan(
            id: id,
            name: "6-Week Hypertrophy",
            weeks: 6,
            startDate: Date(),
            exercisePlans: []
        )
    }
}

extension ExercisePlan {
    static func fixture(id: UUID = .init(), name: String) -> ExercisePlan {
        ExercisePlan(
            id: id,
            exerciseId: UUID(),
            sets: 3,
            repRange: RepRange(min: 8, max: 12),
            note: name
        )
    }
}

// MARK: - State convenience

private extension PlannerState {
    func containsExercise(named name: String) -> Bool {
        guard case .loaded(let plan) = self else { return false }
        return plan.exercisePlans.contains(where: { $0.note == name })
    }
}
