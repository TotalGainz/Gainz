//
//  AnalyticsTabUITests.swift
//  GainzUITests
//
//  Created by AI on 2025-06-06.
//  Mission: advanced, logical, intelligently-designed, world-class code.
//
//  Covers the Analytics tab (“Body Dashboard & Strength Leaderboard”)
//  happy-path flow:
//
//  1.  Open the Analytics tab via custom TabBar.
//  2.  Verify the muscle-heat-map canvas renders.
//  3.  Swipe up to reveal the Leaderboard drawer.
//  4.  Tap “Share Card” to invoke the iOS share-sheet.
//  5.  Dismiss the sheet and ensure we’re still on Analytics.
//
//  Accessibility identifiers must match the SwiftUI views:
//
//    tab_analytics             – tab-bar item
//    analytics_muscleMap       – heat-map Canvas
//    leaderboard_drawer        – bottom-sheet container
//    share_card_button         – primary share CTA
//

import XCTest

final class AnalyticsTabUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Pre-seed demo data so the Analytics dashboard has content.
        app.launchArguments += ["--uitesting", "--demo-analytics"]
        app.launch()
    }

    /// Ensures the core Analytics dashboard and interactions work.
    func testAnalyticsDashboardFlow_HappyPath() throws {
        // 1. Navigate to Analytics tab.
        let analyticsTab = app.tabBars.buttons["tab_analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 3))
        analyticsTab.tap()

        // 2. Muscle heat-map should be visible.
        let muscleMap = app.otherElements["analytics_muscleMap"]
        XCTAssertTrue(muscleMap.waitForExistence(timeout: 3))

        // 3. Pull up Leaderboard drawer.
        muscleMap.swipeUp()           // Gesture on canvas to reveal drawer.
        let leaderboard = app.otherElements["leaderboard_drawer"]
        XCTAssertTrue(leaderboard.waitForExistence(timeout: 3))

        // 4. Tap Share Card.
        let shareButton = app.buttons["share_card_button"]
        XCTAssertTrue(shareButton.exists)
        shareButton.tap()

        // Verify iOS share sheet appears.
        let activitySheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(activitySheet.waitForExistence(timeout: 5))

        // Dismiss share sheet (cancel button may vary by locale).
        app.buttons["Cancel"].firstMatch.tap()

        // 5. Confirm we remain in Analytics tab.
        XCTAssertTrue(muscleMap.waitForExistence(timeout: 2))
    }
}
