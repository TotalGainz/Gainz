//
//  MesocyclePlan.swift
//  Domain – Models
//
//  Immutable blueprint for a 4-to-6-week hypertrophy-biased block.
//  Built on Clean-Architecture guidelines (MVVM / Domain layer) and
//  literature-backed periodisation theory.
//
//  ───── References ─────
//  Mesocycle fundamentals :contentReference[oaicite:0]{index=0}
/*  Clean architecture & Swift domain modelling
    – Apple Swift Tour :contentReference[oaicite:1]{index=1}
    – Swift immutability & Sendable :contentReference[oaicite:2]{index=2}
    – MVVM-Clean patterns in iOS :contentReference[oaicite:3]{index=3}
*/
import Foundation

// MARK: - MesocyclePlan

/// A periodised training block with a clear objective (hypertrophy, strength, peaking).
///
/// The plan is composed of sequential `WeekPlan`s; each week owns its `DayPlan`s.
/// • Pure value type, Sendable & Codable → safe across concurrency domains.
/// • No HRV, recovery, or bar-speed parameters—volume & effort only.
///
public struct MesocyclePlan: Identifiable, Hashable, Codable, Sendable {

    // MARK: Core Fields
    public let id: UUID
    public let objective: Objective
    public let startDate: Date
    public let weeks: [WeekPlan]
    public let notes: String?

    // MARK: Derived
    public var lengthInWeeks: Int { weeks.count }

    public var endDate: Date {
        guard
            let lastDay = weeks.last?.days.last,
            let finalDate = Calendar.current.date(byAdding: .day,
                                                  value: weeks.count * 7 - 1,
                                                  to: startDate)
        else { return startDate }
        return max(finalDate, lastDay.date)
    }

    /// Aggregate weekly volume (kg•reps) across the whole mesocycle.
    public var totalVolume: Double {
        weeks.reduce(0) { $0 + $1.totalVolume }
    }

    // MARK: Init
    public init(
        id: UUID = .init(),
        objective: Objective,
        startDate: Date = .init(),
        weeks: [WeekPlan],
        notes: String? = nil
    ) {
        precondition((4...6).contains(weeks.count),
                     "Mesocycle must be 4–6 weeks long.")
        self.id = id
        self.objective = objective
        self.startDate = startDate
        self.weeks = weeks
        self.notes = notes
    }
}

// MARK: - Objective
public enum Objective: String, Codable, CaseIterable {
    case hypertrophy
    case strength
    case peaking
    case deload
}

// MARK: - WeekPlan
public struct WeekPlan: Hashable, Codable, Sendable {

    public let index: Int          // 1-based within the mesocycle
    public let days: [DayPlan]

    public var totalVolume: Double {
        days.reduce(0) { $0 + $1.totalVolume }
    }

    public init(index: Int, days: [DayPlan]) {
        precondition(!days.isEmpty && days.count <= 7,
                     "Week must have 1-7 training days.")
        self.index = index
        self.days = days
    }
}

// MARK: - DayPlan
public struct DayPlan: Hashable, Codable, Sendable {

    public struct ExercisePrescription: Hashable, Codable, Sendable {
        public let exerciseId: UUID
        public let sets: Int
        public let reps: Int
        public let rirTarget: Int
        public let load: Double     // Suggested starting weight (kg)

        public var setVolume: Double { Double(sets * reps) * load }
    }

    public let date: Date
    public let focusMuscleGroups: Set<MuscleGroup>
    public let prescriptions: [ExercisePrescription]

    public var totalVolume: Double {
        prescriptions.reduce(0) { $0 + $1.setVolume }
    }
}
