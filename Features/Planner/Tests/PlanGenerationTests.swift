//
//  PlanGenerationTests.swift
//  Gainz – Planner Feature
//
//  Verifies that PlanGenerator builds mesocycles that obey our
//  hypertrophy principles (weekly volume, muscle-group frequency,
//  progressive overload, fatigue deload) *without* relying on HRV or
//  bar-velocity metrics.
//
//  Created on 27 May 2025.
//

import XCTest
@testable import Planner   // Feature target under test
@testable import Domain    // MesocyclePlan, Exercise, etc.

// MARK: - Fixture Helpers
private extension MuscleGroup {
    static let chest   : MuscleGroup = .chest
    static let triceps : MuscleGroup = .triceps
    static let quads   : MuscleGroup = .quads
}

final class PlanGenerationTests: XCTestCase {

    private var generator: PlanGenerator!

    override func setUp() {
        super.setUp()
        generator = PlanGenerator()   // stateless service
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    // MARK: - Happy-Path: 4-Week Hypertrophy Block

    func testGenerateMesocycle_hypertrophy4Weeks() throws {
        // Given
        let request = MesocycleRequest(
            goal               : .hypertrophy,
            weeks              : 4,
            daysPerWeek        : 5,
            targetMuscleGroups : [.chest, .triceps, .quads]
        )

        // When
        let plan = try generator.generateMesocycle(from: request)

        // Then – high-level assertions
        XCTAssertEqual(plan.weeks.count, 4, "Should produce exactly 4 calendar weeks")

        // Each muscle group must appear ≥2× / week for hypertrophy
        plan.weeks.forEach { week in
            XCTAssertGreaterThanOrEqual(week.trainings(for: .chest).count, 2)
            XCTAssertGreaterThanOrEqual(week.trainings(for: .triceps).count, 2)
            XCTAssertGreaterThanOrEqual(week.trainings(for: .quads).count, 2)
        }

        // Progressive overload: week N+1 tonnage ≥ week N
        zip(plan.weeks, plan.weeks.dropFirst()).forEach { prev, next in
            XCTAssertGreaterThanOrEqual(next.totalTonnage, prev.totalTonnage,
                                        "Tonnage must not regress between consecutive weeks")
        }

        // Optional deload: last week volume < prior week (if flag set)
        if request.includesDeload {
            let penultimate = plan.weeks[2]
            let deload      = plan.weeks[3]
            XCTAssertLessThan(deload.totalTonnage, penultimate.totalTonnage,
                              "Deload week tonnage should be lower to dissipate fatigue")
        }
    }

    // MARK: - Edge: Invalid Configurations

    func testGenerateMesocycle_invalidDaysPerWeek_throws() {
        // Given – more training days than the calendar allows
        let badRequest = MesocycleRequest(
            goal        : .hypertrophy,
            weeks       : 4,
            daysPerWeek : 8,   // invalid
            targetMuscleGroups: [.chest]
        )

        // Then
        XCTAssertThrowsError(try generator.generateMesocycle(from: badRequest)) { error in
            guard case PlanGenerationError.invalidDaysPerWeek = error else {
                return XCTFail("Expected invalidDaysPerWeek error")
            }
        }
    }

    func testGenerateMesocycle_zeroMuscleGroups_throws() {
        let badRequest = MesocycleRequest(
            goal               : .hypertrophy,
            weeks              : 4,
            daysPerWeek        : 4,
            targetMuscleGroups : []
        )
        XCTAssertThrowsError(try generator.generateMesocycle(from: badRequest)) { error in
            guard case PlanGenerationError.noMuscleGroupsSelected = error else {
                return XCTFail("Expected noMuscleGroupsSelected error")
            }
        }
    }

    // MARK: - Determinism

    func testGenerateMesocycle_idempotentForSameSeed() throws {
        // Given – deterministic seed
        let request = MesocycleRequest(
            goal        : .hypertrophy,
            weeks       : 4,
            daysPerWeek : 5,
            targetMuscleGroups: [.chest, .triceps]
        )
        let seed: UInt64 = 42

        // When
        let planA = try generator.generateMesocycle(from: request, seed: seed)
        let planB = try generator.generateMesocycle(from: request, seed: seed)

        // Then
        XCTAssertEqual(planA, planB, "Same seed + same request should yield identical plans")
    }
}
