//
//  DateFormatter+Gainz.swift
//  FeatureSupport
//
//  Centralised cache of DateFormatters & helpers.
//  • Thread-safe via `static let` initialisation.
//  • Locale-aware (defaults to user’s current Locale).
//  • Time-zone aligned to user settings; overrideable.
//  • No UIKit / SwiftUI imports → usable across Domain, Services, Watch.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - GainzDateStyle

/// Predefined date / time layouts used throughout the app.
/// Add new cases here instead of scattering raw format strings.
public enum GainzDateStyle {
    case workoutList        // “Mon, 27 May”
    case workoutDetail      // “Monday, 27 May 2025”
    case timeOnly           // “14:37”
    case isoDate            // “2025-05-27”
    case isoDateTime        // “2025-05-27T14:37:52Z”
}

// MARK: - DateFormatter + Gainz

public extension DateFormatter {

    /// Returns a cached formatter for the requested style.
    static func gainz(style: GainzDateStyle,
                      locale: Locale = .current,
                      timeZone: TimeZone = .current) -> DateFormatter {
        switch style {
        case .workoutList:   return Self.cached("EEE, d MMM", locale, timeZone)
        case .workoutDetail: return Self.cached("EEEE, d MMM yyyy", locale, timeZone)
        case .timeOnly:      return Self.cached("HH:mm", locale, timeZone)
        case .isoDate:       return Self.cached("yyyy-MM-dd", locale, timeZone)
        case .isoDateTime:   return Self.cached("yyyy-MM-dd'T'HH:mm:ssXXXXX", locale, timeZone)
        }
    }

    // MARK: - Private cache

    /// Builds (lazily) and reuses a formatter keyed by its pattern + locale + timeZone.
    private static func cached(_ pattern: String,
                               _ locale: Locale,
                               _ timeZone: TimeZone) -> DateFormatter {
        let key = "\(pattern)|\(locale.identifier)|\(timeZone.identifier)"
        if let existing = Cache.formatters[key] { return existing }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        Cache.formatters[key] = formatter
        return formatter
    }

    /// Static dictionary lives in process memory; DateFormatter is not thread-safe
    /// but `static let` initialisation is, so lookups are safe after creation.
    private enum Cache {
        static var formatters: [String: DateFormatter] = [:]
    }
}

// MARK: - Date helpers

public extension Date {

    /// Shorthand for converting a date to string with Gainz styles.
    func formatted(_ style: GainzDateStyle,
                   locale: Locale = .current,
                   timeZone: TimeZone = .current) -> String {
        DateFormatter.gainz(style: style, locale: locale, timeZone: timeZone)
            .string(from: self)
    }
}
