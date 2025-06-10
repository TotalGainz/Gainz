//  AnalyticsCoordinator.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Coordinates navigation for the Analytics Dashboard feature, managing routes to sub-views (heatmap, scorecard, etc).
//

import SwiftUI
import Combine
import Domain            // Domain models (WorkoutSession, Exercise, etc.)
import CoreUI            // Shared UI styling and components
import FeatureInterfaces // Provides AnalyticsDashboardFeatureInterface protocol

// MARK: - Navigation Routes

/// All destinations within the Analytics Dashboard flow.
public enum AnalyticsRoute: Hashable {
    case dashboard                            // Main overview
    case muscleHeatmap                        // Muscle stimulus distribution screen
    case strengthScorecard                    // Strength 1RM progress screen
    case vitalStatDetail(VitalStatKind)       // Detail for a specific vital stat
    case leaderboard                          // Friends leaderboard
}

/// Types of vital stats for detail view (excluding HRV per requirements).
public enum VitalStatKind: String, Hashable, Codable {
    case restingHeartRate, sleepDuration, weightTrend
}

// MARK: - Coordinator

@MainActor
public final class AnalyticsCoordinator: ObservableObject {
    private let analyticsUseCase: CalculateAnalyticsUseCase
    private let haptic = HapticManager.shared

    @Published public var path: [AnalyticsRoute] = []

    public init(analyticsUseCase: CalculateAnalyticsUseCase) {
        self.analyticsUseCase = analyticsUseCase
    }
}

// MARK: - Feature Interface Conformance

extension AnalyticsCoordinator: AnalyticsDashboardFeatureInterface {
    public func start() -> AnyView {
        AnyView(AnalyticsCoordinatorView(coordinator: self))
    }

    public func handleDeepLink(_ route: AnalyticsRoute) {
        if path.isEmpty {
            path = [route]    // set initial route
        } else {
            path.append(route)
        }
    }
}

// MARK: - SwiftUI Bridge

/// Hosts the NavigationStack bound to the coordinator's route path.
private struct AnalyticsCoordinatorView: View {
    @StateObject var coordinator: AnalyticsCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.makeDashboard()
                .navigationDestination(for: AnalyticsRoute.self) { route in
                    coordinator.buildDestination(for: route)
                }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            coordinator.haptic.fire(.soft)
        }
    }
}

// MARK: - Navigation Factory Methods

extension AnalyticsCoordinator {
    /// Constructs the root Analytics dashboard view with navigation callbacks.
    func makeDashboard() -> some View {
        AnalyticsView(analyticsUseCase: analyticsUseCase) { selectedRoute in
            // Child view emits a route when a tile is tapped.
            path.append(selectedRoute)
        }
        .brandStyled()  // Apply global brand styling (e.g., gradient background).
    }

    /// Builds the appropriate destination view for a given route.
    @ViewBuilder
    func buildDestination(for route: AnalyticsRoute) -> some View {
        switch route {
        case .dashboard:
            makeDashboard()
        case .muscleHeatmap:
            MuscleHeatmapView(analyticsUseCase: analyticsUseCase)
        case .strengthScorecard:
            StrengthScorecardView(analyticsUseCase: analyticsUseCase)
        case .vitalStatDetail(let kind):
            VitalStatDetailView(kind: kind, analyticsUseCase: analyticsUseCase)
        case .leaderboard:
            LeaderboardView(analyticsUseCase: analyticsUseCase)
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsCoordinator(analyticsUseCase: .preview).start()
        .preferredColorScheme(.dark)
}
