// swift-tools-version: 5.10
// Package.swift
// FeatureSupport Package Manifest
//
// Defines the Swift Package Manager configuration for the FeatureSupport package.
// Specifies the package name, supported platforms (iOS 17+, watchOS 10+, macOS 13+, tvOS 17+, visionOS 1+),
// products (the FeatureSupport library), package dependencies, and targets (source and test modules).

import PackageDescription

let package = Package(
    name: "FeatureSupport",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "FeatureSupport",
            targets: ["FeatureSupport"]
        )
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../CoreUI"),
        .package(path: "../ServiceHealth"),
        .package(path: "../AnalyticsService")
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
