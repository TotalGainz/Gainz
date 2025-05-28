// swift-tools-version:5.9
//
//  Package.swift
//  Modules/CoreNetworking
//
//  Gainz ▸ Lightweight REST & realtime gateway for all platforms.
//  Depends only on Foundation and async/await—zero third-party baggage
//  so the module compiles on iOS, watchOS, macOS, visionOS, and Linux.
//
//  ─────────────────────────────────────────────────────────────────
//
//  To add external clients (e.g., AsyncHTTPClient for server builds),
//  extend the target conditionally with #if os(Linux) in Sources.
//
//  Created on 27 May 2025.
//

import PackageDescription

let package = Package(
    name: "CoreNetworking",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CoreNetworking",
            targets: ["CoreNetworking"]
        )
    ],
    targets: [
        .target(
            name: "CoreNetworking",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                // Treat warnings as errors in CI
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "CoreNetworkingTests",
            dependencies: ["CoreNetworking"],
            path: "Tests"
        )
    ]
)
