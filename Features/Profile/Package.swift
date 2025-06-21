// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Profile",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Profile",
            type: .dynamic,
            targets: ["Profile"]
        )
    ],
    dependencies: [
        // Internal packages
        .package(path: "../../PlatformAgnostic/Domain"),
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/ServiceHealth"),
        // External image caching library
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.0")
    ],
    targets: [
        .target(
            name: "Profile",
            dependencies: [
                "Domain",
                "CoreUI",
                "ServiceHealth",
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .define("SWIFTUI_PREVIEW", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "ProfileTests",
            dependencies: ["Profile"],
            path: "Tests"
        )
    ]
)
