// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "AnalyticsService",
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
            name: "AnalyticsService",
            targets: ["AnalyticsService"]
        )
    ],
    dependencies: [
        // Apple open-source packages for algorithms & data collections
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        // Local workspace packages
        .package(path: "../../PlatformAgnostic/Domain"),
        .package(path: "../CorePersistence")
    ],
    targets: [
        .target(
            name: "AnalyticsService",
            dependencies: [
                "Domain",
                "CorePersistence",
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Crypto", package: "swift-crypto")
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "AnalyticsServiceTests",
            dependencies: ["AnalyticsService"],
            path: "Tests"
        )
    ]
)
