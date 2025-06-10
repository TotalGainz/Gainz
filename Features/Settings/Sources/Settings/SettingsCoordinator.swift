// SettingsCoordinator.swift
// Gainz – Settings Feature Module
//
// Coordinator for Settings module. Manages navigation flow and links to sub-features (like Notification settings).
// Owns a NavigationPath for deep linking, creates the SettingsViewModel, and provides the SettingsView for presentation.

import SwiftUI
import Combine
import CoreUI
import ServiceHealth

// MARK: - Settings Coordinator
@MainActor
public final class SettingsCoordinator: ObservableObject, SettingsCoordinatorProtocol {
    // The child view model for Settings, created with dependency injection
    public let viewModel: SettingsViewModel
    // Published navigation path for pushing deeper routes (used by NavigationStack)
    @Published public var path = NavigationPath()
    
    // Define navigation routes within Settings feature
    enum SettingsRoute: Hashable {
        case notifications  // route to NotificationSettingsView
    }
    
    // MARK: - Initialization
    public init(
        appearanceManager: AppearanceManaging = .shared,
        feedbackManager: FeedbackManaging = .shared,
        storage: UserDefaults = .standard
    ) {
        // Initialize the Settings view model with injected dependencies
        self.viewModel = SettingsViewModel(appearanceManager: appearanceManager,
                                           feedbackManager: feedbackManager,
                                           storage: storage)
        // Link the view model back to this coordinator for navigation callbacks
        self.viewModel.coordinator = self
    }
    
    // MARK: - Coordinator Interface
    /// Navigate to the Notification Settings screen
    public func openNotificationSettings() {
        // Append the route to the NavigationPath to trigger navigation in the NavigationStack
        path.append(SettingsRoute.notifications)
    }
    
    // MARK: - Build Settings View
    /// Construct the root Settings view, embedding this coordinator’s navigation logic.
    public func makeSettingsView() -> SettingsView {
        // Provide the SettingsView with its view model and this coordinator
        return SettingsView(viewModel: viewModel, coordinator: self)
    }
}
