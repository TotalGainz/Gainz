// swift-tools-version: 5.9
//
//  package.swift
//  Features/Home
//
//  Stand-alone SwiftPM module for the “Home” tab.
//  Ships as a library so the root app target can link it,
//  and as a test target for isolated ViewModel + snapshot tests.
//
//  Dependencies
//  ────────────
//  • Domain          – pure business logic & models
//  • CoreUI          – typography, colors, ButtonStyle, etc.
//  • FeatureSupport  – utilities like UnitConversion, DateFormatters
//
//  Platforms
//  ─────────
//  • iOS 17+        – primary deployment
//  • watchOS 10+    – (future) for glance widgets
//  • visionOS 1.0+  – (future) panoramic dashboard
//

import PackageDescription

let package = Package(
    name: "HomeFeature",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "HomeFeature",
            targets: ["HomeFeature"]
        )
    ],
    dependencies: [
        .package(path: "../../PlatformAgnostic/Domain"),
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/FeatureSupport")
    ],
    targets: [
        // Main feature target
        .target(
            name: "HomeFeature",
            dependencies: [
                "Domain",
                "CoreUI",
                "FeatureSupport"
            ],
            path: "Sources",
            swiftSettings: [
                // Treat warnings as errors for strict hygiene
                .unsafeFlags(["-warnings-as-errors"])
            ]
        ),

        // Unit & snapshot tests
        .testTarget(
            name: "HomeFeatureTests",
            dependencies: ["HomeFeature"],
            path: "Tests"
        )
    ]
)
