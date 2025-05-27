// PreviewData.swift
// Gainz ▸ Static fixtures for SwiftUI previews & Playgrounds
// Generated: 2025‑05‑27

import Foundation
@testable import Domain

// MARK: ‑ Exercises
extension Exercise {
    static let benchPress = Exercise(
        id: UUID(uuidString: "11111111‑2222‑3333‑4444‑555555555555")!,
        name: "Barbell Bench Press",
        primaryMuscle: .chest,
        equipment: .barbell,
        metric: .weightReps
    )

    static let squat = Exercise(
        id: UUID(uuidString: "aaaaaaaa‑bbbb‑cccc‑dddd‑eeeeeeeeeeee")!,
        name: "Back Squat",
        primaryMuscle: .quadriceps,
        equipment: .barbell,
        metric: .weightReps
    )

    static let pullUp = Exercise(
        id: UUID(uuidString: "99999999‑8888‑7777‑6666‑555555555555")!,
        name: "Weighted Pull‑Up",
        primaryMuscle: .lats,
        equipment: .bodyweight,
        metric: .weightReps
    )
}

// MARK: ‑ SetLogs
extension SetLog {
    static func make(weight: Double, reps: Int, rpe: Double) -> SetLog {
        .init(
            id: UUID(),
            weight: weight,
            reps: reps,
            rpe: rpe,
            timestamp: Date()
        )
    }
}

// MARK: ‑ ExerciseLog
extension ExerciseLog {
    static func sample(_ exercise: Exercise) -> ExerciseLog {
        .init(
            exercise: exercise,
            sets: [
                .make(weight: 100, reps: 8, rpe: 7.5),
                .make(weight: 100, reps: 8, rpe: 8),
                .make(weight: 90, reps: 10, rpe: 8.5)
            ],
            notes: "Felt solid form, minimal fatigue"
        )
    }
}

// MARK: ‑ WorkoutSession
extension WorkoutSession {
    static let chestDay = WorkoutSession(
        id: UUID(uuidString: "0F0F0F0F‑0F0F‑0F0F‑0F0F‑0F0F0F0F0F0F")!,
        date: Date(),
        title: "Chest Hypertrophy A",
        exerciseLogs: [
            .sample(.benchPress),
            .sample(.pullUp)
        ],
        duration: 62 * 60,
        perceivedExertion: 8,
        notes: "Great pump; keep same weight next week."
    )
}

// MARK: ‑ MesocyclePlan
extension MesocyclePlan {
    static let hypertrophy = MesocyclePlan(
        id: UUID(uuidString: "12345678‑1234‑1234‑1234‑123456789012")!,
        startDate: Calendar.current.startOfDay(for: Date()),
        weeks: 4,
        split: .pushPullLegs,
        progressionModel: .linear,
        sessions: [
            WorkoutSession.chestDay
        ],
        goalDescription: "8‑week hypertrophy focussed block",
        createdAt: Date()
    )
}

// MARK: ‑ PreviewProvider Bridge
#if DEBUG
struct PreviewData {
    static let session = WorkoutSession.chestDay
    static let plan = MesocyclePlan.hypertrophy
}
#endif