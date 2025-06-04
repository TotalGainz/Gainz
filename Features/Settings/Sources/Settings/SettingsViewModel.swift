//  SettingsViewModel.swift
//  Gainz – Settings Feature
//
//  Created by AI Auto-Generated on 2025-06-04.
//
//  This @MainActor ObservableObject exposes three user-preferences and
//  propagates changes to the shared CoreUI managers.  Using Combine’s
//  automatic publisher synthesis via @Published keeps SettingsView in-sync
//  without extra glue code.
//
//  NOTE: Intentionally no HRV or Velocity-Tracking logic per project scope.

import SwiftUI
import Combine
import CoreUI

@MainActor
public final class SettingsViewModel: ObservableObject {

    // MARK: - Published User Preferences

    @Published public var darkModeEnabled: Bool {
        didSet { appearanceManager.setDarkMode(darkModeEnabled) }
    }

    @Published public var hapticsEnabled: Bool {
        didSet { feedbackManager.hapticsEnabled = hapticsEnabled }
    }

    @Published public var notificationsEnabled: Bool {
        didSet { feedbackManager.notificationsEnabled = notificationsEnabled }
    }

    // MARK: - Private

    private let appearanceManager: AppearanceManaging
    private let feedbackManager: FeedbackManaging
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        appearanceManager: AppearanceManaging = .shared,
        feedbackManager: FeedbackManaging = .shared,
        storage: UserDefaults = .standard
    ) {
        self.appearanceManager   = appearanceManager
        self.feedbackManager     = feedbackManager

        // Bootstrap from persisted values via @AppStorage wrapper manually
        _darkModeEnabled        = Published(initialValue: storage.bool(forKey: SettingsKey.darkModeEnabled.rawValue))
        _hapticsEnabled         = Published(initialValue: storage.object(forKey: SettingsKey.hapticsEnabled.rawValue) as? Bool ?? true)
        _notificationsEnabled   = Published(initialValue: storage.object(forKey: SettingsKey.notificationsEnabled.rawValue) as? Bool ?? true)

        bindAppStorage(using: storage)
    }

    // MARK: - Persistence Bridge

    private func bindAppStorage(using storage: UserDefaults) {
        $darkModeEnabled
            .dropFirst() // ignore seed value
            .sink { storage.set($0, forKey: SettingsKey.darkModeEnabled.rawValue) }
            .store(in: &cancellables)

        $hapticsEnabled
            .dropFirst()
            .sink { storage.set($0, forKey: SettingsKey.hapticsEnabled.rawValue) }
            .store(in: &cancellables)

        $notificationsEnabled
            .dropFirst()
            .sink { storage.set($0, forKey: SettingsKey.notificationsEnabled.rawValue) }
            .store(in: &cancellables)
    }

    // MARK: - Convenience Toggle APIs (optional)

    public func toggleDarkMode()       { darkModeEnabled.toggle() }
    public func toggleHaptics()        { hapticsEnabled.toggle() }
    public func toggleNotifications()  { notificationsEnabled.toggle() }
}

// MARK: - SettingsKey

fileprivate enum SettingsKey: String {
    case darkModeEnabled
    case hapticsEnabled
    case notificationsEnabled
}

// MARK: - Protocol Shims (for dependency-injection / unit-testing)

public protocol AppearanceManaging {
    static var shared: AppearanceManaging { get }
    func setDarkMode(_ enabled: Bool)
}

public protocol FeedbackManaging {
    static var shared: FeedbackManaging { get }
    var hapticsEnabled: Bool { get set }
    var notificationsEnabled: Bool { get set }
}
