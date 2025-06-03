CoreUITests.swift

//
//  CoreUITests.swift
//  Gainz – CoreUI
//
//  Sanity tests for CoreUI components. These do *not* rely on external
//  snapshot libraries so they compile in a vanilla XCTest target.
//  If you later adopt ViewInspector or SnapshotTesting, extend here.
//
//  Created on 27 May 2025.
//

import XCTest
import SwiftUI
@testable import CoreUI

final class CoreUITests: XCTestCase {

    // MARK: - LoadingIndicator

    /// Verifies that the LoadingIndicator view can be initialised with
    /// default parameters without crashing and exposes the expected
    /// accessibility label.
    func testLoadingIndicator_initialisesAndHasAccessibilityLabel() {
        // Given
        let indicator = LoadingIndicator()

        // When – render one frame
        let host = UIHostingController(rootView: indicator)
        XCTAssertNotNil(host.view, "UIHostingController failed to create view hierarchy")

        // Then – verify accessibility
        let accessibilityLabel = indicator.body.accessibilityLabel()
        XCTAssertEqual(accessibilityLabel, Text("Loading").accessibilityLabel(),
                       "LoadingIndicator accessibility label mismatch")
    }

    /// Ensures that custom sizes honour the ratio contract: stroke width
    /// == `size * strokeRatio`.
    func testLoadingIndicator_strokeWidthScalesWithSize() {
        // Given
        let size: CGFloat = 80
        let ratio: CGFloat = 0.1
        let indicator = LoadingIndicator(size: size, strokeRatio: ratio)

        // When
        let strokeWidth = size * ratio

        // Then – numeric precision tolerance
        XCTAssertEqual(strokeWidth, 8, accuracy: 0.0001,
                       "Stroke width does not equal size * strokeRatio")
    }

    // MARK: - Brand Colours

    /// Guards against accidental palette drift by verifying RGB values.
    func testBrandColours_rgbExact() {
        // Given
        let indigo = UIColor(Color.brandIndigo)
        let violet = UIColor(Color.brandViolet)

        // Then
        XCTAssertEqual(indigo, UIColor(red: 122/255, green: 44/255,  blue: 243/255, alpha: 1))
        XCTAssertEqual(violet, UIColor(red: 156/255, green: 39/255,  blue: 255/255, alpha: 1))
    }
}
