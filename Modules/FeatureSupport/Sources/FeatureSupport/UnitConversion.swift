//
//  UnitConversion.swift
//  FeatureSupport
//
//  Lightweight, dependency-free helpers for common fitness-centric
//  unit conversions.  Pure Foundation; no HealthKit, no CoreLocation.
//
//  • Precision ≥ IEEE-754 Double (15 decimal digits).
//  • Rounded helpers for UI display (defaults to 2 dp).
//  • Zero velocity, HRV, or recovery logic — by design.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation

// MARK: - UnitConversion

/// Namespace for one-line unit conversions.
/// ```swift
/// let plates = UnitConversion.kgToLb(100)   // 220.46
/// let arm    = UnitConversion.cmToIn(40)    // 15.75
/// ```
public enum UnitConversion {

    // MARK: Scalars
    private static let poundsPerKilogram      = 2.204_622_621_85
    private static let inchesPerCentimeter    = 0.393_700_787_4
    private static let feetPerMeter           = 3.280_839_895

    private static let kilometersPerMile      = 1.609_344
    private static let metersPerYard          = 0.914_4

    // MARK: Weight

    /// Converts kilograms → pounds.
    public static func kgToLb(_ kg: Double,
                              roundedTo decimals: Int = 2) -> Double {
        ((kg * poundsPerKilogram) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    /// Converts pounds → kilograms.
    public static func lbToKg(_ lb: Double,
                              roundedTo decimals: Int = 2) -> Double {
        ((lb / poundsPerKilogram) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    // MARK: Length

    /// Converts centimeters → inches.
    public static func cmToIn(_ cm: Double,
                              roundedTo decimals: Int = 2) -> Double {
        ((cm * inchesPerCentimeter) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    /// Converts inches → centimeters.
    public static func inToCm(_ inches: Double,
                              roundedTo decimals: Int = 2) -> Double {
        ((inches / inchesPerCentimeter) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    /// Converts meters → feet.
    public static func mToFt(_ meters: Double,
                             roundedTo decimals: Int = 2) -> Double {
        ((meters * feetPerMeter) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    /// Converts feet → meters.
    public static func ftToM(_ feet: Double,
                             roundedTo decimals: Int = 2) -> Double {
        ((feet / feetPerMeter) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    // MARK: Distance

    /// Converts miles → kilometres.
    public static func miToKm(_ miles: Double,
                              roundedTo decimals: Int = 2) -> Double {
        ((miles * kilometersPerMile) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    /// Converts kilometres → miles.
    public static func kmToMi(_ km: Double,
                              roundedTo decimals: Int = 2) -> Double {
        ((km / kilometersPerMile) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    /// Converts yards → metres.
    public static func ydToM(_ yards: Double,
                             roundedTo decimals: Int = 2) -> Double {
        ((yards * metersPerYard) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }

    /// Converts metres → yards.
    public static func mToYd(_ meters: Double,
                             roundedTo decimals: Int = 2) -> Double {
        ((meters / metersPerYard) * pow(10, Double(decimals)))
            .rounded() / pow(10, Double(decimals))
    }
}
