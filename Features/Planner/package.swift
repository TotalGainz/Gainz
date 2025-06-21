// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Planner",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Planner",
            type: .dynamic,
            targets: ["Planner"]
        )
    ],
    dependencies: [
        .package(path: "../../PlatformAgnostic/Domain"),
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/FeatureSupport"),
        .package(path: "../../Modules/CorePersistence")
    ],
    targets: [
        .target(
            name: "Planner",
            dependencies: [
                "Domain",
                "CoreUI",
                "FeatureSupport",
                "CorePersistence"
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"])
            ]
        ),
        .testTarget(
            name: "PlannerTests",
            dependencies: ["Planner"],
            path: "Tests"
        )
    ]
)
