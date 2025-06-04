//
//  LeaderboardView.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Shows top lifters and body-comp trends among friends, with
//  animated rank transitions and a “you” highlight stripe.
//
//  Created by AI-Assistant on 2025-06-03.
//

import SwiftUI
import Domain   // LeaderboardEntry, LeaderboardCategory
import CoreUI   // ColorPalette, AsyncAvatar, ShadowTokens

// MARK: – Display Model
public struct LeaderboardEntry: Identifiable, Hashable {
    public let id         : UUID
    public let userName   : String
    public let avatarURL  : URL?
    public let metricValue: Double   // kg or points
    public let rank       : Int
    public let isCurrentUser: Bool
}

// Metric buckets selectable by segment
public enum LeaderboardCategory: String, CaseIterable, Identifiable {
    case totalStrength = "Strength"
    case bodyweight    = "Body Wt."
    case ffmi          = "FFMI"
    public var id: String { rawValue }
}

// MARK: – View
public struct LeaderboardView: View {

    // Injected from ViewModel
    @State public var selected: LeaderboardCategory = .totalStrength
    @State public var board   : [LeaderboardCategory : [LeaderboardEntry]]

    public var body: some View {
        VStack {
            Picker("Metric", selection: $selected) {
                ForEach(LeaderboardCategory.allCases) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // List auto-animates when data changes
            List {
                ForEach(board[selected] ?? []) { entry in
                    LeaderboardRow(entry: entry)
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
    }
}

// MARK: – Row
private struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 14) {
            Text("\(entry.rank)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(width: 34, height: 34)
                .foregroundStyle(rankColor)
                .background(
                    Circle()
                        .fill(rankColor.opacity(0.15))
                )
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

    // Rank-based color flourish
    private var rankColor: Color {
        switch entry.rank {
        case 1:  Color.yellow
        case 2:  Color.gray
        case 3:  Color.brown
        default: Color.secondary
        }
    }

    private var formattedMetric: String {
        switch LeaderboardCategory.totalStrength {
        case .totalStrength: "\(Int(entry.metricValue)) kg total"
        case .bodyweight:    "\(String(format: "%.1f", entry.metricValue)) kg"
        case .ffmi:          "\(String(format: "%.1f", entry.metricValue)) FFMI"
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        Button {
            let text = "\(entry.userName) hits #\(entry.rank) on Gainz Leaderboard!"
            UIPasteboard.general.string = text
        } label: {
            Label("Copy Rank", systemImage: "doc.on.doc")
        }
    }
}

// MARK: – Preview
#if DEBUG
struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView(
            board: [
                .totalStrength: demoEntries(),
                .bodyweight:    demoEntries(),
                .ffmi:          demoEntries()
            ]
        )
        .preferredColorScheme(.dark)
    }

    private static func demoEntries() -> [LeaderboardEntry] {
        (1...10).map {
            LeaderboardEntry(
                id: .init(), userName: "Athlete\($0)",
                avatarURL: nil, metricValue: Double.random(in: 300...600),
                rank: $0, isCurrentUser: $0 == 4
            )
        }
    }
}
#endif
