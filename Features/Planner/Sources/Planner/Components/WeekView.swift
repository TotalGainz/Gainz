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
        LazyVGrid(columns: Self.gridColumns,
                  spacing: 8) {
            ForEach(viewModel.dayPlans) { day in
                DayCard(day: day,
                        isToday: Calendar.current.isDateInToday(day.date),
                        isDragging: viewModel.draggingId == day.id)
                    .matchedGeometryEffect(id: day.id,
                                           in: dragNamespace,
                                           isSource: viewModel.draggingId == day.id)
                    .onDrag {
                        viewModel.draggingId = day.id
                        return NSItemProvider(object: day.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate:
                                WeekReorderDropDelegate(day: day, viewModel: viewModel))
            }
        }
        .animation(.spring(duration: 0.25), value: viewModel.dayPlans)
        .padding(.horizontal, 8)
    }

    // MARK: Grid

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
                .foregroundColor(isToday ? CoreUI.Colors.accent : .primary)

            Text("\(day.workoutCount)")
                .font(.title2.bold())
                .foregroundColor(.primary)

            if let vol = day.totalReps {
                Text("\(vol) reps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isToday ? CoreUI.Colors.cardToday
                               : CoreUI.Colors.cardBase)
                .opacity(isDragging ? 0.3 : 1)
        )
    }
}

// MARK: - Drop Delegate

private struct WeekReorderDropDelegate<VM: WeekViewModeling>: DropDelegate {
    let day: DayPlan
    let viewModel: VM

    func validateDrop(info: DropInfo) -> Bool { true }

    func performDrop(info: DropInfo) -> Bool {
        guard let sourceId = viewModel.draggingId else { return false }
        viewModel.reorder(from: sourceId, to: day.id)
        viewModel.draggingId = nil
        return true
    }
}

// MARK: - Protocols & DTOs

/// Lightweight DTO for UI.
public struct DayPlan: Identifiable, Hashable {
    public let id: UUID
    public let date: Date
    public let workoutCount: Int
    public let totalReps: Int?

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
        date.formatted(.dateTime.weekday(.abbreviated))
    }
}

/// ViewModel contract – allows preview mocks & unit tests.
public protocol WeekViewModeling: ObservableObject {
    var dayPlans: [DayPlan] { get }
    var draggingId: UUID? { get set }
    func reorder(from sourceId: UUID, to destinationId: UUID)
}

// MARK: - Previews

#if DEBUG
import FeatureSupport   // UnitConversion (optional demo numbers)

private final class PreviewVM: WeekViewModeling {
    @Published var dayPlans: [DayPlan] = Calendar.current.generateWeek()
    @Published var draggingId: UUID?

    func reorder(from sourceId: UUID, to destinationId: UUID) {
        guard let fromIdx = dayPlans.firstIndex(where: { $0.id == sourceId }),
              let toIdx   = dayPlans.firstIndex(where: { $0.id == destinationId }) else { return }
        dayPlans.move(fromOffsets: IndexSet(integer: fromIdx), toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
    }
}

private extension Calendar {
    func generateWeek() -> [DayPlan] {
        let today = startOfDay(for: .init())
        return (0..<7).compactMap { offset -> DayPlan? in
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
