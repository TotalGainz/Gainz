// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FeatureInterfaces",
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
            name: "FeatureInterfaces",
            targets: ["FeatureInterfaces"]
        )
    ],
    dependencies: [
        .package(path: "../../PlatformAgnostic/Domain")
    ],
    targets: [
        .target(
            name: "FeatureInterfaces",
            dependencies: ["Domain"],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        )
        // Note: No test target (protocol definitions only)
    ]
)
