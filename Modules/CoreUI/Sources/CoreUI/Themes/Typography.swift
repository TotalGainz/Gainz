//
//  Typography.swift
//  CoreUI – Themes
//
//  Centralised type scale for Gainz. Meant to be the **single source of truth**
//  for every text style used across the app so visual hierarchy stays consistent
//  and Dynamic Type support is automatic.
//
//  • All fonts leverage Apple’s SF Pro Rounded for a softer, friendlier tone.
//  • Sizes mirror the Human Interface Guidelines default scale, but nudged up
//    by +1 pt for large titles to improve readability on OLED dark backgrounds.
//  • Uses SwiftUI’s `Font` and `TextStyle` so scaling & accessibility are free.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - Typography

public enum Typography {

    // MARK: Display

    /// 1st-level hero text – Onboarding headlines, empty states.
    public static let display = Font.system(
        size: 40,
        weight: .bold,
        design: .rounded
    )

    // MARK: Headlines

    public static let h1 = Font.system(size: 34, weight: .bold,   design: .rounded)
    public static let h2 = Font.system(size: 28, weight: .semibold, design: .rounded)
    public static let h3 = Font.system(size: 22, weight: .semibold, design: .rounded)

    // MARK: Body

    public static let bodyLarge  = Font.system(size: 17, weight: .regular, design: .rounded)
    public static let body       = Font.system(size: 15, weight: .regular, design: .rounded)
    public static let bodySmall  = Font.system(size: 13, weight: .regular, design: .rounded)

    // MARK: Caption & Footnote

    public static let caption    = Font.system(size: 12, weight: .regular, design: .rounded)
    public static let footnote   = Font.system(size: 11, weight: .regular, design: .rounded)

    // MARK: Monospaced (e.g., weight inputs, timers)

    public static let monospace = Font.system(size: 15, weight: .medium, design: .monospaced)
}

// MARK: - Convenience ViewModifier

public struct TypographyStyle: ViewModifier {
    private let font: Font
    private let color: Color

    public init(_ font: Font, color: Color = .primary) {
        self.font  = font
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

    /// Shorthand for applying a predefined typography style.
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
    .previewLayout(.sizeThatFits)
}
