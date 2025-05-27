#!/usr/bin/swift sh
/*
 dev_app_generator.swift
 Gainz ▸ Internal Developer Utility
 -----------------------------------------------------------
 A one-shot CLI for scaffolding new SwiftPM feature packages,
 demo screens, and unit-test targets that comply with Gainz’
 architecture & style guides.

 ⚠️  Run this only from repo root:
      `swift dev_app_generator.swift --feature Planner`
 -----------------------------------------------------------
*/

// MARK: - Dependencies (Swift-sh fetches automatically)
//ArgumentParser 1.3.0 <https://github.com/apple/swift-argument-parser.git>
import ArgumentParser
import Foundation

// MARK: - Helper Extensions
extension FileManager {
    func mkdir(_ path: String) throws {
        try createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }
    func touch(_ path: String, contents: String = "") throws {
        let url = URL(fileURLWithPath: path)
        try contents.data(using: .utf8)?.write(to: url, options: .atomic)
    }
    func exists(_ path: String) -> Bool { fileExists(atPath: path) }
}

// MARK: - Templates
enum Templates {
    static func modulePackage(name: String) -> String {
        """
        // swift-tools-version:5.9
        import PackageDescription

        let package = Package(
            name: "\(name)",
            platforms: [.iOS(.v17)],
            products: [.library(name: "\(name)", targets: ["\(name)"])],
            targets: [
                .target(name: "\(name)", dependencies: []),
                .testTarget(name: "\(name)Tests", dependencies: ["\(name)"])
            ]
        )
        """
    }

    static func featureView(name: String) -> String {
        """
        import SwiftUI

        public struct \(name)View: View {
            @StateObject private var viewModel = \(name)ViewModel()

            public init() {}

            public var body: some View {
                VStack {
                    Text("\\(viewModel.title)")
                        .font(.largeTitle)
                        .padding()
                    Spacer()
                }
                .navigationTitle(viewModel.title)
                .onAppear { viewModel.onAppear() }
            }
        }

        #Preview { \(name)View() }
        """
    }

    static func featureViewModel(name: String) -> String {
        """
        import Foundation
        import Combine

        @MainActor
        public final class \(name)ViewModel: ObservableObject {
            @Published public private(set) var title = "\(name)"

            public init() {}

            public func onAppear() {
                // TODO: add analytics ping or data fetch
            }
        }
        """
    }

    static func unitTest(name: String) -> String {
        """
        import XCTest
        @testable import \(name)

        final class \(name)ViewModelTests: XCTestCase {
            func testInitialTitle() {
                let vm = \(name)ViewModel()
                XCTAssertEqual(vm.title, "\(name)")
            }
        }
        """
    }
}

// MARK: - CLI Definition
struct DevAppGenerator: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Generate Gainz feature modules or demo apps quickly."
    )

    @Option(name: .shortAndLong, help: "Name of the feature package (e.g., Planner, Home, Profile).")
    var feature: String?

    func run() throws {
        guard let feature = feature else {
            throw ValidationError("⚠️  --feature <Name> is required.")
        }
        try createFeature(named: feature)
        print("✅  Feature \(feature) scaffolded successfully.")
    }

    // MARK: - Private
    private func createFeature(named name: String) throws {
        let fm = FileManager.default
        let path = "Packages/GainzFeature\(name)"
        guard !fm.exists(path) else {
            throw ValidationError("❌  Package already exists at \(path).")
        }

        // Modules
        try fm.mkdir("\(path)/Sources")
        try fm.mkdir("\(path)/Tests")

        // Package.swift
        try fm.touch("\(path)/Package.swift", contents: Templates.modulePackage(name: "GainzFeature\(name)"))

        // Source files
        try fm.touch("\(path)/Sources/\(name)View.swift", contents: Templates.featureView(name: name))
        try fm.touch("\(path)/Sources/\(name)ViewModel.swift", contents: Templates.featureViewModel(name: name))

        // Unit tests
        try fm.touch("\(path)/Tests/\(name)ViewModelTests.swift", contents: Templates.unitTest(name: name))
    }
}

// MARK: - Entry
DevAppGenerator.main()
