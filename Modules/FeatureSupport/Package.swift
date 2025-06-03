// swift-tools-version: 5.9
//
//  package.swift
//  Gainz ▸ FeatureSupport
//
//  Hosts shared view-model helpers, environment adapters, and reusable
//  Combine utilities consumed by every Feature/* module. Pure SwiftPM
//  so feature bundles can import it on iOS, watchOS, visionOS, macOS.
//
//  Dependencies
//  ────────────
//  • Domain            – value-type models & business rules
//  • CoreUI            – design tokens, typography, colors
//  • ServiceHealth     – permission helpers & local-notification bridge
//  • AnalyticsService  – event emitter interfaces
//
//  Created 27 May 2025.
//

import PackageDescription

let package = Package(
    name: "FeatureSupport",
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
            name: "FeatureSupport",
            targets: ["FeatureSupport"]
        )
    ],
    dependencies: [
        // Local workspace packages
        .package(name: "Domain",           path: "../../PlatformAgnostic/Domain"),
        .package(name: "CoreUI",           path: "../CoreUI"),
        .package(name: "ServiceHealth",    path: "../ServiceHealth"),
        .package(name: "AnalyticsService", path: "../AnalyticsService")
    ],
    targets: [
        .target(
            name: "FeatureSupport",
            dependencies: [
                "Domain",
                "CoreUI",
                "ServiceHealth",
                "AnalyticsService"
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "FeatureSupportTests",
            dependencies: ["FeatureSupport"],
            path: "Tests"
        )
    ]
)
