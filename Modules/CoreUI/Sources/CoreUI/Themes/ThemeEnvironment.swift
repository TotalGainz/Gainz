// ThemeEnvironment.swift
// CoreUI – Themes
//
// Custom environment keys for theming and typography injection across Gainz UI components.
// • Provides a ColorPalette and TypographyPalette via SwiftUI's environment for dynamic theming.
// • Default values use Gainz's standard color tokens and type scale.
// • Developers can override these at runtime for custom themes (e.g. dark/light or accessibility).
//
// Created for Gainz on 10 June 2025.

import SwiftUI

// MARK: - Design Token Containers

/// A collection of named colors (design tokens) representing the app's color palette.
/// Use this to access semantic colors (e.g., surfaces, text, brand colors) in a themable way.
/// By injecting a custom `ColorPalette` into the SwiftUI environment, you can
/// override the app's default colors dynamically.
public struct ColorPalette {
    // Core surface colors
    public var surface: Color            // Primary background surface (base background)
    public var surfaceElevated: Color    // Elevated surface (cards, sheets, etc.)
    public var surfaceSecondary: Color   // Secondary background (e.g. for buttons, secondary elements)

    // Text colors
    public var textPrimary: Color        // Primary text color (on primary surfaces)
    public var textSecondary: Color      // Secondary text color (subtitles, hints, etc.)

    // Brand colors & gradients
    public var brandIndigo: Color        // Primary brand color (indigo)
    public var brandViolet: Color        // Secondary brand color (violet)
    /// Array of brand colors forming the default gradient (indigo → violet).
    public var brandGradient: [Color] {
        [brandIndigo, brandViolet]
    }

    // Status colors
    public var success: Color           // Success state (e.g. positive feedback)
    public var warning: Color           // Warning/caution state
    public var error: Color             // Error state (critical issues)

    /// Initializes a color palette. If no parameters are provided, the app's default theme colors are used.
    public init(
        surface: Color = .surface,
        surfaceElevated: Color = .surfaceElevated,
        surfaceSecondary: Color = .surfaceSecondary,
        textPrimary: Color = .textPrimary,
        textSecondary: Color = .textSecondary,
        brandIndigo: Color = .brandIndigo,
        brandViolet: Color = .brandViolet,
        success: Color = .success,
        warning: Color = .warning,
        error: Color = .error
    ) {
        // Using static color aliases ensures correct resource bundle is used (works in SwiftPM or Xcode).
        self.surface = surface
        self.surfaceElevated = surfaceElevated
        self.surfaceSecondary = surfaceSecondary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.brandIndigo = brandIndigo
        self.brandViolet = brandViolet
        self.success = success
        self.warning = warning
        self.error = error
    }
}

/// A collection of font styles (design tokens) representing the app's typography scale.
/// This mirrors Gainz's type scale defined in `Typography.swift`.
/// An explicit `button` style is included for controls. Inject a custom `TypographyPalette`
/// via the environment to override font choices (e.g., for theming or accessibility).
public struct TypographyPalette {
    // Display and headline fonts
    public var display: Font      // Largest display style (e.g. onboarding hero text)
    public var h1: Font           // Primary header (large title)
    public var h2: Font           // Secondary header
    public var h3: Font           // Tertiary header

    // Body and supplementary text fonts
    public var bodyLarge: Font    // Larger body text (emphasis)
    public var body: Font         // Default body text
    public var bodySmall: Font    // Small body text (fine print)
    public var caption: Font      // Caption text
    public var footnote: Font     // Footnote text

    // Monospaced and control fonts
    public var monospace: Font    // Monospaced font (numeric data, timers, etc.)
    public var button: Font       // Font for buttons and controls

    /// Initializes a typography palette. Defaults use the Gainz standard font (SF Pro Rounded) at various sizes.
    /// - Note: All default fonts scale with Dynamic Type to support accessibility.
    public init(
        display: Font = Typography.display,
        h1: Font = Typography.h1,
        h2: Font = Typography.h2,
        h3: Font = Typography.h3,
        bodyLarge: Font = Typography.bodyLarge,
        body: Font = Typography.body,
        bodySmall: Font = Typography.bodySmall,
        caption: Font = Typography.caption,
        footnote: Font = Typography.footnote,
        monospace: Font = Typography.monospace,
        button: Font = Font.system(size: 17, weight: .semibold, design: .rounded) // Default button font
    ) {
        // Default values align with the Typography scale; these can be overridden via the environment.
        self.display = display
        self.h1 = h1
        self.h2 = h2
        self.h3 = h3
        self.bodyLarge = bodyLarge
        self.body = body
        self.bodySmall = bodySmall
        self.caption = caption
        self.footnote = footnote
        self.monospace = monospace
        self.button = button
    }
}

// MARK: - Environment Keys & Values

/// EnvironmentKey for the current ColorPalette.
/// By default, this is Gainz's standard dark-mode-first color palette.
private struct ColorPaletteKey: EnvironmentKey {
    @MainActor static let defaultValue: ColorPalette = ColorPalette()
}

private struct TypographyKey: EnvironmentKey {
    @MainActor static let defaultValue: TypographyPalette = TypographyPalette()
}

public extension EnvironmentValues {
    /// The active color palette for theming UI components.
    /// Use this to access or override the app's colors dynamically.
    /// All Gainz UI components (e.g. PrimaryButton, SecondaryButton) read from this palette.
    /// Example: `.environment(\.colorPalette, myPalette)`.
    var colorPalette: ColorPalette {
        get { self[ColorPaletteKey.self] }
        set { self[ColorPaletteKey.self] = newValue }
    }

    /// The active typography palette for styling text in UI components.
    /// Gainz components (buttons, labels) use this to determine font styles (`button` font, etc).
    /// Example: `.environment(\.typography, myTypographyPalette)`.
    var typography: TypographyPalette {
        get { self[TypographyKey.self] }
        set { self[TypographyKey.self] = newValue }
    }
}
