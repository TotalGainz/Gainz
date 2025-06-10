//  ProgressRingView.swift
//  CoreUI – Components
//
//  Circular progress indicator for goals (volume, sets completed, etc.).
//  Brand-aligned: black background, indigo-violet gradient, smooth ease-out animation.
//  100% SwiftUI (no UIKit). Works on iOS, watchOS, macOS, visionOS.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - ProgressRingView

public struct ProgressRingView<Label: View>: View {

    // Progress fraction (0.0 to 1.0)
    @Binding private var progress: Double
    // Ring diameter in points
    private let size: CGFloat
    // Stroke line width (absolute, not relative)
    private let lineWidth: CGFloat
    // Optional center label content
    private let labelContent: () -> Label

    public init(
        progress: Binding<Double>,
        size: CGFloat = 80,
        lineWidth: CGFloat = 10,
        @ViewBuilder label: @escaping () -> Label = { EmptyView() }
    ) {
        self._progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.labelContent = label
    }

    // MARK: Body
    public var body: some View {
        ZStack {
            // Background track (faint circular track)
            Circle()
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress arc (trimmed circle indicating progress)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [Color.brandIndigo, Color.brandViolet],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))  // start at 12 o’clock (top)
                .animation(.easeOut(duration: 0.5), value: progress)

            // Center content (e.g., percentage text)
            labelContent()
                .frame(width: size * 0.6, height: size * 0.6)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Preview

#Preview("Progress Ring") {
    VStack(spacing: 16) {
        ProgressRingView(progress: .constant(0.75)) {
            Text("75%")
                .foregroundColor(.white)
                .font(.headline)
        }
        .frame(width: 100, height: 100)
        ProgressRingView(progress: .constant(0.3))
            .frame(width: 100, height: 100)
    }
    .padding()
    .background(Color.black)
    .foregroundColor(.white)
}
