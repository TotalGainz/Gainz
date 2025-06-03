//
//  CustomTabBarItemView.swift
//  CoreUI – Components
//
//  Gainz-branded tab-bar item with gradient accent and subtle haptics.
//  • Works with a `TabItem` model (icon SF Symbol + title).
//  • Animates size/opacity on selection.
//  • Dark-mode first; light-mode inverts legibility automatically.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - Model

/// Simple data model describing a tab-bar slot.
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
        .contentShape(Rectangle())         // larger tap target
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .onChange(of: isSelected) { newValue in
            if newValue { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        .accessibilityLabel(item.title)
    }

    // MARK: Private helpers
    private var iconGradient: LinearGradient {
        isSelected
        ? LinearGradient(
            colors: [.brandIndigo, .brandViolet],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        : LinearGradient(
            colors: [Color.gray.opacity(0.6)],
            startPoint: .top, endPoint: .bottom)
    }

    private var labelColor: Color {
        isSelected ? .white : .gray.opacity(0.7)
    }

    private var backgroundHighlight: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.brandIndigo, .brandViolet],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .fixedLayout(width: 160, height: 60)) {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 0) {
            CustomTabBarItemView(item: TabItem(systemIconName: "house.fill", title: "Home"), isSelected: true)
            CustomTabBarItemView(item: TabItem(systemIconName: "figure.walk", title: "Workouts"), isSelected: false)
        }
    }
}
