// swift-tools-version: 5.9
//
//  package.swift
//  Features/Planner
//
//  SwiftPM manifest for the “Planner” feature bundle.
//  Responsible for calendar-style mesocycle planning and drag-drop
//  workout arrangement.
//
//  Dependencies
//  ────────────
//  • Domain          – MesocyclePlan, ExercisePlan, PlanGenerator
//  • CoreUI          – Styles, spacing, gradient tokens
//  • FeatureSupport  – UnitConversion, Date helpers
//  • CorePersistence – read/write Mesocycle templates
//
//  Platforms
//  ─────────
//  • iOS 17+        – primary target
//  • watchOS 10+    – long-term glance widgets
//

import PackageDescription

let package = Package(
    name: "PlannerFeature",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "PlannerFeature",
            targets: ["PlannerFeature"]
        )
    ],
    dependencies: [
        .package(path: "../../PlatformAgnostic/Domain"),
        .package(path: "../../Modules/CoreUI"),
        .package(path: "../../Modules/FeatureSupport"),
        .package(path: "../../Modules/CorePersistence")
    ],
    targets: [
        // Main feature target
        .target(
            name: "PlannerFeature",
            dependencies: [
                "Domain",
                "CoreUI",
                "FeatureSupport",
                "CorePersistence"
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"])    // maintain strict hygiene
            ]
        ),

        // Unit & snapshot tests
        .testTarget(
            name: "PlannerFeatureTests",
            dependencies: ["PlannerFeature"],
            path: "Tests"
        )
    ]
)
