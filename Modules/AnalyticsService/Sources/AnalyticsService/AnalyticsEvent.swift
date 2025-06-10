//  AnalyticsEvent.swift
//  AnalyticsService
//
//  Type-safe analytics event definitions for telemetry. Each case carries strongly-typed
//  payload data and can be encoded to JSON for buffering or network transmission.
//
//  Design notes
//  ─────────────
//  • Pure Swift struct/enum — no third-party SDK or UI framework dependencies.
//  • Encoded as `{ "caseId": <eventName>, "payload": { ... } }` for interoperability.
//  • Custom Codable conformance ensures associated values round-trip through JSON.
//  • No HRV, recovery-score, or bar-velocity metrics are ever captured.
//  • Extend cautiously; adding cases is fine, but removing or renaming breaks decoding.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Domain   // Types like RPE, exercise identifiers, etc.

// MARK: - AnalyticsEvent

/// Finite set of analytics events that Gainz records. Extend this enum cautiously.
/// Removing or renaming a case is a breaking change for downstream consumers.
public enum AnalyticsEvent: Hashable, Codable {

    // App-level lifecycle
    case appOpened                             // App cold launch (no payload)
    case appBackgrounded(time: TimeInterval)   // Moved to background; duration since open

    // Onboarding / settings
    case onboardingCompleted(userId: UUID)     // User finished onboarding (user identifier)
    case darkModeToggled(isOn: Bool)           // User toggled dark mode setting

    // Planner & training flow
    case workoutSessionStarted(sessionId: UUID, date: Date)
    case workoutSessionEnded(sessionId: UUID, duration: TimeInterval)
    case exerciseLogged(exerciseId: UUID, reps: Int, weight: Double, rpe: RPE)

    // Error & diagnostics
    case errorLogged(code: String, message: String)

    // MARK: Coding Keys

    private enum CodingKeys: String, CodingKey {
        case caseId
        case payload
    }

    // MARK: Encodable

    /// Custom encoding to JSON with a `caseId` and typed `payload`.
    /// Example output: `{ "caseId": "exerciseLogged", "payload": { ... } }`
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .appOpened:
            try container.encode("appOpened", forKey: .caseId)
            // No payload for appOpened.

        case .appBackgrounded(let time):
            try container.encode("appBackgrounded", forKey: .caseId)
            try container.encode(["time": time], forKey: .payload)

        case .onboardingCompleted(let userId):
            try container.encode("onboardingCompleted", forKey: .caseId)
            try container.encode(["userId": userId], forKey: .payload)

        case .darkModeToggled(let isOn):
            try container.encode("darkModeToggled", forKey: .caseId)
            try container.encode(["isOn": isOn], forKey: .payload)

        case .workoutSessionStarted(let id, let date):
            try container.encode("workoutSessionStarted", forKey: .caseId)
            try container.encode(["sessionId": id, "date": date], forKey: .payload)

        case .workoutSessionEnded(let id, let duration):
            try container.encode("workoutSessionEnded", forKey: .caseId)
            try container.encode(["sessionId": id, "duration": duration], forKey: .payload)

        case .exerciseLogged(let eId, let reps, let weight, let rpe):
            try container.encode("exerciseLogged", forKey: .caseId)
            // Encode RPE via its raw value or codable representation
            try container.encode(["exerciseId": eId,
                                   "reps": reps,
                                   "weight": weight,
                                   "rpe": rpe], forKey: .payload)

        case .errorLogged(let code, let message):
            try container.encode("errorLogged", forKey: .caseId)
            try container.encode(["code": code, "message": message], forKey: .payload)
        }
    }

    // MARK: Decodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(String.self, forKey: .caseId)

        switch caseId {
        case "appOpened":
            self = .appOpened

        case "appBackgrounded":
            let payload = try container.decode([String: TimeInterval].self, forKey: .payload)
            // Default to 0 if key missing (should not happen in well-formed data)
            let time = payload["time"] ?? 0
            self = .appBackgrounded(time: time)

        case "onboardingCompleted":
            let payload = try container.decode([String: UUID].self, forKey: .payload)
            guard let uid = payload["userId"] else {
                throw DecodingError.dataCorruptedError(
                    forKey: .payload, in: container,
                    debugDescription: "Missing userId in onboardingCompleted payload"
                )
            }
            self = .onboardingCompleted(userId: uid)

        case "darkModeToggled":
            let payload = try container.decode([String: Bool].self, forKey: .payload)
            let isOn = payload["isOn"] ?? false
            self = .darkModeToggled(isOn: isOn)

        case "workoutSessionStarted":
            // Decode into a structured payload (expects sessionId and date)
            let p = try container.decode(SessionStartedPayload.self, forKey: .payload)
            self = .workoutSessionStarted(sessionId: p.sessionId, date: p.date)

        case "workoutSessionEnded":
            let p = try container.decode(SessionEndedPayload.self, forKey: .payload)
            self = .workoutSessionEnded(sessionId: p.sessionId, duration: p.duration)

        case "exerciseLogged":
            let p = try container.decode(ExerciseLoggedPayload.self, forKey: .payload)
            self = .exerciseLogged(
                exerciseId: p.exerciseId,
                reps: p.reps,
                weight: p.weight,
                rpe: p.rpe
            )

        case "errorLogged":
            let payload = try container.decode([String: String].self, forKey: .payload)
            let code = payload["code"] ?? "unknown"
            let message = payload["message"] ?? ""
            self = .errorLogged(code: code, message: message)

        default:
            // Unknown caseId – data is likely from a newer app version or corrupt.
            throw DecodingError.dataCorruptedError(
                forKey: .caseId, in: container,
                debugDescription: "Unrecognized AnalyticsEvent case '\(caseId)'"
            )
        }
    }

    // MARK: - Associated Value Payloads (for decoding convenience)

    private struct SessionStartedPayload: Codable {
        let sessionId: UUID
        let date: Date
    }
    private struct SessionEndedPayload: Codable {
        let sessionId: UUID
        let duration: TimeInterval
    }
    private struct ExerciseLoggedPayload: Codable {
        let exerciseId: UUID
        let reps: Int
        let weight: Double
        let rpe: RPE
    }
}

 // MARK: - Preview stub (non-App targets)

#if DEBUG && !os(watchOS)
import XCTest
struct AnalyticsEvent_Preview {
    static let samples: [AnalyticsEvent] = [
        .appOpened,
        .exerciseLogged(
            exerciseId: UUID(),
            reps: 5,
            weight: 100,
            rpe: .eight
        )
    ]
}
#endif
