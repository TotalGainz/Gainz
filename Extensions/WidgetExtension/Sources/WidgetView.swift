//
//  WidgetView.swift
//  Gainz • WidgetExtension
//
//  Created by AI on 2025-06-06.
//  Renders either the upcoming workout card *or* a streak badge,
//  depending on `WidgetContent.Kind` supplied by the TimelineProvider.
//
//  Uses only lightweight SwiftUI drawing—no Health-related (HRV/velocity) code.
//

import WidgetKit
import SwiftUI
import CoreUI              // ProgressRingView, ColorPalette

// MARK: – Content Model (lightweight, Codable so the provider can embed it)

struct WidgetContent: TimelineEntry, Codable {
    enum Kind: String, Codable { case nextWorkout, streak }
    let date: Date                     // required by WidgetKit
    let kind: Kind
    // next workout fields
    let workoutName: String?
    let workoutDate: Date?
    // streak fields
    let streakCount: Int?
    
    static var placeholder: WidgetContent {
        .init(date: .now,
              kind: .nextWorkout,
              workoutName: "Pull – Back & Biceps",
              workoutDate: Calendar.current.date(byAdding: .hour, value: 4, to: .now),
              streakCount: nil)
    }
}

// MARK: – Root View

struct WidgetView: View {
    @Environment(\.widgetFamily) private var family
    let content: WidgetContent
    
    var body: some View {
        switch content.kind {
        case .nextWorkout: NextWorkoutCard(content: content, family: family)
        case .streak:      StreakBadge(content: content, family: family)
        }
    }
}

// MARK: – Next-Workout Card

private struct NextWorkoutCard: View {
    let content: WidgetContent
    let family: WidgetFamily
    
    private var formattedDate: String {
        guard let workoutDate = content.workoutDate else { return "Scheduled soon" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: workoutDate)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Workout")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(content.workoutName ?? "Rest Day")
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if family != .accessoryRectangular {
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "dumbbell.fill")
                .resizable()
                .scaledToFit()
                .frame(width: family == .systemSmall ? 20 : 26,
                       height: family == .systemSmall ? 20 : 26)
                .foregroundStyle(ColorPalette.accent)
        }
        .padding()
        .background(.bar)           // blurred material
        .accessibilityElement()
        .accessibilityLabel("Next workout \(content.workoutName ?? "") at \(formattedDate)")
    }
}

// MARK: – Streak Badge

private struct StreakBadge: View {
    let content: WidgetContent
    let family: WidgetFamily
    
    private var progress: Double {
        min(Double(content.streakCount ?? 0) / 7.0, 1.0)     // 7-day benchmark
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressRingView(progress: progress,
                             ringWidth: family == .systemSmall ? 6 : 8)
                .frame(width: family == .systemSmall ? 46 : 60,
                       height: family == .systemSmall ? 46 : 60)
                .overlay(
                    Text("\(content.streakCount ?? 0)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ColorPalette.accent)
                )
            if family != .accessoryRectangular {
                Text("Day Streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.bar)
        .accessibilityElement()
        .accessibilityLabel("Workout streak \(content.streakCount ?? 0) days")
    }
}

// MARK: – Previews

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetView(content: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            WidgetView(content: WidgetContent(date: .now,
                                              kind: .streak,
                                              workoutName: nil,
                                              workoutDate: nil,
                                              streakCount: 5))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
    }
}
