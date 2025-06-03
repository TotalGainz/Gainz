//
//  StreakBadgeView.swift
//  HomeFeature ▸ Widgets
//
//  A tiny, reusable SwiftUI component that visualises the athlete’s
//  consecutive-day workout streak.  Designed for inline use on the Home
//  tab, but small enough to embed inside push-notification previews,
//  lock-screen widgets, and watch-complications.
//
//  ─────────────────────────────────────────────────────────────
//  • BRAND — pulls gradient & typography from CoreUI tokens.
//  • ACCESSIBILITY — VoiceOver announces streak count + context.
//  • ANIMATION — spring-loaded bump when the streak increments.
//  • NO HRV / recovery / velocity metrics.
//  ─────────────────────────────────────────────────────────────
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import CoreUI          // Gradient.palette, Font.bodySmall, etc.

public struct StreakBadgeView: View {

    // MARK: - Input
    public let streakCount: Int    // e.g. 7 → “🔥 7-day streak”

    // MARK: - Body
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

    // MARK: - Gradient
    private var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: CoreUI.Gradient.phoenix),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview
#if DEBUG
struct StreakBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StreakBadgeView(streakCount: 7)
                .previewLayout(.sizeThatFits)
                .padding()
                .background(Color.black)

            StreakBadgeView(streakCount: 42)
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
                .padding()
        }
    }
}
#endif
