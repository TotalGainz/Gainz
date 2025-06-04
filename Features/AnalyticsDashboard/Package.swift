// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AnalyticsDashboard",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17)
    ],
    products: [
        .library(
            name: "AnalyticsDashboard",
            targets: ["AnalyticsDashboard"]
        )
    ],
    dependencies: [
        // Local, in-repo modules
        .package(path: "../../CoreDesignSystem"),
        .package(path: "../../CorePersistence"),
        .package(path: "../../CoreNetworking"),
        .package(path: "../../SharedModels"),
        .package(path: "../../Utilities")
    ],
    targets: [
        .target(
            name: "AnalyticsDashboard",
            dependencies: [
                "CoreDesignSystem",
                "CorePersistence",
                "CoreNetworking",
                "SharedModels",
                "Utilities"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "AnalyticsDashboardTests",
            dependencies: ["AnalyticsDashboard"],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
