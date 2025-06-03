// swift-tools-version: 5.9
//
//  package.swift
//  Gainz ▸ FeatureInterfaces
//
//  Defines the public-facing protocols for each Feature package
//  (Planner, WorkoutLogger, AnalyticsDashboard, etc.) so that Feature
//  implementations can be swapped or mocked without touching
//  higher-level code.
//
//  Created 27 May 2025.
//

import PackageDescription

let package = Package(
    name: "FeatureInterfaces",
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
            name: "FeatureInterfaces",
            targets: ["FeatureInterfaces"]
        )
    ],
    dependencies: [
        // Domain models shared across all features
        .package(name: "Domain", path: "../PlatformAgnostic/Domain")
    ],
    targets: [
        .target(
            name: "FeatureInterfaces",
            dependencies: ["Domain"],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        )
    ]
)
