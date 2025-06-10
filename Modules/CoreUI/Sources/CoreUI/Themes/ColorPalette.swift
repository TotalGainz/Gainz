//  ColorPalette.swift
//  CoreUI – Themes
//
//  Centralized Gainz color tokens.
//  -------------------------------------------------------------
//  • SwiftUI color extensions + semantic aliases.
//  • Dark-mode first; light mode variants provided via assets.
//  • Gradient helpers for the signature indigo→violet blend.
//  • No external asset catalog required (colors defined in code).
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - Semantic Colors

public extension Color {

    // Base surfaces
    static let surface        = Color("Surface", bundle: .module)          // #000000  / #FFFFFF
    static let surfaceElevated = Color("SurfaceElevated", bundle: .module) // #121212  / #F8F8F8

    // Text
    static let textPrimary   = Color("TextPrimary", bundle: .module)       // #FFFFFF  / #000000
    static let textSecondary = Color("TextSecondary", bundle: .module)     // #B3B3B3  / #5A5A5A

    // Brand
    static let brandIndigo   = Color(red: 122/255, green: 44/255,  blue: 243/255)  // #7A2CF3
    static let brandViolet   = Color(red: 156/255, green: 39/255,  blue: 255/255)  // #9C27FF
    static let brandGradientStart = brandIndigo
    static let brandGradientEnd   = brandViolet
    static let brandGradient      = [brandGradientStart, brandGradientEnd] // [#7A2CF3, #9C27FF]

    // Status
    static let success = Color(red: 75/255,  green: 207/255, blue: 151/255) // #4BCF97
    static let warning = Color(red: 247/255, green: 198/255, blue: 28/255)  // #F7C61C
    static let error   = Color(red: 235/255, green: 87/255,  blue: 87/255)  // #EB5757
}

// MARK: - Gradient Helpers

public extension LinearGradient {

    /// Default Gainz left-to-right brand gradient.
    static let brandHorizontal = LinearGradient(
        colors: [.brandGradientStart, .brandGradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Top-to-bottom variant for buttons and strokes.
    static let brandVertical = LinearGradient(
        colors: [.brandGradientStart, .brandGradientEnd],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        Text("Primary").foregroundColor(.textPrimary)
        Text("Secondary").foregroundColor(.textSecondary)
        RoundedRectangle(cornerRadius: 12)
            .fill(.brandHorizontal)
            .frame(height: 44)
            .overlay(Text("Gradient CTA").foregroundColor(.white))
    }
    .padding(24)
    .background(Color.surface)
    .previewLayout(.sizeThatFits)
}
