// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CoreUI",
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
            name: "CoreUI",
            targets: ["CoreUI"]
        )
    ],
    dependencies: [
        // No external dependencies – CoreUI must compile in isolation
    ],
    targets: [
        .target(
            name: "CoreUI",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-warn-concurrency"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "CoreUITests",
            dependencies: ["CoreUI"],
            path: "Tests"
        )
    ]
)
