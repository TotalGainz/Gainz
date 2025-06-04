//
//  AnalyticsViewModelTests.swift
//  Gainz – AnalyticsDashboard Tests
//
//  Unit tests validating key analytics calculations performed by `AnalyticsViewModel`.
//  • Weekly deltas   – verifies correct Δ between trailing-7-day aggregates. explanation for o3 (UPDATED).txt](file-service://file-CnLa5rmYAZJgvi98KEwAKv)
/* • Peak detection  – ensures local maxima/minima in smoothed series are flagged for PR banners.IUX Roadmap.txt](file-service://file-3J5YLRXNt4e6KPXDLuth4z)
   • Regression slope – confirms linear-trend slope is computed with ±1 % tolerance on synthetic data. explanation for o3 (UPDATED).txt](file-service://file-CnLa5rmYAZJgvi98KEwAKv)
*/
//  NOTE:  These tests rely on deterministic mock data and run fully offline; no HealthKit/CloudKit access.
//

import XCTest
import Combine
import Foundation
@testable import AnalyticsDashboard          // SPM target under test
@testable import Domain                      // exposes AnalyticsRepository protocol + TimeSeriesPoint model

// MARK: - AnalyticsViewModelTests
final class AnalyticsViewModelTests: XCTestCase {

    // Keep cancellables alive for async Combine assertions
    private var bag = Set<AnyCancellable>()

    // MARK: Weekly delta
    func testWeeklyWeightDeltaCalculation() throws {
        // GIVEN a repository returning weight for three consecutive Mondays
        let start = Calendar.current.startOfDay(for: Date())
        let series: [TimeSeriesPoint] = [
            .init(date: start.addingTimeInterval(-14.days), value: 80),
            .init(date: start.addingTimeInterval(-7.days),  value: 79),
            .init(date: start,                              value: 78),
        ]
        let repo = MockAnalyticsRepository(metric: .bodyWeightKg, series: series)
        let vm   = AnalyticsViewModel(repository: repo)

        // WHEN we trigger a refresh
        let exp = expectation(description: "Weekly Δ published")
        vm.$weeklyWeightDelta
            .dropFirst()                               // ignore initial default nil
            .sink { delta in
                // THEN Δ == −1 kg/week within 1 g tolerance
                XCTAssertEqual(delta, -1, accuracy: 0.001)
                exp.fulfill()
            }
            .store(in: &bag)

        vm.refresh()
        wait(for: [exp], timeout: 0.5)
    }

    // MARK: Peak detection
    func testPeakDetectionReturnsLatestPersonalRecord() {
        // GIVEN volume spikes on specific dates
        let base = Calendar.current.startOfDay(for: Date())
        let series = stride(from: 0, to: 21, by: 1).map { offset -> TimeSeriesPoint in
            let v = offset == 10 ? 15.0 : 7.0   // peak on day 10
            return .init(date: base.addingTimeInterval(TimeInterval(-offset.days)), value: v)
        }
        let repo = MockAnalyticsRepository(metric: .weeklyVolume, series: series)
        let vm   = AnalyticsViewModel(repository: repo)

        let latestPeak = vm.detectLatestPeak(in: series.map(\.value))
        XCTAssertEqual(latestPeak.index, 10)
        XCTAssertEqual(latestPeak.value, 15.0)
    }

    // MARK: Regression slope
    func testLinearRegressionSlopeMatchesGroundTruth() {
        // GIVEN a perfectly ascending squat 1 RM (kg) over 8 weeks: y = 2x + 100
        let base = Calendar.current.startOfDay(for: Date())
        let series = (0..<8).map { i -> TimeSeriesPoint in
            .init(date: base.addingTimeInterval(TimeInterval(-i.weeks)),
                  value: 100 + Double(i) * 2)
        }
        let repo = MockAnalyticsRepository(metric: .squat1RM, series: series)
        let vm   = AnalyticsViewModel(repository: repo)

        let slope = vm.regressionSlope(for: .squat1RM, weeksBack: 8)
        XCTAssertEqual(slope, 2.0, accuracy: 0.01)     // allow 0.01 kg/wk tolerance
    }
}

// MARK: - Test doubles
/// Lightweight in-memory stub replacing `AnalyticsRepository`
private final class MockAnalyticsRepository: AnalyticsRepository {

    private let metric: AnalyticsMetric
    private let series: [TimeSeriesPoint]

    init(metric: AnalyticsMetric, series: [TimeSeriesPoint]) {
        self.metric = metric
        self.series = series
    }

    func fetchSeries(for metric: AnalyticsMetric,
                     interval: AnalyticsInterval) async throws -> [TimeSeriesPoint] {
        // For simplicity ignore interval filtering – caller supplies trimmed data
        guard metric == self.metric else { return [] }
        return series
    }
}

// MARK: - Time helpers
private extension TimeInterval {
    static var day:  TimeInterval { 86_400 }
    static var week: TimeInterval { 604_800 }
}
private extension Int {
    var days:  TimeInterval { TimeInterval(self) * .day  }
    var weeks: TimeInterval { TimeInterval(self) * .week }
}
