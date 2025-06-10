//  ProfileCoordinator.swift
//  Gainz – Profile Feature
//
//  Created by AI-Assistant on 2025-06-03.
//  Purpose: Centralises navigation for the Profile tab using MVVM-C.
//
//  References:
//  – Modern SwiftUI Coordinator examples (NavigationStack)  ⟶ see citations.
//  – Apple Combine docs for @Published bindings.
//  – No HRV / velocity analytics per product spec.
//

import SwiftUI
import Combine
import Domain            // UserProfile model types
import CoreUI            // Brand modifiers & palette
import FeatureInterfaces // exposes ProfileFeatureInterface
import ServicePersistence    // user profile & workout data storage
import ServiceMetrics        // body metrics calculations
import ServiceExport         // data export logic

// MARK: – Route Enumeration

/// Declarative map of destinations reachable from Profile.
public enum ProfileRoute: Hashable {
    case root         // main profile screen
    case editProfile  // edit profile details
    case settings     // app settings
    case history      // workout history list
    case dataExport   // data export
}

// MARK: – Coordinator

@MainActor
public final class ProfileCoordinator: ObservableObject {

    // MARK: Public Navigation Path
    @Published public var path: [ProfileRoute] = []  // navigation state for Profile

    // MARK: Dependencies
    private let profileRepo: UserProfileRepositoryProtocol    // user profile repository
    private let metricsUseCase: CalculateMetricsUseCaseProtocol  // calculates BMI, FFMI, etc.
    private let exportUseCase: ExportDataUseCaseProtocol      // handles data export
    private let workoutRepo: WorkoutSessionRepositoryProtocol // workout sessions repository

    // MARK: – Init
    public init(profileRepo: UserProfileRepositoryProtocol,
                metricsUseCase: CalculateMetricsUseCaseProtocol,
                exportUseCase: ExportDataUseCaseProtocol,
                workoutRepo: WorkoutSessionRepositoryProtocol) {
        self.profileRepo   = profileRepo
        self.metricsUseCase = metricsUseCase
        self.exportUseCase  = exportUseCase
        self.workoutRepo    = workoutRepo
    }
}

// MARK: – Interface Conformance

extension ProfileCoordinator: ProfileFeatureInterface {

    /// Entrypoint consumed by AppCoordinator / TabRouter.
    public func start() -> AnyView {
        AnyView(ProfileCoordinatorView(coordinator: self))
    }

    /// Deep-link router (e.g., universal-link or widget).
    public func handleDeepLink(_ route: ProfileRoute) {
        if path.isEmpty {
            path = [route]
        } else {
            path.append(route)
        }
    }
}

// MARK: – SwiftUI Bridge

private struct ProfileCoordinatorView: View {

    @StateObject var coordinator: ProfileCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.makeRoot()
                .navigationDestination(for: ProfileRoute.self) { route in
                    coordinator.buildDestination(for: route)
                }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: – Factory Helpers

extension ProfileCoordinator {

    /// Root Profile screen.
    func makeRoot() -> some View {
        ProfileView(
            viewModel: .init(profileRepo: profileRepo,
                             metricsUseCase: metricsUseCase,
                             exportUseCase: exportUseCase,
                             hasSeparateSettingsTab: false)
        )
        // ProfileView uses NavigationLinks for child routes
    }

    /// Switchboard for subsequent destinations.
    @ViewBuilder
    func buildDestination(for route: ProfileRoute) -> some View {
        switch route {
        case .root:
            makeRoot()

        case .editProfile:
            EditProfileView(viewModel: .init(repository: profileRepo))  // Edit Profile screen (external feature)

        case .settings:
            SettingsView(viewModel: .init())  // Settings screen (external feature)

        case .history:
            HistoryListView(viewModel: .init(repo: workoutRepo))  // workout history screen

        case .dataExport:
            DataExportView(useCase: exportUseCase)  // data export screen
        }
    }
}

// MARK: – Preview

#if DEBUG
import PreviewKit

struct ProfileCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCoordinator(
            profileRepo: PreviewUserProfileRepository(),
            metricsUseCase: PreviewMetricsUseCase(),
            exportUseCase: PreviewExportUseCase(),
            workoutRepo: PreviewWorkoutSessionRepository()
        ).start()
            .preferredColorScheme(.dark)
    }
}
#endif
