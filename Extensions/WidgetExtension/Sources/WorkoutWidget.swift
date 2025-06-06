//
//  WorkoutWidget.swift
//  Gainz • WidgetExtension
//
//  Created by AI on 2025-06-06.
//  Copyright © 2025 Echelon Commerce LLC.
//

import WidgetKit
import SwiftUI
import CoreUI            // ProgressRingView, ColorPalette
import CorePersistence   // DatabaseManager for fetches

// MARK: – Model

struct WorkoutEntry: TimelineEntry {
    let date: Date
    let workoutName: String
    let completedSets: Int
    let totalSets: Int
    let accentColor: Color
}

// MARK: – Provider

struct WorkoutProvider: TimelineProvider {
    private let storage = DatabaseManager.shared
    
    func placeholder(in context: Context) -> WorkoutEntry {
        WorkoutEntry(date: .now,
                     workoutName: "Today: Push – Chest & Triceps",
                     completedSets: 0,
                     totalSets: 24,
                     accentColor: ColorPalette.accent)            // brand gradient anchor
    }
    
    func getSnapshot(in context: Context,
                     completion: @escaping (WorkoutEntry) -> Void) {
        completion(makeEntry())
    }
    
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<WorkoutEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh fifteen minutes after last set OR at midnight if no workout
        let refresh = Calendar.current.nextDate(after: .now,
                                                matching: DateComponents(minute: 0, second: 0),
                                                matchingPolicy: .nextTime)
                        ?? .now.addingTimeInterval(60 * 60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
    
    // MARK: – Helpers
    
    private func makeEntry() -> WorkoutEntry {
        // Simplified fetch; production uses Combine publisher for live updates.
        let session = storage.fetchTodaySession()
        return WorkoutEntry(date: .now,
                            workoutName: session?.title ?? "Rest Day",
                            completedSets: session?.loggedSets ?? 0,
                            totalSets: session?.plannedSets ?? 0,
                            accentColor: ColorPalette.accent)
    }
}

// MARK: – View

struct WorkoutWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorkoutEntry
    
    var body: some View {
        switch family {
        case .systemSmall, .accessoryRectangular:
            smallView
        default:
            mediumView
        }
    }
    
    // MARK: – Layouts
    
    private var smallView: some View {
        ZStack {
            LinearGradient(colors: [entry.accentColor, entry.accentColor.opacity(0.7)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                ProgressRingView(progress: progress,
                                 ringWidth: 6)
                    .frame(width: 44, height: 44)
                
                Text(progressText)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
            }
            .padding()
        }
    }
    
    private var mediumView: some View {
        HStack(spacing: 12) {
            ProgressRingView(progress: progress,
                             ringWidth: 8)
                .frame(width: 58, height: 58)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.workoutName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(entry.completedSets)/\(entry.totalSets) sets logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.bar)   // blurred material for brand polish
    }
    
    // MARK: – Derived
    
    private var progress: Double {
        guard entry.totalSets > 0 else { return 0 }
        return Double(entry.completedSets) / Double(entry.totalSets)
    }
    
    private var progressText: String {
        entry.totalSets == 0 ? "Rest Day" : "\(Int(progress * 100))% done"
    }
}

// MARK: – Widget

@main
struct WorkoutWidget: Widget {
    let kind = "WorkoutWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: WorkoutProvider()) { entry in
            WorkoutWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Workout Progress")
        .description("Shows your current workout completion at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: – Previews

struct WorkoutWidget_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutWidgetEntryView(entry: WorkoutEntry(date: .now,
                                                   workoutName: "Push – Chest & Triceps",
                                                   completedSets: 12,
                                                   totalSets: 24,
                                                   accentColor: ColorPalette.accent))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
