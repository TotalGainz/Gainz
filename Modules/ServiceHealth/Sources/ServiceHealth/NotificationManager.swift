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

/// A global manager that handles scheduling and managing local notifications for the Gainz app.
/// This is implemented as an `actor` (singleton) to ensure thread-safe operations across different threads.
public actor NotificationManager {

    // MARK: Singleton

    /// The shared singleton instance of `NotificationManager` for global use.
    public static let shared = NotificationManager()
    /// Private initializer to enforce singleton usage.
    private init() {}

    // MARK: Public API

    /// Requests user authorization for displaying alerts, sounds, and badge notifications.
    /// - Returns: `true` if permission was granted, or `false` if denied or an error occurred.
    /// - Note: This method uses async/await. It should be called at app launch or when notification functionality is first needed.
    ///         If permission is granted (or was already granted), this will also configure the app's notification categories and actions (e.g., quick actions for notifications).
    @discardableResult
    public func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            // Request system alert/sound/badge notification permissions.
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            // After obtaining authorization, set up custom notification categories and actions.
            await configureNotificationCategories()
            return granted
        } catch {
            #if DEBUG
            print("🔔 Notification permission error:", error)
            #endif
            return false
        }
    }

    /// Schedules (or replaces) a one-off local notification at the specified future date.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the notification. If a notification with the same identifier is already pending, it will be replaced (preventing duplicate reminders).
    ///   - title: The primary text (usually bold) shown in the notification alert.
    ///   - body: The secondary text shown in the notification alert (detail message).
    ///   - date: The date and time (in the user’s locale/timezone) when the notification should fire.
    /// - Throws: An error if scheduling the notification fails (e.g., if notifications are not authorized).
    /// - Note: This function uses `UNCalendarNotificationTrigger` to schedule an exact date. It does not repeat.
    public func scheduleNotification(
        id: String,
        title: String,
        body: String,
        at date: Date
    ) async throws {
        // Create a calendar-based trigger for the specified date.
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            ),
            repeats: false  // one-time notification (no repetition)
        )

        // Prepare the notification content with provided title and body.
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default  // use default notification sound (could be customized if needed)
        content.categoryIdentifier = GainzCategory.workoutReminder.rawValue  // assign category for custom actions

        // Create the notification request with a unique identifier, content, and trigger time.
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        // Schedule the notification. If an existing pending notification has the same identifier, it will be replaced by this new request.
        let center = UNUserNotificationCenter.current()
        try await center.add(request)
    }

    /// Cancels any pending or delivered notification with the specified identifier.
    /// - Parameter id: The identifier of the notification to cancel.
    /// - Note: This will remove the notification if it is still waiting to be delivered, and also clear it from Notification Center if it was already delivered.
    public func cancelNotification(id: String) async {
        let center = UNUserNotificationCenter.current()
        // Remove any scheduled notification request with this identifier (not yet delivered).
        await center.removePendingNotificationRequests(withIdentifiers: [id])
        // Also remove the notification from Notification Center if it has been delivered already.
        await center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    /// Clears all local notifications scheduled or delivered by Gainz.
    /// - Important: This only removes notifications for the Gainz app and does not affect notifications from other apps.
    public func clearAll() async {
        let center = UNUserNotificationCenter.current()
        // Remove all pending Gainz notification requests.
        await center.removeAllPendingNotificationRequests()
        // Remove all delivered Gainz notifications from Notification Center.
        await center.removeAllDeliveredNotifications()
    }

    // MARK: Private

    /// Registers custom notification categories and actions (buttons) for this app.
    /// This should be called once per app launch, after obtaining notification permission.
    private func configureNotificationCategories() async {
        let center = UNUserNotificationCenter.current()

        // Define a custom action that will be available on certain notifications (e.g., a "Start Workout" button).
        let startAction = UNNotificationAction(
            identifier: GainzAction.startWorkout.rawValue,
            title: "Start Workout",              // Button title in the notification interface
            options: [.foreground]               // Launch app in foreground when action is tapped
        )

        // Define a notification category that uses the above action.
        let workoutCategory = UNNotificationCategory(
            identifier: GainzCategory.workoutReminder.rawValue,  // link to category used in notifications
            actions: [startAction],                              // the actions available for this category
            intentIdentifiers: [],                               // not using Siri intents here
            options: [.customDismissAction]                      // option to handle when user dismisses the notification
        )

        // Register the new category with the system.
        await center.setNotificationCategories([workoutCategory])
    }
}

// MARK: - Enums

/// Identifiers for custom notification categories used in Gainz.
private enum GainzCategory: String {
    case workoutReminder = "GAINZ_WORKOUT_REMINDER"
}

/// Identifiers for custom notification actions used in Gainz (for interactive notifications).
private enum GainzAction: String {
    case startWorkout = "GAINZ_ACTION_START_WORKOUT"
}
