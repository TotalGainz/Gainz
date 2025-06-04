//
//  HistoryListView.swift
//  Gainz – Profile Feature
//
//  Created by AI-Assistant on 2025-06-03.
//
//  Design & implementation notes:
//
//  • Groups workout sessions by calendar week using `Section<Date>`
//    headers formatted via `RelativeDateTimeFormatter` for a
//    conversational feel.  [oai_citation:0‡developer.apple.com](https://developer.apple.com/documentation/foundation/relativedatetimeformatter?utm_source=chatgpt.com)
//
//  • Uses SwiftUI’s native `List` with `refreshable` to provide
//    pull-to-refresh semantics.  [oai_citation:1‡stackoverflow.com](https://stackoverflow.com/questions/74247686/bug-in-swiftui-ios-15-list-refresh-action-is-executed-on-an-old-instance-of-vi?utm_source=chatgpt.com) [oai_citation:2‡gist.github.com](https://gist.github.com/inTheAM/a17a96a13ab8d30095240acea39c1115?utm_source=chatgpt.com)
//
//  • Provides swipe-to-delete actions with `.onDelete` and
//    `.swipeActions`, mirroring Apple Mail UX.  [oai_citation:3‡medium.com](https://medium.com/%40thanhtra.sqcb/swiftui-for-beginner-8-list-deletion-swipe-actions-context-menus-and-activity-controller-8f9a5de31000?utm_source=chatgpt.com) [oai_citation:4‡kodeco.com](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/4-implementing-swipe-to-delete-in-swiftui?utm_source=chatgpt.com)
//
//  • Leverages `@Published` in the view-model for reactive updates
//    and Combine integration.  [oai_citation:5‡developer.apple.com](https://developer.apple.com/documentation/combine/published?utm_source=chatgpt.com) [oai_citation:6‡paigeshin1991.medium.com](https://paigeshin1991.medium.com/swift-combine-about-published-wrapper-things-you-probably-didnt-know-8711706d890f?utm_source=chatgpt.com)
//
//  • Sorts sessions descending by date before diffing for sections.  [oai_citation:7‡stackoverflow.com](https://stackoverflow.com/questions/42479412/sort-by-date-swift-3?utm_source=chatgpt.com)
//
//  • Chooses `List` over `LazyVStack` for out-of-box cell reuse,
//    because performance is adequate for historical logs.  [oai_citation:8‡fatbobman.com](https://fatbobman.com/en/posts/list-or-lazyvstack/?utm_source=chatgpt.com)
//
//  • Demonstrates date-based Section headers pattern.  [oai_citation:9‡stackoverflow.com](https://stackoverflow.com/questions/73733910/swiftui-sorting-a-structured-array-and-show-date-item-into-a-section-header?utm_source=chatgpt.com)
//
//  • Navigates to a detail screen via `NavigationLink` inside each row.  [oai_citation:10‡developer.apple.com](https://developer.apple.com/tutorials/swiftui/building-lists-and-navigation?utm_source=chatgpt.com)
//
//  • Avoids HRV / bar-speed analytics per product spec; shows sets,
//    reps, and tonnage only.
//
// ---------------------------------------------------------------------

import SwiftUI
import Domain               // WorkoutSession
import ServicePersistence    // WorkoutSessionRepositoryProtocol

// MARK: – View

public struct HistoryListView: View {

    // MARK: Dependencies
    @StateObject private var viewModel: HistoryListViewModel

    // MARK: Init
    public init(viewModel: HistoryListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Body
    public var body: some View {
        List {
            ForEach(viewModel.sectionedSessions.keys.sorted(by: >), id: \.self) { weekStart in
                Section(header: Text(sectionHeader(for: weekStart))) {
                    ForEach(viewModel.sectionedSessions[weekStart]!) { session in
                        NavigationLink(value: session.id) {
                            HistoryRowView(session: session)
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.delete(in: weekStart, offsets: indexSet)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteAll(in: weekStart)
                        } label: { Label("Delete Week", systemImage: "trash") }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("History")
        .refreshable { await viewModel.refresh() }
        .navigationDestination(for: WorkoutSession.ID.self) { id in
            WorkoutDetailView(sessionID: id)
        }
        .task { await viewModel.load() }
    }

    // MARK: Helpers

    private func sectionHeader(for weekStart: Date) -> String {
        viewModel.relativeFormatter.localizedString(for: weekStart, relativeTo: .now)
    }
}

// MARK: – ViewModel

@MainActor
public final class HistoryListViewModel: ObservableObject {

    // MARK: Published
    @Published private(set) var sectionedSessions: [Date: [WorkoutSession]] = [:]

    // MARK: Dependencies
    private let repo: WorkoutSessionRepositoryProtocol
    let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    // MARK: Init
    public init(repo: WorkoutSessionRepositoryProtocol) {
        self.repo = repo
    }

    // MARK: Loading

    func load() async {
        await refresh()
    }

    func refresh() async {
        do {
            var sessions = try await repo.fetchAllSessions()
            sessions.sort { $0.date > $1.date }              // newest first
            sectionedSessions = Dictionary(
                grouping: sessions,
                by: { Calendar.current.startOfWeek(for: $0.date) }
            )
        } catch {
            print("History refresh failed: \(error)")
        }
    }

    // MARK: Deletion

    func delete(in weekStart: Date, offsets: IndexSet) {
        guard var list = sectionedSessions[weekStart] else { return }
        offsets.map { list[$0] }.forEach { session in
            try? repo.delete(sessionID: session.id)
        }
        list.remove(atOffsets: offsets)
        sectionedSessions[weekStart] = list
    }

    func deleteAll(in weekStart: Date) {
        guard let list = sectionedSessions[weekStart] else { return }
        list.forEach { try? repo.delete(sessionID: $0.id) }
        sectionedSessions[weekStart] = []
    }
}

// MARK: – Row View

private struct HistoryRowView: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(session.totalVolume, format: .number) kg")
                    .font(.subheadline)
                    .bold()
                Text("\(session.setCount) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: – Date Helper

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        startOfDay(for: dateComponents([.yearForWeekOfYear, .weekOfYear], from: date).date!)
    }
}

// MARK: – Preview

#if DEBUG
import PreviewKit

struct HistoryListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HistoryListView(
                viewModel: .init(repo: PreviewWorkoutSessionRepository())
            )
        }
        .preferredColorScheme(.dark)
    }
}
#endif
