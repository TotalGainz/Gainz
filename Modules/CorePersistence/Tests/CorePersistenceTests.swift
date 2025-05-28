//
//  CorePersistenceTests.swift
//  Gainz – CorePersistence
//
//  Integration-level tests that validate CoreDataStack boot-straps,
//  imports seed exercises, and performs CRUD round-trips for Domain models.
//  Uses an *in-memory* NSPersistentContainer so tests run fast and leave
//  no artefacts on disk.
//
//  Created on 27 May 2025.
//

import XCTest
import Combine
@testable import CorePersistence
@testable import Domain   // Domain models for equality checks

final class CorePersistenceTests: XCTestCase {

    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var stack: CoreDataStack!
    private var db: DatabaseManager!

    // MARK: - Setup / Teardown
    override func setUpWithError() throws {
        try super.setUpWithError()

        // In-memory container so each test starts fresh.
        stack = try CoreDataStack(modelName: "Gainz", storeType: .inMemory)
        db    = DatabaseManager(stack: stack)

        // Seed exercises.json synchronously for deterministic tests.
        try db.seedInitialDataIfNeeded(bundle: .module)   // .module resolves to test bundle
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        stack = nil
        db    = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests

    /// Verifies that seed data is imported exactly once and all exercises exist.
    func testSeedDataImport_createsExercises() throws {
        // Given
        let initialCount = try db.exerciseCount()

        // When  – call seeding again (should be idempotent)
        try db.seedInitialDataIfNeeded(bundle: .module)
        let secondCount = try db.exerciseCount()

        // Then
        XCTAssertGreaterThan(initialCount, 0, "Seed import should create >0 exercises")
        XCTAssertEqual(initialCount, secondCount,
                       "Re-running seeder must not create duplicates")
    }

    /// Round-trip CRUD for a single Exercise entity.
    func testExerciseCRUD_roundTrip() throws {
        // Given
        let bench = Exercise(name: "Test Bench",
                             primaryMuscles: [.chest],
                             mechanicalPattern: .horizontalPush,
                             equipment: .barbell)

        // When – Create
        try db.saveExercise(bench)
        var fetched = try db.fetchExercise(id: bench.id)

        // Then – Verify create
        XCTAssertEqual(fetched?.name, bench.name)

        // When – Update
        let renamed = Exercise(id: bench.id,
                               name: "Renamed Bench",
                               primaryMuscles: bench.primaryMuscles,
                               secondaryMuscles: bench.secondaryMuscles,
                               mechanicalPattern: bench.mechanicalPattern,
                               equipment: bench.equipment)
        try db.saveExercise(renamed)
        fetched = try db.fetchExercise(id: bench.id)

        // Then – Verify update
        XCTAssertEqual(fetched?.name, "Renamed Bench")

        // When – Delete
        try db.deleteExercise(id: bench.id)
        fetched = try db.fetchExercise(id: bench.id)

        // Then – Verify delete
        XCTAssertNil(fetched, "Exercise should be nil after deletion")
    }

    /// Asserts that WorkoutSession persistence keeps referential integrity
    /// with its ExerciseLogs and SetRecords.
    func testWorkoutSession_persistsWithCascade() throws {
        // Given – make dummy exercise
        let squat = Exercise(name: "In-Memory Squat",
                             primaryMuscles: [.quads],
                             mechanicalPattern: .squat,
                             equipment: .barbell)
        try db.saveExercise(squat)

        // Build Session
        let set = SetRecord(id: .init(),
                            weight: 100,
                            reps: 8,
                            rpe: .eight)
        let log = ExerciseLog(id: .init(),
                              exerciseId: squat.id,
                              sets: [set])
        let session = WorkoutSession(id: .init(),
                                     date: Date(),
                                     exerciseLogs: [log])

        // When – Save session
        try db.saveWorkoutSession(session)

        // Then – Fetch & assert
        let fetched = try db.fetchWorkoutSession(id: session.id)
        XCTAssertEqual(fetched?.exerciseLogs.first?.sets.first?.weight, 100)

        // When – Delete session
        try db.deleteWorkoutSession(id: session.id)

        // Then – cascading delete should remove child objects
        let orphanLog = try db.fetchExerciseLog(id: log.id)
        XCTAssertNil(orphanLog, "Cascade delete failed – ExerciseLog still exists")
    }
}
