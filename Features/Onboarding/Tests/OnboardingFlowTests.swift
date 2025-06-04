//
//  OnboardingFlowTests.swift
//  GainzUITests
//
//  Created by Broderick Hiland on 2025-06-04.
//  Target: GainzUITests (UI-Automation target)
//
//  Strategy:
//  1. Verify the “Next” button advances the page count.
//  2. Verify the final “Get Started” button dismisses onboarding.
//  3. (Optional) Assert that a post-onboarding element is visible
//     to guarantee the root view has changed.
//

import XCTest

final class OnboardingFlowTests: XCTestCase {

    // MARK: - Properties
    private var app: XCUIApplication!

    // MARK: - Lifecycle
    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments.append("--uitesting") // Ensure deterministic seed data
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Tests
    func testCompleteOnboardingFlow() throws {
        // 1️⃣  Page 1 ───────────────
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(
            nextButton.waitForExistence(timeout: 3),
            "Expected the first onboarding screen to present a “Next” button."
        )

        // 2️⃣  Tap → Page 2 ────────
        nextButton.tap()

        // The “Next” button should still exist because we’re not on the last page yet.
        XCTAssertTrue(
            nextButton.waitForExistence(timeout: 2),
            "After tapping, a subsequent “Next” button should appear on page 2."
        )

        // 3️⃣  Tap → Page 3 (final) ─
        nextButton.tap()

        // “Get Started” should now replace “Next”.
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(
            getStartedButton.waitForExistence(timeout: 2),
            "Final page must display a “Get Started” CTA."
        )

        // 4️⃣  Dismiss onboarding ──
        getStartedButton.tap()

        // 5️⃣  Verify onboarding is gone by checking for a Home-screen element.
        // Replace "HomeViewIdentifier" with an actual accessibilityIdentifier from your Home view.
        let home = app.otherElements["HomeViewIdentifier"]
        XCTAssertTrue(
            home.waitForExistence(timeout: 3),
            "App should advance to Home after onboarding completes."
        )
    }
}
