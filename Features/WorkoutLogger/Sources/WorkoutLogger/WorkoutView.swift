//
//  WorkoutView.swift
//  Feature – WorkoutLogger
//
//  High-fidelity SwiftUI screen for live set logging.
//  ─────────────────────────────────────────────────────────────
//  • Dark-mode native, uses DesignSystem tokens (CoreUI).
//  • No HRV, recovery, or velocity badges.
//  • Accessible, Dynamic-Type-aware, VoiceOver-labeled.
//  • Stateless UI → drives through WorkoutViewModel intent enum.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Combine
import Domain
import CoreUI        // Color & typography tokens

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
                Color.coreBackground.ignoresSafeArea()

                ScrollViewReader { proxy in
                    List {
                        Section(header: sessionHeader) {
                            ForEach(viewModel.state.exerciseLogs) { log in
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
                    .onReceive(viewModel.autoScrollPublisher) { id in
                        withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }

                // Floating CTA
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
                                        colors: [.phoenixStart, .phoenixEnd],
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
            .sheet(item: $viewModel.bindingForSheet) { sheet in
                switch sheet {
                case .exercisePicker:
                    ExercisePickerView { exercise in
                        viewModel.send(.exercisePicked(exercise))
                    }
                case .setEditor(let logID, let set):
                    SetEditorView(logID: logID, set: set) { updated in
                        viewModel.send(.setEdited(logID, updated))
                    }
                case .finishSummary(let summary):
                    WorkoutSummaryView(summary: summary) {
                        viewModel.send(.dismissSummary)
                    }
                }
            }
            .alert(item: $viewModel.bindingForAlert) { alert in
                Alert(title: Text(alert.title),
                      message: Text(alert.message),
                      dismissButton: .default(Text("OK"), action: alert.action))
            }
            .task { await viewModel.start() }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Header View
    @ViewBuilder
    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.state.dateString)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Current Session")
                .font(.title3.bold())
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
            HStack {
                Text(log.exerciseName)
                    .font(.headline)
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

            ForEach(log.sets) { set in
                SetRow(set: set) {
                    action(.editSet(set))
                }
            }

            Button(role: .none) {
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

// MARK: - Set Row

private struct SetRow: View {
    let set: SetRecord
    let edit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(set.index)")
                .monospacedDigit()
                .frame(width: 28)
                .foregroundColor(.secondary)

            Text("\(Int(set.weight)) kg")
                .font(.body)

            Text("× \(set.reps)")
                .font(.body)

            if let rpe = set.rpe {
                Text(rpe.description)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.phoenixStart.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            Button {
                edit()
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit set \(set.index)")
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: edit)
    }
}

// MARK: - Preview

#if DEBUG
struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutView(viewModel: WorkoutViewModel.preview)
            .environment(\.colorScheme, .dark)
            .previewLayout(.device)
    }
}
#endif
