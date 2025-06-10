// SettingsViewModel.swift
// Gainz – Settings Feature Module
//
// @MainActor ObservableObject that exposes user preference toggles (appearance, haptics, notifications).
// Propagates changes to shared managers (AppearanceManaging, FeedbackManaging) and persists values via UserDefaults.
// Uses dependency injection for easy testing, and keeps UI updated through @Published properties.

import SwiftUI
import Combine
import CoreUI
import CorePersistence

// Protocol defining navigation actions from Settings (for decoupling Coordinator from ViewModel)
protocol SettingsCoordinatorProtocol: AnyObject {
    func openNotificationSettings()
}

// MARK: - Settings ViewModel
@MainActor
public final class SettingsViewModel: ObservableObject {
    // MARK: - Published User Preferences
    @Published public var darkModeEnabled: Bool {
        didSet {
            // Apply appearance change immediately through AppearanceManager
            appearanceManager.setDarkMode(darkModeEnabled)
            // Persist the new value
            userDefaults.set(darkModeEnabled, forKey: SettingsKey.darkModeEnabled.rawValue)
        }
    }
    
    @Published public var hapticsEnabled: Bool {
        didSet {
            // Enable/disable haptic feedback globally via FeedbackManager
            feedbackManager.hapticsEnabled = hapticsEnabled
            // Persist the new value
            userDefaults.set(hapticsEnabled, forKey: SettingsKey.hapticsEnabled.rawValue)
        }
    }
    
    @Published public var notificationsEnabled: Bool {
        didSet {
            // Update global notifications setting via FeedbackManager (scheduling or unscheduling notifications)
            feedbackManager.notificationsEnabled = notificationsEnabled
            // Persist the new value
            userDefaults.set(notificationsEnabled, forKey: SettingsKey.notificationsEnabled.rawValue)
        }
    }
    
    // MARK: - Dependencies
    private let appearanceManager: AppearanceManaging
    private let feedbackManager: FeedbackManaging
    private let userDefaults: UserDefaults
    
    // Weak reference to the coordinator to trigger navigation (internal, not exposed publicly)
    internal weak var coordinator: SettingsCoordinatorProtocol?
    
    // MARK: - Initialization
    public init(
        appearanceManager: AppearanceManaging = .shared,
        feedbackManager: FeedbackManaging = .shared,
        storage: UserDefaults = .standard
    ) {
        self.appearanceManager = appearanceManager
        self.feedbackManager = feedbackManager
        self.userDefaults = storage
        
        // Initialize published properties from stored values (with sensible defaults if unset)
        let storedDarkMode = storage.bool(forKey: SettingsKey.darkModeEnabled.rawValue)
        let storedHaptics = (storage.object(forKey: SettingsKey.hapticsEnabled.rawValue) as? Bool) ?? true
        let storedNotifications = (storage.object(forKey: SettingsKey.notificationsEnabled.rawValue) as? Bool) ?? true
        darkModeEnabled = storedDarkMode
        hapticsEnabled = storedHaptics
        notificationsEnabled = storedNotifications
        
        // Note: Property observers (didSet) are not called during init, so managers will not be signaled here.
        // The AppearanceManager may be configured elsewhere (e.g., app launch) to apply the saved theme.
    }
    
    // MARK: - Navigation Intents
    /// Call to open the detailed Notification Settings screen
    public func openNotificationSettings() {
        coordinator?.openNotificationSettings()
    }
    
    // MARK: - Preference Keys (namespace for UserDefaults keys)
    private enum SettingsKey: String {
        case darkModeEnabled, hapticsEnabled, notificationsEnabled
    }
}
