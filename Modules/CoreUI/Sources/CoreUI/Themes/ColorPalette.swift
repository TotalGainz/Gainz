// ColorPalette.swift
// CoreUI – Themes
//
// Centralized Gainz color tokens.
// • SwiftUI color extensions for semantic aliases.
// • Dark-mode–first; light-mode variants provided via assets.
// • Gradient helpers for the signature indigo→violet blend.
// • No external asset catalog required (colors defined in code).
//
// Created for Gainz on 27 May 2025.

import SwiftUI

// MARK: - Bundle Fallback

/// A dummy token for locating this module's bundle.
private class BundleToken {}

private extension Bundle {
    /// The bundle where Gainz design assets (like named colors) are located.
    /// Uses `Bundle.module` for SwiftPM; falls back to the main bundle for this module in other contexts.
    static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}

// MARK: - Semantic Colors

public extension Color {
    // Base surfaces
    static let surface = Color("Surface", bundle: .resourceBundle)            // dark: #000000, light: #FFFFFF
    static let surfaceElevated = Color("SurfaceElevated", bundle: .resourceBundle) // dark: #121212, light: #F8F8F8
    static let surfaceSecondary = Color("SurfaceSecondary", bundle: .resourceBundle) // (design token)

    // Text colors
    static let textPrimary = Color("TextPrimary", bundle: .resourceBundle)     // dark: #FFFFFF, light: #000000
    static let textSecondary = Color("TextSecondary", bundle: .resourceBundle) // dark: #B3B3B3, light: #5A5A5A

    // Brand colors (indigo → violet)
    static let brandIndigo = Color(red: 122/255, green: 44/255,  blue: 243/255)  // #7A2CF3
    static let brandViolet = Color(red: 156/255, green: 39/255,  blue: 255/255)  // #9C27FF
    static let brandGradientStart = brandIndigo
    static let brandGradientEnd   = brandViolet
    static let brandGradient      = [brandGradientStart, brandGradientEnd]       // [#7A2CF3, #9C27FF]

    // Status colors
    static let success = Color(red: 75/255,  green: 207/255, blue: 151/255) // #4BCF97
    static let warning = Color(red: 247/255, green: 198/255, blue: 28/255)  // #F7C61C
    static let error   = Color(red: 235/255, green: 87/255,  blue: 87/255)  // #EB5757
}

// MARK: - Gradient Helpers

public extension LinearGradient {
    /// Default Gainz brand gradient (left-to-right).
    static let brandHorizontal = LinearGradient(
        colors: Color.brandGradient,
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Vertical variant of the Gainz brand gradient.
    static let brandVertical = LinearGradient(
        colors: Color.brandGradient,
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Preview

#if DEBUG
struct ColorPalette_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            Text("Primary").foregroundColor(.textPrimary)
            Text("Secondary").foregroundColor(.textSecondary)
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient.brandHorizontal)
                .frame(height: 44)
                .overlay(Text("Gradient CTA").foregroundColor(.white))
        }
        .padding(24)
        .background(Color.surface)
        .previewLayout(.sizeThatFits)
    }
}
#endif
