// swift-tools-version: 5.9
//
//  Package.swift
//  Gainz ▸ CoreUI
//
//  SwiftPM manifest for the cross-platform design-system module that houses
//  color tokens, typography, spacing utilities, and view modifiers.
//  ──────────────────────────────────────────────────────────────────────────
//  • No external dependencies – CoreUI must compile in isolation.
//  • Targets build for iOS, watchOS, visionOS, macOS, and tvOS.
//  • Resources pipeline injects asset catalogs and fonts.
//
//  Created on 27 May 2025.
//

import PackageDescription

let package = Package(
    name: "CoreUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        /// Library exposes `GainzColor`, `GainzFont`, `GradientButtonStyle`, etc.
        .library(name: "CoreUI", targets: ["CoreUI"])
    ],
    dependencies: [
        // Intentionally empty – keep zero-dependency footprint.
    ],
    targets: [
        .target(
            name: "CoreUI",
            dependencies: [],
            path: "Sources",
            resources: [
                // Asset catalogs (e.g., phoenix gradient, brand colors)
                .process("Resources/Assets.xcassets"),
                // Custom fonts (SF Pro display/rounded subsets)
                .process("Resources/Fonts")
            ],
            swiftSettings: [
                // Opt into modern concurrency checks on release builds.
                .unsafeFlags(["-Xfrontend", "-warn-concurrency"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "CoreUITests",
            dependencies: ["CoreUI"],
            path: "Tests"
        )
    ]
)
