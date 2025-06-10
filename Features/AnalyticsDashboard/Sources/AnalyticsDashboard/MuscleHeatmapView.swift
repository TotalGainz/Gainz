//  MuscleHeatmapView.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Displays a front/back muscle heatmap indicating strength tiers for each muscle group.
//  Uses SwiftUI Canvas to draw an SVG-based human silhouette, colored by tier (0 = gray, 5 = purple).
//  Tapping a muscle opens a detail sheet with more info via a dedicated view.
//
//  Note: HRV & barbell velocity metrics are intentionally excluded per spec.
//

import SwiftUI
import Charts
import Domain
import CoreUI

// MARK: - Main View

public struct MuscleHeatmapView: View {
    @StateObject private var viewModel: MuscleHeatmapVM
    @State private var showingFront = true           // Controls front/back toggle.
    @State private var selected: MuscleGroup?        // Selected muscle (for detail sheet).

    public init(analyticsUseCase: CalculateAnalyticsUseCase) {
        _viewModel = StateObject(wrappedValue: MuscleHeatmapVM(analyticsUseCase: analyticsUseCase))
    }

    public var body: some View {
        ZStack {
            Canvas { context, size in
                let mannequin = showingFront ? MuscleMask.front : MuscleMask.back
                for muscle in mannequin {
                    let tier = viewModel.tier(for: muscle.group)
                    context.fill(muscle.path(in: size), with: .color(ColorPalette.tierHue(tier)))
                }
            }
            .aspectRatio(0.5, contentMode: .fit)
            .accessibilityLabel(heatmapAltText)
            .onTapGesture { location in
                if let tappedGroup = viewModel.hitTest(location, in: showingFront ? .front : .back) {
                    selected = tappedGroup
                }
            }

            // Front/Back view toggle control at bottom.
            VStack {
                Spacer()
                Toggle(isOn: $showingFront.animation(.easeInOut)) {
                    Text(showingFront ? "Front" : "Back")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.button)
                .padding(.bottom, 8)
            }
        }
        .sheet(item: $selected) { muscle in
            // Present detail sheet for the selected muscle group.
            MuscleDetailSheet(muscle: muscle, analyticsUseCase: viewModel.analyticsUseCase)
                .presentationDetents([.medium, .large])
        }
        .brandCardShadow()  // Apply consistent card shadow from CoreUI.
        .padding()
        .task {
            // Load muscle tiers when the view appears.
            await viewModel.refresh()
        }
    }

    /// Accessibility label summarizing the heatmap content.
    private var heatmapAltText: String {
        viewModel.altDescription(showingFront: showingFront)
    }
}

// MARK: - ViewModel

@MainActor
private final class MuscleHeatmapVM: ObservableObject {
    let analyticsUseCase: CalculateAnalyticsUseCase

    @Published private(set) var tiers: [MuscleGroup: Int] = [:]

    init(analyticsUseCase: CalculateAnalyticsUseCase) {
        self.analyticsUseCase = analyticsUseCase
    }

    /// Fetches current muscle strength tiers (e.g., from analysis of personal bests).
    func refresh() async {
        tiers = await analyticsUseCase.currentMuscleTiers()
    }

    /// Returns the strength tier for a given muscle group (0 if none).
    func tier(for muscle: MuscleGroup) -> Int {
        tiers[muscle] ?? 0
    }

    /// Hit-tests a tap location on the canvas, returning the MuscleGroup if one was hit.
    func hitTest(_ location: CGPoint, in side: MannequinSide) -> MuscleGroup? {
        let masks = side == .front ? MuscleMask.front : MuscleMask.back
        return masks.first(where: { $0.pathContains(location) })?.group
    }

    /// Accessibility description providing strongest and weakest muscle groups.
    func altDescription(showingFront: Bool) -> String {
        let strongest = tiers.max(by: { $0.value < $1.value })?.key.displayName ?? "none"
        let weakest = tiers.min(by: { $0.value < $1.value })?.key.displayName ?? "none"
        return "Muscle heatmap \(showingFront ? "front" : "back") view. Strongest muscle: \(strongest). Weakest: \(weakest)."
    }
}

// MARK: - Supporting Types

/// Represents a muscle shape (path) for the front or back silhouette.
private struct MuscleMask: Identifiable {
    let id = UUID()
    let group: MuscleGroup
    let bezier: Path

    static let front: [MuscleMask] = Self.loadSVG(named: "front_mannequin")
    static let back:  [MuscleMask] = Self.loadSVG(named: "back_mannequin")

    func path(in size: CGSize) -> Path {
        var scaled = bezier
        let scale = min(size.width, size.height)
        scaled = scaled.applying(CGAffineTransform(scaleX: scale, y: scale))
        return scaled
    }

    func pathContains(_ point: CGPoint) -> Bool {
        bezier.contains(point)
    }

    private static func loadSVG(named assetName: String) -> [MuscleMask] {
        // TODO: Implement SVG parsing and mapping to MuscleGroup.
        return []
    }
}

private enum MannequinSide { case front, back }

extension ColorPalette {
    /// Returns a consistent color for a given strength tier (0…5).
    static func tierHue(_ tier: Int) -> Color {
        switch tier {
        case 0: return Color(.systemGray5)
        case 1: return Color("TierBlue")
        case 2: return Color("TierGreen")
        case 3: return Color("TierYellow")
        case 4: return Color("TierOrange")
        default: return Color("TierPurple")
        }
    }
}

// MARK: - Preview

#Preview {
    MuscleHeatmapView(analyticsUseCase: .preview)
        .preferredColorScheme(.dark)
        .padding()
        .previewLayout(.sizeThatFits)
}
