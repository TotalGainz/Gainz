//  ProfileViewModel.swift
//  Gainz – Profile Feature
//
//  Created by AI-Assistant on 2025-06-03.
//
//  Architectural notes:
//  – Follows MVVM with @Published bindings for SwiftUI refresh.
//  – Uses Swift Concurrency for async/await data loading.
//  – HealthKit permission workflow mirrors Apple samples.
//  – Metric calculations rely on standard BMI / FFMI formulae.
//  – HRV & velocity metrics intentionally omitted per product scope.
//

import SwiftUI
import Combine
import Domain                   // UserProfile, BodyMetrics, StatsSummary
import ServicePersistence       // UserProfileRepositoryProtocol
import ServiceMetrics           // CalculateMetricsUseCaseProtocol
import ServiceHealth            // HealthKitSyncManager

// MARK: – ViewModel

@MainActor
public final class ProfileViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published public private(set) var avatarImage: Image? = nil
    @Published public private(set) var displayName: String = ""
    @Published public private(set) var primaryGoal: String = ""
    @Published public private(set) var metricTiles: [MetricTile] = []
    @Published public private(set) var lifetimeSummary: StatsSummary = .empty
    @Published public var healthKitConnected: Bool = false {
        didSet { handleHealthKitToggle() }
    }

    /// Flag to hide Settings shortcut when a dedicated tab exists.
    public let hasSeparateSettingsTab: Bool

    // MARK: - Dependencies
    private let profileRepo: UserProfileRepositoryProtocol
    private let metricsUseCase: CalculateMetricsUseCaseProtocol
    private let healthKit: HealthKitSyncManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    public init(profileRepo: UserProfileRepositoryProtocol,
                metricsUseCase: CalculateMetricsUseCaseProtocol,
                healthKit: HealthKitSyncManager = .shared,
                hasSeparateSettingsTab: Bool = false) {
        self.profileRepo          = profileRepo
        self.metricsUseCase       = metricsUseCase
        self.healthKit            = healthKit
        self.hasSeparateSettingsTab = hasSeparateSettingsTab

        // Sync local toggle with HealthKit manager
        healthKit.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: &$healthKitConnected)
    }

    // MARK: - Lifecycle

    /// Loads profile + metrics on first appearance.
    public func load() async {
        await refresh()
    }

    /// Pull-to-refresh delegate.
    public func refresh() async {
        do {
            let profile = try await profileRepo.fetchUserProfile()
            mapProfile(profile)

            let metrics = try await metricsUseCase.calculate(for: profile.id)
            mapMetrics(metrics)
            lifetimeSummary = metrics.lifetimeSummary
        } catch {
            // TODO: Route to global error handler
            print("Profile refresh failed: \(error)")
        }
    }

    // MARK: - Helpers & Mapping

    private func handleHealthKitToggle() {
        Task {
            if healthKitConnected {
                try? await healthKit.requestPermission() // async HealthKit auth
            } else {
                healthKit.deauthorize()
            }
        }
    }

    private func mapProfile(_ profile: UserProfile) {
        displayName  = profile.displayName
        primaryGoal  = profile.primaryGoal
        if let data  = profile.avatarPNGData,
           let uiImg = UIImage(data: data) {
            avatarImage = Image(uiImage: uiImg)
        } else {
            avatarImage = nil
        }
    }

    private func mapMetrics(_ metrics: BodyMetrics) {
        metricTiles = [
            .init(title: "Weight",
                  value: metrics.weight.formatted(.number.precision(.fractionLength(1))),
                  unit: "kg"),
            .init(title: "BMI",
                  value: metrics.bmi.formatted(.number.precision(.fractionLength(1))),
                  unit: nil),
            .init(title: "FFMI",
                  value: metrics.ffmi.formatted(.number.precision(.fractionLength(1))),
                  unit: nil),
            .init(title: "Height",
                  value: metrics.height.formatted(),
                  unit: "cm"),
            .init(title: "Age",
                  value: metrics.age.formatted(),
                  unit: "y")
        ]
    }
}

// MARK: – DTOs

public struct MetricTile: Identifiable {
    public let id = UUID()
    public let title: String
    public let value: String
    public let unit: String?
}

// MARK: – Preview Stubs

#if DEBUG
import PreviewKit

extension ProfileViewModel {
    static let preview: ProfileViewModel = {
        let vm = ProfileViewModel(
            profileRepo: PreviewUserProfileRepository(),
            metricsUseCase: PreviewMetricsUseCase(),
            hasSeparateSettingsTab: false
        )
        Task { await vm.load() }
        return vm
    }()
}
#endif
