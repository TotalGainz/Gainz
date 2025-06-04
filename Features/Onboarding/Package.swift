// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Onboarding",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]
        )
    ],
    dependencies: [
        // Internal modules
        .package(path: "../DesignSystem"),
        .package(path: "../Navigation"),
        .package(path: "../CorePersistence"),
        // External packages
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.7.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.2.0"),
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.5.0"),
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.55.0"),
        .package(url: "https://github.com/SwiftGen/SwiftGen.git", from: "6.6.0")
    ],
    targets: [
        .target(
            name: "Onboarding",
            dependencies: [
                "DesignSystem",
                "Navigation",
                "CorePersistence",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "CombineExt", package: "CombineExt")
            ],
            path: "Sources/Onboarding",
            resources: [
                .process("Resources")
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint"),
                .plugin(name: "SwiftGenPlugin", package: "SwiftGen")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-bare-slash-regex"], .when(configuration: .release)),
                .unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "OnboardingTests",
            dependencies: [
                "Onboarding",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Tests/OnboardingTests",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
        .executableTarget(
            name: "OnboardingDemo",
            dependencies: [
                "Onboarding"
            ],
            path: "Demo"
        )
    ]
)
