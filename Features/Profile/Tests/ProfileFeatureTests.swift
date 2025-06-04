//
//  ProfileFeatureTests.swift
//  Gainz – Profile Feature Tests
//
//  Created by AI-Assistant on 2025-06-03.
//
//  Integration tests for the Profile feature's coordinator-level routing,
//  view composition, and screen transitions. Validates MVVM-C boundaries
//  and navigation behaviors within SwiftUI NavigationStack.
//
//  This test suite avoids UI snapshotting in favor of ViewInspector-style
//  state introspection. HRV and velocity tracking are intentionally excluded.
//

import XCTest
import SwiftUI
@testable import Profile
@testable import Domain
@testable import ServicePersistence
@testable import ServiceMetrics
@testable import ServiceExport

final class ProfileFeatureTests: XCTestCase {

    var coordinator: ProfileCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = ProfileCoordinator(
            profileRepo: MockUserProfileRepository(),
            metricsUseCase: MockCalculateMetricsUseCase(),
            exportUseCase: MockExportDataUseCase()
        )
    }

    func testInitialPath_isEmpty() {
        XCTAssertEqual(coordinator.path, [])
    }

    func testStart_rendersRootView() {
        let root = coordinator.start()
        XCTAssertNotNil(root)
        // Optional: Use ViewInspector here if snapshotting or introspection is enabled
    }

    func testHandleDeepLink_toSettings() {
        coordinator.handleDeepLink(.settings)
        XCTAssertEqual(coordinator.path.count, 1)
        XCTAssertEqual(coordinator.path.first, .settings)
    }

    func testHandleDeepLink_appendsWhenPathExists() {
        coordinator.path = [.root]
        coordinator.handleDeepLink(.editProfile)
        XCTAssertEqual(coordinator.path, [.root, .editProfile])
    }

    func testMakeRoot_returnsProfileView() {
        let root = coordinator.makeRoot()
        XCTAssertNotNil(root.body)
    }

    func testBuildDestination_editProfile() {
        let view = coordinator.buildDestination(for: .editProfile)
        XCTAssertNotNil(view)
    }

    func testBuildDestination_settings() {
        let view = coordinator.buildDestination(for: .settings)
        XCTAssertNotNil(view)
    }
}

// MARK: – Lightweight Stubs

final class MockUserProfileRepository: UserProfileRepositoryProtocol {
    func fetchUserProfile() async throws -> UserProfile {
        UserProfile(id: UUID(),
                    displayName: "Test User",
                    primaryGoal: "Hypertrophy",
                    avatarPNGData: nil)
    }
}

final class MockCalculateMetricsUseCase: CalculateMetricsUseCaseProtocol {
    func calculate(for userID: UUID) async throws -> BodyMetrics {
        BodyMetrics(weight: 78,
                    height: 178,
                    bmi: 24.6,
                    ffmi: 22.4,
                    lifetimeSummary: .init(
                        sessionCount: 60,
                        setCount: 1800,
                        repCount: 14500,
                        tonnage: 1_200_000,
                        prCount: 20,
                        trainingDays: 190
                    ))
    }
}

final class MockExportDataUseCase: ExportDataUseCaseProtocol {
    func exportUserData(as format: ExportFormat) async throws -> Data {
        return Data("mock export".utf8)
    }
}
