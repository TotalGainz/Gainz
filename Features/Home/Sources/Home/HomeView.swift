//
//  HomeView.swift
//  HomeFeature
//
//  SwiftUI entry point for the “Home” tab.
//  Shows: greeting, next-workout card, key metrics grid, and quick actions.
//  • Brand-consistent visuals via CoreUI tokens.
//  • Asynchronous refresh & skeletons.
//  • Zero HRV / recovery / velocity logic.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import CoreUI          // color & typography tokens
import Domain          // WorkoutSession, MesocyclePlan
import FeatureSupport  // UnitConversion, DateFormatters

// MARK: - HomeView

public struct HomeView: View {

    // View-model drives state; injected for testability
    @StateObject private var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel = .init()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    greeting
                    nextWorkoutCard
                    metricsGrid
                    quickActions
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(CoreUI.Color.background.ignoresSafeArea())
            .navigationTitle("")                // large title hidden
            .navigationBarHidden(true)
            .task { await viewModel.onAppear() } // async bootstrap
            .refreshable { await viewModel.refresh() }
        }
        .alert(item: $viewModel.error) { err in
            Alert(title: Text("Oops"), message: Text(err.message))
        }
    }
}

// MARK: - Sections

private extension HomeView {

    /// “Good morning, Brody” + date
    var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.greeting)
                .font(CoreUI.Font.headingXL)
            Text(viewModel.formattedDate)
                .font(CoreUI.Font.bodyM)
                .foregroundColor(CoreUI.Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(when: viewModel.isLoading)
    }

    /// Card for the next scheduled workout
    var nextWorkoutCard: some View {
        Button {
            viewModel.openNextWorkout()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.nextWorkoutTitle)
                        .font(CoreUI.Font.headingM)
                    Text(viewModel.nextWorkoutSubtitle)
                        .font(CoreUI.Font.bodyS)
                        .foregroundColor(CoreUI.Color.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(CoreUI.Color.accent)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(CoreUI.Color.cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                CoreUI.Color.accent
                    .frame(width: 4)
                    .mask(alignment: .leading) { Rectangle() } , alignment: .leading
            )
        }
        .buttonStyle(.plain)
        .redacted(when: viewModel.isLoading)
    }

    /// Grid of key daily metrics
    var metricsGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 16) {
            MetricCell(title: "Week Volume",
                       value: viewModel.weeklyVolume,
                       unit: "kg")
            MetricCell(title: "Sessions",
                       value: viewModel.completedSessions,
                       unit: "/\(viewModel.sessionsPlanned)")
            MetricCell(title: "Avg. RPE",
                       value: viewModel.averageRPE,
                       unit: "")
            MetricCell(title: "Body-weight",
                       value: viewModel.bodyWeight,
                       unit: "kg")
        }
        .redacted(when: viewModel.isLoading)
    }

    /// Row of quick-action buttons
    var quickActions: some View {
        HStack(spacing: 16) {
            QuickAction(icon: "plus.circle",
                        label: "Log Set") { viewModel.openQuickLog() }
            QuickAction(icon: "calendar",
                        label: "Planner") { viewModel.openPlanner() }
            QuickAction(icon: "chart.bar",
                        label: "Analytics") { viewModel.openAnalytics() }
        }
    }
}

// MARK: - Sub-components

private struct MetricCell: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(CoreUI.Font.bodyS)
                .foregroundColor(CoreUI.Color.secondaryText)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(CoreUI.Font.headingL)
                if !unit.isEmpty {
                    Text(unit)
                        .font(CoreUI.Font.bodyS)
                        .foregroundColor(CoreUI.Color.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(CoreUI.Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct QuickAction: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(CoreUI.Color.accent.opacity(0.15), in: Circle())
                Text(label)
                    .font(CoreUI.Font.bodyS)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    HomeView(viewModel: .preview)
        .environment(\.colorScheme, .dark)
}
#endif
