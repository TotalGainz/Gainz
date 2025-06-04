//
//  OnboardingView.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI

// MARK: - OnboardingView
@MainActor
public struct OnboardingView: View {

    // MARK: State
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = OnboardingPage.samplePages

    // MARK: Body
    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                        .accessibilityElement(children: .contain)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            PageControl(numberOfPages: pages.count, currentPage: $currentPage)
                .padding(.vertical, 12)

            primaryButton(title: currentPage == pages.lastIndex ? "Get Started" : "Next") {
                advance()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Helpers
    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation { currentPage += 1 }
        } else {
            dismiss()
        }
    }

    @ViewBuilder
    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x8C3DFF), Color(hex: 0x4925D6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityLabel(title)
        }
    }
}

// MARK: - OnboardingPageView
private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 260)
                .accessibilityHidden(true)

            Text(page.title)
                .font(.system(.title, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .accessibilityAddTraits(.isHeader)

            Text(page.subtitle)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PageControl
private struct PageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { i in
                Circle()
                    .fill(i == currentPage ? Color(hex: 0x8C3DFF) : Color.gray.opacity(0.4))
                    .frame(width: i == currentPage ? 10 : 8, height: i == currentPage ? 10 : 8)
                    .scaleEffect(i == currentPage ? 1.2 : 1)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }
}

// MARK: - Models
private struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String

    static let samplePages: [OnboardingPage] = [
        .init(imageName: "Phoenix-Logo",
              title: "Rise Stronger",
              subtitle: "Smarter training plans driven by cutting-edge sports science."),
        .init(imageName: "Chart-Progress",
              title: "Track Everything",
              subtitle: "Lift logs, nutrition, sleep and recovery in one seamless hub."),
        .init(imageName: "Community",
              title: "Beat Your Best",
              subtitle: "Compete with friends and climb the leaderboards.")
    ]
}

// MARK: - Utilities
private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex & 0xFF0000) >> 16) / 255,
            green: Double((hex & 0x00FF00) >> 8) / 255,
            blue: Double(hex & 0x0000FF) / 255,
            opacity: opacity
        )
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif
