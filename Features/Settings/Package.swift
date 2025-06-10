// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Settings",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Settings",
            type: .dynamic,
            targets: ["Settings"]
        )
    ],
    dependencies: [
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/CorePersistence"),
        .package(path: "../../Modules/ServiceHealth")
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: [
                "CoreUI",
                "CorePersistence",
                "ServiceHealth"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings"],
            path: "Tests"
        )
    ]
)
