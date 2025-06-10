// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Domain",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Domain",
            targets: ["Domain"]
        )
    ],
    dependencies: [
        // High-performance data structures & algorithms
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "Domain",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "Sources",
            exclude: ["README.md"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .define("ENABLE_LOGGING", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            path: "Tests"
        )
    ]
)
