//
//  StrengthScorecardView.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Displays current 1-RM progress for the five core lifts using
//  minimalist radial progress rings inspired by Swift Charts’ new
//  `SectorMark` and custom `Circle` overlays [oai_citation:0‡swiftwithmajid.com](https://swiftwithmajid.com/2023/09/26/mastering-charts-in-swiftui-pie-and-donut-charts/?utm_source=chatgpt.com) [oai_citation:1‡sarunw.com](https://sarunw.com/posts/swiftui-circular-progress-bar/?utm_source=chatgpt.com) [oai_citation:2‡swiftwithmajid.com](https://swiftwithmajid.com/2023/01/26/mastering-charts-in-swiftui-custom-marks/?utm_source=chatgpt.com) [oai_citation:3‡appcoda.com](https://www.appcoda.com/swiftui-chart-ios17/?utm_source=chatgpt.com) [oai_citation:4‡medium.com](https://medium.com/devtechie/donut-chart-in-swiftui-6adbca7b964f?utm_source=chatgpt.com).
//  Layout principles borrow from modern weight-lifting dashboards
//  to maintain rapid at-a-glance clarity for strength athletes [oai_citation:5‡patrickspafford.com](https://patrickspafford.com/blog/building-a-weightlifting-app-with-swiftui/?utm_source=chatgpt.com).
//
//  Created by AI-Assistant on 2025-06-03.
//  Licensed to Echelon Commerce LLC.
//

import SwiftUI
import Domain   // LiftKind (squat, bench, deadlift, ohp, row)
import CoreUI   // ColorPalette, ShadowTokens

// MARK: - ViewModel

/// Lightweight binding so the view remains preview-friendly & testable.
public struct StrengthLiftModel: Identifiable, Hashable {
    public let id = UUID()
    public let kind: LiftKind
    public let current1RM: Double    // kg
    public let target1RM: Double     // kg
    
    public var progress: Double { min(current1RM / target1RM, 1.0) }
    public var liftName: String { kind.rawValue.uppercased() }
    public var iconName: String {
        switch kind {
        case .squat:       "figure.strengthtraining.traditional"
        case .benchPress:  "figure.strengthtraining.traditional"
        case .deadlift:    "figure.strengthtraining.traditional"
        case .overheadPress: "figure.strengthtraining.traditional"
        case .barbellRow:  "figure.strengthtraining.traditional"
        }
    }
    
    public init(kind: LiftKind, current1RM: Double, target1RM: Double) {
        self.kind = kind
        self.current1RM = current1RM
        self.target1RM = target1RM
    }
}

// MARK: - Main View

public struct StrengthScorecardView: View {
    
    // MARK: Injection
    @State public var lifts: [StrengthLiftModel]
    
    // MARK: Grid config
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(lifts) { lift in
                    LiftRingTile(model: lift)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
        }
        .navigationTitle("Strength Scorecard")
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Sub-Component

private struct LiftRingTile: View {
    
    let model: StrengthLiftModel
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                // Progress ring (animated)
                Circle()
                    .trim(from: 0, to: CGFloat(model.progress))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [ColorPalette.phoenix, ColorPalette.phoenix.opacity(0.5)]),
                            center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: model.progress)
                // Icon
                Image(systemName: model.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(ColorPalette.phoenix)
            }
            .frame(width: 100, height: 100)
            .shadow(color: ShadowTokens.tile, radius: 6, x: 0, y: 4)
            
            VStack(spacing: 2) {
                Text(model.liftName)
                    .font(.headline)
                Text("\(Int(model.current1RM)) / \(Int(model.target1RM)) kg")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: ShadowTokens.tile, radius: 7, x: 0, y: 5)
        )
    }
}

// MARK: - Domain Stub (until integrated with real models)

/// Strength lifts relevant for scorecard.  Kept internal to file for now.
/// Replace with shared `Domain/LiftKind.swift` when available.
enum LiftKind: String, CaseIterable {
    case squat = "Squat"
    case benchPress = "Bench"
    case deadlift = "Deadlift"
    case overheadPress = "OHP"
    case barbellRow = "Row"
}

// MARK: - Preview

#if DEBUG
struct StrengthScorecardView_Previews: PreviewProvider {
    static var previews: some View {
        StrengthScorecardView(
            lifts: [
                .init(kind: .squat, current1RM: 170, target1RM: 180),
                .init(kind: .benchPress, current1RM: 125, target1RM: 140),
                .init(kind: .deadlift, current1RM: 200, target1RM: 220),
                .init(kind: .overheadPress, current1RM: 80, target1RM: 90),
                .init(kind: .barbellRow, current1RM: 110, target1RM: 120)
            ]
        )
        .preferredColorScheme(.dark)
    }
}
#endif
