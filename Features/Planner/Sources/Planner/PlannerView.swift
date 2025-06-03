//
//  PlannerView.swift
//  PlannerFeature
//
//  SwiftUI façade that surfaces the drag-and-drop mesocycle calendar.
//  ────────────────────────────────────────────────────────────────
//  • Consumes `PlannerViewModel.State` via `@StateObject` binding.
//  • Drag targets and drop delegates let the athlete rearrange
//    whole workouts or single ExercisePlans across days.
//  • Animates with implicit spring; complies with Dynamic Type.
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

    // Inject via init for testability
    public init(viewModel: PlannerViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body
    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Planner")
                .toolbar { refreshButton }
                .task { vm.send(.onAppear) }
        }
    }

    // MARK: Private Sections

    @ViewBuilder
    private var content: some View {
        if vm.state.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            calendarGrid
        }
    }

    /// 7-column grid, one row per week of the current mesocycle.
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7),
                  spacing: 12) {
            ForEach(vm.state.days) { day in
                DayCell(day: day)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8),
                               value: vm.state.days)
                    .onDrag { vm.dragItem(for: day) }
                    .onDrop(of: PlannerViewModel.dragUTType,
                            delegate: vm.dropDelegate(for: day))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if !vm.state.isLoading {
                Button {
                    vm.send(.refreshTapped)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let day: PlannerViewModel.DayState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day.dateLabel)
                .font(.caption2)
                .foregroundStyle(Color.secondary)

            if let workout = day.workout {
                Text(workout.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accent)
                            .shadow(radius: 1, y: 1)
                    )
            } else {
                Spacer(minLength: 24)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.separator, lineWidth: 1)
        )
    }
}
