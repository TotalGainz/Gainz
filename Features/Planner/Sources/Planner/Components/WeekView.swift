//
//  WeekView.swift
//  PlannerFeature
//
//  Visual calendar strip for a seven-day training microcycle.
//  Shows each day as a tappable card, highlights “today,” and
//  supports drag-to-reorder for rapid mesocycle adjustments.
//
//  ─────────────  Design Rules  ─────────────
//  • Pure SwiftUI – no UIKit bridging.
//  • No persistence; external ViewModel publishes `DayPlan` array.
//  • Zero HRV / velocity / recovery metrics.
// 
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain          // WorkoutSession, ExercisePlan
import CoreUI          // Color/Font tokens

// MARK: - Public API

/// Displays one week of `DayPlan` cards with drag-and-drop reordering.
public struct WeekView<VM: WeekViewModeling>: View {
    // Dependency inversion for testability
    @ObservedObject private var viewModel: VM
    @Namespace private var dragNamespace

    public init(viewModel: VM) {
        self.viewModel = viewModel
    }

    public var body: some View {
        LazyVGrid(columns: Self.gridColumns, spacing: 8) {
            ForEach(viewModel.dayPlans) { day in
                DayCard(day: day,
                        isToday: Calendar.current.isDateInToday(day.date),
                        isDragging: viewModel.draggingId == day.id)
                    .matchedGeometryEffect(id: day.id, in: dragNamespace,
                                            isSource: viewModel.draggingId == day.id)
                    .onDrag {
                        // Set draggingId and provide an NSItemProvider (with UUID string) for the drag.
                        viewModel.draggingId = day.id
                        return NSItemProvider(object: day.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: WeekReorderDropDelegate(day: day, viewModel: viewModel))
            }
        }
        .animation(.spring(duration: 0.25), value: viewModel.dayPlans)  // animate reordering changes
        .padding(.horizontal, 8)
    }

    // MARK: Grid Layout
    
    private static let gridColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(minimum: 44), spacing: 8),
        count: 7
    )
}

// MARK: - DayCard

private struct DayCard: View {
    let day: DayPlan
    let isToday: Bool
    let isDragging: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(day.weekdaySymbol)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isToday ? Color.accent : .primary)
            Text("\(day.workoutCount)")
                .font(.title2.bold())
                .foregroundColor(.primary)
            if let reps = day.totalReps {
                Text("\(reps) reps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isToday ? Color.cardToday : Color.cardBase)
                .opacity(isDragging ? 0.3 : 1)  // make dragged item semi-transparent
        )
    }
}

// MARK: - Drop Delegate

private struct WeekReorderDropDelegate<VM: WeekViewModeling>: DropDelegate {
    let day: DayPlan
    let viewModel: VM

    func validateDrop(info: DropInfo) -> Bool {
        true  // allow drop on any day
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let sourceId = viewModel.draggingId else { return false }
        // Trigger viewModel to reorder from the dragged source day to this target day.
        viewModel.reorder(from: sourceId, to: day.id)
        viewModel.draggingId = nil
        return true
    }
}

// MARK: - Protocols & DTOs

/// Lightweight DTO for UI representing a single day and its summary.
public struct DayPlan: Identifiable, Hashable {
    public let id: UUID
    public let date: Date
    public let workoutCount: Int      // number of workouts (typically 0 or 1)
    public let totalReps: Int?        // total reps planned (optional for days with workouts)

    public init(id: UUID = .init(),
                date: Date,
                workoutCount: Int,
                totalReps: Int? = nil) {
        self.id = id
        self.date = date
        self.workoutCount = workoutCount
        self.totalReps = totalReps
    }

    var weekdaySymbol: String {
        // Abbreviated weekday name (e.g., Mon, Tue)
        date.formatted(.dateTime.weekday(.abbreviated))
    }
}

/// ViewModel contract – allows preview mocks & unit tests to drive WeekView.
public protocol WeekViewModeling: ObservableObject {
    var dayPlans: [DayPlan] { get }
    var draggingId: UUID? { get set }
    func reorder(from sourceId: UUID, to destinationId: UUID)
}

// MARK: - Previews

#if DEBUG
import FeatureSupport   // UnitConversion (for optional demo numbers)

private final class PreviewVM: WeekViewModeling {
    @Published var dayPlans: [DayPlan] = Calendar.current.generateWeek()
    @Published var draggingId: UUID?

    func reorder(from sourceId: UUID, to destinationId: UUID) {
        guard let fromIdx = dayPlans.firstIndex(where: { $0.id == sourceId }),
              let toIdx   = dayPlans.firstIndex(where: { $0.id == destinationId }) else { return }
        // Reorder array: move item from fromIdx to toIdx position.
        dayPlans.move(fromOffsets: IndexSet(integer: fromIdx), toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
    }
}

private extension Calendar {
    func generateWeek() -> [DayPlan] {
        let today = startOfDay(for: .init())
        return (0..<7).compactMap { offset in
            guard let date = date(byAdding: .day, value: offset, to: today) else { return nil }
            return DayPlan(date: date,
                           workoutCount: offset % 3 == 0 ? 1 : 0,
                           totalReps: offset % 3 == 0 ? 120 : nil)
        }
    }
}

struct WeekView_Previews: PreviewProvider {
    static var previews: some View {
        WeekView(viewModel: PreviewVM())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif
