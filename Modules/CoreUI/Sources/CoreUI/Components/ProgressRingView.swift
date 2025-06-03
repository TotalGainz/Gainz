//
//  ProgressRingView.swift
//  CoreUI – Components
//
//  Circular progress indicator used for goals (volume, sets completed, etc.).
//  Brand-aligned: black canvas, indigo-violet gradient, smooth ease-out animation.
//  Pure SwiftUI; zero UIKit.  Works on iOS, watchOS, macOS, visionOS.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - ProgressRingView

public struct ProgressRingView: View {

    // Progress 0…1
    @Binding private var progress: Double
    // Ring diameter
    private let size: CGFloat
    // Line width (absolute, not ratio) so small rings stay readable
    private let lineWidth: CGFloat
    // Optional centered label (e.g., % string)
    private let label: () -> AnyView

    public init(
        progress: Binding<Double>,
        size: CGFloat = 80,
        lineWidth: CGFloat = 10,
        @ViewBuilder label: @escaping () -> some View = { EmptyView() }
    ) {
        self._progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.label = { AnyView(label()) }
    }

    // MARK: Body
    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.brandIndigo, .brandViolet]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // start at 12 o’clock
                .animation(.easeOut(duration: 0.5), value: progress)

            // Center content
            label()
                .frame(width: size * 0.6, height: size * 0.6)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Brand Colors (fallback)

private extension Color {
    static let brandIndigo = Color(red: 122 / 255, green: 44 / 255, blue: 243 / 255)
    static let brandViolet = Color(red: 156 / 255, green: 
