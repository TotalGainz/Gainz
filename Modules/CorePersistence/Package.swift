// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CorePersistence",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13),
        .tvOS(.v17),
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
        .package(path: "../Domain")
        // External option: GRDB for server-side SQLite (disabled by default)
        // .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.5.0")
    ],
    targets: [
        .target(
            name: "CorePersistence",
            dependencies: [
                "Domain"
                // , "GRDB"    // uncomment when using GRDB
            ],
            path: "Sources",
            resources: [
                .process("SeedData")
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
