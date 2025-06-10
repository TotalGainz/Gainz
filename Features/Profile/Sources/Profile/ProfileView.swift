//  ProfileView.swift
//  Gainz – Profile Feature
//
//  Created by AI-Assistant on 2025-06-03.
//  References: UX spec for Profile screen (v8 Roadmap) [oai_citation:0‡v8 UIUX Roadmap.txt](file-service://file-3J5YLRXNt4e6KPXDLuth4z),
//              Navigation schema (tab bar) [oai_citation:1‡navigation v8.txt](file-service://file-C4Kpusi7gehKFFAnxsh2hV),
//              Module outline for Profile feature [oai_citation:2‡repo explanation for o3 (UPDATED).txt](file-service://file-CnLa5rmYAZJgvi98KEwAKv)
//

import SwiftUI
import Combine
import Domain           // UserProfile, WorkoutSession models
import CoreUI           // ColorPalette, BrandTypography
import ServiceHealth    // HealthKitSyncManager

// MARK: – View

public struct ProfileView: View {

    // MARK: State
    @StateObject private var viewModel: ProfileViewModel

    // MARK: Init
    public init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statsSection
                lifetimeSection
                integrationsSection
                settingsShortcut
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
    }
}

// MARK: – Sub-Views

private extension ProfileView {

    // Avatar + name + goal
    var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            AvatarView(image: viewModel.avatarImage,
                       placeholderGlyph: "person.crop.circle.fill")
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.displayName)
                    .font(.brandTitle) // CoreUI typography
                Text(viewModel.primaryGoal)
                    .font(.brandSubheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Edit button navigates to Edit Profile screen
            NavigationLink(value: ProfileRoute.editProfile) {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(8)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit profile")
        }
    }

    // Body metrics grid (Weight, BMI, FFMI, Height, Age)
    var statsSection: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3),
                  spacing: 16) {
            ForEach(viewModel.metricTiles) { tile in
                MetricTileView(tile: tile)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
    }

    // Lifetime workout résumé (tap to view history)
    var lifetimeSection: some View {
        NavigationLink(value: ProfileRoute.history) {
            StatsSummaryView(summary: viewModel.lifetimeSummary)
                .padding()
                .background(ColorPalette.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .accessibilityLabel("Lifetime workout stats, tap to view history")
    }

    // Connected apps & export
    var integrationsSection: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $viewModel.healthKitConnected) {
                Label("Apple Health", systemImage: "heart.fill")
            }
            .toggleStyle(.switch)

            // Export data button navigates to DataExport screen
            NavigationLink(value: ProfileRoute.dataExport) {
                Label("Export Workout & Body Data", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(ColorPalette.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // Link to Settings (if separate tab absent)
    @ViewBuilder
    var settingsShortcut: some View {
        if !viewModel.hasSeparateSettingsTab {
            NavigationLink(value: ProfileRoute.settings) {
                Label("Settings", systemImage: "gearshape")
                    .font(.brandBody)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ColorPalette.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
}

// MARK: – Preview

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView(viewModel: .preview)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
