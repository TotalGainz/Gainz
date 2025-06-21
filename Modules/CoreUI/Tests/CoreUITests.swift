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
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI
@testable import CoreUI

final class CoreUITests: XCTestCase {

    // MARK: - LoadingIndicator

    /// Verifies that the LoadingIndicator view can be initialised with
    /// default parameters without crashing and exposes the expected
    /// accessibility label.
    #if canImport(UIKit)
    func testLoadingIndicator_initialisesAndHasAccessibilityLabel() {
        // Given
        let indicator = LoadingIndicator()

        // When – render one frame
        let host = UIHostingController(rootView: indicator)
        XCTAssertNotNil(host.view, "UIHostingController failed to create view hierarchy")

        // Then – verify accessibility
        // Verify that the hosting view's accessibility label matches the indicator.
        let hostLabel = host.view.accessibilityLabel
        XCTAssertEqual(hostLabel, "Loading",
                       "LoadingIndicator accessibility label mismatch")
    }


    // MARK: - Brand Colours

    #endif

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

    #if canImport(UIKit)
    typealias PlatformColor = UIColor
    #elseif canImport(AppKit)
    typealias PlatformColor = NSColor
    #endif

    #if canImport(UIKit) || canImport(AppKit)
    /// Guards against accidental palette drift by verifying RGB values for brand colors.
    func testBrandColours_rgbExact() {
        let indigo = PlatformColor(Color.brandIndigo)
        let violet = PlatformColor(Color.brandViolet)
        let expectedIndigo = PlatformColor(red: 122/255, green: 44/255,  blue: 243/255, alpha: 1)
        let expectedViolet = PlatformColor(red: 156/255, green: 39/255,  blue: 255/255, alpha: 1)
        // Compare RGBA components in sRGB with tolerance, ignoring color-space metadata
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        indigo.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        expectedIndigo.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        XCTAssertEqual(r1, r2, accuracy: 1e-3)
        XCTAssertEqual(g1, g2, accuracy: 1e-3)
        XCTAssertEqual(b1, b2, accuracy: 1e-3)
        XCTAssertEqual(a1, a2, accuracy: 1e-3)
        violet.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        expectedViolet.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        XCTAssertEqual(r1, r2, accuracy: 1e-3)
        XCTAssertEqual(g1, g2, accuracy: 1e-3)
        XCTAssertEqual(b1, b2, accuracy: 1e-3)
        XCTAssertEqual(a1, a2, accuracy: 1e-3)
    }
    #endif

}
