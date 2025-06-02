//
//  PrimaryButton.swift
//  CoreUI ▸ Components
//
//  Gainz primary call-to-action button.
//  • Gradient violet accent, 24 pt corner radius.
//  • Scales down slightly on press for tactile feedback.
//  • Dynamic Type & Accessibility ready.
//
//  Created on 27 May 2025.
//

import SwiftUI

// MARK: - PrimaryButtonStyle

public struct PrimaryButtonStyle: ButtonStyle {

    // Gradient tokens fetched from Asset catalog (or SwiftGen)
    private let gradient = LinearGradient(
        colors: [Color("AccentPurpleStart"), Color("AccentPurpleEnd")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(gradient)
                    .shadow(color: Color.black.opacity(0.25),
                            radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7),
                       value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Convenience API

public extension Button {

    /// Gainz convenience wrapper – keeps call-site terse.
    static func primary(_ title: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            Button.primary("Log Workout") { }
            Button.primary("Start Session") { }
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .previewLayout(.sizeThatFits)
    }
}
#endif
