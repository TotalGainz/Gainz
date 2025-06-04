//
//  MuscleHeatmapView.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Renders an interactive anterior / posterior muscle heat-map using
//  SwiftUI Canvas + brand gradient, driven by tier scores (0-5).
//
//  References:
//  • “Muscle Strength Heatmap” spec in UI/UX Roadmap IUX Roadmap.txt](file-service://file-3J5YLRXNt4e6KPXDLuth4z)
//  • Tier hue scale & tap-sheet behavior  and strength leaderboard.txt](file-service://file-NeVSoNpijvv9ywpESL2jNm)
//  • MVVM Combine pattern for SwiftUI dashboards  [oai_citation:2‡gabhisekdev.medium.com](https://gabhisekdev.medium.com/use-mvvm-and-combine-in-swiftui-ac44be0911d8?utm_source=chatgpt.com)  [oai_citation:3‡swiftwithmajid.com](https://swiftwithmajid.com/2020/02/05/building-viewmodels-with-combine-framework/?utm_source=chatgpt.com)
//  • RectangleMark & Charts heat-map inspiration  [oai_citation:4‡swiftyplace.com](https://www.swiftyplace.com/blog/swiftcharts-create-charts-and-graphs-in-swiftui?utm_source=chatgpt.com)  [oai_citation:5‡developer.apple.com](https://developer.apple.com/documentation/charts/rectanglemark?utm_source=chatgpt.com)
//  • Canvas overlays & gradients in SwiftUI  [oai_citation:6‡swiftbysundell.com](https://www.swiftbysundell.com/articles/backgrounds-and-overlays-in-swiftui?utm_source=chatgpt.com)  [oai_citation:7‡stackoverflow.com](https://stackoverflow.com/questions/56488577/how-to-fill-shape-with-gradient-in-swiftui?utm_source=chatgpt.com)
//  • Tree-map / heat-map case study  [oai_citation:8‡medium.com](https://medium.com/%40jaredcassoutt/creating-a-treemap-heatmap-for-stocks-in-swiftui-fb7db054e4ab?utm_source=chatgpt.com)
//  • ObservableObject update mechanics  [oai_citation:9‡stackoverflow.com](https://stackoverflow.com/questions/74171322/how-to-trigger-automatic-swiftui-updates-with-observedobject-using-mvvm?utm_source=chatgpt.com)
//  • Domain repo structure for AnalyticsUseCase l v8 repo copy.txt](file-service://file-QqfK4uFYABMBwPJgHouZYx)
//  • Accessibility alt-text guidance for heat-map IUX Roadmap.txt](file-service://file-3J5YLRXNt4e6KPXDLuth4z)
//
//  NOTE: HRV & bar-velocity tracking explicitly excluded per product brief.
//

import SwiftUI
import Charts
import Domain
import CoreUI

// MARK: – View

public struct MuscleHeatmapView: View {

    @StateObject private var viewModel: MuscleHeatmapVM

    /// Flip between front / back mannequin.
    @State private var showingFront = true
    /// Selected muscle for sheet.
    @State private var selected: MuscleGroup?

    // MARK: Init
    public init(analyticsUseCase: CalculateAnalyticsUseCase) {
        _viewModel = StateObject(wrappedValue: .init(analyticsUseCase: analyticsUseCase))
    }

    // MARK: Body
    public var body: some View {
        ZStack {
            Canvas { ctx, size in
                let mannequin = showingFront
                    ? MuscleMask.front
                    : MuscleMask.back

                for muscle in mannequin {
                    let tier = viewModel.tier(for: muscle.group)
                    ctx.fill(
                        muscle.path(in: size),
                        with: .color(ColorPalette.tierHue(tier))
                    )
                }
            }
            .aspectRatio(0.5, contentMode: .fit)
            .accessibilityLabel(heatmapAltText)
            .onTapGesture { location in
                guard let tapped = viewModel.hitTest(location,
                                                     in: showingFront ? .front : .back)
                else { return }
                selected = tapped
            }

            // Front/Back toggle control
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
            MuscleDetailSheet(muscle: muscle,
                              analyticsUseCase: viewModel.analyticsUseCase)
                .presentationDetents([.medium, .large])
        }
        .brandCardShadow() // CoreUI ViewModifier
        .padding()
        .task { await viewModel.refresh() }
    }

    private var heatmapAltText: String {
        viewModel.altDescription(showingFront: showingFront)
    }
}

// MARK: – ViewModel

@MainActor
final class MuscleHeatmapVM: ObservableObject {

    // Dependencies
    let analyticsUseCase: CalculateAnalyticsUseCase

    // Cache of muscle→tier
    @Published private(set) var tiers: [MuscleGroup: Int] = [:]

    init(analyticsUseCase: CalculateAnalyticsUseCase) {
        self.analyticsUseCase = analyticsUseCase
    }

    func refresh() async {
        tiers = await analyticsUseCase.currentMuscleTiers()
    }

    func tier(for muscle: MuscleGroup) -> Int {
        tiers[muscle, default: 0]
    }

    /// Hit-test location into mannequin to find selected muscle.
    func hitTest(_ location: CGPoint, in side: MannequinSide) -> MuscleGroup? {
        let masks = side == .front ? MuscleMask.front : MuscleMask.back
        return masks.first(where: { $0.pathContains(location) })?.group
    }

    func altDescription(showingFront: Bool) -> String {
        let strongest = tiers.max { $0.value < $1.value }?.key.displayName ?? "none"
        let weakest  = tiers.min { $0.value < $1.value }?.key.displayName ?? "none"
        return "Heatmap view, \(showingFront ? "front" : "back"). Strongest: \(strongest). Weakest: \(weakest)."
    }
}

// MARK: – Supporting Types

/// Enum matches Domain’s `MuscleGroup` but with body-side metadata.
private struct MuscleMask: Identifiable {
    let id = UUID()
    let group: MuscleGroup
    let bezier: Path

    static let front: [MuscleMask] = Self.loadSVG(named: "front_mannequin")
    static let back:  [MuscleMask] = Self.loadSVG(named: "back_mannequin")

    func path(in size: CGSize) -> Path {
        var scaled = bezier
        let scale = min(size.width, size.height)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        scaled = scaled.applying(transform)
        return scaled
    }

    func pathContains(_ point: CGPoint) -> Bool {
        bezier.contains(point)
    }

    private static func loadSVG(named asset: String) -> [Self] {
        // Placeholder: real implementation parses SVG & associates ids → MuscleGroup.
        []
    }
}

private enum MannequinSide { case front, back }

// MARK: – Color Mapping

extension ColorPalette {
    /// Returns brand hue for tier 0…5 (gray→purple).
    static func tierHue(_ tier: Int) -> Color {
        switch tier {
        case 0: return Color(.systemGray5)
        case 1: return Color("TierBlue")     // Assets.xcassets
        case 2: return Color("TierGreen")
        case 3: return Color("TierYellow")
        case 4: return Color("TierOrange")
        default: return Color("TierPurple")
        }
    }
}

// MARK: – Previews

#if DEBUG
struct MuscleHeatmapView_Previews: PreviewProvider {
    static var previews: some View {
        MuscleHeatmapView(analyticsUseCase: .preview)
            .preferredColorScheme(.dark)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
