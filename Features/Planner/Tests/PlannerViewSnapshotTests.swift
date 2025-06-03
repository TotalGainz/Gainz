//
//  PlannerViewSnapshotTests.swift
//  Gainz – Planner Feature
//
//  Validates that the Planner home screen renders identically
//  across devices, Dynamic Type, and light/dark modes.
//  Uses Point-Free’s SnapshotTesting with a 2 × precision.
//
//  Note: run `swift test --enable-test-discovery` from the
//  Feature target root to regenerate references when UI changes.
//
//  Created on 27 May 2025.
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import PlannerFeature      // SwiftPM module for the Planner
@testable import Domain             // MesocyclePlan, WorkoutSession mocks
@testable import CoreUI             // Design tokens for accurate theming

final class PlannerViewSnapshotTests: XCTestCase {

    // MARK: - Test config
    override func setUp() {
        super.setUp()
        // Record = true will overwrite reference snaps.
        // Flip only when intentionally updating baselines.
        isRecording = false
    }

    // MARK: - Fixtures

    /// Returns a fully populated view model in preview state.
    private func makeViewModel() -> PlannerViewModel {
        let planner = PlannerViewModel()

        // Inject dummy mesocycle (4-week linear progression).
        let mockPlan = MesocyclePlan.mockLinearChestFocused()
        planner.bind(plan: mockPlan, animated: false)

        return planner
    }

    /// Convenience wrapper to host SwiftUI view in a UIKit container
    /// sized like the target device.
    private func render<V: View>(
        _ view: V,
        device: ViewImageConfig.Device = .iPhone15Pro,
        colorScheme: ColorScheme = .dark,
        sizeCategory: ContentSizeCategory = .large
    ) -> UIView {
        let root = UIHostingController(rootView: view
            .environment(\.colorScheme, colorScheme)
            .environment(\.sizeCategory, sizeCategory)
        )
        root.view.frame = CGRect(origin: .zero, size: device.size)
        root.view.layoutIfNeeded()
        return root.view
    }

    // MARK: - Tests

    func testPlanner_dark_large() {
        let vm   = makeViewModel()
        let view = PlannerHomeScreen(viewModel: vm)

        assertSnapshot(
            matching: render(view),
            as: .image(on: .iPhone15Pro),
            named: "Planner_dark_large"
        )
    }

    func testPlanner_light_accessibilityXL() {
        let vm   = makeViewModel()
        let view = PlannerHomeScreen(viewModel: vm)

        assertSnapshot(
            matching: render(
                view,
                device: .iPhone15ProMax,
                colorScheme: .light,
                sizeCategory: .accessibilityExtraLarge
            ),
            as: .image(on: .iPhone15ProMax),
            named: "Planner_light_a11yXL"
        )
    }
}
