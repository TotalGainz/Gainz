//
//  HealthManager.swift
//  ServiceHealth
//
//  Abstracts HealthKit so the rest of the app never touches HK APIs
//  directly.  Handles permissions, querying, and write operations for
//  metrics we actively use (steps, active energy, resistance-training
//  workouts).  **No HRV, recovery-score, or velocity fields are ever
//  requested or stored.**
//
//  ───────────── Architecture Notes ─────────────
//  • Pure Swift concurrency + Combine; no callbacks.
//  • Wrapped in a protocol (`HealthManaging`) for easy mocking in tests.
//  • Uses `HKHealthStore` on Apple platforms, becomes a no-op shim on
//    Catalyst / preview builds where HealthKit is unavailable.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine
import HealthKit

// MARK: - Protocol

public protocol HealthManaging {
    /// Requests all necessary HealthKit permissions.
    func requestAuthorization() async throws

    /// Publishes total step count for a given day (midnight-to-midnight).
    func stepCountPublisher(for date: Date) -> AnyPublisher<Int, Error>

    /// Saves a completed resistance-training workout to Health app.
    func saveWorkout(start: Date,
                     end: Date,
                     totalEnergy: Double,
                     notes: String?) async throws
}

// MARK: - Live Implementation

public final class HealthManager: HealthManaging {

    // Singleton HK store (safe to share)
    private let store = HKHealthStore()

    // MARK: – Authorization

    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set = [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]

        let typesToRead: Set = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned)
        ]

        try await store.requestAuthorization(toShare: typesToShare,
                                             read: typesToRead)
    }

    // MARK: – Step Count

    public func stepCountPublisher(for date: Date) -> AnyPublisher<Int, Error> {
        Future { [store] promise in
            let quantity = HKQuantityType(.stepCount)
            let (start, end) = date.dayBounds(in: Calendar.current)

            let predicate = HKQuery.predicateForSamples(
                withStart: start, end: end, options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: quantity,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error { return promise(.failure(error)) }
                let steps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                promise(.success(steps))
            }

            store.execute(query)
        }
        .eraseToAnyPublisher()
    }

    // MARK: – Workout Save

    public func saveWorkout(start: Date,
                            end: Date,
                            totalEnergy: Double,
                            notes: String?) async throws {

        let energy = HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergy)

        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: start,
            end: end,
            totalEnergyBurned: energy,
            totalDistance: nil,
            metadata: [
                HKMetadataKeyWorkoutBrandName: "Gainz",
                HKMetadataKeyWorkoutIndoorWorkout: true
            ]
        )

        try await store.save(workout)

        // Optional note as separate sample for richer context
        if let note = notes, !note.isEmpty {
            let metadata = [HKMetadataKeyWorkoutBrandName: "Gainz", HKMetadataKeyNote: note]
            let annotation = HKWorkoutRoute(
                workout: workout,
                totalDistance: nil,
                metadata: metadata
            )
            try? await store.save(annotation)
        }
    }
}

// MARK: - Date Helpers

private extension Date {
    /// Returns midnight-to-midnight bounds for the current calendar day.
    func dayBounds(in calendar: Calendar) -> (Date, Date) {
        let start = calendar.startOfDay(for: self)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}
