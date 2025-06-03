//
//  PlannerViewModel.swift
//  PlannerFeature
//
//  Governs the Mesocycle Planner screen: loads the active mesocycle,
//  lets the athlete tap a calendar day, drag-drop exercises, and
//  persists every mutation.  Pure MVVM; zero SwiftUI imports.
//
//  ▸ Dependencies are injected as protocols to remain testable.
//  ▸ All async work is marshalled onto the main actor for UI safety.
//  ▸ Absolutely no HRV, recovery, nor velocity logic—hypertrophy only.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import Domain                // MesocyclePlan, ExercisePlan, PlanRepository
import CorePersistence       // ExerciseRepository for look-ups
import FeatureSupport        // UnitConversion, Date helpers

// MARK: - PlannerViewModel

@MainActor
public final class PlannerViewModel: ObservableObject {

    // MARK: State

    public struct State: Equatable {
        public var mesocycle: MesocyclePlan?
        public var selectedDate: Date = .init()
        public var workoutForSelectedDay: [ExercisePlan] = []
        public var isLoading: Bool = true
        public var errorMessage: String?
    }

    @Published public private(set) var state = State()

    // MARK: Dependencies

    private let planRepo: PlanRepository
    private let exerciseRepo: ExerciseRepository
    private let generator: PlanGenerator
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    public init(planRepo: PlanRepository,
                exerciseRepo: ExerciseRepository,
                generator: PlanGenerator) {
        self.planRepo      = planRepo
        self.exerciseRepo  = exerciseRepo
        self.generator     = generator
    }

    // MARK: Intents

    public enum Action {
        case onAppear
        case selectDate(Date)
        case addExercise(UUID)                        // exerciseId
        case removeExercise(UUID)                     // planId
        case reorderExercises(IndexSet, Int)          // fromOffsets → to
        case regenerateMesocycle
    }

    /// Dispatch user intent.
    public func send(_ action: Action) {
        switch action {
        case .onAppear:
            Task { await bootstrap() }

        case .selectDate(let date):
            state.selectedDate = date
            loadWorkout(for: date)

        case .addExercise(let exerciseId):
            Task { await addExerciseToSelectedDay(exerciseId) }

        case .removeExercise(let planId):
            Task { await removeExercise(planId) }

        case .reorderExercises(let from, let to):
            Task { await moveExercise(from: from, to: to) }

        case .regenerateMesocycle:
            Task { await regenerateCycle() }
        }
    }

    // MARK: Bootstrap

    private func bootstrap() async {
        state.isLoading = true
        do {
            if let active = try planRepo.fetchActiveMesocycle() {
                state.mesocycle = active
            } else {
                // Generate a default 5-week hypertrophy mesocycle
                state.mesocycle = try generator.generateMesocycle(weeks: 5)
                try planRepo.saveMesocycle(state.mesocycle!)
            }
            loadWorkout(for: state.selectedDate)
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }

    // MARK: Load helpers

    private func loadWorkout(for date: Date) {
        guard let mc = state.mesocycle else { return }
        if let day = mc.plan.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            state.workoutForSelectedDay = day.exercisePlans
        } else {
            state.workoutForSelectedDay = []
        }
    }

    // MARK: Mutations

    private func addExerciseToSelectedDay(_ exerciseId: UUID) async {
        guard var mc = state.mesocycle else { return }
        do {
            let exercise = try exerciseRepo.fetchExercise(id: exerciseId)
            var day = try mc.ensureDay(date: state.selectedDate)
            let plan = ExercisePlan(exerciseId: exercise.id,
                                    sets: 3,
                                    repRange: .init(min: 8, max: 12),
                                    mechanicalPattern: exercise.mechanicalPattern,
                                    equipment: exercise.equipment)
            day.exercisePlans.append(plan)
            try planRepo.saveMesocycle(mc)
            state.mesocycle = mc
            loadWorkout(for: state.selectedDate)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func removeExercise(_ planId: UUID) async {
        guard var mc = state.mesocycle else { return }
        do {
            try mc.removeExercise(planId: planId, on: state.selectedDate)
            try planRepo.saveMesocycle(mc)
            state.mesocycle = mc
            loadWorkout(for: state.selectedDate)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func moveExercise(from offsets: IndexSet, to destination: Int) async {
        guard var mc = state.mesocycle else { return }
        do {
            try mc.moveExercise(on: state.selectedDate, from: offsets, to: destination)
            try planRepo.saveMesocycle(mc)
            state.mesocycle = mc
            loadWorkout(for: state.selectedDate)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func regenerateCycle() async {
        do {
            state.isLoading = true
            state.mesocycle = try generator.generateMesocycle(weeks: 5)
            if let mc = state.mesocycle {
                try planRepo.saveMesocycle(mc)
            }
            loadWorkout(for: state.selectedDate)
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }
}
