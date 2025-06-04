// swift-tools-version:5.10
//  Package manifest for the **Gainz/Profile** feature package.
//  Built per SwiftPM official docs [oai_citation:0‡swift.org](https://swift.org/documentation/package-manager/?utm_source=chatgpt.com) and Xcode standalone-package guide [oai_citation:1‡developer.apple.com](https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode?utm_source=chatgpt.com).
//  Mirrors modern modularisation patterns for iOS apps [oai_citation:2‡nimblehq.co](https://nimblehq.co/blog/modern-approach-modularize-ios-swiftui-spm?utm_source=chatgpt.com) and adheres to the
//  module / product distinctions outlined by Swift forums [oai_citation:3‡forums.swift.org](https://forums.swift.org/t/module-vs-product-vs-target/27640?utm_source=chatgpt.com).
//  Tools-version declaration logic follows SE-0152 spec [oai_citation:4‡github.com](https://github.com/apple/swift-evolution/blob/main/proposals/0152-package-manager-tools-version.md?utm_source=chatgpt.com).
//  Manifest syntax reference: PackageDescription API docs [oai_citation:5‡docs.swift.org](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html?utm_source=chatgpt.com).
//  External dependency Kingfisher chosen for asset caching with iOS-version alignment [oai_citation:6‡stackoverflow.com](https://stackoverflow.com/questions/57774820/swift-package-manager-dependency-ios-version?utm_source=chatgpt.com).
//  Folder placement rules prevent `Package.swift` access errors in CI pipelines [oai_citation:7‡stackoverflow.com](https://stackoverflow.com/questions/75473774/package-manifest-at-package-swift-cannot-be-accessed-package-swift-doesnt?utm_source=chatgpt.com).
//  Usage details for swift-package‐manager CLI in GitHub manual [oai_citation:8‡github.com](https://github.com/apple/swift-package-manager/blob/main/Documentation/Usage.md?utm_source=chatgpt.com).
//  Upcoming “package traits” pitch motivates strict-concurrency flag adoption here [oai_citation:9‡forums.swift.org](https://forums.swift.org/t/pitch-package-traits/72191?utm_source=chatgpt.com).
//  (No HRV or velocity-tracking dependencies included, per project scope.)

import PackageDescription

let package = Package(
    name: "Profile",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        /// Exposes `Profile` as an internal dynamic framework for the main app & previews.
        .library(
            name: "Profile",
            targets: ["Profile"]
        )
    ],
    dependencies: [
        // Internal packages (relative paths keep mono-repo cohesion).
        .package(path: "../../Modules/Domain"),
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/FeatureInterfaces"),

        // External: lightweight image-caching helper.
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.0")
    ],
    targets: [
        // MARK: Primary Feature Target
        .target(
            name: "Profile",
            dependencies: [
                "Domain",
                "CoreUI",
                "FeatureInterfaces",
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "Sources",
            resources: [
                .process("Resources")   // asset catalogs & localized strings
            ],
            swiftSettings: [
                // Compile-time flags
                .enableUpcomingFeature("StrictConcurrency"),   // safer actors & Sendable checks
                .define("SWIFTUI_PREVIEW", .when(configuration: .debug))
            ]
        ),

        // MARK: Unit & Snapshot Tests
        .testTarget(
            name: "ProfileTests",
            dependencies: ["Profile"],
            path: "Tests"
        )
    ]
)

//  End of Package.swift
