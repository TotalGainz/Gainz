// WorkoutViewModel.swift

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
        public var activeSetIndex: Int? = nil      // nil indicates no set in progress
        public var isSaving: Bool = false
        public var error: String?
    }

    public enum Action {
        case addExerciseTapped
        case exercisePicked(Exercise)
        case exerciseIntent(UUID, ExerciseLogIntent)
        case deleteExercise(at: IndexSet)
        case setEdited(UUID, SetRecord)
        case finishTapped
        case saveAndExit
        case dismissSummary
        case dismissError
        // Existing set-in-progress actions (used internally or future features)
        case startSet
        case finishSet(weight: Double, reps: Int, rpe: RPE?)
        case nextExercise
        case previousExercise
    }

    // MARK: Dependencies

    private let repo: WorkoutRepository
    private let time: TimeProvider
    private var cancellables = Set<AnyCancellable>()

    // MARK: Publishers & State

    @Published public private(set) var state: State
    @Published public var currentSheet: SheetDestination?      // current active sheet (if any)
    @Published public var alertInfo: AlertInfo?                // info for any error alert
    @Published public var showRestOverlay: Bool = false        // controls the rest timer overlay

    // This subject emits an exercise ID when a new exercise is added, so the view can auto-scroll
    private let autoScrollSubject = PassthroughSubject<UUID, Never>()
    public var autoScrollPublisher: AnyPublisher<UUID, Never> {
        autoScrollSubject.eraseToAnyPublisher()
    }

    // MARK: Sheet Destination Enum

    public enum SheetDestination: Identifiable, Hashable {
        case exercisePicker
        case setEditor(logID: UUID, set: SetRecord)
        case finishSummary(summary: WorkoutSession)

        public var id: String {
            switch self {
            case .exercisePicker:
                return "exercisePicker"
            case .setEditor(let logID, _):
                return "setEditor-\(logID)"
            case .finishSummary(let summary):
                // Use the session ID (or a static identifier if not available) as unique id
                return "finishSummary-\(summary.id.uuidString)"
            }
        }
    }

    // MARK: Alert Info Struct

    public struct AlertInfo: Identifiable {
        public let id = UUID()
        public let title: String
        public let message: String
        public let action: (() -> Void)?
    }

    // MARK: Init

    public init(session: WorkoutSession,
                repo: WorkoutRepository,
                time: TimeProvider) {
        self.state = State(session: session)
        self.repo = repo
        self.time = time
    }

    // MARK: Intent Handler

    /// Entry point for all user intents/actions from the WorkoutView.
    @MainActor
    public func send(_ action: Action) {
        switch action {
        case .addExerciseTapped:
            // User tapped "Add Exercise" in the toolbar – present exercise picker sheet.
            currentSheet = .exercisePicker

        case .exercisePicked(let exercise):
            // User selected a new exercise from the picker – create a new ExerciseLog and append to session.
            let newLog = ExerciseLog(id: UUID(),
                                     exerciseId: exercise.id,
                                     exerciseName: exercise.name,
                                     sets: [])
            state.session.exerciseLogs.append(newLog)
            state.activeExerciseIndex = state.session.exerciseLogs.count - 1
            // Trigger scroll to the new exercise entry
            autoScrollSubject.send(newLog.id)

        case .exerciseIntent(let logID, let intent):
            // Handle intents at the exercise level (e.g., add set, edit set, context menu).
            guard let exerciseIndex = state.session.exerciseLogs.firstIndex(where: { $0.id == logID }) else {
                break  // if exercise not found, ignore
            }
            state.activeExerciseIndex = exerciseIndex
            switch intent {
            case .contextMenuTapped:
                // Future enhancement: show exercise-level options (e.g., skip or details).
                break
            case .editSet(let set):
                // Open set editor sheet for the selected set.
                currentSheet = .setEditor(logID: logID, set: set)
            case .addSetTapped:
                // Start a new set for this exercise – open the set editor with an empty set.
                let newSet = SetRecord(id: UUID(),
                                       timestamp: time.now,
                                       weight: 0,
                                       reps: 0,
                                       rpe: nil)
                currentSheet = .setEditor(logID: logID, set: newSet)
            }

        case .deleteExercise(let indexSet):
            // Remove exercise(s) from the session.
            for index in indexSet.sorted(by: >) {
                state.session.exerciseLogs.remove(at: index)
                // Adjust activeExerciseIndex if necessary
                if index < state.activeExerciseIndex {
                    state.activeExerciseIndex -= 1
                } else if index == state.activeExerciseIndex {
                    // If removing the currently active exercise, move focus to previous exercise if possible
                    state.activeExerciseIndex = max(0, state.activeExerciseIndex - 1)
                }
            }
            // Clear any in-progress set if an exercise was removed
            state.activeSetIndex = nil

        case .setEdited(let logID, let updatedSet):
            // User finished editing a set (either added new or modified existing).
            if let exerciseIndex = state.session.exerciseLogs.firstIndex(where: { $0.id == logID }) {
                var exerciseLog = state.session.exerciseLogs[exerciseIndex]
                if let existingIndex = exerciseLog.sets.firstIndex(where: { $0.id == updatedSet.id }) {
                    // Update existing set
                    exerciseLog.sets[existingIndex] = updatedSet
                } else {
                    // Append new set (use current time as final timestamp for logging)
                    var newSet = updatedSet
                    newSet.timestamp = time.now
                    exerciseLog.sets.insert(newSet, at: exerciseLog.sets.count)
                    // After logging a new set, show the rest timer overlay
                    showRestOverlay = true
                }
                state.session.exerciseLogs[exerciseIndex] = exerciseLog
            }
            // Dismiss the set editor sheet
            currentSheet = nil
            // Clear any "active set" tracking since editing is complete
            state.activeSetIndex = nil

        case .finishTapped:
            // User tapped finish workout – save session and present summary on success.
            persistSession(towardsSummary: true)

        case .saveAndExit:
            // Save session without presenting summary (for programmatic use).
            persistSession(towardsSummary: false)

        case .dismissSummary:
            // User closed the summary view – dismiss it.
            currentSheet = nil
            // Return to planner or root could be handled by a coordinator via repository event if needed.

        case .dismissError:
            // Acknowledge an error alert – clear the error state and alert info.
            state.error = nil
            alertInfo = nil

        // Existing base actions for set flow (used internally or for potential extended logic)
        case .startSet:
            // Mark the start of a new set for the current exercise (if none in progress).
            guard state.activeSetIndex == nil else { break }
            state.activeSetIndex = currentExerciseLog.sets.count

        case .finishSet(let weight, let reps, let rpe):
            // Complete a set in progress by appending it to the current exercise log.
            guard let setIndex = state.activeSetIndex else { break }
            appendSet(weight: weight, reps: reps, rpe: rpe, at: setIndex)
            state.activeSetIndex = nil
            // After finishing a set, trigger rest overlay
            showRestOverlay = true

        case .nextExercise:
            // Move focus to next exercise in the session (if exists).
            state.activeExerciseIndex = min(state.activeExerciseIndex + 1,
                                            state.session.exerciseLogs.count - 1)
            state.activeSetIndex = nil

        case .previousExercise:
            // Move focus to previous exercise in the session.
            state.activeExerciseIndex = max(state.activeExerciseIndex - 1, 0)
            state.activeSetIndex = nil
        }
    }

    // MARK: Private Helpers

    /// Convenient accessor for the currently active exercise log.
    private var currentExerciseLog: ExerciseLog {
        state.session.exerciseLogs[state.activeExerciseIndex]
    }

    /// Append a new set record to the current exercise log at the specified index.
    private func appendSet(weight: Double, reps: Int, rpe: RPE?, at index: Int) {
        var exerciseLog = currentExerciseLog
        let newSet = SetRecord(id: UUID(),
                               timestamp: time.now,
                               weight: weight,
                               reps: reps,
                               rpe: rpe)
        exerciseLog.sets.insert(newSet, at: index)
        // Replace the modified exercise log in session
        state.session.exerciseLogs[state.activeExerciseIndex] = exerciseLog
    }

    /// Persist the current workout session using the repository. Optionally presents summary on success.
    private func persistSession(towardsSummary: Bool) {
        state.isSaving = true
        repo.saveWorkoutSession(state.session)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                // End of saving process
                guard let self = self else { return }
                self.state.isSaving = false
                if case let .failure(error) = completion {
                    // Saving failed – store error and prepare alert
                    self.state.error = error.localizedDescription
                    self.alertInfo = AlertInfo(title: "Could Not Save",
                                               message: error.localizedDescription,
                                               action: { [weak self] in self?.send(.dismissError) })
                }
            } receiveValue: { [weak self] savedSession in
                // Successfully saved session
                guard let self = self else { return }
                if towardsSummary {
                    // Present the summary sheet with the saved session data
                    self.currentSheet = .finishSummary(summary: savedSession ?? self.state.session)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Computed Properties for UI

public extension WorkoutViewModel.State {
    /// Title of the workout session for display (e.g., workout plan name or generic label).
    var sessionTitle: String {
        // Use associated workout plan name if available, otherwise a default title.
        if let planName = session.planName ?? session.title {
            return planName
        }
        return "Workout Session"
    }

    /// Formatted date string for the session (e.g., "Mon 27 May").
    var dateString: String {
        let date = session.date ?? Date()
        return WorkoutViewModel.State.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "E d MMM"
        return df
    }()
}
