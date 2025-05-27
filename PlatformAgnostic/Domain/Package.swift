// swift-tools-version: 5.9
import PackageDescription

/// Gainz ▸ PlatformAgnostic/Domain
/// Pure business-logic layer—zero UIKit, no HealthKit, no HRV/velocity bells.
/// Compiles on every Apple platform + Linux for future server-side exports.
let package = Package(
    name: "GainzDomain",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "GainzDomain",
            targets: ["GainzDomain"]
        )
    ],
    dependencies: [
        // Apple OSS utilities for performant collections & algorithms.
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "GainzDomain",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "Sources",
            exclude: [
                "README.md"
            ],
            resources: [
                // Generated SwiftGen assets (type-safe enums) if any.
                // Pure code here, but reserved for future domain JSON/CSV payloads.
                .copy("Generated")
            ],
            swiftSettings: [
                // Opt in to strict concurrency everywhere.
                .enableUpcomingFeature("StrictConcurrency"),
                // Treat warnings as errors except in Release where optimisation may surface warnings.
                .warningsAsErrors(true),
                // Expose convenient compile-time flag for debug logging.
                .define("ENABLE_LOGGING", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "GainzDomainTests",
            dependencies: ["GainzDomain"],
            path: "Tests"
        )
    ]
)
