// swift-tools-version: 5.9
//
//  Package.swift
//  Features ▸ WorkoutLogger
//
//  Swift Package manifest for the WorkoutLogger feature bundle.
//  ────────────────────────────────────────────────────────────
//  • Local, file-system based dependencies keep the workspace self-contained.
//  • Default localisation is “en”; resources live under Sources/WorkoutLogger/Resources.
//  • Builds on iOS 17+ and watchOS 10+ to leverage the latest SwiftUI APIs.
//  • Unit tests compile against an in-memory CorePersistence stack for speed.
//

import PackageDescription

let package = Package(
    name: "WorkoutLogger",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "WorkoutLogger", targets: ["WorkoutLogger"])
    ],
    dependencies: [
        // Domain models (Exercises, WorkoutSession, etc.)
        .package(path: "../../PlatformAgnostic/Domain"),
        // Shared UI tokens & components
        .package(path: "../../Modules/CoreUI"),
        // Persistence layer for fetch / save
        .package(path: "../../Modules/CorePersistence")
    ],
    targets: [
        // MARK: - Feature Target
        .target(
            name: "WorkoutLogger",
            dependencies: [
                "Domain",
                "CoreUI",
                "CorePersistence"
            ],
            path: "Sources",
            resources: [
                .process("Resources")   // JSON, images, Localizable.strings
            ],
            swiftSettings: [
                // Treat warnings as errors in feature targets
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .debug))
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "WorkoutLoggerTests",
            dependencies: [
                "WorkoutLogger",
                "Domain",
                "CorePersistence"
            ],
            path: "Tests"
        )
    ]
)
