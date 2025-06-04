//  Package.swift
//  Gainz – Settings Feature Module
//
//  Manifest created using Swift Package Manager best-practices.  References:
//  • Official PackageDescription docs  [oai_citation:0‡docs.swift.org](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html?utm_source=chatgpt.com)
//  • Apple Developer manifest examples  [oai_citation:1‡developer.apple.com](https://developer.apple.com/documentation/packagedescription?utm_source=chatgpt.com)
//  • Local path dependencies syntax forum thread  [oai_citation:2‡forums.swift.org](https://forums.swift.org/t/how-to-add-local-swift-package-as-dependency/26457?utm_source=chatgpt.com) [oai_citation:3‡developer.apple.com](https://developer.apple.com/documentation/packagedescription/package/dependency/package%28path%3A%29?utm_source=chatgpt.com)
//  • Multi-platform & platform-specific guidance  [oai_citation:4‡forums.swift.org](https://forums.swift.org/t/adding-platform-specific-dependency-to-multi-platform-swift-package/49645?utm_source=chatgpt.com) [oai_citation:5‡developer.apple.com](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app?utm_source=chatgpt.com)
//  • Target vs. product distinctions  [oai_citation:6‡stackoverflow.com](https://stackoverflow.com/questions/70965294/swift-package-manifest-what-is-the-difference-between-library-targets-and-targ?utm_source=chatgpt.com)
//  • Apple sample manifest (DeckOfPlayingCards)  [oai_citation:7‡github.com](https://github.com/apple/example-package-deckofplayingcards/blob/main/Package.swift?utm_source=chatgpt.com)
//  • Nested local package advice  [oai_citation:8‡stackoverflow.com](https://stackoverflow.com/questions/78370778/how-to-add-a-local-package-dependency-to-a-local-package-in-xcode-how-to-nest-p?utm_source=chatgpt.com)
//  • SPM usage reference  [oai_citation:9‡github.com](https://github.com/apple/swift-package-manager/blob/main/Documentation/Usage.md?utm_source=chatgpt.com)
//  • Modular architecture tutorial  [oai_citation:10‡youtube.com](https://www.youtube.com/watch?v=jnv3K0mbIDo&utm_source=chatgpt.com)
//  • Linking local packages discussion  [oai_citation:11‡forums.swift.org](https://forums.swift.org/t/how-to-link-a-package-locally-into-my-swift-project/47358?utm_source=chatgpt.com)
//
//  Note: This module has **no HRV or Velocity-Tracking code** by design.

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
        // Local modular dependencies
        .package(path: "../../Core/CoreUI"),
        .package(path: "../../Core/CorePersistence"),
        .package(path: "../../Core/DesignSystem")
    ],
    targets: [
        // MARK: - Primary Module
        .target(
            name: "Settings",
            dependencies: [
                "CoreUI",
                "CorePersistence",
                "DesignSystem"
            ],
            path: "Sources",
            resources: [
                // Allows localisation strings, asset catalogs, etc.
                .process("Resources")
            ],
            swiftSettings: [
                // Enable strict concurrency for safety.
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings"],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
