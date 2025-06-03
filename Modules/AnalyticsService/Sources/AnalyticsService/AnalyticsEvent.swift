//
//  AnalyticsEvent.swift
//  AnalyticsService
//
//  Type-safe analytics payloads that can be encoded, queued, and shipped
//  to any backend.  Inspired by best-practice wrappers that decouple view
//  code from third-party SDK strings.  [oai_citation:0‡Medium](https://medium.com/better-programming/design-an-analytics-or-event-tracking-manager-for-an-ios-app-75979e7144ee?utm_source=chatgpt.com) [oai_citation:1‡Mixpanel](https://mixpanel.com/blog/how-to-add-analytics-event-tracking-in-swiftui-the-elegant-way/?utm_source=chatgpt.com) [oai_citation:2‡Chris Eidhof](https://chris.eidhof.nl/post/swift-analytics/?utm_source=chatgpt.com)
//
//  Design notes
//  ─────────────
//  • Pure Swift struct/enum — no SDK imports, no UIKit/SwiftUI.
//  • `Codable` & `Hashable` via custom synthesis so associated-value
//    enums round-trip through JSON.  [oai_citation:3‡Nil Coalescing](https://nilcoalescing.com/blog/CodableConformanceForSwiftEnums?utm_source=chatgpt.com) [oai_citation:4‡Stack Overflow](https://stackoverflow.com/questions/44580719/how-do-i-make-an-enum-decodable-in-swift?utm_source=chatgpt.com) [oai_citation:5‡Swift by Sundell](https://www.swiftbysundell.com/articles/codable-synthesis-for-swift-enums?utm_source=chatgpt.com)
//  • No HRV, recovery, or bar-velocity metrics are captured.
//  • Add / deprecate cases via semantic versioning to avoid breaking the
//    ingest pipeline.  [oai_citation:6‡Segment](https://segment.com/docs/connections/sources/catalog/libraries/mobile/apple/implementation/?utm_source=chatgpt.com)
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Domain   // RPE, Exercise IDs, etc.

// MARK: - AnalyticsEvent

/// Finite set of events Gainz records.  Extend cautiously; removing or
/// renaming a case is a breaking change for consumers downstream.
public enum AnalyticsEvent: Hashable, Codable {

    // App-level lifecycle
    case appOpened                      // cold launch
    case appBackgrounded(time: TimeInterval)

    // Onboarding / settings
    case onboardingCompleted(userId: UUID)
    case darkModeToggled(isOn: Bool)

    // Planner & training flow
    case workoutSessionStarted(sessionId: UUID, date: Date)
    case workoutSessionEnded(sessionId: UUID, duration: TimeInterval)

    case exerciseLogged(
        exerciseId: UUID,
        reps: Int,
        weight: Double,
        rpe: RPE
    )

    // Error & diagnostics
    case errorLogged(code: String, message: String)

    // MARK: Coding Keys

    private enum CodingKeys: String, CodingKey {
        case caseId
        case payload
    }

    // MARK: Codable

    /// Encodes the enum w/ associated data as `{ "caseId": "exerciseLogged",
    /// "payload": { ... } }`.  Pattern mirrors Segment & Mixpanel guides.  [oai_citation:7‡Segment](https://segment.com/docs/connections/sources/catalog/libraries/mobile/apple/implementation/?utm_source=chatgpt.com) [oai_citation:8‡Intro to iOS Development](https://ios-course.cornellappdev.com/chapters/debugging/analytics?utm_source=chatgpt.com)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .appOpened:
            try container.encode("appOpened", forKey: .caseId)

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
            try container.encode(
                ["sessionId": id, "duration": duration],
                forKey: .payload
            )

        case .exerciseLogged(let eId, let reps, let weight, let rpe):
            try container.encode("exerciseLogged", forKey: .caseId)
            try container.encode(
                ["exerciseId": eId,
                 "reps": reps,
                 "weight": weight,
                 "rpe": rpe.rawValue],
                forKey: .payload
            )

        case .errorLogged(let code, let message):
            try container.encode("errorLogged", forKey: .caseId)
            try container.encode(
                ["code": code, "message": message],
                forKey: .payload
            )
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId    = try container.decode(String.self, forKey: .caseId)

        switch caseId {
        case "appOpened":
            self = .appOpened

        case "appBackgrounded":
            let pay = try container.decode([String: TimeInterval].self,
                                           forKey: .payload)
            self = .appBackgrounded(time: pay["time"] ?? 0)

        case "onboardingCompleted":
            let pay = try container.decode([String: UUID].self,
                                           forKey: .payload)
            self = .onboardingCompleted(userId: pay["userId"]!)

        case "darkModeToggled":
            let pay = try container.decode([String: Bool].self,
                                           forKey: .payload)
            self = .darkModeToggled(isOn: pay["isOn"] ?? false)

        case "workoutSessionStarted":
            let pay = try container.decode([String: DateCodableValue].self,
                                           forKey: .payload)
            self = .workoutSessionStarted(
                sessionId: pay["sessionId"]!.uuid,
                date: pay["date"]!.date
            )

        case "workoutSessionEnded":
            let pay = try container.decode([String: DoubleCodableValue].self,
                                           forKey: .payload)
            self = .workoutSessionEnded(
                sessionId: pay["sessionId"]!.uuid,
                duration: pay["duration"]!.double
            )

        case "exerciseLogged":
            let pay = try container.decode([String: ExercisePayload].self,
                                           forKey: .payload)
            let p   = pay["exerciseId"]!
            self = .exerciseLogged(
                exerciseId: p.id,
                reps: p.reps,
                weight: p.weight,
                rpe: p.rpe
            )

        case "errorLogged":
            let pay = try container.decode([String: String].self,
                                           forKey: .payload)
            self = .errorLogged(
                code: pay["code"] ?? "unknown",
                message: pay["message"] ?? ""
            )

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .caseId,
                in: container,
                debugDescription: "Unknown AnalyticsEvent case '\(caseId)'"
            )
        }
    }
}

// MARK: - Helper Codable wrappers

/// Lightweight wrappers so we can map heterogeneous JSON payloads
/// without a giant struct per case.  [oai_citation:9‡SketchyTech](https://sketchytech.blogspot.com/2018/08/swift-codable-encounters-of-enum-kind.html?utm_source=chatgpt.com) [oai_citation:10‡Natan Rolnik's blog](https://blog.natanrolnik.me/codable-enums-associated-values?utm_source=chatgpt.com)
private struct DateCodableValue: Codable { let uuid: UUID; let date: Date
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let d = try c.decode([String: String].self)
        uuid = UUID(uuidString: d["sessionId"] ?? "") ?? UUID()
        date = ISO8601DateFormatter().date(from: d["date"] ?? "") ?? .init()
    }
}
private struct DoubleCodableValue: Codable { let uuid: UUID; let double: Double
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let d = try c.decode([String: String].self)
        uuid   = UUID(uuidString: d["sessionId"] ?? "") ?? UUID()
        double = Double(d["duration"] ?? "") ?? 0
    }
}
private struct ExercisePayload: Codable {
    let id: UUID; let reps: Int; let weight: Double; let rpe: RPE
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
