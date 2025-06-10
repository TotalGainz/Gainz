// WorkoutView.swift

import SwiftUI
import Combine
import Domain
import CoreUI      // Design tokens (ColorPalette, Typography) if needed
import DesignSystem // If needed for design tokens in new structure

// Define intents for exercise-level interactions within the workout view.
enum ExerciseLogIntent {
    case contextMenuTapped
    case editSet(SetRecord)
    case addSetTapped
}

// MARK: - View

public struct WorkoutView: View {
    // MARK: State
    @StateObject private var viewModel: WorkoutViewModel

    // MARK: Init
    public init(viewModel: @autoclosure @escaping () -> WorkoutViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    // MARK: Body
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.coreBackground.ignoresSafeArea()

                ScrollViewReader { proxy in
                    List {
                        Section(header: sessionHeader) {
                            ForEach(viewModel.state.session.exerciseLogs) { log in
                                ExerciseLogCell(log: log) { intent in
                                    viewModel.send(.exerciseIntent(log.id, intent))
                                }
                                .listRowSeparator(.hidden)
                                .id(log.id)
                            }
                            .onDelete { indexSet in
                                viewModel.send(.deleteExercise(at: indexSet))
                            }
                        }
                    }
                    .listStyle(.plain)
                    // Scroll to newly added exercise when signaled by the ViewModel
                    .onReceive(viewModel.autoScrollPublisher) { newLogId in
                        withAnimation { proxy.scrollTo(newLogId, anchor: .bottom) }
                    }
                }

                // Floating action button (finish workout)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { viewModel.send(.finishTapped) }) {
                            Image(systemName: "checkmark")
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.phoenixStart, Color.phoenixEnd],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(radius: 8)
                        }
                        .accessibilityLabel("Finish Workout")
                        .padding(.trailing, 20)
                        .padding(.bottom, 32)
                    }
                }

                // Rest timer overlay appears after logging a set
                if viewModel.showRestOverlay {
                    RestTimerOverlay(duration: 90,
                                     isPresented: $viewModel.showRestOverlay) {
                        // On rest complete – ready for next set (no additional action needed)
                    } onSkip: {
                        // If user skips rest – just close the overlay (handled by binding)
                    }
                }
            }
            .navigationTitle(viewModel.state.sessionTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.send(.addExerciseTapped) }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Exercise")
                }
            }
            .sheet(item: $viewModel.currentSheet) { sheet in
                // Navigate to appropriate sheet content based on destination
                switch sheet {
                case .exercisePicker:
                    // Launch exercise selection UI for adding a new exercise
                    ExercisePickerView { exercise in
                        viewModel.send(.exercisePicked(exercise))
                    }
                case .setEditor(let logID, let set):
                    // Launch set editor for the given exercise log and set
                    SetEditorView(logID: logID, set: set) { updatedSet in
                        viewModel.send(.setEdited(logID, updatedSet))
                    }
                case .finishSummary(let summary):
                    // Show workout summary after finishing the session
                    WorkoutSummaryView(summary: summary) {
                        viewModel.send(.dismissSummary)
                    }
                }
            }
            .alert(item: $viewModel.alertInfo) { alert in
                Alert(title: Text(alert.title),
                      message: Text(alert.message),
                      dismissButton: .default(Text("OK"), action: alert.action))
            }
            .task {
                // Perform any startup logic when view appears
                await viewModel.start()   // (If start performs async setup such as loading session by ID)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Header View (session title and date)
    @ViewBuilder
    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.state.dateString)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Current Session")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Exercise Cell

private struct ExerciseLogCell: View {
    let log: ExerciseLog
    let action: (ExerciseLogIntent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise header with name and options button
            HStack {
                Text(log.exerciseName)
                    .font(.headline)   // dynamic text style
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    action(.contextMenuTapped)
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Exercise Options")
            }

            // List of sets for this exercise
            ForEach(log.sets) { set in
                SetRow(set: set) {
                    action(.editSet(set))
                }
            }

            // Add set button for this exercise
            Button {
                action(.addSetTapped)
            } label: {
                Label("Add Set", systemImage: "plus.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Add set to \(log.exerciseName)")
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Set Row (displaying a logged set with edit option)

private struct SetRow: View {
    let set: SetRecord
    let edit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Set index badge
            Text("#\(set.index)")
                .monospacedDigit()
                .frame(width: 28)
                .foregroundColor(.secondary)

            // Weight and reps
            Text("\(Int(set.weight)) kg")
                .font(.body)
            Text("× \(set.reps)")
                .font(.body)

            // Optional RPE chip
            if let rpeValue = set.rpe {
                Text(rpeValue.description)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.phoenixStart.opacity(0.15))
                    .clipShape(Capsule())
                    .accessibilityLabel("R P E \(rpeValue)")
            }

            Spacer()

            // Edit set button (pencil icon)
            Button(action: edit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit set \(set.index)")
        }
        .contentShape(Rectangle())  // Make entire row tappable (for edit via onTap)
        .onTapGesture(perform: edit)
    }
}
