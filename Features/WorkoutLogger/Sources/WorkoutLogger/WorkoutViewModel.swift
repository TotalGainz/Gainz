//
//  WorkoutViewModel.swift
//  Features • WorkoutLogger
//
//  MVVM state-machine for live workout logging.
//  ─────────────────────────────────────────────────────────
//  • Pure Combine – no SwiftUI import (views own the UI).
//  • Pulls dependencies via protocol injection for testability.
//  • No HRV, recovery-score, or velocity data.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Domain   // WorkoutSession, ExerciseLog, SetRecord
import CoreServices   // WorkoutRepository, TimeProvider

// MARK: - ViewModel

public final class WorkoutViewModel: ObservableObject {

    // MARK: Nested Types
    public struct State: Equatable {
        public var session: WorkoutSession
        public var activeExerciseIndex: Int = 0
        public var activeSetIndex: Int?      // nil → no set in progress
        public var isSaving: Bool = false
        public var error: String?
    }

    public enum Action {
        case startSet
        case finishSet(weight: Double, reps: Int, rpe: RPE)
        case nextExercise
        case previousExercise
        case saveAndExit
        case dismissError
    }

    // MARK: Dependencies
    private let repo: WorkoutRepository
    private let time: TimeProvider
    private var cancellables = Set<AnyCancellable>()

    // MARK: Publishers
    @Published public private(set) var state: State

    // MARK: Init
    public init(
        session: WorkoutSession,
        repo: WorkoutRepository,
        time: TimeProvider
    ) {
        self.state = State(session: session)
        self.repo = repo
        self.time = time
    }

    // MARK: Intent → Mutation entry point
    @MainActor
    public func send(_ action: Action) {
        switch action {
        case .startSet:
            guard state.activeSetIndex == nil else { return }
            state.activeSetIndex = currentExerciseLog.sets.count

        case let .finishSet(weight, reps, rpe):
            guard let setIndex = state.activeSetIndex else { return }
            appendSet(weight: weight, reps: reps, rpe: rpe, at: setIndex)
            state.activeSetIndex = nil

        case .nextExercise:
            state.activeExerciseIndex = min(state.activeExerciseIndex + 1,
                                            state.session.exerciseLogs.count - 1)

        case .previousExercise:
            state.activeExerciseIndex = max(state.activeExerciseIndex - 1, 0)

        case .saveAndExit:
            persistSession()

        case .dismissError:
            state.error = nil
        }
    }
}

// MARK: - Private helpers
private extension WorkoutViewModel {

    var currentExerciseLog: ExerciseLog {
        state.session.exerciseLogs[state.activeExerciseIndex]
    }

    func appendSet(weight: Double, reps: Int, rpe: RPE, at index: Int) {
        var log = currentExerciseLog
        let set = SetRecord(id: UUID(),
                            timestamp: time.now,
                            weight: weight,
                            reps: reps,
                            rpe: rpe)

        log.sets.insert(set, at: index)
        replaceExerciseLog(log)
    }

    func replaceExerciseLog(_ log: ExerciseLog) {
        state.session.exerciseLogs[state.activeExerciseIndex] = log
    }

    func persistSession() {
        state.isSaving = true
        repo.saveWorkoutSession(state.session)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.state.isSaving = false
                if case let .failure(error) = completion {
                    self?.state.error = error.localizedDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
