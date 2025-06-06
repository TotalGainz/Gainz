//
//  OnboardingFlowUITests.swift
//  GainzUITests
//
//  Created by AI on 2025-06-06.
//  Mission: Advanced, logical, intelligently-designed, world-class code.
//
//  These UI tests cover the happy-path first-launch onboarding flow.
//  They tap through every step (Goal → Experience → Frequency → Preferences → Plan Preview)
//  and assert that the final “Start My Plan” state appears.
//

import XCTest

final class OnboardingFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += ["--uitesting", "--reset-onboarding"]
        app.launch()
    }

    /// Walks a brand-new user through the entire onboarding wizard and
    /// verifies that the plan preview screen is shown.
    func testCompleteOnboardingFlow_HappyPath() throws {
        // Step 1: choose primary goal (“Build Muscle”)
        let buildMuscle = app.buttons["goal_buildMuscle"]
        XCTAssertTrue(buildMuscle.waitForExistence(timeout: 3))
        buildMuscle.tap()

        // Step 2: select experience level (“Intermediate”)
        let intermediate = app.buttons["experience_intermediate"]
        XCTAssertTrue(intermediate.waitForExistence(timeout: 3))
        intermediate.tap()

        // Step 3: adjust weekly frequency (slider) and continue
        let frequencySlider = app.sliders["frequency_slider"]
        XCTAssertTrue(frequencySlider.exists)
        frequencySlider.adjust(toNormalizedSliderPosition: 0.75) // ≈ 4–5 days
        app.buttons["frequency_next"].tap()

        // Step 4: skip / accept default preferences if the screen exists
        if app.buttons["preferences_next"].waitForExistence(timeout: 2) {
            app.buttons["preferences_next"].tap()
        }

        // Step 5: verify plan preview and primary CTA
        let startPlan = app.buttons["start_plan"]
        XCTAssertTrue(startPlan.waitForExistence(timeout: 4))

        // Extra: headline copy sanity-check
        let title = app.staticTexts["plan_preview_title"]
        XCTAssertTrue(title.label.contains("Your 1st Training Cycle"))
    }
}
