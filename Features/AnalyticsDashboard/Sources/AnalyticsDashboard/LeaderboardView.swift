//  LeaderboardView.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Displays a leaderboard of users (friends) comparing strength or body metrics, with
//  segment controls for different categories. Highlights the current user and animates rank changes.
//

import SwiftUI
import Domain   // LeaderboardEntry, LeaderboardCategory definitions
import CoreUI   // ColorPalette, AsyncAvatar, ShadowTokens

// MARK: - Data Models

/// A single entry (row) in the leaderboard.
public struct LeaderboardEntry: Identifiable, Hashable {
    public let id: UUID
    public let userName: String
    public let avatarURL: URL?
    public let metricValue: Double   // Value for the metric (e.g., total strength or weight).
    public let rank: Int
    public let isCurrentUser: Bool

    public init(id: UUID = UUID(),
                userName: String,
                avatarURL: URL? = nil,
                metricValue: Double,
                rank: Int,
                isCurrentUser: Bool = false) {
        self.id = id
        self.userName = userName
        self.avatarURL = avatarURL
        self.metricValue = metricValue
        self.rank = rank
        self.isCurrentUser = isCurrentUser
    }
}

/// The metric categories selectable in the leaderboard (Strength, Body Weight, FFMI).
public enum LeaderboardCategory: String, CaseIterable, Identifiable {
    case totalStrength = "Strength"
    case bodyweight    = "Body Wt."
    case ffmi          = "FFMI"

    public var id: String { rawValue }
}

// MARK: - Main View

public struct LeaderboardView: View {
    @StateObject private var viewModel: LeaderboardVM
    @State private var selected: LeaderboardCategory = .totalStrength

    public init(analyticsUseCase: CalculateAnalyticsUseCase) {
        _viewModel = StateObject(wrappedValue: LeaderboardVM(analyticsUseCase: analyticsUseCase))
    }

    public var body: some View {
        VStack {
            Picker("Metric", selection: $selected) {
                ForEach(LeaderboardCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                ForEach(viewModel.board[selected] ?? []) { entry in
                    LeaderboardRow(entry: entry, category: selected)
                        .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .background(entry.isCurrentUser ? ColorPalette.phoenix.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .scrollContentBackground(.hidden)
            .animation(.default, value: selected)
        }
        .navigationTitle("Leaderboard")
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            await viewModel.refresh()
        }
    }
}

// MARK: - ViewModel

@MainActor
private final class LeaderboardVM: ObservableObject {
    private let analyticsUseCase: CalculateAnalyticsUseCase
    @Published var board: [LeaderboardCategory: [LeaderboardEntry]] = [:]

    init(analyticsUseCase: CalculateAnalyticsUseCase) {
        self.analyticsUseCase = analyticsUseCase
    }

    /// Fetches leaderboard data for all categories (e.g., from network or database).
    func refresh() async {
        board = await analyticsUseCase.fetchLeaderboardEntries()
    }
}

// MARK: - Row View

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let category: LeaderboardCategory

    var body: some View {
        HStack(spacing: 14) {
            Text("\(entry.rank)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(width: 34, height: 34)
                .foregroundStyle(rankColor)
                .background(Circle().fill(rankColor.opacity(0.15)))
            AsyncAvatar(url: entry.avatarURL, fallbackText: entry.userName)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.userName)
                    .fontWeight(entry.isCurrentUser ? .bold : .regular)
                Text(formattedMetric)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu { shareButton }
    }

    /// Rank circle color (gold/silver/bronze for top 3, else secondary).
    private var rankColor: Color {
        switch entry.rank {
        case 1:  return .yellow
        case 2:  return .gray
        case 3:  return .brown
        default: return .secondary
        }
    }

    /// Formats the entry's metric value with appropriate unit or label.
    private var formattedMetric: String {
        switch category {
        case .totalStrength:
            return "\(Int(entry.metricValue)) kg total"
        case .bodyweight:
            return String(format: "%.1f kg", entry.metricValue)
        case .ffmi:
            return String(format: "%.1f FFMI", entry.metricValue)
        }
    }

    /// Context menu option to copy the user's rank to clipboard.
    @ViewBuilder
    private var shareButton: some View {
        Button {
            let copyText = "\(entry.userName) is #\(entry.rank) on the leaderboard for \(category.rawValue)."
            UIPasteboard.general.string = copyText
        } label: {
            Label("Copy Rank", systemImage: "doc.on.doc")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LeaderboardView(analyticsUseCase: .preview)
            .preferredColorScheme(.dark)
    }
}
