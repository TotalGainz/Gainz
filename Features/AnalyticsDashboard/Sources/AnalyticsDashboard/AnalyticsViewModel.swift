//  AnalyticsViewModel.swift
//  Gainz
//
//  Created by AI on 2025-06-03.
//  © Echelon Commerce LLC. All rights reserved.
//
//  Responsibilities:
//  • Orchestrate HealthKit + workout DB fetch, calculate BMI/FFMI & strength tiers, expose derived models.
//  • Provide data to AnalyticsView (scrollable dashboard with Body, Strength, Recovery segments).
//  • Exclude HRV and bar-velocity tracking per latest requirements.
//

import Foundation
import Combine
import SwiftUI
import HealthKit

import Domain            // Domain models (Exercise, WorkoutSession, HealthMetric, etc.)
import CorePersistence   // Data persistence layer (Core Data wrappers)
import CoreUI

@MainActor
public final class AnalyticsViewModel: ObservableObject {

    // MARK: - Published Dashboard State

    /// Key body composition stats (Weight, Body Fat %, BMI, FFMI, Steps, Calories).
    @Published public private(set) var vitalStats: [VitalStatTile] = []
    /// Strength scorecard metrics (composite strength score and individual lift stats).
    @Published public private(set) var strengthMetrics: StrengthDashboard = .placeholder
    /// Muscle strength heatmap values (tier 0–5 per MuscleGroup, 0 = no data).
    @Published public private(set) var heatmap: [MuscleGroup: Int] = [:]
    /// Share sheet payload for progress card.
    @Published public var sharePayload: ShareCardPayload?

    // MARK: - Dependencies

    private let analyticsUseCase: CalculateAnalyticsUseCase
    private let calendar: Calendar

    // MARK: - Initialization

    public init(analyticsUseCase: CalculateAnalyticsUseCase, calendar: Calendar = .current) {
        self.analyticsUseCase = analyticsUseCase
        self.calendar = calendar
    }

    // MARK: - Public API

    /// Refreshes all dashboard data by fetching latest metrics and computing derived values.
    public func refreshAll() async {
        do {
            async let vitalTiles = analyticsUseCase.fetchVitalStatTiles(granularity: .day)
            async let strengthData = analyticsUseCase.fetchStrengthDashboard(since: calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date())
            async let muscleMap = analyticsUseCase.fetchMuscleHeatmap()
            let (vitals, strength, heat) = try await (vitalTiles, strengthData, muscleMap)
            self.vitalStats = vitals.filter { $0.kind != .hrv }  // Exclude HRV if present.
            self.strengthMetrics = strength
            self.heatmap = heat
        } catch {
            // Handle errors gracefully (e.g., log or provide user feedback).
            print("AnalyticsViewModel refresh error: \(error)")
        }
    }

    /// Initiates share sheet payload generation for the progress card.
    public func shareTapped() {
        // Create share card payload from current state.
        let total = Int(strengthMetrics.totalStrengthScore)
        let headline = "5-Lift Total \(total) kg"
        // Compute an approximate percentile ranking (average of lift percentiles).
        let avgPercentile = strengthMetrics.lifts.map { $0.percentile }.reduce(0.0, +) / Double(max(strengthMetrics.lifts.count, 1))
        let topPercent = max(0, 100 - Int(avgPercentile * 100))
        let subheadline = "You're in the Top \(topPercent)%!"
        // Use up to 3 top lifts for share metrics.
        let metrics: [ShareCardPayload.Metric] = strengthMetrics.lifts.prefix(3).map {
            ShareCardPayload.Metric(name: $0.exercise.name, value: "\(Int($0.oneRM)) kg")
        }
        sharePayload = ShareCardPayload(headline: headline, subheadline: subheadline, avatarURL: nil, metricRows: metrics)
    }

    // MARK: - Supporting Models

    /// Simple data model for vital stat tiles.
    public struct VitalStatTile: Identifiable {
        public enum Kind: String {
            case weight, bodyFat, bmi, ffmi, steps, calories, hrv
        }
        public let id = UUID()
        public let kind: Kind
        public let value: Double
        public let unit: String
        public let delta: Double?          // 7-day change (nil if not applicable).
        public let color: Color
    }

    /// Composite strength metrics (total score and individual lifts).
    public struct StrengthDashboard {
        public var totalStrengthScore: Double
        public var lifts: [LiftMetric]

        public static let placeholder = StrengthDashboard(totalStrengthScore: 0, lifts: [])

        public struct LiftMetric: Identifiable {
            public let id = UUID()
            public let exercise: Exercise    // Domain model for the lift (name, type, etc.)
            public let oneRM: Double         // One-rep max weight for this exercise.
            public let percentile: Double    // Percentile ranking for this oneRM.
        }
    }

    // MARK: - Preview Support

    #if DEBUG
    extension AnalyticsViewModel {
        public static var preview: AnalyticsViewModel {
            AnalyticsViewModel(analyticsUseCase: .preview)
        }
    }
    #endif
}
