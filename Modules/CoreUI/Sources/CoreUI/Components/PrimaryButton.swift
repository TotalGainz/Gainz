//  PrimaryButton.swift
//  CoreUI – Components
//
//  Gainz primary call-to-action button.
//  • Violet gradient background, 24 pt corner radius.
//  • Scales down slightly on press for tactile feedback.
//  • Supports Dynamic Type & Accessibility out of the box.
//
//  Created on 27 May 2025.
//

import SwiftUI

// MARK: - PrimaryButtonStyle

public struct PrimaryButtonStyle: ButtonStyle {

    // Brand gradient background for the button
    private let gradient = LinearGradient(
        colors: [Color.brandIndigo, Color.brandViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(gradient)
                    .shadow(color: Color.black.opacity(0.25),
                            radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)  // press-down effect
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Convenience API

public extension Button {
    /// Creates a full-width primary CTA button with the given title.
    static func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

// MARK: - Convenience Style Extension

public extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Shorthand for applying the primary button style (e.g. `.buttonStyle(.primary)`).
    static var primary: PrimaryButtonStyle { .init() }
}

// MARK: - Preview

#Preview("Primary Button") {
    VStack(spacing: 24) {
        Button.primary("Log Workout") {}
        Button("Start Session") {}.buttonStyle(.primary)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    .padding()
    .background(Color.black.ignoresSafeArea())
    .foregroundColor(.white)
    .previewLayout(.sizeThatFits)
}
