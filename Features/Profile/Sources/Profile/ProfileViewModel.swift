//
//  ProfileViewModel.swift
//  Gainz – Profile Feature
//
//  Created by AI-Assistant on 2025-06-03.
//
//  Architectural notes:
//  – Follows MVVM with @Published bindings for SwiftUI refresh. [oai_citation:0‡odenza.medium.com](https://odenza.medium.com/mvvm-design-pattern-in-swiftui-with-observableobject-published-observedobject-to-fetch-json-data-bdfb845f5361?utm_source=chatgpt.com)
 //  – Uses Swift Concurrency for async data loading. [oai_citation:1‡stackoverflow.com](https://stackoverflow.com/questions/75771766/how-to-update-swiftui-view-with-async-data?utm_source=chatgpt.com) [oai_citation:2‡medium.com](https://medium.com/%40myofficework000/loading-initial-data-in-swiftui-task-or-viewmodel-a531adbe01ba?utm_source=chatgpt.com)
 //  – HealthKit permission workflow mirrors Apple samples. [oai_citation:3‡developer.apple.com](https://developer.apple.com/documentation/healthkit/running-queries-with-swift-concurrency?utm_source=chatgpt.com) [oai_citation:4‡developer.apple.com](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data?utm_source=chatgpt.com)
//  – Metric calculations rely on standard BMI [oai_citation:5‡stackoverflow.com](https://stackoverflow.com/questions/57023483/calculate-the-bmi-using-mass-and-height-and-use-if-else-statements-to-print-if?utm_source=chatgpt.com) and FFMI formulae. [oai_citation:6‡ffmicalculator.org](https://ffmicalculator.org/?utm_source=chatgpt.com) [oai_citation:7‡omnicalculator.com](https://www.omnicalculator.com/health/ffmi?utm_source=chatgpt.com)
//  – Toggle binding pattern informed by Combine best-practice. [oai_citation:8‡stackoverflow.com](https://stackoverflow.com/questions/71319628/is-there-any-way-for-a-toggle-to-operate-on-a-member-of-a-binding?utm_source=chatgpt.com)
//
//  HRV & Velocity tracking intentionally omitted per spec.
//

import SwiftUI
import Combine
import Domain                   // UserProfile, BodyMetrics, StatsSummary
import ServicePersistence       // UserProfileRepositoryProtocol
import ServiceMetrics           // CalculateMetricsUseCaseProtocol
import ServiceExport            // ExportDataUseCaseProtocol
import ServiceHealth            // HealthKitSyncManager

// MARK: – ViewModel

@MainActor
public final class ProfileViewModel: ObservableObject {

    // MARK: Published UI state
    @Published public private(set) var avatarImage: Image? = nil
    @Published public private(set) var displayName: String = ""
    @Published public private(set) var primaryGoal: String = ""
    @Published public private(set) var metricTiles: [MetricTile] = []
    @Published public private(set) var lifetimeSummary: StatsSummary = .empty
    @Published public var healthKitConnected: Bool = false {
        didSet { handleHealthKitToggle() }
    }

    /// Whether the tab-bar already exposes Settings.
    public let hasSeparateSettingsTab: Bool

    // MARK: Dependencies
    private let profileRepo: UserProfileRepositoryProtocol
    private let metricsUseCase: CalculateMetricsUseCaseProtocol
    private let exportUseCase: ExportDataUseCaseProtocol
    private let healthKit: HealthKitSyncManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init
    public init(profileRepo: UserProfileRepositoryProtocol,
                metricsUseCase: CalculateMetricsUseCaseProtocol,
                exportUseCase: ExportDataUseCaseProtocol,
                healthKit: HealthKitSyncManager = .shared,
                hasSeparateSettingsTab: Bool = false) {
        self.profileRepo     = profileRepo
        self.metricsUseCase  = metricsUseCase
        self.exportUseCase   = exportUseCase
        self.healthKit       = healthKit
        self.hasSeparateSettingsTab = hasSeparateSettingsTab

        // Listen to health-sync updates
        healthKit.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: &$healthKitConnected)
    }

    // MARK: Lifecycle

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
            // Ideally route to global error handler
            print("Profile refresh failed: \(error)")
        }
    }

    // MARK: User Intents

    public func editProfileTapped() {
        // TODO: Wire to EditProfileCoordinator
    }

    public func exportDataTapped() {
        Task {
            do { try await exportUseCase.exportUserData() }
            catch { print("Export failed: \(error)") }
        }
    }

    // MARK: Helpers

    private func handleHealthKitToggle() {
        Task {
            if healthKitConnected {
                try? await healthKit.requestPermission() // async/await API [oai_citation:9‡developer.apple.com](https://developer.apple.com/documentation/healthkit/running-queries-with-swift-concurrency?utm_source=chatgpt.com)
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
        // BMI example: weight(kg) / height(m)^2. [oai_citation:10‡gist.github.com](https://gist.github.com/abdullahbutt/d22298399d771e10ae134aa013ebe8f4?utm_source=chatgpt.com)
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
                  unit: "cm")
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
extension ProfileViewModel {
    static let preview: ProfileViewModel = {
        let vm = ProfileViewModel(
            profileRepo: PreviewUserProfileRepository(),
            metricsUseCase: PreviewMetricsUseCase(),
            exportUseCase: PreviewExportUseCase(),
            hasSeparateSettingsTab: false
        )
        Task { await vm.load() }
        return vm
    }()
}
#endif
