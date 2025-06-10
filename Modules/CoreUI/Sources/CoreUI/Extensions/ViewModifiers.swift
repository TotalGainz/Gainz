//  ViewModifiers.swift
//  CoreUI – Extensions
//
//  Collection of brand-specific SwiftUI view modifiers that
//  encapsulate common styling rules: card surfaces, gradient text,
//  and phoenix-wing shadows.
//
//  Import only in SwiftUI layers; never link Domain / Persistence.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - CardStyle

/// Applies Gainz’ unified card appearance:
/// • Deep-black surface (`Color.black` with 90% opacity)
/// • 24 pt corner radius
/// • Soft shadow that mimics logo wing glow
public struct CardStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding()  // interior spacing
            .background(Color.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.brandViolet.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

public extension View {
    /// Shorthand for applying Gainz card style.
    func gainzCard() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - GradientText

/// Renders text with the indigo-to-violet brand gradient.
public struct GradientText: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .foregroundStyle(LinearGradient(
                colors: [Color.brandIndigo, Color.brandViolet],
                startPoint: .leading, endPoint: .trailing
            ))
    }
}

public extension View {
    /// Shorthand for applying Gainz gradient text styling.
    func gainzGradientText() -> some View {
        modifier(GradientText())
    }
}

// MARK: - SectionHeader

/// Standardised section header styling: semibold font, gradient text,
/// top alignment with extra top padding, and marked as header for accessibility.
public struct SectionHeader: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.system(.title3, design: .rounded, weight: .semibold))
            .gainzGradientText()
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

public extension View {
    /// Shorthand for applying Gainz section header style.
    func gainzSectionHeader() -> some View {
        modifier(SectionHeader())
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        Text("Dashboard")
            .gainzSectionHeader()

        Text("This is a card surface with Gainz styling.")
            .gainzCard()

        Text("Gradient Title")
            .font(.largeTitle.bold())
            .gainzGradientText()
    }
    .padding()
    .background(Color.black.ignoresSafeArea())
}
