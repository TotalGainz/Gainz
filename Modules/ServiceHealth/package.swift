// swift-tools-version: 5.9
//
//  package.swift
//  Gainz ▸ ServiceHealth
//
//  Abstraction layer over HealthKit, local notifications, and background
//  refresh tasks. Keeps the rest of the codebase platform-agnostic by
//  hiding Apple-specific frameworks behind a pure-Swift API.
//
//  Created 27 May 2025.
//

import PackageDescription

let package = Package(
    name: "ServiceHealth",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .macOS(.v13),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ServiceHealth",
            targets: ["ServiceHealth"]
        )
    ],
    dependencies: [
        // Local workspace packages
        .package(name: "Domain", path: "../../PlatformAgnostic/Domain"),
        .package(name: "CorePersistence", path: "../CorePersistence")
    ],
    targets: [
        .target(
            name: "ServiceHealth",
            dependencies: [
                "Domain",
                "CorePersistence"
            ],
            path: "Sources",
            swiftSettings: [
                // Enforce warning-free production builds
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "ServiceHealthTests",
            dependencies: ["ServiceHealth"],
            path: "Tests"
        )
    ]
)
