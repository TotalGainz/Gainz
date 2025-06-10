//  SettingsFeatureInterface.swift
//  FeatureInterfaces
//
//  Exposes a single, dependency-inverted contract that any layer
//  (AppCoordinator, deep-link handler, watchOS companion) can use to
//  present the Settings screen and react to preference changes—without
//  importing the Settings feature’s internal code.
//
//  • Pure SwiftPM target; relies only on Foundation, Combine, SwiftUI.
//  • No HRV, recovery, or velocity metrics.
//  • Type-safe enums instead of stringly-typed keys.
//  • Reactive stream so consumers auto-update on preference edits.
//
//  Created for Gainz on 27 May 2025.
//
import Foundation
import Combine
import SwiftUI

// MARK: - UserPreferences

/// Immutable snapshot of user-configurable app settings.
public struct UserPreferences: Equatable, Codable {

    public enum WeightUnit: String, Codable, CaseIterable { case kg, lb }
    public enum LengthUnit: String, Codable, CaseIterable { case cm, inch }
    public enum Theme: String, Codable, CaseIterable { case system, light, dark }

    public var weightUnit: WeightUnit
    public var lengthUnit: LengthUnit
    public var notificationsEnabled: Bool
    public var theme: Theme

    public init(
        weightUnit: WeightUnit = .lb,
        lengthUnit: LengthUnit = .inch,
        notificationsEnabled: Bool = true,
        theme: Theme = .system
    ) {
        self.weightUnit = weightUnit
        self.lengthUnit = lengthUnit
        self.notificationsEnabled = notificationsEnabled
        self.theme = theme
    }
}

// MARK: - PreferenceUpdate

/// Strongly-typed mutations so callers can’t send malformed data.
public enum PreferenceUpdate {
    case weightUnit(UserPreferences.WeightUnit)
    case lengthUnit(UserPreferences.LengthUnit)
    case notificationsEnabled(Bool)
    case theme(UserPreferences.Theme)
}

// MARK: - Interface

/// Dependency-inverted façade every other module talks to.
public protocol SettingsFeatureInterface: AnyObject {

    /// Root SwiftUI view for Settings, type-erased so UIKit hosts it too.
    /// – Parameter onDismiss: callback when user taps “Done”.
    func makeSettingsRoot(onDismiss: @escaping () -> Void) -> AnyView

    /// Current preferences and a live stream of future edits.
    var preferencesPublisher: AnyPublisher<UserPreferences, Never> { get }

    /// Programmatically mutate a subset of preferences.
    func apply(_ update: PreferenceUpdate)
}

// MARK: - Environment Key

private struct SettingsFeatureKey: EnvironmentKey {
    static let defaultValue: SettingsFeatureInterface? = nil
}

public extension EnvironmentValues {
    /// Dependency-injection hook for the Settings feature.
    /// ```swift
    /// @Environment(\.settingsFeature) private var settingsFeature
    /// ```
    var settingsFeature: SettingsFeatureInterface? {
        get { self[SettingsFeatureKey.self] }
        set { self[SettingsFeatureKey.self] = newValue }
    }
}
