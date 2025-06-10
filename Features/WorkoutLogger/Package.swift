// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WorkoutLogger",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "WorkoutLogger",
            type: .dynamic,
            targets: ["WorkoutLogger"]
        )
    ],
    dependencies: [
        .package(path: "../../Modules/Domain"),
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/ServiceHealth"),
        .package(path: "../../Modules/AnalyticsService"),
        .package(path: "../../Modules/CorePersistence")
    ],
    targets: [
        .target(
            name: "WorkoutLogger",
            dependencies: [
                "Domain",
                "CoreUI",
                "ServiceHealth",
                "AnalyticsService"
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .debug))
            ]
        ),
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
