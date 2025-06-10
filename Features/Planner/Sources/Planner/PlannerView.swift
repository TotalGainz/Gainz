//
//  PlannerView.swift
//  PlannerFeature
//
//  SwiftUI façade that surfaces the drag-and-drop mesocycle calendar.
//  ────────────────────────────────────────────────────────────────
//  • Consumes `PlannerViewModel.State` via `@StateObject` binding.
//  • Drag targets and drop delegates let the athlete rearrange
//    whole workouts or add exercises across days with drag-and-drop.
//  • Animates with implicit springs; complies with Dynamic Type.
//  • Zero HRV, recovery, or velocity metrics shown—hypertrophy only.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain              // MesocyclePlan, WorkoutSession
import CoreUI              // Color tokens, typography
import FeatureSupport      // UnitConversion

// MARK: - PlannerView

public struct PlannerView: View {
    // MARK: Dependencies
    @StateObject private var vm: PlannerViewModel

    // Inject ViewModel via initializer for testability and dependency injection
    public init(viewModel: PlannerViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body
    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Planner")
                .toolbar { refreshButton }
                .task { vm.send(.onAppear) }  // bootstrap when the view appears
        }
    }

    // MARK: Private Sections

    @ViewBuilder
    private var content: some View {
        if vm.state.isLoading {
            // Show a full-screen progress indicator while loading/generating mesocycle.
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            calendarGrid
        }
    }

    /// A multi-week calendar grid with 7 columns (Mon–Sun) and one row per week of the current mesocycle.
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7),
                  spacing: 12) {
            ForEach(vm.state.days) { day in
                DayCell(day: day)
                    // Animate any changes to the days array with a spring for smooth reordering.
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.state.days)
                    // Enable dragging an entire workout plan card to another day (only if a workout exists for that day).
                    .onDrag { vm.dragItem(for: day) }
                    // Enable dropping either a dragged workout (internal) or a dragged exercise (external) onto this day.
                    .onDrop(of: PlannerViewModel.dragUTTypes, delegate: vm.dropDelegate(for: day))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// Toolbar button to regenerate the mesocycle (e.g., shuffle or refresh the plan).
    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if !vm.state.isLoading {
                Button {
                    vm.send(.regenerateMesocycle)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Regenerate Plan")
            }
        }
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let day: PlannerViewModel.DayState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Day number label (e.g., "1", "2", ...).
            Text(day.dateLabel)
                .font(.caption2)
                .foregroundStyle(Color.secondary)
            if let workout = day.workout {
                // If a workout is planned on this day, show its title in a pill.
                Text(workout.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accent)    // highlight color for a planned workout
                            .shadow(radius: 1, y: 1)
                    )
            } else {
                // Empty day spacer to keep cell height consistent.
                Spacer(minLength: 24)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(day.accessibilityLabel)
    }
}
