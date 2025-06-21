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
        // Core utilities: high-performance collections & algorithms
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0")
    ],
    targets: [
        .target(
            /// Core domain logic: models, repositories, use-cases, and protocol abstractions.
            name: "Domain",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "Sources",
            swiftSettings: [
                // Enable concurrency model strictness ahead-of-time
                .enableUpcomingFeature("StrictConcurrency"),
                // Controlled debug logging in Domain
                .define("ENABLE_LOGGING", .when(configuration: .debug))
            ],
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            path: "Tests"
        )
    ]
)
