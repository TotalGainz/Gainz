//
//  DayCardView.swift
//  PlannerFeature
//
//  Visual card for a single calendar day in the Planner grid.
//  • Shows date, planned workout title (if any), and total set count.
//  • Uses CoreUI tokens for consistent colors, fonts, and shadows.
//  • Taps bubble up via onTap closure so parent Coordinator can handle navigation.
//  • No HRV, recovery, or velocity data shown (hypertrophy focus).
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain           // MesocyclePlan, WorkoutSession models
import CoreUI           // Color tokens, fonts

// MARK: - ViewModel

public struct DayCardViewModel: Identifiable, Equatable {
    public let id: UUID          // stable unique identifier (one per day)
    public let date: Date
    public let workoutTitle: String?
    public let plannedSets: Int

    public init(
        id: UUID = .init(),
        date: Date,
        workoutTitle: String?,
        plannedSets: Int
    ) {
        self.id = id
        self.date = date
        self.workoutTitle = workoutTitle
        self.plannedSets = plannedSets
    }
}

// MARK: - View

public struct DayCardView: View {
    // MARK: Input
    public let model: DayCardViewModel
    public let onTap: (DayCardViewModel) -> Void

    // MARK: Derived UI
    private var isToday: Bool {
        Calendar.current.isDateInToday(model.date)
    }
    private var dateString: String {
        // Day of month (no leading zero)
        let df = DateFormatter()
        df.dateFormat = "d"
        return df.string(from: model.date)
    }

    // MARK: Body
    public var body: some View {
        Button {
            onTap(model)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isToday ? Color.accent : .primary)
                if let title = model.workoutTitle {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                if model.plannedSets > 0 {
                    Text("\(model.plannedSets) sets")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Card background with subtle shadow
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cardBackground)
                    .shadow(radius: isToday ? 6 : 2, y: isToday ? 2 : 1)
            )
            .overlay(
                // Outline stroke: highlight accent border if today
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isToday ? Color.accent : Color.border, lineWidth: isToday ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DayCardView(
            model: .init(date: Date(), workoutTitle: "Push A", plannedSets: 18),
            onTap: { _ in }
        )
        DayCardView(
            model: .init(date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                         workoutTitle: nil, plannedSets: 0),
            onTap: { _ in }
        )
    }
    .padding()
    .background(Color(.systemBackground))
    .previewLayout(.sizeThatFits)
}
