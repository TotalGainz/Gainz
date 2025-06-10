// SettingsView.swift
// Gainz – Settings Feature Module
//
// SwiftUI view presenting grouped user preferences toggles (Dark Mode, Haptics, etc.),
// with navigation to deeper settings (e.g., Notification permissions). Conforms to HIG
// for settings layout using Form and Section. Navigation is handled via SettingsCoordinator.

import SwiftUI
import Combine
import CoreUI
import DesignSystem

// MARK: - Settings View (Main Preferences Screen)
@MainActor
public struct SettingsView: View {
    // Observing the view model (holds user preferences state and logic)
    @ObservedObject private var viewModel: SettingsViewModel
    // The coordinator drives navigation to deeper settings screens
    @ObservedObject private var coordinator: SettingsCoordinator
    
    public init(viewModel: SettingsViewModel, coordinator: SettingsCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
    }
    
    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            Form {
                // Appearance preferences section
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $viewModel.darkModeEnabled) {
                        Text("Dark Mode")
                    }
                }
                
                // Feedback (haptics) preferences section
                Section(header: Text("Feedback")) {
                    Toggle(isOn: $viewModel.hapticsEnabled) {
                        Text("Haptics")
                    }
                }
                
                // Notifications preferences section
                Section(header: Text("Notifications")) {
                    // Row showing current notifications setting with navigation to detail screen
                    Button(action: {
                        // Delegate to view model to handle navigation intent
                        viewModel.openNotificationSettings()
                    }) {
                        HStack {
                            Text("Notifications")
                            Spacer()
                            // Show current status (On/Off) in a secondary text style
                            Text(viewModel.notificationsEnabled ? "On" : "Off")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            // Define destination for the Notification Settings route via coordinator
            .navigationDestination(for: SettingsCoordinator.SettingsRoute.self) { route in
                switch route {
                case .notifications:
                    // Navigate to the NotificationSettingsView, injecting the same view model via environment
                    NotificationSettingsView()
                        .environmentObject(viewModel)
                }
            }
        }
    }
}
