//
//  ProfileViewModelTests.swift
//  Gainz – Profile Feature Tests
//
//  Created by AI-Assistant on 2025-06-03.
//
//  Unit tests for ProfileViewModel covering state, refresh logic,
//  HealthKit toggling, and export behavior. HRV and velocity tracking
//  intentionally excluded per spec.
//
//  Follows XCTest + async/await patterns. Uses lightweight stubs
//  conforming to the relevant protocols in `PreviewKit`.
//

import XCTest
@testable import Profile
@testable import Domain
@testable import ServicePersistence
@testable import ServiceMetrics
@testable import ServiceExport
@testable import ServiceHealth

final class ProfileViewModelTests: XCTestCase {

    var viewModel: ProfileViewModel!
    var mockProfileRepo: MockUserProfileRepository!
    var mockMetricsUseCase: MockCalculateMetricsUseCase!
    var mockExportUseCase: MockExportDataUseCase!
    var mockHealthKit: MockHealthKitSyncManager!

    override func setUp() {
        super.setUp()
        mockProfileRepo = .init()
        mockMetricsUseCase = .init()
        mockExportUseCase = .init()
        mockHealthKit = .init()
        viewModel = ProfileViewModel(
            profileRepo: mockProfileRepo,
            metricsUseCase: mockMetricsUseCase,
            exportUseCase: mockExportUseCase,
            healthKit: mockHealthKit,
            hasSeparateSettingsTab: false
        )
    }

    func testInitialState_isEmpty() {
        XCTAssertEqual(viewModel.displayName, "")
        XCTAssertEqual(viewModel.primaryGoal, "")
        XCTAssertTrue(viewModel.metricTiles.isEmpty)
        XCTAssertFalse(viewModel.healthKitConnected)
    }

    func testLoad_populatesDisplayNameAndMetrics() async {
        await viewModel.load()

        XCTAssertEqual(viewModel.displayName, "Test User")
        XCTAssertEqual(viewModel.primaryGoal, "Gain muscle")
        XCTAssertEqual(viewModel.metricTiles.count, 4)
        XCTAssertEqual(viewModel.lifetimeSummary.sessionCount, 42)
    }

    func testToggleHealthKit_grantsPermission() async {
        XCTAssertFalse(mockHealthKit.didRequestPermission)
        viewModel.healthKitConnected = true
        try? await Task.sleep(nanoseconds: 100_000_000) // wait a tick
        XCTAssertTrue(mockHealthKit.didRequestPermission)
    }

    func testToggleHealthKit_revokesPermission() {
        viewModel.healthKitConnected = false
        XCTAssertTrue(mockHealthKit.didDeauthorize)
    }

    func testExportData_succeedsSilently() async {
        await viewModel.exportDataTapped()
        XCTAssertTrue(mockExportUseCase.didExport)
    }
}

// MARK: – Mocks

final class MockUserProfileRepository: UserProfileRepositoryProtocol {
    func fetchUserProfile() async throws -> UserProfile {
        UserProfile(id: UUID(),
                    displayName: "Test User",
                    primaryGoal: "Gain muscle",
                    avatarPNGData: nil)
    }
}

final class MockCalculateMetricsUseCase: CalculateMetricsUseCaseProtocol {
    func calculate(for userID: UUID) async throws -> BodyMetrics {
        BodyMetrics(
            weight: 75.5,
            height: 180,
            bmi: 23.3,
            ffmi: 21.8,
            lifetimeSummary: .init(
                sessionCount: 42,
                setCount: 1200,
                repCount: 9800,
                tonnage: 875000,
                prCount: 14,
                trainingDays: 150
            )
        )
    }
}

final class MockExportDataUseCase: ExportDataUseCaseProtocol {
    var didExport = false
    func exportUserData(as format: ExportFormat) async throws -> Data {
        didExport = true
        return Data("mock,export,data\n1,2,3".utf8)
    }
}

final class MockHealthKitSyncManager: HealthKitSyncManager {
    var didRequestPermission = false
    var didDeauthorize = false

    override func requestPermission() async throws {
        didRequestPermission = true
    }

    override func deauthorize() {
        didDeauthorize = true
    }
}
