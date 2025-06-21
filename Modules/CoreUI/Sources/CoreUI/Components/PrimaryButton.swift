// PrimaryButton.swift
// CoreUI – Components
//
// Gainz primary call-to-action button.
// • Indigo-to-violet gradient background, 24 pt corner radius.
// • Scales down slightly on press for tactile feedback.
// • Supports Dynamic Type & Accessibility.
// • Uses environment-driven colors and typography for theming.
//
// Created on 27 May 2025.

import SwiftUI

// MARK: - PrimaryButtonStyle

public struct PrimaryButtonStyle: ButtonStyle {
    // Inject design tokens from the environment for theming
    @Environment(\.colorPalette) private var palette
    @Environment(\.typography) private var typography

    public func makeBody(configuration: Configuration) -> some View {
        let gradient = LinearGradient(
            gradient: Gradient(colors: palette.brandGradient),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return configuration.label
            .font(typography.button)  // Use designated button font (scales with Dynamic Type)
            .foregroundColor(.white)  // White text on brand gradient
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity) // Full-width button
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(gradient)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0) // Press-down effect
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Convenience API

public extension Button where Label == Text {
    /// Creates a full-width primary CTA button with the given title.
    /// (Avoids generic label inference by returning a concrete Button<Text>.)
    /// Creates a full-width primary CTA button with the given title.
    /// Returns an opaque view conforming to primary style.
    static func primary<S: StringProtocol>(_ title: S, action: @escaping () -> Void) -> some View {
        // Using the `title` initializer avoids a closure and clarifies the Label type.
        Button(title, action: action)
            .buttonStyle(.primary)
    }
}

// MARK: - Convenience Style Extension

public extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Shorthand for applying the primary button style (e.g. `.buttonStyle(.primary)`).
    static var primary: PrimaryButtonStyle { .init() }
}

// MARK: - Preview

#if DEBUG
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
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
}
#endif
