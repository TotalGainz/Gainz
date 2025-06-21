//  CustomTabBarItemView.swift
//  CoreUI – Components
//
//  Gainz-branded tab bar item with gradient accent and subtle haptics.
//  • Works with a `TabItem` model (SF Symbol icon + title).
//  • Animates highlight on selection (with ease-in-out).
//  • Dark-mode first; automatically adjusts for light mode legibility.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Model

/// Simple data model describing a tab bar item (icon and title).
public struct TabItem: Identifiable, Hashable {
    public let id = UUID()
    public let systemIconName: String
    public let title: String

    public init(systemIconName: String, title: String) {
        self.systemIconName = systemIconName
        self.title = title
    }
}

// MARK: - View

public struct CustomTabBarItemView: View {
    let item: TabItem
    let isSelected: Bool

    public init(item: TabItem, isSelected: Bool) {
        self.item = item
        self.isSelected = isSelected
    }

    // MARK: Body
    public var body: some View {
        VStack(spacing: 4) {
            Image(systemName: item.systemIconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconGradient)
                .frame(height: 24)
            Text(item.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(labelColor)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(backgroundHighlight)
        .contentShape(Rectangle())        // expands tappable area
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .onChange(of: isSelected) { selected in
            if selected {
                // Subtle haptic feedback on selection (iOS/tvOS only)
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
        }
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Private Helpers

    /// Gradient for the icon: brand colors when selected, gray when not.
    private var iconGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [Color.brandIndigo, Color.brandViolet],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray.opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    /// Label color: white when selected, muted gray when not.
    private var labelColor: Color {
        isSelected ? .white : .gray.opacity(0.7)
    }

    /// Background highlight for selected state (rounded rectangle with gradient stroke).
    private var backgroundHighlight: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.brandIndigo, Color.brandViolet],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
        }
    }
}

// MARK: - SwiftUI Previews

#if DEBUG
/// Live preview of `CustomTabBarItemView` to validate layout, theming, and interaction.
/// Uses fixed dimensions to isolate the component in Xcode Canvas.
@available(iOS 17.0, tvOS 17.0, watchOS 10.0, macOS 14.0, *)
#Preview("CustomTabBarItemView", traits: .fixedLayout(width: 160, height: 60)) {
    ZStack {
        Color.surfaceElevated.ignoresSafeArea()
        HStack(spacing: 0) {
            CustomTabBarItemView(
                item: TabItem(systemIconName: "house.fill", title: "Home"),
                isSelected: true
            )
            CustomTabBarItemView(
                item: TabItem(systemIconName: "figure.walk", title: "Workouts"),
                isSelected: false
            )
        }
    }
}
#endif
