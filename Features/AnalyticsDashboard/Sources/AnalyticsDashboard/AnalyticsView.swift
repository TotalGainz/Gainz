//  AnalyticsView.swift
//  AnalyticsDashboard Feature
//
//  The main Analytics dashboard view, summarizing body composition, muscle strength, and key daily metrics.
//  Tapping tiles navigates to detailed views via the provided route callback.
//

import SwiftUI
import CoreUI
import Domain

public struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel
    private let onSelectRoute: ((AnalyticsRoute) -> Void)?

    public init(analyticsUseCase: CalculateAnalyticsUseCase, onSelectRoute: ((AnalyticsRoute) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(analyticsUseCase: analyticsUseCase))
        self.onSelectRoute = onSelectRoute
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header: Avatar and body stat tiles.
                HStack(spacing: 16) {
                    AvatarView(image: nil, badge: nil)
                        .frame(width: 54, height: 54)
                    Spacer(minLength: 0)
                    HStack(spacing: 12) {
                        ForEach(viewModel.vitalStats.filter { stat in
                            // Only primary body stats in header.
                            switch stat.kind {
                            case .weight, .bodyFat, .bmi, .ffmi: return true
                            default: return false
                            }
                        }) { stat in
                            VitalStatTileView(
                                model: VitalStatTileModel(
                                    kind: .weightTrend,
                                    valueText: formatted(stat.value, unit: stat.unit),
                                    deltaText: stat.delta.map { $0 >= 0 ? "▲ \(Int($0))" : "▼ \(abs(Int($0)))" },
                                    isPositiveDelta: stat.delta.map { $0 >= 0 },
                                    accent: stat.color,
                                    systemImageName: iconOverride(for: stat.kind)
                                ),
                                tapAction: (stat.kind == .weight ? { onSelectRoute?(.vitalStatDetail(.weightTrend)) } : nil)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Muscle heatmap overview.
                if !viewModel.heatmap.isEmpty {
                    Text("Muscle Heatmap")
                        .font(.headline)
                        .padding(.horizontal)
                    ZStack {
                        MuscleHeatmapView(analyticsUseCase: viewModel.analyticsUseCase)
                            .allowsHitTesting(false)  // Static overview
                        Rectangle().fill(Color.clear)  // overlay to capture tap
                    }
                    .frame(height: 280)
                    .padding(.horizontal)
                    .onTapGesture {
                        onSelectRoute?(.muscleHeatmap)
                    }
                }

                // Daily metrics (e.g., steps, calories).
                if !viewModel.vitalStats.isEmpty {
                    Text("Daily Metrics")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.vitalStats.filter { stat in
                                switch stat.kind {
                                case .steps, .calories: return true
                                default: return false
                                }
                            }) { stat in
                                SmallMetricTileView(
                                    title: stat.kind == .steps ? "Steps" : "Calories",
                                    value: formatted(stat.value, unit: stat.unit),
                                    delta: stat.delta.map { $0 >= 0 ? "+\(Int($0))" : "\(Int($0))" }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                // Strength progress summary.
                Text("Strength Progress")
                    .font(.headline)
                    .padding(.horizontal)
                StrengthScorecardView(analyticsUseCase: viewModel.analyticsUseCase)
                    .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Analytics")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.shareTapped() }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share progress card")
            }
        }
        .sheet(item: $viewModel.sharePayload) { payload in
            ShareCardGenerator.makeShareSheet(for: payload)
        }
        .onAppear {
            Task { await viewModel.refreshAll() }
        }
    }

    /// Formats a numeric value with its unit string.
    private func formatted(_ value: Double, unit: String) -> String {
        let intVal = Int(value)
        if Double(intVal) == value {
            return unit.isEmpty ? "\(intVal)" : "\(intVal) \(unit)"
        } else {
            return unit.isEmpty ? "\(value)" : "\(String(format: "%.1f", value)) \(unit)"
        }
    }

    /// Determines a custom SF Symbol name for certain stat kinds (if needed).
    private func iconOverride(for kind: AnalyticsViewModel.VitalStatTile.Kind) -> String? {
        switch kind {
        case .bodyFat:   return "percent"
        case .bmi:       return "gauge.medium"
        case .ffmi:      return "dumbbell"
        case .steps:     return "figure.walk"
        case .calories:  return "flame.fill"
        default:         return nil
        }
    }
}

// A simple view for horizontal metric tiles (e.g., Steps, Calories).
private struct SmallMetricTileView: View {
    let title: String
    let value: String
    let delta: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            if let delta = delta {
                Text(delta)
                    .font(.caption2)
                    .foregroundColor(delta.hasPrefix("+") ? .green : .red)
            }
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: ShadowTokens.tile, radius: 3, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnalyticsView(analyticsUseCase: .preview)
    }
}
