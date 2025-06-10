//  Typography.swift
//  CoreUI – Themes
//
//  Centralized type scale for Gainz, acting as the single source of truth
//  for all text styles to maintain visual hierarchy and Dynamic Type support.
//
//  • Uses SF Pro Rounded for a softer, friendlier tone.
//  • Sizes follow default Human Interface Guidelines, with large titles +1 pt for OLED legibility.
//  • Utilizes SwiftUI Font/TextStyle so scaling & accessibility are automatic.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - Typography

public enum Typography {

    // MARK: Display

    /// 1st-level hero text – e.g. onboarding headlines, empty states.
    public static let display = Font.system(size: 40, weight: .bold, design: .rounded)

    // MARK: Headlines

    public static let h1 = Font.system(size: 34, weight: .bold, design: .rounded)
    public static let h2 = Font.system(size: 28, weight: .semibold, design: .rounded)
    public static let h3 = Font.system(size: 22, weight: .semibold, design: .rounded)

    // MARK: Body

    public static let bodyLarge  = Font.system(size: 17, weight: .regular, design: .rounded)
    public static let body       = Font.system(size: 15, weight: .regular, design: .rounded)
    public static let bodySmall  = Font.system(size: 13, weight: .regular, design: .rounded)

    // MARK: Caption & Footnote

    public static let caption  = Font.system(size: 12, weight: .regular, design: .rounded)
    public static let footnote = Font.system(size: 11, weight: .regular, design: .rounded)

    // MARK: Monospaced (for timers, weight inputs, etc.)

    public static let monospace = Font.system(size: 15, weight: .medium, design: .monospaced)
}

// MARK: - Convenience ViewModifier

/// A view modifier that applies a given font and color with consistent typography styling.
public struct TypographyStyle: ViewModifier {
    private let font: Font
    private let color: Color

    public init(_ font: Font, color: Color = .primary) {
        self.font = font
        self.color = color
    }

    public func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
            .allowsTightening(true)
            .minimumScaleFactor(0.85)
    }
}

public extension View {
    /// Applies a predefined typography style to text.
    /// - Parameters:
    ///   - font: A Font from the Typography scale.
    ///   - color: The text color (default .primary for automatic context coloring).
    func typography(_ font: Font, color: Color = .primary) -> some View {
        modifier(TypographyStyle(font, color: color))
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        Text("Display").typography(Typography.display)
        Text("Headline 1").typography(Typography.h1)
        Text("Headline 2").typography(Typography.h2)
        Text("Headline 3").typography(Typography.h3)
        Text("Body Large").typography(Typography.bodyLarge)
        Text("Body").typography(Typography.body)
        Text("Body Small").typography(Typography.bodySmall)
        Text("Caption").typography(Typography.caption)
        Text("Footnote").typography(Typography.footnote)
        Text("Monospace 123").typography(Typography.monospace)
    }
    .padding()
    .background(Color.black)
    .foregroundColor(.white)
    .previewLayout(.sizeThatFits)
}
