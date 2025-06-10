//  AvatarView.swift
//  CoreUI – Components
//
//  Circular avatar that renders either
//  • a remote image (AsyncImage, iOS 15+),
//  • a local Image/UIImage,
//  • the user’s initials inside a gradient ring, or
//  • a default placeholder silhouette.
//
//  Brand cohesion: deep-black canvas, indigo-to-violet stroke.
//  100% SwiftUI (no UIKit), so it works on iOS, watchOS, macOS, visionOS.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI

// MARK: - AvatarView

public struct AvatarView: View {

    // MARK: Public API

    public enum Source: Equatable {
        case asyncURL(URL)
        case image(Image)      // e.g. Image("profile_pic")
        case initials(String)  // up to 3 characters recommended
        case placeholder       // default silhouette icon
    }

    private let source: Source
    private let size: CGFloat
    private let ringWidth: CGFloat

    /// Creates a circular avatar view.
    /// - Parameters:
    ///   - source: The image source for the avatar (URL, Image, initials, or placeholder).
    ///   - size: Diameter of the avatar in points (default 56).
    ///   - ringWidth: Width of the outer gradient ring stroke (default 2).
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
            // Gradient ring border
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.brandIndigo, Color.brandViolet]),
                        center: .center
                    ),
                    lineWidth: ringWidth
                )
            // Avatar content
            contentView
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }

    // MARK: - Private Views

    @ViewBuilder
    private var contentView: some View {
        switch source {
        case .asyncURL(let url):
            // Remote image from URL
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                placeholderView
            }
        case .image(let image):
            // Already available local image
            image
                .resizable()
                .scaledToFill()
        case .initials(let text):
            // User initials with gradient background
            Text(text)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.brandIndigo, Color.brandViolet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .placeholder:
            // Default placeholder silhouette
            placeholderView
        }
    }

    /// Default placeholder view (silhouette icon).
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

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        AvatarView(source: .asyncURL(URL(string: "https://source.unsplash.com/random/400x400")!), size: 72)
        AvatarView(source: .initials("BH"))
        AvatarView(source: .placeholder)
    }
    .padding()
    .background(Color.black.ignoresSafeArea())
}
