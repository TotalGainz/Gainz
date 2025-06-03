//
//  LoadingIndicator.swift
//  CoreUI – Components
//
//  Brand-aware, lightweight loading spinner.
//  • SwiftUI-only (no UIKit), so it runs everywhere.
//  • Respects Gainz color grammar: deep-black canvas + indigo-violet gradient.
//  • Uses vector shapes, no raster assets.
//  • Motion: 1.2 s linear rotation, infinite.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - LoadingIndicator

public struct LoadingIndicator: View {

    // Diameter of the spinner
    private let size: CGFloat
    // Line width relative to size (0…1)
    private let strokeRatio: CGFloat

    public init(size: CGFloat = 44, strokeRatio: CGFloat = 0.12) {
        self.size = size
        self.strokeRatio = strokeRatio
    }

    // MARK: Body
    public var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.8)              // open-ended 80 % arc
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [.brandIndigo, .brandViolet]),
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: size * strokeRatio,
                    lineCap: .round
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1.2).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.isImage)
    }

    // MARK: Private
    @State private var isAnimating = false
}

// MARK: - Brand Colors (fallback)

private extension Color {

    /// Gainz primary gradient start (indigo #7A2CF3)
    static let brandIndigo = Color(red: 122 / 255, green: 44 / 255, blue: 243 / 255)

    /// Gainz primary gradient end (violet #9C27FF)
    static let brandViolet = Color(red: 156 / 255, green: 39 / 255, blue: 255 / 255)
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LoadingIndicator(size: 60)
    }
}
