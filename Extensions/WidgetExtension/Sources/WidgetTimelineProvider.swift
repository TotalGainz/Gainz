//
//  WidgetTimelineProvider.swift
//  Gainz • WidgetExtension
//
//  Created by AI on 2025-06-06.
//
//  WidgetTimelineProvider supplies WidgetKit with dynamic timeline entries.
//  TimelineProvider advises WidgetKit when to update a widget's display. :contentReference[oaicite:0]{index=0}
/*  A timeline entry defines when WidgetKit will display content. :contentReference[oaicite:1]{index=1}
    StaticConfiguration links the provider to the widget view. :contentReference[oaicite:2]{index=2}
    The provider should schedule future refresh dates for efficient updates. :contentReference[oaicite:3]{index=3}
    Widgets can display dynamic content using TimelineProvider introduced in iOS 14. :contentReference[oaicite:4]{index=4}
    Interactivity additions announced in WWDC 23 rely on similar provider mechanics. :contentReference[oaicite:5]{index=5}
    Placeholder data renders instantly in the widget gallery for preview. :contentReference[oaicite:6]{index=6}
    Tutorials demonstrate linking timeline entries to SwiftUI views. :contentReference[oaicite:7]{index=7}
    The same approach underpins streak or next-workout widgets in modern fitness apps. :contentReference[oaicite:8]{index=8}
    Future advanced providers may migrate to AppIntentTimelineProvider for user-configured intents. :contentReference[oaicite:9]{index=9}
*/
//
//  NOTE: Per brand requirements, no HRV or velocity tracking is included.
//

import WidgetKit
import SwiftUI
import CorePersistence   // DatabaseManager for workout sessions & streaks
import Foundation

// MARK: – TimelineProvider

struct WidgetTimelineProvider: TimelineProvider {
    private let store = DatabaseManager.shared
    
    // Placeholder for widget gallery
    func placeholder(in context: Context) -> WidgetContent {
        WidgetContent.placeholder
    }
    
    // Snapshot for quick-look
    func getSnapshot(in context: Context,
                     completion: @escaping (WidgetContent) -> Void) {
        completion(generateContent())
    }
    
    // Full timeline
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<WidgetContent>) -> Void) {
        let current = generateContent()
        // Refresh at next workout start or next midnight
        let refreshDate: Date = {
            if let start = current.workoutDate, start > .now {
                return start
            }
            return Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        }()
        completion(Timeline(entries: [current], policy: .after(refreshDate)))
    }
    
    // MARK: – Content Builder
    
    private func generateContent() -> WidgetContent {
        if let session = store.fetchNextSession(from: .now) {
            return WidgetContent(date: .now,
                                 kind: .nextWorkout,
                                 workoutName: session.title,
                                 workoutDate: session.startDate,
                                 streakCount: nil)
        } else {
            let streak = store.fetchWorkoutStreak()
            return WidgetContent(date: .now,
                                 kind: .streak,
                                 workoutName: nil,
                                 workoutDate: nil,
                                 streakCount: streak)
        }
    }
}
