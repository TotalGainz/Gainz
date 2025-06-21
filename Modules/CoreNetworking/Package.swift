// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CoreNetworking",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CoreNetworking",
            targets: ["CoreNetworking"]
        )
    ],
    dependencies: [
        // Internal model layer
        .package(path: "../../PlatformAgnostic/Domain"),
        // Combine helpers for reactive pipelines
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "CoreNetworking",
            dependencies: [
                "Domain",
                .product(name: "CombineExt", package: "CombineExt")
            ],
            path: "Sources",
            swiftSettings: [
                // Strict concurrency with actor-isolated URLSession wrappers
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-warnings-as-errors"])
            ]
        ),
        .testTarget(
            name: "CoreNetworkingTests",
            dependencies: ["CoreNetworking"],
            path: "Tests"
        )
    ]
)
