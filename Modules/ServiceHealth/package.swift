// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ServiceHealth",
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
            name: "ServiceHealth",
            targets: ["ServiceHealth"]
        )
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../CorePersistence")
    ],
    targets: [
        .target(
            name: "ServiceHealth",
            dependencies: [
                "Domain",
                "CorePersistence"
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "ServiceHealthTests",
            dependencies: ["ServiceHealth"],
            path: "Tests"
        )
    ]
)
