//
//  AnalyticsView.swift
//  Features/AnalyticsDashboard
//
//  Created by Gainz AI on 2025-06-03.
//

import SwiftUI
import CoreUI
import Domain
import Charts

// MARK: - AnalyticsView

public struct AnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel

    public init(viewModel: @autoclosure @escaping () -> AnalyticsViewModel = AnalyticsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                Picker("Section", selection: $viewModel.section) {
                    ForEach(AnalyticsSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    switch viewModel.section {
                    case .body: bodySection
                    case .strength: strengthSection
                    case .recovery: recoverySection
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(ColorPalette.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.shareTapped) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share progress card")
                }
            }
            .sheet(isPresented: $viewModel.showLeaderboard) {
                LeaderboardView()
                    .environmentObject(viewModel)
            }
            .task { await viewModel.onAppear() }
        }
    }
}

// MARK: - Subviews

private extension AnalyticsView {
    var header: some View {
        HStack(spacing: 16) {
            AvatarView(image: viewModel.avatar, badge: viewModel.tier.badge)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                VitalStatTileView(title: "Weight", value: viewModel.weight, unit: viewModel.weightUnit)
                VitalStatTileView(title: "FFMI", value: viewModel.ffmi)
                VitalStatTileView(title: "BF %", value: viewModel.bodyFatPercent, unit: "%")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    var bodySection: some View {
        VStack(spacing: 24) {
            MannequinView(strengthMap: viewModel.strengthMap)
                .frame(height: 280)
                .accessibilityLabel("Interactive muscle strength heatmap")

            metricsStrip
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    var strengthSection: some View {
        StrengthScorecardView(scorecard: viewModel.scorecard)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
    }

    var recoverySection: some View {
        RecoveryOverviewView(model: viewModel.recoveryModel)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
    }

    var metricsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(viewModel.metricTiles) { tile in
                    MetricTileView(tile: tile)
                }
            }
            .padding(.horizontal, 4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Daily metrics strip")
    }
}

// MARK: - Supporting Types

public enum AnalyticsSection: String, CaseIterable, Identifiable {
    case body, strength, recovery

    public var id: Self { self }

    var title: String {
        switch self {
        case .body: "Body"
        case .strength: "Strength"
        case .recovery: "Recovery"
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
        .environmentObject(AnalyticsViewModel.preview)
}
