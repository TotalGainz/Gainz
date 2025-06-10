//  StrengthScorecardView.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Shows the user's progress toward target one-rep maxes for core lifts using radial progress rings.
//  Each ring indicates current 1RM vs target 1RM for a lift (e.g., Squat, Bench Press), animating as progress fills.
//

import SwiftUI
import Domain   // LiftKind definitions for exercise types
import CoreUI   // ColorPalette, ShadowTokens for styling

// MARK: - Data Model

/// Data model representing a single lift's strength progress.
public struct StrengthLiftModel: Identifiable, Hashable {
    public let id = UUID()
    public let kind: LiftKind            // Lift type (e.g., squat, benchPress).
    public let current1RM: Double       // Current one-rep max in kg.
    public let target1RM: Double        // Target one-rep max goal in kg.

    public var progress: Double {
        min(current1RM / target1RM, 1.0)
    }
    public var liftName: String {
        kind.rawValue.uppercased()
    }
    public var iconName: String {
        // Using a generic weightlifting icon for all lifts.
        "figure.strengthtraining.traditional"
    }

    public init(kind: LiftKind, current1RM: Double, target1RM: Double) {
        self.kind = kind
        self.current1RM = current1RM
        self.target1RM = target1RM
    }
}

// MARK: - Main View

public struct StrengthScorecardView: View {
    @StateObject private var viewModel: StrengthScorecardVM

    // Two-column grid for lift tiles.
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    public init(analyticsUseCase: CalculateAnalyticsUseCase) {
        _viewModel = StateObject(wrappedValue: StrengthScorecardVM(analyticsUseCase: analyticsUseCase))
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(viewModel.lifts) { lift in
                    LiftRingTile(model: lift)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
        }
        .navigationTitle("Strength Scorecard")
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            await viewModel.refresh()
        }
    }
}

// MARK: - ViewModel

@MainActor
private final class StrengthScorecardVM: ObservableObject {
    private let analyticsUseCase: CalculateAnalyticsUseCase
    @Published var lifts: [StrengthLiftModel] = []

    init(analyticsUseCase: CalculateAnalyticsUseCase) {
        self.analyticsUseCase = analyticsUseCase
    }

    /// Fetches current vs target 1RM for core lifts.
    func refresh() async {
        lifts = await analyticsUseCase.currentLiftProgress()
    }
}

// MARK: - Subviews

/// A tile showing a lift's progress ring and details.
private struct LiftRingTile: View {
    let model: StrengthLiftModel

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background track circle.
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                // Progress ring (trimmed circle).
                Circle()
                    .trim(from: 0, to: CGFloat(model.progress))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [
                                        ColorPalette.phoenix,
                                        ColorPalette.phoenix.opacity(0.5)
                                     ]),
                                     center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: model.progress)
                // Lift icon at center.
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

// MARK: - Preview

#Preview {
    NavigationStack {
        StrengthScorecardView(analyticsUseCase: .preview)
            .preferredColorScheme(.dark)
    }
}
