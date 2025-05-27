//  GainzPreviews.playground
//  A one‑stop Swift Playgrounds hub that wires up live previews for
//  the flagship Gainz UI components. Import the feature packages,
//  place this playground next to your Xcode project, and hit ▶️.
//
//  Mission: accelerate design QA — see every screen, dark/light, dynamic
//  type, and layout variants in one scrollable grid without spinning up
//  a simulator.

import SwiftUI
import PlaygroundSupport

// MARK: ‑ Feature imports (SPM targets)
@testable import HomeFeature
@testable import PlannerFeature
@testable import WorkoutLoggerFeature
@testable import AnalyticsDashboardFeature
@testable import CoreUI

//──────────────────────────────────────────────────────────────────────────────
// MARK: ‑ Preview Grid Helper
//──────────────────────────────────────────────────────────────────────────────

/// Responsive grid that lays out child previews with adaptive columns.
private struct PreviewGrid<Content: View>: View {
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 170, maximum: 240), spacing: 32)
    ]

    let content: () -> Content

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 32) {
                content()
            }
            .padding(32)
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
// MARK: ‑ Root Preview
//──────────────────────────────────────────────────────────────────────────────

struct GainzPreviewRoot: View {
    var body: some View {
        PreviewGrid {
            // Each feature exposes its own `XView_Previews` conformance.
            HomeView_Previews.preferredLayout()
            PlannerView_Previews.preferredLayout()
            WorkoutLoggerView_Previews.preferredLayout()
            AnalyticsDashboardView_Previews.preferredLayout()
        }
        .environment(\.colorScheme, .dark)
        .environment(\.sizeCategory, .large)
    }
}

//──────────────────────────────────────────────────────────────────────────────
// MARK: ‑ PreviewProvider Convenience
//──────────────────────────────────────────────────────────────────────────────

extension PreviewProvider {
    /// Helper that pins all previews to the same device + display name.
    static func preferredLayout() -> some View {
        Group {
            Self.previews
                .previewDevice("iPhone 15 Pro")
                .previewDisplayName(String(describing: Self.self))
        }
    }
}

//──────────────────────────────────────────────────────────────────────────────
// MARK: ‑ Live View
//──────────────────────────────────────────────────────────────────────────────

PlaygroundPage.current.setLiveView(GainzPreviewRoot())
