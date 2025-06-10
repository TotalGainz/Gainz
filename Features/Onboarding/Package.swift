// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Onboarding",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Onboarding",
            type: .dynamic,
            targets: ["Onboarding"]
        )
    ],
    dependencies: [
        // Point-Free Composable Architecture & Dependencies
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.7.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.2.0"),
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.5.0"),
        // Internal modules
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/FeatureInterfaces")
    ],
    targets: [
        .target(
            name: "Onboarding",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "CombineExt", package: "CombineExt"),
                "CoreUI",
                "FeatureInterfaces"
            ],
            path: "Sources",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "OnboardingTests",
            dependencies: ["Onboarding"],
            path: "Tests"
        )
    ]
)
