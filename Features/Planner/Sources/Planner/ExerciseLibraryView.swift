//
//  ExerciseLibraryView.swift
//  Feature – Planner
//
//  Shows a searchable, adaptive LazyVGrid of all exercises.
//  Filtering is debounced via Combine to avoid layout thrash for every keystroke.
//  Drag-to-add uses onDrag/onDrop so users can pull exercises into the day planner.
//
//  Search bar & `.searchable` pattern             – see Kodeco guide  [oai_citation:0‡Kodeco](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/7-create-a-search-bar-in-a-list-in-swiftui?utm_source=chatgpt.com)
//  Adaptive LazyVGrid column logic                 – Reddit & Medium examples  [oai_citation:1‡Reddit](https://www.reddit.com/r/SwiftUI/comments/heebgz/how_to_make_the_new_lazyvgrid_column_count_dynamic/?utm_source=chatgpt.com) [oai_citation:2‡Medium](https://medium.com/%40viralswift/mastering-swiftui-grids-creating-flexible-grid-based-layouts-df99a7dad7b3?utm_source=chatgpt.com)
//  Drag reordering / custom drop delegates         – Daniel Saidi blog + Reddit thread  [oai_citation:3‡Daniel Saidi](https://danielsaidi.com/blog/2023/08/30/enabling-drag-reordering-in-swiftui-lazy-grids-and-stacks?utm_source=chatgpt.com) [oai_citation:4‡Reddit](https://www.reddit.com/r/SwiftUI/comments/1hd0f6t/has_anyone_succeeded_in_making_manual_reordering/?utm_source=chatgpt.com)
//  Combine debounced search                        – Medium & StackOverflow patterns  [oai_citation:5‡Medium](https://medium.com/%40amitaswal87/debounce-in-combine-swiftui-b6e55d2792dc?utm_source=chatgpt.com) [oai_citation:6‡Stack Overflow](https://stackoverflow.com/questions/66164898/swiftui-combine-debounce-textfield?utm_source=chatgpt.com)
//  iOS 15+ search suggestions API                  – Apple docs & related SO post  [oai_citation:7‡Apple Developer](https://developer.apple.com/documentation/swiftui/suggesting-search-terms?utm_source=chatgpt.com) [oai_citation:8‡Stack Overflow](https://stackoverflow.com/questions/68153209/swiftui-searchable-in-ios-15-navigationbardrawerdisplaymode-always?utm_source=chatgpt.com)
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Combine
import Domain

// MARK: - ViewModel

@MainActor
final class ExerciseLibraryViewModel: ObservableObject {
    // Input
    @Published var searchText = ""
    // Output
    @Published private(set) var filtered: [Exercise] = []

    private let repo: ExerciseRepository
    private var allExercises: [Exercise] = []
    private var cancellables = Set<AnyCancellable>()

    init(repo: ExerciseRepository) {
        self.repo = repo
        bind()
    }

    func load() async {
        allExercises = await repo.fetchAllExercises()
        filtered = allExercises
    }

    private func bind() {
        // Debounce search to 250 ms so grid does not churn on every keystroke.
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                if text.isEmpty {
                    filtered = allExercises
                } else {
                    filtered = allExercises.filter {
                        $0.name.localizedCaseInsensitiveContains(text)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - ExerciseLibraryView

struct ExerciseLibraryView: View {
    // Dependencies
    @StateObject private var viewModel: ExerciseLibraryViewModel
    // Grid layout
    @Environment(\.horizontalSizeClass) private var hSize

    init(repo: ExerciseRepository) {
        _viewModel = StateObject(wrappedValue: ExerciseLibraryViewModel(repo: repo))
    }

    private var adaptiveColumns: [GridItem] {
        // .adaptive auto-tunes cell count across iPhone/iPad sizes  [oai_citation:9‡Stack Overflow](https://stackoverflow.com/questions/78662416/how-to-create-a-dynamic-grid-that-changes-column-size-when-a-subviews-width-cha?utm_source=chatgpt.com)
        [GridItem(.adaptive(minimum: 140), spacing: 16)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                ForEach(viewModel.filtered) { exercise in
                    ExerciseCard(exercise: exercise)
                        .onDrag {
                            try? JSONEncoder().encode(exercise).asNSItemProvider()
                        }
                }
            }
            .padding(.horizontal, 16)
            .animation(.default, value: viewModel.filtered)
        }
        .navigationTitle("Exercise Library")
        .searchable(text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always))
        .task {
            await viewModel.load()
        }
    }
}

// MARK: - ExerciseCard

private struct ExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            Text(exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

// MARK: - Helpers

private extension Data {
    /// Wrap encoded bytes in an NSItemProvider for drag & drop.
    func asNSItemProvider() -> NSItemProvider {
        NSItemProvider(item: self as NSData, typeIdentifier: "public.json")
    }
}

#if DEBUG
import PreviewAssets

struct ExerciseLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ExerciseLibraryView(repo: MockExerciseRepo())
        }
    }
}
#endif
