//
//  PlanGeneratorTests.swift
//  PlatformAgnostic • Domain • Tests
//
//  Golden-path and edge-case tests for `PlanGenerator`.
//  Ensures periodisation logic is stable and science-aligned.
//  No HRV, recovery, or bar-velocity metrics are referenced.
//
//  Created: 27 May 2025
//

import XCTest
@testable import Domain

final class PlanGeneratorTests: XCTestCase {

    // System-under-test
    private var generator: PlanGenerator!
    private var exerciseRepo: ExerciseRepositoryMock!

    //──────────────────────────────────────────────
    // MARK: – Setup
    //──────────────────────────────────────────────
    override func setUp() {
        super.setUp()
        exerciseRepo = ExerciseRepositoryMock()
        generator = PlanGenerator(exerciseRepository: exerciseRepo)
    }

    override func tearDown() {
        generator = nil
        exerciseRepo = nil
        super.tearDown()
    }

    //──────────────────────────────────────────────
    // MARK: – Tests
    //──────────────────────────────────────────────

    /// Requested `weeks` count should equal output weeks.
    func test_generateMesocycle_hasExpectedWeekCount() throws {
        let plan = try generator.generateMesocycle(
            goal: .hypertrophy,
            lengthInWeeks: 4,
            splitTemplate: .pushPullLegs
        )
        XCTAssertEqual(plan.weeks.count, 4)
    }

    /// Volume should climb each week until the final deload-week drop.
    func test_generateMesocycle_progressiveOverload_thenDeload() throws {
        let plan = try generator.generateMesocycle(
            goal: .hypertrophy,
            lengthInWeeks: 5,                // Week 5 is deload
            splitTemplate: .upperLower
        )

        let weeklyVolumes = plan.weeks.map { $0.totalPlannedReps }
        // Ascending 1-…-n-1
        let overloadTrendOK = zip(weeklyVolumes, weeklyVolumes.dropFirst())
            .dropLast()                     // ignore deload edge
            .allSatisfy { $0 < $1 }

        XCTAssertTrue(overloadTrendOK, "Volume should increase week-to-week until deload")
        XCTAssertLessThan(weeklyVolumes.last!,
                          weeklyVolumes[weeklyVolumes.count - 2],
                          "Deload week must reduce volume")
    }

    /// All generated exercise IDs must be present in the catalog.
    func test_generatorUsesOnlyCatalogExercises() throws {
        let plan = try generator.generateMesocycle(
            goal: .hypertrophy,
            lengthInWeeks: 3,
            splitTemplate: .fullBody
        )

        let unknownIDs = plan.allExerciseIDs.subtracting(Set(exerciseRepo.catalog.keys))
        XCTAssertTrue(unknownIDs.isEmpty, "Unknown exercise IDs: \(unknownIDs)")
    }

    /// Rep ranges should remain within 5–30 reps for hypertrophy.
    func test_repRangeWithinBounds() throws {
        let workout = try generator.generateWorkout(
            for: .monday(ofWeek: 1),
            goal: .hypertrophy,
            splitTemplate: .pushPullLegs
        )

        let invalid = workout.exercisePlans.first {
            $0.repRange.min < 5 || $0.repRange.max > 30
        }
        XCTAssertNil(invalid, "Rep range outside 5–30 bounds")
    }

    /// Ensure no forbidden HRV / velocity keys sneak into domain types.
    func test_mesocycleContainsNoHRVorVelocityFields() throws {
        let plan = try generator.generateMesocycle(
            goal: .hypertrophy,
            lengthInWeeks: 4,
            splitTemplate: .pushPullLegs
        )

        let mirror = Mirror(reflecting: plan)
        let forbidden = mirror.children.contains { child in
            guard let label = child.label?.lowercased() else { return false }
            return label.contains("hrv") || label.contains("velocity")
        }
        XCTAssertFalse(forbidden, "MesocyclePlan must not contain HRV or velocity metrics")
    }
}

//──────────────────────────────────────────────
// MARK: – Test Doubles
//──────────────────────────────────────────────

/// Minimal in-memory exercise repo satisfying the Domain protocol.
private final class ExerciseRepositoryMock: ExerciseRepository {

    fileprivate let catalog: [UUID: Exercise] = {
        let squat = Exercise(
            name: "Back Squat",
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes],
            mechanicalPattern: .squat,
            equipment: .barbell
        )
        let bench = Exercise(
            name: "Bench Press",
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps],
            mechanicalPattern: .horizontalPush,
            equipment: .barbell
        )
        return [squat.id: squat, bench.id: bench]
    }()

    // MARK: – Protocol stubs
    func fetchAll() -> [Exercise] { Array(catalog.values) }
    subscript(id: UUID) -> Exercise? { catalog[id] }
}
