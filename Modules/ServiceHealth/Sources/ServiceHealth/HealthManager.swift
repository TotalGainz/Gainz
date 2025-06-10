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
#if canImport(HealthKit)
import HealthKit
#endif

// MARK: - Protocol

/// Abstraction for health data interactions. Allows the app to request permissions, query data, and save workouts without directly depending on HealthKit.
/// - Note: Having a protocol makes it easy to provide a mock or dummy implementation for testing or platforms where HealthKit is not available.
public protocol HealthManaging {
    /// Requests all necessary HealthKit permissions from the user.
    /// - Throws: An error if authorization fails (for example, if HealthKit is not available or permission was denied).
    func requestAuthorization() async throws

    /// Publishes the total step count for a given day (midnight to midnight).
    /// - Parameter date: The day for which to retrieve the step count total.
    /// - Returns: A Combine publisher that will emit the total number of steps taken during that day, or an error.
    func stepCountPublisher(for date: Date) -> AnyPublisher<Int, Error>

    /// Saves a completed resistance-training workout to the Health app's database.
    /// - Parameters:
    ///   - start: Start time of the workout.
    ///   - end: End time of the workout.
    ///   - totalEnergy: Total active energy burned during the workout (in kilocalories).
    ///   - notes: Optional user notes about the workout (e.g., comments on performance).
    /// - Throws: An error if the workout could not be saved to HealthKit.
    func saveWorkout(start: Date,
                     end: Date,
                     totalEnergy: Double,
                     notes: String?) async throws
}

#if canImport(HealthKit)
// MARK: - Live Implementation (using HealthKit)

/// The live implementation of `HealthManaging` that interacts with HealthKit.
public final class HealthManager: HealthManaging {

    /// Shared HealthKit store instance (thread-safe to share across queries).
    private let store = HKHealthStore()

    // MARK: – Authorization

    /// Requests permission from the user to read and write the health data types used by Gainz.
    /// This includes read access for step count and active energy, and write access for workouts and active energy.
    /// - Throws: An error if HealthKit data is not available or the authorization prompt fails.
    public func requestAuthorization() async throws {
        // If HealthKit is not available on this device (e.g., iPad without Health app or Mac), skip requesting.
        guard HKHealthStore.isHealthDataAvailable() else {
            return  // No-op if health data is not available on this platform.
        }

        // Define the data types the app needs permission to write to HealthKit.
        let typesToShare: Set = [
            HKObjectType.workoutType(),                        // to save workouts
            HKQuantityType(.activeEnergyBurned)                // to log active energy burned
        ]

        // Define the data types the app needs permission to read from HealthKit.
        let typesToRead: Set = [
            HKQuantityType(.stepCount),                        // to read step count data
            HKQuantityType(.activeEnergyBurned)                // to read active energy data
        ]

        // Request authorization for the specified read/write types.
        try await store.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    // MARK: – Step Count

    /// Creates a publisher that will emit the total number of steps for the specified date.
    /// - Parameter date: The date for which to fetch the step count (counts from 00:00 to 23:59 of that day).
    /// - Returns: An `AnyPublisher<Int, Error>` that will publish the step count total. The publisher completes after emitting.
    /// - Note: This uses a `HKStatisticsQuery` to sum all step samples for the day. Combine's `Future` is used to bridge the async result.
    public func stepCountPublisher(for date: Date) -> AnyPublisher<Int, Error> {
        // Use a Combine Future to perform the HealthKit query asynchronously.
        return Future { [store] promise in
            let quantityType = HKQuantityType(.stepCount)
            // Calculate the start and end of the given day using the current calendar.
            let (start, end) = date.dayBounds(in: Calendar.current)

            // Create a predicate for samples within that day.
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

            // Set up a statistics query to sum the step count samples in the given time range.
            let query = HKStatisticsQuery(quantityType: quantityType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, stats, error in
                if let error = error {
                    // If there's an error (e.g., not authorized), forward it to the publisher.
                    return promise(.failure(error))
                }
                // Extract the sum of steps. If stats is nil or no data, default to 0.
                let steps = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                promise(.success(steps))
            }

            // Execute the query on HealthKit.
            store.execute(query)
        }
        .eraseToAnyPublisher()
    }

    // MARK: – Workout Save

    /// Saves a completed strength training workout to HealthKit, including an optional textual note.
    /// - Parameters:
    ///   - start: The start time of the workout session.
    ///   - end: The end time of the workout session.
    ///   - totalEnergy: Total active energy burned (in kilocalories) during the workout.
    ///   - notes: An optional note or comment about the workout.
    /// - Throws: An error if the workout or associated data could not be saved.
    public func saveWorkout(start: Date,
                            end: Date,
                            totalEnergy: Double,
                            notes: String?) async throws {

        // Create a quantity for the energy burned using kilocalories as the unit.
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergy)

        // Construct a workout sample for resistance training (strength training).
        let workout = HKWorkout(activityType: .traditionalStrengthTraining,
                                start: start,
                                end: end,
                                totalEnergyBurned: energyQuantity,
                                totalDistance: nil,
                                metadata: [
                                    HKMetadataKeyWorkoutBrandName: "Gainz",
                                    HKMetadataKeyWorkoutIndoorWorkout: true
                                ])

        // Save the workout to the HealthKit store.
        try await store.save(workout)

        // If the user provided notes, save them as metadata in a related sample.
        if let note = notes, !note.isEmpty {
            // Prepare metadata for the note, tagging it with the same brand name.
            let noteMetadata: [String: Any] = [
                HKMetadataKeyWorkoutBrandName: "Gainz",
                HKMetadataKeyNote: note
            ]
            // Use an HKWorkoutRoute (normally used for GPS routes) to attach the note as metadata.
            let noteSample = HKWorkoutRoute(workout: workout,
                                            totalDistance: nil,
                                            metadata: noteMetadata)
            // Try saving the note sample; if it fails, we ignore the error since the workout itself was saved successfully.
            try? await store.save(noteSample)
        }
    }
}
#else
// MARK: - No-Op Implementation (for platforms without HealthKit)

/// A fallback implementation of `HealthManaging` that performs no operations, for use on platforms where HealthKit is unavailable.
public final class HealthManager: HealthManaging {

    public func requestAuthorization() async throws {
        // HealthKit not available: nothing to request. Simply return without error.
        return
    }

    public func stepCountPublisher(for date: Date) -> AnyPublisher<Int, Error> {
        // HealthKit not available: publish 0 steps (since actual data is inaccessible).
        return Just(0).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    public func saveWorkout(start: Date,
                            end: Date,
                            totalEnergy: Double,
                            notes: String?) async throws {
        // HealthKit not available: simply do nothing (workout is not saved anywhere).
        return
    }
}
#endif

// MARK: - Date Helpers

private extension Date {
    /// Returns the start and end of the day (midnight to midnight) for this date in the given calendar.
    func dayBounds(in calendar: Calendar) -> (Date, Date) {
        let startOfDay = calendar.startOfDay(for: self)
        // Adding one day to the start gives the end boundary (next day's midnight).
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return (startOfDay, endOfDay)
    }
}
