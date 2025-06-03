// swift-tools-version: 5.9
//
//  package.swift
//  Gainz ▸ AnalyticsService
//
//  Provides local + remote analytics for workout sessions and app events.
//  Pure SwiftPM target so it can compile on iOS, watchOS, visionOS, macOS, and server-side Swift.
//
//  Dependencies
//  ────────────
//  • Domain            – value-type models (MesocyclePlan, WorkoutSession, …)
//  • CorePersistence    – repositories for Core Data & cloud sync
//  • swift-algorithms   – sampling & rolling-window helpers (SPM URL)
//  • swift-collections  – OrderedSet, Deque (SPM URL)
//  • swift-crypto       – HMAC signing for batched uploads (SPM URL)
//
//  Created 27 May 2025.
//

import PackageDescription

let package = Package(
    name: "AnalyticsService",
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
            name: "AnalyticsService",
            targets: ["AnalyticsService"]
        )
    ],
    dependencies: [
        // Apple open-source packages
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        // Local workspace packages
        .package(name: "Domain", path: "../../PlatformAgnostic/Domain"),
        .package(name: "CorePersistence", path: "../CorePersistence")
    ],
    targets: [
        .target(
            name: "AnalyticsService",
            dependencies: [
                "Domain",
                "CorePersistence",
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Crypto", package: "swift-crypto")
            ],
            path: "Sources",
            swiftSettings: [
                // Treat warnings as errors in CI
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "AnalyticsServiceTests",
            dependencies: ["AnalyticsService"],
            path: "Tests"
        )
    ]
)
