/// MuscleGroup.swift

import Foundation

/// Enumerates all major skeletal muscle groups relevant for training programs.
public enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    // MARK: Upper Body
    case chest
    case upperBack       // e.g. mid-trap, rhomboids
    case lats
    case traps
    case frontDelts
    case lateralDelts
    case rearDelts
    case biceps
    case triceps
    case forearms

    // MARK: Core
    case abs
    case obliques
    case lowerBack

    // MARK: Lower Body
    case glutes
    case quads
    case hamstrings
    case calves
    case hipAdductors    // inner thigh (groin)
    case hipAbductors    // outer thigh (glute med/min)

    // MARK: Helper Properties

    /// Returns `true` if this muscle group is above the pelvis (upper body).
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

    /// A human-readable display name for UI.
    public var displayName: String {
        switch self {
        case .upperBack:    return "Upper Back"
        case .frontDelts:   return "Front Delts"
        case .lateralDelts: return "Lateral Delts"
        case .rearDelts:    return "Rear Delts"
        case .hipAdductors: return "Hip Adductors"
        case .hipAbductors: return "Hip Abductors"
        default:
            // Capitalize other cases (e.g., "abs" -> "Abs")
            return self.rawValue.capitalized
        }
    }
}
