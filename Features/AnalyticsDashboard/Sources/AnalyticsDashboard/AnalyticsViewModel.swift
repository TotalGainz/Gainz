//
//  AnalyticsViewModel.swift
//  Gainz
//
//  Created by AI on 2025-06-03.
//  © Echelon Commerce LLC. All rights reserved.
//
//  Responsibilities (doc refs):
//  • Orchestrate HealthKit + workout DB fetch, calculate FFMI/BMI & strength tiers, expose Swift Charts models
//    per spec “AnalyticsVM” tech snapshot  [oai_citation:0‡body and strength leaderboard.txt](file-service://file-NeVSoNpijvv9ywpESL2jNm)
//  • Provide data to AnalyticsView (scrollable dashboard w/ Body • Strength • Recovery segments)  [oai_citation:1‡repo explanation for o3 (UPDATED).txt](file-service://file-CnLa5rmYAZJgvi98KEwAKv)
//  • Exclude HRV/velocity tracking per latest requirements
//

import Foundation
import Combine
import SwiftUI
import HealthKit

import Domain                // Exercise, WorkoutSession, HealthMetric
import CorePersistence       // AnyCoreDataStore
import AnalyticsService      // StrengthLevel percentile & smoothing utils
import CoreUI

@MainActor
public final class AnalyticsViewModel: ObservableObject {

    // MARK: - Published Dashboard State

    /// Weight, BF %, BMI, FFMI tiles
    @Published public private(set) var vitalStats: [VitalStatTile] = []

    /// Strength scorecard + lift trends
    @Published public private(set) var strengthMetrics: StrengthDashboard = .placeholder

    /// Muscle-heatmap tint values 0–5 (gray → purple) keyed by `MuscleGroup`
    @Published public private(set) var heatmap: [MuscleGroup: Int] = [:]

    /// Share-card PNG generated on demand
    @Published public private(set) var shareCardImage: UIImage?

    // MARK: - Dependencies

    private let healthStore: HKHealthStore
    private let persistence: AnyCoreDataStore
    private let analytics: AnalyticsProcessing
    private let calendar: Calendar
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        healthStore: HKHealthStore                       = .init(),
        persistence: AnyCoreDataStore                    = .live,
        analytics: AnalyticsProcessing                   = .live,
        calendar: Calendar                               = .current
    ) {
        self.healthStore  = healthStore
        self.persistence  = persistence
        self.analytics    = analytics
        self.calendar     = calendar

        Task { await refreshAll() }
    }

    // MARK: - Public API

    /// Pulls latest HealthKit + workout data and updates all published dashboards.
    public func refreshAll() async {
        async let body = fetchBodyMetrics()
        async let str  = fetchStrengthMetrics()
        async let map  = buildMuscleHeatmap()

        do {
            let (vitals, strength, heat) = try await (body, str, map)
            vitalStats       = vitals
            strengthMetrics  = strength
            heatmap          = heat
        } catch {
            // TODO: surface user-friendly error state
            print("Analytics refresh error:", error)
        }
    }

    /// Generates a shareable progress card PNG (non-blocking).
    public func generateShareCard() {
        Task.detached(priority: .userInitiated) { [heatmap, strengthMetrics] in
            let renderer = ShareCardRenderer(
                heatmap: heatmap,
                strength: strengthMetrics)               // spec in ShareCardGenerator.swift  [oai_citation:2‡repo explanation for o3 (UPDATED).txt](file-service://file-CnLa5rmYAZJgvi98KEwAKv)
            let img = await renderer.render()
            await MainActor.run { self.shareCardImage = img }
        }
    }

    // MARK: - Private helpers

    private func fetchBodyMetrics() async throws -> [VitalStatTile] {
        let samples = try await analytics.fetchRecentHealthMetrics(
            with: healthStore,
            granularity: .day)
        // Apply smoothing & convert to tile view models
        return analytics.makeVitalStatTiles(from: samples)
                       .filter { $0.kind != .hrv }        // strip HRV per prompt
    }

    private func fetchStrengthMetrics() async throws -> StrengthDashboard {
        let sessions = try await persistence.fetchWorkoutSessions(
            since: calendar.date(byAdding: .month, value: -6, to: Date())!)
        return analytics.calculateStrengthDashboard(from: sessions)
    }

    private func buildMuscleHeatmap() async throws -> [MuscleGroup: Int] {
        let lifts = try await persistence.fetchPersonalBests()
        return analytics.makeHeatmap(from: lifts,
                                     tierTable: StrengthLevelTable.shared) // StrengthLevel JSON bundle  [oai_citation:3‡body and strength leaderboard.txt](file-service://file-NeVSoNpijvv9ywpESL2jNm)
    }
}

// MARK: - Supporting Models

public struct VitalStatTile: Identifiable {
    public enum Kind { case weight, bf, bmi, ffmi, steps, calories }
    public let id = UUID()
    public let kind: Kind
    public let value: Double
    public let unit: String
    public let delta: Double?          // 7-day rolling change
    public let color: Color
}

public struct StrengthDashboard {
    public var totalStrengthScore: Double
    public var lifts: [LiftMetric]

    public static let placeholder = StrengthDashboard(
        totalStrengthScore: 0,
        lifts: [])

    public struct LiftMetric: Identifiable {
        public let id = UUID()
        public let exercise: Exercise
        public let oneRM: Double
        public let percentile: Double
    }
}

// MARK: - Mock / Preview

#if DEBUG
extension AnalyticsViewModel {
    public static var preview: AnalyticsViewModel {
        let vm = AnalyticsViewModel(
            healthStore: .init(),
            persistence: .preview,
            analytics: .preview)
        return vm
    }
}
#endif
