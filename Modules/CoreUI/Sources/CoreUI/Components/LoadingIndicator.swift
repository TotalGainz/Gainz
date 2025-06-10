//  LoadingIndicator.swift
//  CoreUI – Components
//
//  Brand-aware, lightweight loading spinner.
//  • 100% SwiftUI (no UIKit) – runs on all platforms.
//  • Uses Gainz color grammar: deep-black background + indigo-violet gradient.
//  • Built with vector shapes (no raster assets).
//  • Motion: 1.2s linear rotation, repeats indefinitely.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - LoadingIndicator

public struct LoadingIndicator: View {

    // Diameter of the spinner (points)
    private let size: CGFloat
    // Line width relative to size (0.0–1.0)
    private let strokeRatio: CGFloat

    @State private var isAnimating = false

    public init(size: CGFloat = 44, strokeRatio: CGFloat = 0.12) {
        self.size = size
        self.strokeRatio = strokeRatio
    }

    // MARK: Body
    public var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.8)  // use 80% of the circle (leave an open gap)
            .stroke(
                AngularGradient(
                    colors: [Color.brandIndigo, Color.brandViolet],
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: size * strokeRatio,
                    lineCap: .round
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                // Start spinning when view appears
                isAnimating = true
            }
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Preview

#Preview("Loading Indicator") {
    ZStack {
        Color.black.ignoresSafeArea()
        LoadingIndicator(size: 60)
    }
}
