//
//  MuscleGroup.swift
//  Domain – Models
//
//  Canonical taxonomy of skeletal muscle groups used across the Domain layer.
//
//  ❖ Design Rules
//  • Platform-agnostic (Foundation-only).
//  • Raw values are kebab-case strings for stable JSON keys.
//  • No hierarchy or overlap—each group is mutually exclusive.
//  • Codable + CaseIterable for easy persistence and UI enumeration.
//
//  Created for Gainz by the Core Domain team on 27 May 2025.
//

import Foundation

/// Enumerates every primary muscle group recognised by Gainz.
///
/// The list is designed for hypertrophy programming flexibility while remaining
/// concise enough for analytics aggregation.
///
/// Extend with caution—adding a new case is fine; renaming or removing breaks
/// compatibility with historical logs.
public enum MuscleGroup: String, Codable, CaseIterable, Hashable, Sendable {

    // MARK: – Upper Body
    case chest
    case upperBack       // mid-trap, rhomboids
    case lats
    case traps
    case frontDelts
    case lateralDelts
    case rearDelts
    case biceps
    case triceps
    case forearms

    // MARK: – Core
    case abs
    case obliques
    case lowerBack

    // MARK: – Lower Body
    case glutes
    case quads
    case hamstrings
    case calves
    case hipAdductors    // groin
    case hipAbductors    // glute med / minimus

    // MARK: – Helper Flags

    /// `true` if the muscle sits above the pelvis.
    public var isUpperBody: Bool {
        switch self {
        case .chest, .upperBack, .lats, .traps,
             .frontDelts, .lateralDelts, .rearDelts,
             .biceps, .triceps, .forearms:
            return true
        default:
            return false
        }
    }

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .upperBack:     return "Upper Back"
        case .frontDelts:    return "Front Delts"
        case .lateralDelts:  return "Lateral Delts"
        case .rearDelts:     return "Rear Delts"
        case .hipAdductors:  return "Hip Adductors"
        case .hipAbductors:  return "Hip Abductors"
        default:             return rawValue.capitalized
        }
    }
}
