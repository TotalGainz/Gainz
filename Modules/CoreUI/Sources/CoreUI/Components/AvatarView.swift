//
//  AvatarView.swift
//  CoreUI – Components
//
//  Circular avatar that renders either
//  • a remote image (AsyncImage, iOS 15+),
//  • a local Image/UIImage,
//  • or the user’s initials inside a gradient ring.
//
//  Brand cohesion: deep-black canvas, indigo-to-violet stroke.
//  Zero UIKit; 100 % SwiftUI so it ports to watchOS / visionOS.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - AvatarView

public struct AvatarView: View {

    // MARK: Public API
    public enum Source: Equatable {
        case asyncURL(URL)
        case image(Image)       // e.g. Image("profile_pic")
        case initials(String)   // up to 3 chars recommended
        case placeholder        // default silhouette
    }

    private let source: Source
    private let size: CGFloat
    private let ringWidth: CGFloat

    /// Creates an avatar.
    /// - Parameters:
    ///   - source: Where the avatar visual should come from.
    ///   - size: Diameter of the avatar in points (default = 56).
    ///   - ringWidth: Width of the gradient stroke (default = 2).
    public init(
        source: Source,
        size: CGFloat = 56,
        ringWidth: CGFloat = 2
    ) {
        self.source = source
        self.size = size
        self.ringWidth = ringWidth
    }

    // MARK: Body
    public var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [.brandIndigo, .brandViolet]),
                        center: .center
                    ),
                    lineWidth: ringWidth
                )
                .frame(width: size, height: size)
                .overlay(contentView.clipShape(Circle()))
        }
    }

    // MARK: Private

    @ViewBuilder
    private var contentView: some View {
        switch source {
        case .asyncURL(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholderView
                }
            }
        case .image(let image):
            image
                .resizable()
                .scaledToFill()
        case .initials(let text):
            Text(text)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [.brandIndigo, .brandViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .placeholder:
            placeholderView
        }
    }

    private var placeholderView: some View {
        Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .padding(size * 0.18)
            .foregroundStyle(Color.gray.opacity(0.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.6))
    }
}

// MARK: - Brand Colors (fallback)

private extension Color {
    static let brandIndigo = Color(red: 122 / 255, green: 44 / 255, blue: 243 / 255)
    static let brandViolet = Color(red: 156 / 255, green: 39 / 255, blue: 255 / 255)
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        AvatarView(
            source: .asyncURL(URL(string: "https://source.unsplash.com/random/400x400")!),
            size: 72
        )
        AvatarView(source: .initials("BH"))
        AvatarView(source: .placeholder)
    }
    .padding()
    .background(Color.black.ignoresSafeArea())
}
