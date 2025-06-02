//
//  SecondaryButton.swift
//  CoreUI – Components
//
//  Consistent “quiet” action button used for secondary calls-to-action.
//  Design rules
//  ────────────────────────────────────────────────────
//  • States: normal, pressed, disabled.
//  • Visual hierarchy: flat neutral surface, brand-gradient stroke.
//  • Accessibility: minimum 44×44 pt hit-target, Dynamic Type label.
//  • Animations: subtle scale-down on press (0.97, 120 ms spring).
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Combine

// MARK: - Public API

/// A button style that renders an outlined capsule with the Gainz
/// indigo-to-violet gradient stroke. Ideal for “Cancel”, “Skip”,
/// or secondary progression actions.
public struct SecondaryButtonStyle: ButtonStyle {

    // Injected design tokens (keeps CoreUI centralised)
    @Environment(\.colorPalette) private var palette
    @Environment(\.typography)   private var font

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font.button)                         // Scales with Dynamic Type
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(minHeight: 44)                       // a11y hit target
            .foregroundStyle(palette.textPrimary)
            .overlay {
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
                Capsule()
                    .fill(palette.surfaceSecondary.opacity(
                        configuration.isPressed ? 0.6 : 0.8
                    ))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                .spring(duration: 0.12, bounce: 0.25),
                value: configuration.isPressed
            )
            .opacity(configuration.isEnabled ? 1 : 0.4)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Convenience Extension

public extension ButtonStyle where Self == SecondaryButtonStyle {
    /// Shorthand `.buttonStyle(.secondary)` usage.
    static var secondary: SecondaryButtonStyle { .init() }
}

// MARK: - Preview

#if DEBUG
#Preview("Secondary Button") {
    Button("Secondary Action") {}
        .buttonStyle(.secondary)
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color.black)        // Simulate dark mode surface
}
#endif
