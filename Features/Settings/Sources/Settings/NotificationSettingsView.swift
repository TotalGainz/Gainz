// NotificationSettingsView.swift
// Gainz – Settings Feature Module
//
// SwiftUI sub-view for managing push notification permissions and preferences.
// Guides the user through enabling notifications via system prompts or Settings app, and shows notification options if allowed.

import SwiftUI
import Combine
import CoreUI
import UserNotifications
import UIKit

// MARK: - Notification Settings View
@MainActor
public struct NotificationSettingsView: View {
    // Inherit the main settings view model via environment to update global settings (notificationsEnabled flag)
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    // Track the system authorization status for notifications
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    // Controls the display of an alert prompting the user to open iOS Settings when permission is denied
    @State private var showDeniedAlert: Bool = false
    
    // User preference toggles for specific notification types (persisted via @AppStorage for two-way sync with UserDefaults)
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled: Bool = true
    @AppStorage("weeklySummaryEnabled") private var weeklySummaryEnabled: Bool = true
    
    public init() {}
    
    public var body: some View {
        Form {
            Section(header: Text("Push Notifications")) {
                switch authorizationStatus {
                case .authorized:
                    // If notifications are authorized, show detailed notification options
                    Toggle("Daily Workout Reminder", isOn: $dailyReminderEnabled)
                    Toggle("Weekly Summary Alerts", isOn: $weeklySummaryEnabled)
                case .denied:
                    // If user has denied notifications, instruct and offer to open Settings
                    Text("Notifications are currently disabled for this app.")
                        .foregroundColor(.secondary)
                    Button("Open Settings") {
                        openSystemNotificationSettings()
                    }
                case .notDetermined:
                    // If permission not asked yet, explain and provide enable button
                    Text("Enable push notifications to stay informed about your workouts and progress.")
                        .foregroundColor(.secondary)
                    Button("Enable Notifications") {
                        requestNotificationPermission()
                    }
                default:
                    // Handle any other unknown statuses (provisional, ephemeral – not used here)
                    Text("Notification preferences are unavailable.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            // Fetch current notification authorization status when view appears
            refreshAuthorizationStatus()
            // Synchronize the global toggle with actual authorization status
            settingsViewModel.notificationsEnabled = (authorizationStatus == .authorized)
        }
        // Listen for app returning to foreground to refresh authorization status
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            refreshAuthorizationStatus()
            // Keep the main notificationsEnabled preference in sync after returning from Settings
            settingsViewModel.notificationsEnabled = (authorizationStatus == .authorized)
        }
        // Alert prompting user to open Settings if permission was denied via prompt
        .alert("Notifications Disabled", isPresented: $showDeniedAlert) {
            Button("Open Settings") {
                openSystemNotificationSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To enable notifications, please allow them in the iOS Settings for this app.")
        }
    }
    
    // MARK: - Permission Handling Methods
    
    /// Refresh the current notification authorization status
    private func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    /// Request push notification authorization from the system
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.refreshAuthorizationStatus()
                if granted {
                    // Permission granted – update global setting to enabled
                    settingsViewModel.notificationsEnabled = true
                } else {
                    // Permission denied – prompt user with an alert to manually enable in Settings
                    self.showDeniedAlert = true
                }
            }
        }
    }
    
    /// Open the iOS Settings app directly to this app's notification settings
    private func openSystemNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
