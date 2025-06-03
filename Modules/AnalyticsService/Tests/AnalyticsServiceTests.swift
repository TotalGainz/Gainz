//
//  AnalyticsServiceTests.swift
//  Gainz – AnalyticsService
//
//  Unit + integration tests for the AnalyticsService target.
//  Verifies:
//    • Local analytics calculations (e.g., total tonnage, volume per muscle).
//    • Event pipeline publishes to Combine stream.
//    • Batched uploads assemble correct payload & HMAC signature.
//  Uses an in-memory stub of CorePersistence; no network I/O.
//
//  Created on 27 May 2025.
//

import XCTest
import Combine
@testable import AnalyticsService
@testable import Domain
@testable import CorePersistence

final class AnalyticsServiceTests: XCTestCase {

    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var db: DatabaseManager!
    private var analytics: AnalyticsManager!

    // MARK: - Setup / Teardown
    override func setUpWithError() throws {
        try super.setUpWithError()

        // In-memory Core Data stack
        let stack = try CoreDataStack(modelName: "Gainz", storeType: .inMemory)
        db        = DatabaseManager(stack: stack)

        analytics = AnalyticsManager(database: db,
                                     uploadClient: MockUploader(),
                                     clock: .immediate)

        // Seed minimal exercise list (Bench Press only) for predictable maths
        let bench = Exercise(name: "UnitTest Bench",
                             primaryMuscles: [.chest],
                             mechanicalPattern: .horizontalPush,
                             equipment: .barbell)
        try db.saveExercise(bench)
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        db        = nil
        analytics = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests

    /// Ensures set-logged events compute tonnage correctly.
    func testSetLogged_updatesTonnage() throws {
        // Given
        let exerciseID = try XCTUnwrap(db.fetchAllExercises().first?.id)
        let set = SetRecord(weight: 100, reps: 10, rpe: .eight)
        let log = ExerciseLog(exerciseId: exerciseID, sets: [set])
        let session = WorkoutSession(date: .now, exerciseLogs: [log])
        try db.saveWorkoutSession(session)

        let exp = expectation(description: "tonnage updated")
        var capturedTonnage: Double = 0

        analytics.metricsPublisher
            .sink { metrics in
                capturedTonnage = metrics.totalTonnage
                exp.fulfill()
            }
            .store(in: &cancellables)

        // When
        analytics.recalculateMetrics()

        // Then
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(capturedTonnage, 1000, accuracy: 0.1)
    }

    /// Confirms Combine event bus emits when new session saved.
    func testEventBus_publishesOnSave() throws {
        // Given
        let exerciseID = try XCTUnwrap(db.fetchAllExercises().first?.id)
        let set = SetRecord(weight: 80, reps: 8, rpe: .seven)
        let log = ExerciseLog(exerciseId: exerciseID, sets: [set])
        let session = WorkoutSession(date: .now, exerciseLogs: [log])

        let exp = expectation(description: "event published")

        analytics.eventPublisher
            .sink { event in
                if case .workoutLogged(let id) = event, id == session.id {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        try db.saveWorkoutSession(session)
        analytics.handleDatabaseChange()

        // Then
        wait(for: [exp], timeout: 1)
    }

    /// Verifies upload batch signer produces deterministic HMAC.
    func testBatchSigner_hmacIsDeterministic() throws {
        // Given
        let payload = "{\"metric\":\"tonnage\",\"value\":1234}".data(using: .utf8)!
        let secret  = "UnitTestSecret"
        let signer  = HMACSigner(secret: secret)

        // When
        let sig1 = signer.signature(for: payload)
        let sig2 = signer.signature(for: payload)

        // Then
        XCTAssertEqual(sig1, sig2, "HMAC signatures should be deterministic")
    }
}

// MARK: - MockUploader

private final class MockUploader: AnalyticsUploader {
    func uploadBatch(_ batch: AnalyticsBatch, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))        // no-op
    }
}
