// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "AnalyticsDashboard",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AnalyticsDashboard",
            type: .dynamic,
            targets: ["AnalyticsDashboard"]
        )
    ],
    dependencies: [
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/Domain"),
        .package(path: "../../Modules/AnalyticsService"),
        .package(path: "../../Modules/FeatureInterfaces")
    ],
    targets: [
        .target(
            name: "AnalyticsDashboard",
            dependencies: [
                "CoreUI",
                "Domain",
                "AnalyticsService",
                "FeatureInterfaces"
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"])
            ]
        ),
        .testTarget(
            name: "AnalyticsDashboardTests",
            dependencies: ["AnalyticsDashboard"],
            path: "Tests"
        )
    ]
)
