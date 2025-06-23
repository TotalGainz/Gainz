// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Home",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Home",
            type: .dynamic,
            targets: ["Home"]
        )
    ],
    dependencies: [
        .package(path: "../../Modules/Domain"),
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/FeatureSupport"),
        .package(path: "../../Modules/FeatureInterfaces"),
        .package(path: "../../Modules/AnalyticsService")
    ],
    targets: [
        .target(
            name: "Home",
            dependencies: [
                "Domain",
                "CoreUI",
                "FeatureSupport",
                "FeatureInterfaces",
                "AnalyticsService"
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"])
            ]
        ),
        .testTarget(
            name: "HomeTests",
            dependencies: ["Home"],
            path: "Tests"
        )
    ]
)
