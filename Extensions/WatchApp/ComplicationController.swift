//
//  ComplicationController.swift
//  Gainz • WatchApp
//
//  Provides ClockKit complications that mirror the iOS widget logic:
//  – “Next Workout” progress ring (sets logged / total)
//  – “Streak” day counter
//  Brand-consistent colors; no HRV / velocity tracking.
//  © 2025 Echelon Commerce LLC.
//

import ClockKit
import SwiftUI
import CoreUI            // ProgressRingView, ColorPalette
import CorePersistence   // DatabaseManager for workout data

// MARK: – SwiftUI views used inside graphic complications

private struct RingGaugeView: View {
    let progress: Double
    var body: some View {
        ProgressRingView(progress: progress, ringWidth: 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StreakView: View {
    let streak: Int
    var body: some View {
        ZStack {
            ProgressRingView(progress: min(Double(streak) / 7, 1), ringWidth: 4)
            Text("\(streak)")
                .font(.caption2.bold())
                .foregroundStyle(ColorPalette.accent)
        }
    }
}

// MARK: – ComplicationDataSource

final class ComplicationController: NSObject, CLKComplicationDataSource {
    private let db = DatabaseManager.shared
    
    // Families we fully support
    private let families: [CLKComplicationFamily] = [
        .graphicCircular,
        .modularSmall
    ]
    
    // MARK: Descriptors
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let next = CLKComplicationDescriptor(
            identifier: "nextWorkout",
            displayName: "Next Workout",
            supportedFamilies: families
        )
        let streak = CLKComplicationDescriptor(
            identifier: "streakDays",
            displayName: "Workout Streak",
            supportedFamilies: families
        )
        handler([next, streak])
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) { }
    
    // MARK: Timeline
    
    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        handler(entry(for: complication, at: .now))
    }
    
    func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void
    ) {
        // one entry 6 hours ahead to nudge ClockKit refresh
        guard let nextDate = Calendar.current.date(byAdding: .hour, value: 6, to: date) else {
            handler(nil); return
        }
        handler([entry(for: complication, at: nextDate)].compactMap { $0 })
    }
    
    // MARK: Placeholders
    
    func getPlaceholderTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        handler(template(for: complication, session: nil, streak: 3))
    }
    
    // MARK: Helpers
    
    private func entry(for complication: CLKComplication, at date: Date) -> CLKComplicationTimelineEntry? {
        if complication.identifier == "nextWorkout",
           let session = db.fetchTodaySession() {
            return CLKComplicationTimelineEntry(
                date: date,
                complicationTemplate: template(for: complication, session: session, streak: nil)
            )
        } else {
            let streak = db.fetchWorkoutStreak()
            return CLKComplicationTimelineEntry(
                date: date,
                complicationTemplate: template(for: complication, session: nil, streak: streak)
            )
        }
    }
    
    private func template(
        for complication: CLKComplication,
        session: WorkoutSession?,
        streak: Int?
    ) -> CLKComplicationTemplate? {
        switch complication.family {
            
        // MARK: GraphicCircular
            
        case .graphicCircular:
            if complication.identifier == "nextWorkout",
               let session {
                let progress = Double(session.loggedSets) / max(Double(session.plannedSets), 1)
                return CLKComplicationTemplateGraphicCircularView(
                    RingGaugeView(progress: progress)
                )
            } else if let streak {
                return CLKComplicationTemplateGraphicCircularView(
                    StreakView(streak: streak)
                )
            }
            
        // MARK: ModularSmall
            
        case .modularSmall:
            if complication.identifier == "nextWorkout",
               let session {
                let text = CLKSimpleTextProvider(text: "\(session.loggedSets)/\(session.plannedSets)")
                return CLKComplicationTemplateModularSmallStackText(
                    line1TextProvider: CLKSimpleTextProvider(text: "Sets"),
                    line2TextProvider: text
                )
            } else if let streak {
                return CLKComplicationTemplateModularSmallStackText(
                    line1TextProvider: CLKSimpleTextProvider(text: "Streak"),
                    line2TextProvider: CLKSimpleTextProvider(text: "\(streak)")
                )
            }
            
        default: return nil
        }
        return nil
    }
}
