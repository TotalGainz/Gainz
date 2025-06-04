//
//  AnalyticsDashboardSnapshotTests.swift
//  Gainz – AnalyticsDashboard Snapshot Tests
//
//  Snapshot (golden-image) tests for top-level dashboard components.
//  Uses the open-source “SnapshotTesting” library by Point-Free 🕵️‍♂️🖼️,
//  which renders SwiftUI views off-screen and compares them against a
//  previously-recorded PNG reference.  Any pixel drift outside the diff
//  tolerance will fail the test and attach a tri-image diff to Xcode’s
//  report navigator.  Techniques, API usage, and best practices are
//  referenced below:  SnapshotTesting docs  [oai_citation:0‡github.com](https://github.com/pointfreeco/swift-snapshot-testing?utm_source=chatgpt.com),
//  SwiftUI-specific write-ups  [oai_citation:1‡medium.com](https://medium.com/%40ashokrwt/snapshot-testing-in-swiftui-d88640b4906d?utm_source=chatgpt.com) [oai_citation:2‡vadimbulavin.com](https://www.vadimbulavin.com/snapshot-testing-swiftui-views/?utm_source=chatgpt.com),
//  multi-sim/device advice  [oai_citation:3‡github.com](https://github.com/pointfreeco/swift-snapshot-testing/issues/182?utm_source=chatgpt.com) [oai_citation:4‡medium.com](https://medium.com/%40adamkdz/device-agnostic-snapshot-testing-4982fdd214c5?utm_source=chatgpt.com),
//  Medium/OSS examples  [oai_citation:5‡medium.com](https://medium.com/cstech/ui-test-automation-snapshot-testing-in-ios-bd8bcb595cf8?utm_source=chatgpt.com) [oai_citation:6‡onnerb.medium.com](https://onnerb.medium.com/swift-ui-testing-with-snapshottesting-db0752d7cd14?utm_source=chatgpt.com) [oai_citation:7‡medium.com](https://medium.com/%40syedqamar.a1/multi-preview-snapshot-testing-swiftui-7d03df3413d2?utm_source=chatgpt.com),
//  library releases & Swift Testing support  [oai_citation:8‡pointfree.co](https://www.pointfree.co/blog/posts/146-swift-testing-support-for-snapshottesting?utm_source=chatgpt.com) [oai_citation:9‡github.com](https://github.com/pointfreeco/swift-snapshot-testing/releases?utm_source=chatgpt.com),
//  and UI diff tooling tips  [oai_citation:10‡github.com](https://github.com/pointfreeco/swift-snapshot-testing/issues/176?utm_source=chatgpt.com).
//
//  NOTE:
//  • No HRV or velocity-tracking views are included, per product scope.
//  • Set the “RECORD=1” environment variable to re-record snapshots.
//
//  Created by AI-Assistant on 2025-06-03.
//  Licensed to Echelon Commerce LLC.
//

import XCTest
import SwiftUI
import SnapshotTesting        // SPM target
@testable import AnalyticsDashboard
@testable import Domain
@testable import CoreUI

// MARK: – Global test config

private let snapshotPrecision: Float = 0.995   // 0.5 % pixel tolerance
private let size   = CGSize(width: 430, height: 932)  // iPhone 15 Pro frame

/// Records automatically when env var `RECORD` is set (↵ to update goldens).
private var isRecording: Bool {
    ProcessInfo.processInfo.environment["RECORD"] == "1"
}

// MARK: – Main test case

final class AnalyticsDashboardSnapshotTests: XCTestCase {

    // MARK: VitalStatTileView
    func testVitalStatTile_LightAndDark() {
        let model = VitalStatTileModel(kind: .restingHeartRate,
                                       valueText: "52 bpm",
                                       deltaText: "▲ 2 %",
                                       isPositiveDelta: true)
        assertSnapshots(of: VitalStatTileView(model: model),
                        named: "VitalStatTile_RHR",
                        size: size)
    }

    // MARK: StrengthScorecardView
    func testStrengthScorecard_DefaultDataset() {
        let lifts: [StrengthLiftModel] = [
            .init(kind: .squat,          current1RM: 170, target1RM: 180),
            .init(kind: .benchPress,     current1RM: 125, target1RM: 140),
            .init(kind: .deadlift,       current1RM: 200, target1RM: 220),
            .init(kind: .overheadPress,  current1RM:  80, target1RM:  90),
            .init(kind: .barbellRow,     current1RM: 110, target1RM: 120)
        ]
        assertSnapshots(of: StrengthScorecardView(lifts: lifts),
                        named: "StrengthScorecard_Default",
                        size: size)
    }

    // MARK: LeaderboardView
    func testLeaderboard_TopTen() {
        let board: [LeaderboardCategory : [LeaderboardEntry]] = [
            .totalStrength: demoLeaders(),
            .bodyweight:    demoLeaders(),
            .ffmi:          demoLeaders()
        ]
        assertSnapshots(of: LeaderboardView(board: board),
                        named: "Leaderboard_Top10",
                        size: size)
    }
}

// MARK: – Utilities

/// Wrapper producing light & dark-mode snapshots for greater coverage.
private func assertSnapshots<V: View>(of view: V,
                                      named name: String,
                                      size: CGSize,
                                      file: StaticString = #file,
                                      testName: String = #function,
                                      line: UInt = #line) {
    let hosting = UIHostingController(rootView: view)
    hosting.view.frame = CGRect(origin: .zero, size: size)

    // Light
    hosting.overrideUserInterfaceStyle = .light
    assertSnapshot(matching: hosting,
                   as: .image(precision: snapshotPrecision),
                   named: "\(name)_light",
                   record: isRecording,
                   file: file, testName: testName, line: line)

    // Dark
    hosting.overrideUserInterfaceStyle = .dark
    assertSnapshot(matching: hosting,
                   as: .image(precision: snapshotPrecision),
                   named: "\(name)_dark",
                   record: isRecording,
                   file: file, testName: testName, line: line)
}

/// Generates ten fake leaderboard entries (ranked 1…10).
private func demoLeaders() -> [LeaderboardEntry] {
    (1...10).map {
        LeaderboardEntry(id: .init(),
                         userName: "Athlete\($0)",
                         avatarURL: nil,
                         metricValue: Double.random(in: 300...600),
                         rank: $0,
                         isCurrentUser: $0 == 4)
    }
}
