// swift-tools-version: 5.9
//
//  Package.swift
//  Modules/CorePersistence
//
//  Persistence layer for Gainz — wraps Core Data (or GRDB when running on Linux),
//  provides repositories consumed by Domain & Feature modules.
//  Pure SwiftPM; no Xcodeproj needed.
//
//  ────────────────────────────────────────────────────────────
//  • Depends on Domain for model schemas.
//  • SeedData bundled as resources (exercises.json, etc.).
//  • Swift strict-concurrency enabled.
//  • No UI frameworks imported.
//  • Tests live in CorePersistenceTests.
//

import PackageDescription

let package = Package(
    name: "CorePersistence",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CorePersistence",
            targets: ["CorePersistence"]
        )
    ],
    dependencies: [
        // Internal domain schema
        .package(path: "../../PlatformAgnostic/Domain"),
        // External option: GRDB for server-side SQLite (disabled by default)
        // .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.5.0")
    ],
    targets: [
        .target(
            name: "CorePersistence",
            dependencies: [
                "Domain"
                // , "GRDB"        // uncomment when using GRDB
            ],
            path: "Sources",
            resources: [
                .process("SeedData") // exercises.json etc.
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency=complete"),
                .unsafeFlags(["-warn-concurrency"], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "CorePersistenceTests",
            dependencies: ["CorePersistence", "Domain"],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
