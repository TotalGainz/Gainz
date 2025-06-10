//  UnitConversion.swift
//  FeatureSupport
//
//  Lightweight, dependency-free helpers for common fitness-centric
//  unit conversions. Uses only Foundation (no HealthKit or CoreLocation).
//
//  • Precision ≥ IEEE-754 Double (~15 decimal digits).
//  • Rounded results for UI display (default: 2 decimal places).
//  • No conversions for velocity, heart rate variability (HRV), or recovery metrics (by design).
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - UnitConversion

/// A namespace for one-line unit conversions between metric and imperial units.
///
/// Example usage:
/// ```swift
/// let plates = UnitConversion.kgToLb(100)   // 220.46
/// let armCircumference = UnitConversion.cmToIn(40)    // 15.75
/// ```
public enum UnitConversion {

    // MARK: - Constants

    /// Conversion factor from kilograms to pounds.
    private static let poundsPerKilogram: Double = 2.204_622_621_85
    /// Conversion factor from centimeters to inches.
    private static let inchesPerCentimeter: Double = 0.393_700_787_4
    /// Conversion factor from meters to feet.
    private static let feetPerMeter: Double = 3.280_839_895
    /// Conversion factor from miles to kilometers.
    private static let kilometersPerMile: Double = 1.609_344
    /// Conversion factor from yards to meters.
    private static let metersPerYard: Double = 0.914_4

    // MARK: - Weight

    /// Converts a weight from kilograms to pounds, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - kg: The weight in kilograms.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The weight in pounds, rounded to the given number of decimal places.
    @inlinable public static func kgToLb(_ kg: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((kg * poundsPerKilogram) * scale).rounded() / scale
    }

    /// Converts a weight from pounds to kilograms, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - lb: The weight in pounds.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The weight in kilograms, rounded to the given number of decimal places.
    @inlinable public static func lbToKg(_ lb: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((lb / poundsPerKilogram) * scale).rounded() / scale
    }

    // MARK: - Length

    /// Converts a length from centimeters to inches, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - cm: The length in centimeters.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The length in inches, rounded to the given number of decimal places.
    @inlinable public static func cmToIn(_ cm: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((cm * inchesPerCentimeter) * scale).rounded() / scale
    }

    /// Converts a length from inches to centimeters, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - inches: The length in inches.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The length in centimeters, rounded to the given number of decimal places.
    @inlinable public static func inToCm(_ inches: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((inches / inchesPerCentimeter) * scale).rounded() / scale
    }

    /// Converts a length from meters to feet, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - meters: The length in meters.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The length in feet, rounded to the given number of decimal places.
    @inlinable public static func mToFt(_ meters: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((meters * feetPerMeter) * scale).rounded() / scale
    }

    /// Converts a length from feet to meters, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - feet: The length in feet.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The length in meters, rounded to the given number of decimal places.
    @inlinable public static func ftToM(_ feet: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((feet / feetPerMeter) * scale).rounded() / scale
    }

    // MARK: - Distance

    /// Converts a distance from miles to kilometers, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - miles: The distance in miles.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The distance in kilometers, rounded to the given number of decimal places.
    @inlinable public static func miToKm(_ miles: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((miles * kilometersPerMile) * scale).rounded() / scale
    }

    /// Converts a distance from kilometers to miles, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - km: The distance in kilometers.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The distance in miles, rounded to the given number of decimal places.
    @inlinable public static func kmToMi(_ km: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((km / kilometersPerMile) * scale).rounded() / scale
    }

    /// Converts a distance from yards to meters, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - yards: The distance in yards.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The distance in meters, rounded to the given number of decimal places.
    @inlinable public static func ydToM(_ yards: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((yards * metersPerYard) * scale).rounded() / scale
    }

    /// Converts a distance from meters to yards, rounded to a specified number of decimal places.
    /// - Parameters:
    ///   - meters: The distance in meters.
    ///   - decimals: Number of decimal places for rounding (default is 2).
    /// - Returns: The distance in yards, rounded to the given number of decimal places.
    @inlinable public static func mToYd(_ meters: Double, roundedTo decimals: Int = 2) -> Double {
        let scale = pow(10, Double(decimals))
        return ((meters / metersPerYard) * scale).rounded() / scale
    }
}
