//
//  NotificationManager.swift
//  ServiceHealth
//
//  Responsible for all local-notification orchestration—requesting permission,
//  scheduling workout reminders, and cancelling alerts. Pure Swift; depends
//  only on UserNotifications so it compiles on iOS, watchOS, visionOS, and macOS.
//
//  Design principles
//  ─────────────────
//  • Async/await API for modern concurrency.
//  • Thread-safe singleton via `actor`.
//  • Guards against dupes by always replacing an existing request on same id.
//  • Brand-consistent sounds & categories wired through `GainzCategory.*`.
//  • No HRV, recovery, or velocity metrics.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import UserNotifications

// MARK: - NotificationManager

public actor NotificationManager {

    // MARK: Singleton
    public static let shared = NotificationManager()
    private init() {}

    // MARK: Public API

    /// Requests user permission for alerts, sounds, and badges.
    /// Returns `true` if granted.
    @discardableResult
    public func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await configureNotificationCategories()
            return granted
        } catch {
            #if DEBUG
            print("🔔 Notification permission error:", error)
            #endif
            return false
        }
    }

    /// Schedules (or replaces) a one-off notification at the given date.
    ///
    /// - Parameters:
    ///   - id:     Stable identifier so duplicates are replaced, not stacked.
    ///   - title:  Primary text (bold) shown in the alert.
    ///   - body:   Secondary text.
    ///   - date:   Trigger date (user’s locale).
    public func scheduleNotification(
        id: String,
        title: String,
        body: String,
        at date: Date
    ) async throws {
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            ),
            repeats: false
        )
        let content             = UNMutableNotificationContent()
        content.title            = title
        content.body             = body
        content.sound            = .default
        content.categoryIdentifier = GainzCategory.workoutReminder.rawValue

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        try await center.add(request)
    }

    /// Cancels a pending or delivered notification by id.
    public func cancelNotification(id: String) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: [id])
        await center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    /// Clears all Gainz notifications (does *not* affect other apps).
    public func clearAll() async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()
        await center.removeAllDeliveredNotifications()
    }

    // MARK: Private

    /// Registers custom categories/actions once per launch.
    private func configureNotificationCategories() async {
        let center = UNUserNotificationCenter.current()

        // Custom “Start Workout” quick action
        let startAction = UNNotificationAction(
            identifier: GainzAction.startWorkout.rawValue,
            title: "Start Workout",
            options: [.foreground]
        )

        let workoutCategory = UNNotificationCategory(
            identifier: GainzCategory.workoutReminder.rawValue,
            actions: [startAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        await center.setNotificationCategories([workoutCategory])
    }
}

// MARK: - Enums

private enum GainzCategory: String {
    case workoutReminder = "GAINZ_WORKOUT_REMINDER"
}

private enum GainzAction: String {
    case startWorkout = "GAINZ_ACTION_START_WORKOUT"
}
