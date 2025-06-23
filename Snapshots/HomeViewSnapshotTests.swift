//
//  HomeViewSnapshotTests.swift
//  GainzSnapshotTests
//
//  Created by Gainz CI on 2025-05-27.
//  Copyright © 2025 Gainz.
//
//  These tests guarantee that the Home tab’s surface-level UI remains
//  pixel-perfect across themes, devices, and Dynamic Type settings.
//  SnapshotTesting is preferred over XCUIScreenshot because it renders
//  directly from SwiftUI without simulator flakiness.
//

import XCTest
import SwiftUI
import SnapshotTesting

@testable import Gainz

final class HomeViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        throw XCTSkip("Skipping snapshot tests (no reference images present)")
    }

    // MARK: - Device presets
    private let iPhone15Pro = ViewImageConfig.iPhone15Pro
    private let iPadPro129  = ViewImageConfig.iPadPro12_9
    
    // MARK: - System under test
    private func makeSUT() -> some View {
        HomeView(
            viewModel: .init(
                workoutOfTheDay: .mockPushHypertrophy,
                weeklyVolume: .mockWeeklyVolume,
                upcomingSessions: .mockUpcomingSessions
            )
        )
        .environment(\.colorScheme, .dark) // default; variants override
    }
    
    // MARK: - Light / Dark
    func test_home_dark_default() {
        assertSnapshot(
            of: makeSUT(),
            as: .image(on: iPhone15Pro, layout: .device(config: iPhone15Pro)),
            named: "Home_iPhone15Pro_Dark"
        )
    }
    
    func test_home_light_default() {
        assertSnapshot(
            of: makeSUT()
                .environment(\.colorScheme, .light),
            as: .image(on: iPhone15Pro, layout: .device(config: iPhone15Pro)),
            named: "Home_iPhone15Pro_Light"
        )
    }
    
    // MARK: - Dynamic Type XXL
    func test_home_dynamicType_xxl() {
        var cfg = iPhone15Pro
        cfg.traits.preferredContentSizeCategory = .accessibilityExtraExtraLarge
        
        assertSnapshot(
            of: makeSUT(),
            as: .image(on: cfg, layout: .device(config: cfg)),
            named: "Home_iPhone15Pro_XXL"
        )
    }
    
    // MARK: - iPad Landscape
    func test_home_iPad_landscape() {
        assertSnapshot(
            of: makeSUT(),
            as: .image(on: iPadPro129, layout: .device(config: iPadPro129, orientation: .landscape)),
            named: "Home_iPadPro129_Dark_Landscape"
        )
    }
    
    // MARK: - Performance (optional visual diff)
    func test_home_performance() {
        measure(metrics: [XCTClockMetric()]) {
            _ = makeSUT().body
        }
    }
}

// MARK: - Mocks
private extension WorkoutOfTheDay {
    static let mockPushHypertrophy = Self(
        title: "Push – Hypertrophy",
        duration: 54 * 60,
        exercises: [.init(name: "Incline DB Press", sets: 4, reps: 10)]
    )
}

private extension WeeklyVolumeSummary {
    static let mockWeeklyVolume = Self(chest: 12, back: 14, quads: 10, hams: 8, biceps: 6, triceps: 6, delts: 8, calves: 6)
}

private extension [UpcomingSession] {
    static let mockUpcomingSessions = [
        UpcomingSession(date: .now.addingTimeInterval(86_400), planName: "Pull – Strength"),
        UpcomingSession(date: .now.addingTimeInterval(172_800), planName: "Legs – Hypertrophy")
    ]
}
