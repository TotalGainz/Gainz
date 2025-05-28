//
//  DomainModelTests.swift
//  Gainz • Domain Layer
//
//  High-value unit tests that guard invariants on the pure models
//  (Exercise, ExercisePlan, RepRange, RPE).
//
//  Requires XCTest (ships with Xcode)  :contentReference[oaicite:0]{index=0}
//

import XCTest
@testable import Domain   // ← SwiftPM target name

final class DomainModelTests: XCTestCase {

    // MARK: – Exercise

    func testExerciseHashableAndEquality() {
        let squat1 = Exercise(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            name: "Back Squat",
            primaryMuscles: [.quads],
            mechanicalPattern: .squat,
            equipment: .barbell
        )
        let squat2 = Exercise(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            name: "Back Squat",
            primaryMuscles: [.quads],
            mechanicalPattern: .squat,
            equipment: .barbell
        )

        XCTAssertEqual(squat1, squat2, "Same-ID exercises should be equal")
        XCTAssertEqual(Set([squat1, squat2]).count, 1, "Hashable must collapse duplicates")
    }

    // MARK: – RepRange

    func testRepRangeCodableRoundTrip() throws {
        let original = RepRange(min: 8, max: 12)
        let data = try JSONEncoder().encode(original)          // Codable round-trip  :contentReference[oaicite:1]{index=1}
        let decoded = try JSONDecoder().decode(RepRange.self, from: data)

        XCTAssertEqual(original, decoded, "RepRange should encode/decode losslessly")
    }

    // MARK: – ExercisePlan

    func testExercisePlanVolumeMath() {
        let plan = ExercisePlan(
            exerciseId: UUID(),
            sets: 4,
            repRange: RepRange(min: 8, max: 12)
        )

        XCTAssertEqual(plan.averageReps, 10, accuracy: 0.1,
                       "Average reps should be arithmetic mean")
        XCTAssertEqual(plan.plannedTotalReps, 40,
                       "Total reps = sets × average reps")
    }

    // MARK: – RPE

    func testRpeDescription() {
        XCTAssertEqual(RPE.nine.description, "RPE 9")
    }

    // MARK: – Validation Guards

    func testRepRangeValidation() {
        // min must be > 0                       :contentReference[oaicite:2]{index=2}
        XCTAssertThrowsError(try RepRange(min: 0, max: 5))
        // max must be ≥ min
        XCTAssertThrowsError(try RepRange(min: 10, max: 5))
    }
}
