//  DateFormatter+Gainz.swift
//  FeatureSupport
//
//  Centralized cache of DateFormatter instances and date formatting helpers.
//  • Thread-safe caching ensures formatters are created once per format and reused.
//  • Locale-aware (defaults to user's current locale).
//  • Time zone aligned with user settings (overridable per call).
//  • No UIKit / SwiftUI imports → usable across Domain, Services, Watch.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - GainzDateStyle

/// Predefined date/time formats used throughout the app.
/// Add new cases here instead of scattering raw format strings in the code.
public enum GainzDateStyle {
    /// Short date format with abbreviated weekday (e.g., “Mon, 27 May”).
    case workoutList
    /// Long date format including full weekday and year (e.g., “Monday, 27 May 2025”).
    case workoutDetail
    /// Time only in 24-hour format (e.g., “14:37”).
    case timeOnly
    /// Date in ISO 8601 format (YYYY-MM-DD, e.g., “2025-05-27”).
    case isoDate
    /// Date and time in ISO 8601 format with UTC time zone (e.g., “2025-05-27T14:37:52Z”).
    case isoDateTime
}

// MARK: - DateFormatter + Gainz

public extension DateFormatter {
    /// Returns a cached `DateFormatter` configured for the specified style, locale, and time zone.
    ///
    /// This function uses an internal cache to avoid creating new `DateFormatter` instances for the same format.
    /// - Parameters:
    ///   - style: The desired date style (format pattern) defined by `GainzDateStyle`.
    ///   - locale: The locale for formatting (default is the current locale).
    ///   - timeZone: The time zone for formatting (default is the current time zone).
    /// - Returns: A `DateFormatter` instance configured with the given parameters.
    /// - Note: The returned formatter is a shared instance. Do not modify it, and avoid using it concurrently from multiple threads.
    static func gainz(style: GainzDateStyle, locale: Locale = .current, timeZone: TimeZone = .current) -> DateFormatter {
        switch style {
        case .workoutList:
            return Self.cached("EEE, d MMM", locale, timeZone)
        case .workoutDetail:
            return Self.cached("EEEE, d MMM yyyy", locale, timeZone)
        case .timeOnly:
            return Self.cached("HH:mm", locale, timeZone)
        case .isoDate:
            return Self.cached("yyyy-MM-dd", locale, timeZone)
        case .isoDateTime:
            return Self.cached("yyyy-MM-dd'T'HH:mm:ssXXXXX", locale, timeZone)
        }
    }

    // MARK: - Private Cache Implementation

    /// Returns a `DateFormatter` for the given pattern, locale, and time zone, using and updating the cache as needed.
    /// - Note: This method is thread-safe via an internal lock.
    private static func cached(_ pattern: String, _ locale: Locale, _ timeZone: TimeZone) -> DateFormatter {
        let key = "\(pattern)|\(locale.identifier)|\(timeZone.identifier)"
        Cache.lock.lock()
        defer { Cache.lock.unlock() }
        if let formatter = Cache.formatters[key] {
            return formatter
        }
        // Create a new DateFormatter configured with the specified parameters
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        Cache.formatters[key] = formatter
        return formatter
    }

    /// Internal storage for cached formatters and the synchronization lock.
    private enum Cache {
        static var formatters: [String: DateFormatter] = [:]
        static let lock = NSLock()
    }
}

// MARK: - Date Convenience

public extension Date {
    /// Formats the date to a string using a specified `GainzDateStyle`.
    /// - Parameters:
    ///   - style: The date style to use for formatting (see `GainzDateStyle`).
    ///   - locale: The locale for formatting (default is current locale).
    ///   - timeZone: The time zone for formatting (default is current time zone).
    /// - Returns: A string representation of the date formatted according to the given style.
    func formatted(_ style: GainzDateStyle, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        return DateFormatter.gainz(style: style, locale: locale, timeZone: timeZone).string(from: self)
    }
}
