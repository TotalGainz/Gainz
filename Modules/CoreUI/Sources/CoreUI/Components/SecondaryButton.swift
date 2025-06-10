//  SecondaryButton.swift
//  CoreUI – Components
//
//  Consistent "quiet" action button for secondary calls-to-action.
//  Design guidelines:
//  • States: normal, pressed, disabled
//  • Style: flat neutral surface with gradient outline
//  • Accessibility: minimum 44×44 pt hit area; supports Dynamic Type
//  • Animation: subtle press scale (0.97) with a short spring
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - SecondaryButtonStyle (Public API)

/// A button style that renders an outlined capsule with the Gainz indigo-to-violet gradient stroke.
/// Ideal for secondary actions like "Cancel", "Skip", or other less prominent options.
public struct SecondaryButtonStyle: ButtonStyle {

    // Inject design tokens from the environment (centralized theming)
    @Environment(\.colorPalette) private var palette
    @Environment(\.typography) private var font

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font.button)                         // use designated button font (scales with Dynamic Type)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(minHeight: 44)                      // ensure tap target meets accessibility minimum
            .foregroundStyle(palette.textPrimary)
            .overlay {
                // Gradient stroke outline
                Capsule()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: palette.brandGradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .background(
                // Neutral background that darkens when pressed
                Capsule()
                    .fill(palette.surfaceSecondary.opacity(configuration.isPressed ? 0.6 : 0.8))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.12, bounce: 0.25), value: configuration.isPressed)
            .opacity(configuration.isEnabled ? 1.0 : 0.4)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Convenience Extension

public extension ButtonStyle where Self == SecondaryButtonStyle {
    /// Shorthand for applying the secondary button style (e.g. `.buttonStyle(.secondary)`).
    static var secondary: SecondaryButtonStyle { .init() }
}

// MARK: - Preview

#Preview("Secondary Button") {
    VStack(spacing: 16) {
        Button("Secondary Action") {}.buttonStyle(.secondary)
        Button("Disabled Action") {}.buttonStyle(.secondary)
            .disabled(true)
    }
    .padding()
    .background(Color.black.ignoresSafeArea())
    .foregroundColor(.white)
    .previewLayout(.sizeThatFits)
}
