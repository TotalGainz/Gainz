// MARK: - StreakBadgeView.swift

import SwiftUI
import CoreUI          // Gradient palette, font tokens, etc.

/// A small badge showing the athlete’s consecutive-day workout streak.
public struct StreakBadgeView: View {
    // MARK: Input

    public let streakCount: Int

    // MARK: Body

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(gradient)
            Text("\(streakCount)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(gradient)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .contentShape(Capsule(style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streakCount)-day workout streak, keep it up!")
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: streakCount)
    }

    // MARK: - Private

    /// Brand gradient for the flame icon and badge background.
    private var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: CoreUI.Gradient.phoenix),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
