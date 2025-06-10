//
//  PlannerViewModel.swift
//  PlannerFeature
//
//  Governs the Mesocycle Planner screen: loads the active mesocycle,
//  lets the athlete tap a calendar day, drag-drop exercises, and
//  persists every mutation. Pure MVVM (no SwiftUI imports).
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
import UniformTypeIdentifiers

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
        public var days: [DayState] = []  // full calendar days (with or without workouts)
    }

    @Published public private(set) var state = State()

    // MARK: Nested Types

    /// UI representation of a single day in the planner grid.
    public struct DayState: Identifiable, Equatable {
        public let id: Date              // use date as unique identifier
        public let date: Date
        public let workout: WorkoutPlan? // the scheduled workout on this day (if any)

        /// Displayable day-of-month string (no leading zeros).
        var dateLabel: String {
            date.formatted(.dateTime.day())  // e.g., "5" for 5th of the month
        }

        /// Accessibility summary for VoiceOver.
        var accessibilityLabel: String {
            if let workout = workout {
                return "\(date.formatted(.dateTime.month(.abbreviated).day())), \(workout.title), \(workout.exercises.count) exercises"
            } else {
                return "\(date.formatted(.dateTime.month(.abbreviated).day())), Rest Day"
            }
        }

        public static func ==(lhs: DayState, rhs: DayState) -> Bool {
            // Days are equal if date is same and workout basic info is unchanged.
            if lhs.date != rhs.date { return false }
            let lw = lhs.workout, rw = rhs.workout
            if lw == nil && rw == nil {
                return true
            } else if let lw = lw, let rw = rw {
                return lw.title == rw.title &&
                       lw.totalSets == rw.totalSets &&
                       lw.exercises.count == rw.exercises.count
            } else {
                return false
            }
        }
    }

    // MARK: Dependencies

    private let planRepo: PlanRepository
    private let exerciseRepo: ExerciseRepository
    private let generator: PlanGenerator
    private var cancellables = Set<AnyCancellable>()

    // MARK: Drag & Drop Types

    /// Allowed UTIs for drag-and-drop: plain text (for internal workout moves) and JSON (for external exercise adds).
    static let dragUTTypes: [UTType] = [ .text, .json ]

    // Temporary state for a dragging workout (source day).
    private var draggingSourceDate: Date?

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
        case addExercise(UUID)                        // add exercise to currently selected day (exerciseId)
        case removeExercise(UUID)                     // remove an ExercisePlan (planId)
        case reorderExercises(IndexSet, Int)          // reorder exercises within the same day
        case regenerateMesocycle
    }

    /// Handle user intents sent from the view layer.
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

    /// Load active mesocycle or generate a new one if none exists, then prepare UI state.
    private func bootstrap() async {
        state.isLoading = true
        do {
            if let active = try planRepo.fetchActiveMesocycle() {
                state.mesocycle = active
            } else {
                // Generate a default 5-week hypertrophy mesocycle if none is active.
                state.mesocycle = try generator.generateMesocycle(weeks: 5)
                try planRepo.saveMesocycle(state.mesocycle!)
            }
            // Build full calendar days list for UI and load today's workout (if any).
            refreshDays()
            loadWorkout(for: state.selectedDate)
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }

    // MARK: Load Helpers

    /// Load the workout (all ExercisePlans) for a given date into state.workoutForSelectedDay.
    private func loadWorkout(for date: Date) {
        guard let mc = state.mesocycle else { return }
        if let dayPlan = mc.plan.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            state.workoutForSelectedDay = dayPlan.exercisePlans
        } else {
            state.workoutForSelectedDay = []
        }
    }

    // MARK: Mutations (Add/Remove/Reorder Exercises)

    /// Add a new exercise (by id) to the currently selected day.
    private func addExerciseToSelectedDay(_ exerciseId: UUID) async {
        guard var mc = state.mesocycle else { return }
        do {
            let exercise = try exerciseRepo.fetchExercise(id: exerciseId)
            var dayPlan = try mc.ensureDay(date: state.selectedDate)  // ensure a WorkoutPlan exists for selectedDate
            // Create a new ExercisePlan with default volume parameters.
            let newPlan = ExercisePlan(exerciseId: exercise.id,
                                       sets: 3,
                                       repRange: .init(min: 8, max: 12),
                                       mechanicalPattern: exercise.mechanicalPattern,
                                       equipment: exercise.equipment)
            dayPlan.exercisePlans.append(newPlan)
            try planRepo.saveMesocycle(mc)
            state.mesocycle = mc
            refreshDays()
            // If we added to the day currently in detail view, update its list.
            loadWorkout(for: state.selectedDate)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    /// Remove an exercise plan (identified by planId) from the selected day's workout.
    private func removeExercise(_ planId: UUID) async {
        guard var mc = state.mesocycle else { return }
        do {
            // Remove the ExercisePlan from the mesocycle on the selected date.
            try mc.removeExercise(planId: planId, on: state.selectedDate)
            try planRepo.saveMesocycle(mc)
            state.mesocycle = mc
            refreshDays()
            loadWorkout(for: state.selectedDate)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    /// Move (reorder) an exercise within the current day's workout (drag-and-drop within the same list).
    private func moveExercise(from offsets: IndexSet, to destination: Int) async {
        guard var mc = state.mesocycle else { return }
        do {
            try mc.moveExercise(on: state.selectedDate, from: offsets, to: destination)
            try planRepo.saveMesocycle(mc)
            state.mesocycle = mc
            // The day content order changed, refresh the UI.
            refreshDays()
            loadWorkout(for: state.selectedDate)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    // MARK: Mesocycle Regeneration

    /// Completely regenerate a new mesocycle plan (e.g., a fresh 5-week cycle) and save it.
    private func regenerateCycle() async {
        do {
            state.isLoading = true
            state.mesocycle = try generator.generateMesocycle(weeks: 5)
            if let mc = state.mesocycle {
                try planRepo.saveMesocycle(mc)
            }
            refreshDays()
            loadWorkout(for: state.selectedDate)
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoading = false
        }
    }

    // MARK: Calendar Grid Data

    /// Recompute the full list of DayState objects covering all weeks in the mesocycle.
    private func refreshDays() {
        guard let mc = state.mesocycle else {
            state.days = []
            return
        }
        // Determine the full date range (start and end) of the mesocycle in weeks (Monday–Sunday).
        let calendar = Calendar.current
        guard let firstWorkoutDate = mc.plan.map(\.date).min(),
              let lastWorkoutDate = mc.plan.map(\.date).max() else {
            state.days = []
            return
        }
        // Align start to the Monday of the first workout's week.
        var startOfPeriod = calendar.startOfDay(for: firstWorkoutDate)
        let weekdayIndex = calendar.component(.weekday, from: startOfPeriod)
        let offsetToMonday = (weekdayIndex - 2 + 7) % 7  // how many days to go backwards to reach Monday
        startOfPeriod = calendar.date(byAdding: .day, value: -offsetToMonday, to: startOfPeriod) ?? startOfPeriod
        // Align end to the Sunday of the last workout's week.
        var endOfPeriod = calendar.startOfDay(for: lastWorkoutDate)
        let weekdayIndexEnd = calendar.component(.weekday, from: endOfPeriod)
        let offsetToSunday = (7 - weekdayIndexEnd + 1) % 7  // how many days to add to reach Sunday
        endOfPeriod = calendar.date(byAdding: .day, value: offsetToSunday, to: endOfPeriod) ?? endOfPeriod

        // Generate a DayState for each date from startOfPeriod through endOfPeriod (inclusive).
        var days: [DayState] = []
        var currentDate = startOfPeriod
        while currentDate <= endOfPeriod {
            // Find if there's a planned workout on this date.
            let maybeWorkout = mc.plan.first(where: { calendar.isDate($0.date, inSameDayAs: currentDate) })
            days.append(DayState(id: currentDate, date: currentDate, workout: maybeWorkout))
            // Move to next day.
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        state.days = days
    }

    // MARK: Drag & Drop Support

    /// Create an NSItemProvider for dragging a workout from a given day (returns nil if no workout on that day).
    public func dragItem(for day: DayState) -> NSItemProvider? {
        guard day.workout != nil else {
            return nil  // only allow drag if there's a workout to move
        }
        // Store the source date of the dragging workout to use in drop handling.
        draggingSourceDate = day.date
        // Provide a textual representation (ISO date string) for the drag (not strictly used, but required for NSItemProvider).
        let dateString = ISO8601DateFormatter().string(from: day.date)
        return NSItemProvider(object: dateString as NSString)
    }

    /// Return a DropDelegate to handle a drop on the specified target day (either moving a workout or adding an exercise).
    public func dropDelegate(for day: DayState) -> DropDelegate {
        PlannerDropDelegate(targetDate: day.date, viewModel: self)
    }

    /// Internal drop delegate for handling drop events on a day cell.
    private struct PlannerDropDelegate: DropDelegate {
        let targetDate: Date
        unowned let viewModel: PlannerViewModel

        func validateDrop(info: DropInfo) -> Bool {
            // Accept any drop that matches the declared UTTypes (workout move or exercise add).
            return info.hasItemsConforming(to: PlannerViewModel.dragUTTypes)
        }

        func performDrop(info: DropInfo) -> Bool {
            // Determine if this drop corresponds to an internal workout move or an external exercise addition.
            let hasTextItem = info.itemProviders(for: [.text]).first != nil
            let hasJsonItem = info.itemProviders(for: [.json]).first != nil

            if hasTextItem, let sourceDate = viewModel.draggingSourceDate {
                // Handle internal workout move (re-schedule workout from sourceDate to targetDate).
                viewModel.moveWorkout(from: sourceDate, to: targetDate)
                // Clear the dragging source since drop completed.
                viewModel.draggingSourceDate = nil
                return true
            }
            if hasJsonItem, let provider = info.itemProviders(for: [.json]).first {
                // Handle external exercise drop: load exercise data asynchronously.
                provider.loadDataRepresentation(forTypeIdentifier: UTType.json.identifier) { data, _ in
                    guard let data = data else { return }
                    if let exercise = try? JSONDecoder().decode(Exercise.self, from: data) {
                        // Add the dropped exercise to the workout on the target date.
                        Task { await viewModel.addExercise(fromDrop: exercise, to: targetDate) }
                    }
                }
                // If we got a JSON provider, we accept the drop and will add the exercise when data loads.
                viewModel.draggingSourceDate = nil
                return true
            }
            // If we didn't handle the drop, return false to indicate failure.
            return false
        }

        func dropExited(info: DropInfo) {
            // If a drag exited without dropping on this target, clear any dragging flag if appropriate.
            // (We rely on performDrop to clear draggingSourceDate upon completion, so nothing needed here.)
        }
    }

    // MARK: Private Drag/Drop Handlers

    /// Move a workout from one date to another within the mesocycle (swapping if necessary).
    private func moveWorkout(from sourceDate: Date, to destinationDate: Date) {
        guard var mc = state.mesocycle else { return }
        do {
            // Find indices for source and destination workout plans in the mesocycle plan array.
            let planArray = mc.plan
            guard let sourceIndex = planArray.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: sourceDate) }) else {
                return
            }
            // Check if there's an existing workout on the destination date.
            if let destIndex = planArray.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: destinationDate) }) {
                // Swap the dates of the two workouts.
                mc.plan[sourceIndex].date = destinationDate
                mc.plan[destIndex].date = sourceDate
            } else {
                // Move the source workout to the new date if destination has no workout.
                mc.plan[sourceIndex].date = destinationDate
            }
            try planRepo.saveMesocycle(mc)
            state.mesocycle = mc
            // Recompute days and update detail if it was one of the affected days.
            refreshDays()
            if Calendar.current.isDate(sourceDate, inSameDayAs: state.selectedDate) ||
               Calendar.current.isDate(destinationDate, inSameDayAs: state.selectedDate) {
                loadWorkout(for: state.selectedDate)
            }
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    /// Add an exercise (from drag-and-drop) to a specific date's workout.
    private func addExercise(fromDrop exercise: Exercise, to date: Date) async {
        guard var mc = state.mesocycle else { return }
        do {
            // Ensure a WorkoutPlan exists on the drop target date (create if needed).
            var dayPlan = try mc.ensureDay(date: date)
            // Create a new ExercisePlan for the dropped exercise with default volume settings.
            let newPlan = ExercisePlan(exerciseId: exercise.id,
                                       sets: 3,
                                       repRange: .init(min: 8, max: 12),
                                       mechanicalPattern: exercise.mechanicalPattern,
                                       equipment: exercise.equipment)
            dayPlan.exercisePlans.append(newPlan)
            try planRepo.saveMesocycle(mc)
            state.mesocycle = mc
            refreshDays()
            // If the drop was on the currently selected day in detail view, update its exercises list.
            if Calendar.current.isDate(date, inSameDayAs: state.selectedDate) {
                loadWorkout(for: state.selectedDate)
            }
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }
}
