//
//  AnalyticsCoordinator.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Created by AI-Assistant on 2025-06-03.
//  Copyright © 2025 Echelon Commerce LLC.
//

import SwiftUI
import Combine
import Domain            // shared models (WorkoutSession, Exercise, etc.)
import CoreUI            // brand-wide design tokens & components
import FeatureInterfaces // exposes `AnalyticsDashboardFeatureInterface`

// MARK: – Route Enum

/// All navigable destinations within the Analytics Dashboard stack.
public enum AnalyticsRoute: Hashable {
    case dashboard                            // main overview
    case muscleHeatmap                        // stimulus distribution
    case strengthScorecard                    // 1RM & PR analytics
    case vitalStatDetail(VitalStatKind)       // RHR, Sleep, etc.
    case leaderboard                          // body- & strength-based
}

/// Simple “stat kind” discriminator (HRV intentionally excluded)
public enum VitalStatKind: String, Hashable, Codable {
    case restingHeartRate, sleepDuration, weightTrend
}

// MARK: – Coordinator

@MainActor
public final class AnalyticsCoordinator: ObservableObject {

    // MARK: Dependencies
    private let analyticsUseCase: CalculateAnalyticsUseCase
    private let haptic = HapticManager.shared

    // MARK: Navigation
    @Published public var path: [AnalyticsRoute] = []

    // MARK: Init
    public init(analyticsUseCase: CalculateAnalyticsUseCase) {
        self.analyticsUseCase = analyticsUseCase
    }
}

// MARK: – Interface Conformance
extension AnalyticsCoordinator: AnalyticsDashboardFeatureInterface {

    /// Entry-point consumed by `AppCoordinator` or TabRouter.
    public func start() -> AnyView {
        AnyView(AnalyticsCoordinatorView(coordinator: self))
    }

    /// Deep-link router (e.g. from push-notification or widget).
    public func handleDeepLink(_ route: AnalyticsRoute) {
        if path.isEmpty { path = [route] }       // initial push
        else { path.append(route) }              // drill-in
    }
}

// MARK: – SwiftUI Bridge

/// Thin wrapper hosting the NavigationStack bound to the coordinator.
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
        .onAppear { coordinator.haptic.fire(.soft) }
    }
}

// MARK: – Factory Helpers

extension AnalyticsCoordinator {

    /// Root dashboard (summary cards + segmented controls).
    func makeDashboard() -> some View {
        AnalyticsView(viewModel: .init(analyticsUseCase: analyticsUseCase)) { route in
            // child view emits desired route via callback
            path.append(route)
        }
        .brandStyled() // CoreUI ViewModifier for gradient header
    }

    /// Centralised navigation switch.
    @ViewBuilder
    func buildDestination(for route: AnalyticsRoute) -> some View {
        switch route {
        case .dashboard:
            makeDashboard()

        case .muscleHeatmap:
            MuscleHeatmapView(viewModel: .init(analyticsUseCase: analyticsUseCase))

        case .strengthScorecard:
            StrengthScorecardView(viewModel: .init(analyticsUseCase: analyticsUseCase))

        case .vitalStatDetail(let kind):
            VitalStatDetailView(kind: kind,
                                viewModel: .init(analyticsUseCase: analyticsUseCase))

        case .leaderboard:
            LeaderboardView(viewModel: .init(analyticsUseCase: analyticsUseCase))
        }
    }
}

// MARK: – Preview

#if DEBUG
struct AnalyticsCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsCoordinator(analyticsUseCase: .preview).start()
            .preferredColorScheme(.dark)
    }
}
#endif
