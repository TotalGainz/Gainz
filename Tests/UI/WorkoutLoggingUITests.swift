//
//  WorkoutLoggingUITests.swift
//  GainzUITests
//
//  Created by AI on 2025-06-06.
//  Mission: advanced, logical, intelligently-designed, world-class code.
//
//  Scenario: A user launches an in-progress workout, logs every set of the
//  first exercise using one-tap checkboxes, verifies that the floating rest-
//  timer appears, skips the timer, and finishes the session.  We assert that
//  each critical stage in the happy-path flow is reachable via accessibility
//  identifiers.
//
//  UI hierarchy & identifiers are drawn from WorkoutView, ExerciseCardView,
//  SetRowView, RestTimerOverlay, and the custom Tab Bar.
//

import XCTest

final class WorkoutLoggingUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // --uitesting boots the app in test mode; --demo-workout injects a
        // seeded session so the logger opens immediately on the Workout tab.
        app.launchArguments += ["--uitesting", "--demo-workout"]
        app.launch()
    }

    /// End-to-end test of the single-hand “Hero-Cards 2.0” logging flow.
    /// 1.  Tap Workout tab (pulsing when a session is active)
    /// 2.  If shown, tap “Start Workout”
    /// 3.  Log every set of first exercise via checkboxes
    /// 4.  Rest-timer bubble appears → double-tap to skip
    /// 5.  Finish workout and confirm summary sheet
    func testWorkoutLoggingFlow_HappyPath() throws {
        // Navigate to the Workout logger
        let workoutTab = app.tabBars.buttons["tab_workout"]
        XCTAssertTrue(workoutTab.waitForExistence(timeout: 3))
        workoutTab.tap()

        // If the session hasn’t been resumed yet, tap the CTA
        if app.buttons["start_workout_button"].waitForExistence(timeout: 2) {
            app.buttons["start_workout_button"].tap()
        }

        // Verify first exercise card is on-screen
        let firstExercise = app.otherElements["exercise_card_0"]
        XCTAssertTrue(firstExercise.waitForExistence(timeout: 3))

        // Log three sets in quick succession
        for setIndex in 0..<3 {
            let checkbox = firstExercise.buttons["set_checkbox_0_\(setIndex)"]
            XCTAssertTrue(checkbox.waitForExistence(timeout: 2))
            checkbox.tap()
        }

        // Rest-timer bubble should appear once the first set is logged
        let restTimer = app.otherElements["rest_timer"]
        XCTAssertTrue(restTimer.waitForExistence(timeout: 2))

        // Skip the timer via documented double-tap gesture
        restTimer.doubleTap()

        // Scroll to bottom (if needed) and finish workout
        app.swipeUp()
        let finish = app.buttons["finish_workout_button"]
        XCTAssertTrue(finish.waitForExistence(timeout: 3))
        finish.tap()

        // Summary sheet confirms success
        let summaryTitle = app.staticTexts["workout_summary_title"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 3))
    }
}
