//  VitalStatTileView.swift
//  Gainz – AnalyticsDashboard Feature
//
//  A SwiftUI view for displaying a key health metric (e.g., heart rate, sleep, weight trend) with an optional delta indicator.
//
//  References:
//  - Apple HIG: data visualization for health metrics.
//  - SwiftUI layout: uses dynamic font scaling and accessible colors for clarity.
//

import SwiftUI
import Domain   // VitalStatKind definitions (for core health metrics)
import CoreUI   // ColorPalette, ShadowTokens for styling

// MARK: - Presentation Model

/// Model for a single vital stat tile, including formatted value and delta.
public struct VitalStatTileModel: Identifiable, Hashable {
    public let id = UUID()
    public let kind: VitalStatKind            // The metric type (e.g., restingHeartRate, sleepDuration, weightTrend).
    public let valueText: String             // Formatted value (e.g., "52 bpm", "7h 13m").
    public let deltaText: String?            // Change text (e.g., "▲ 2%", "▼ 0.4 kg"), nil if no change.
    public let isPositiveDelta: Bool?        // True if delta is positive, false if negative, nil if no delta.
    public let accent: Color                 // Accent color for the tile (e.g., icon color).
    public let systemImageName: String?      // Optional SF Symbol name to override default icon for this stat.

    public init(kind: VitalStatKind,
                valueText: String,
                deltaText: String? = nil,
                isPositiveDelta: Bool? = nil,
                accent: Color = ColorPalette.phoenix,
                systemImageName: String? = nil) {
        self.kind = kind
        self.valueText = valueText
        self.deltaText = deltaText
        self.isPositiveDelta = isPositiveDelta
        self.accent = accent
        self.systemImageName = systemImageName
    }
}

// MARK: - Vital Stat Tile View

/// A tappable tile view showing a vital stat value and its recent change.
public struct VitalStatTileView: View {
    public let model: VitalStatTileModel
    public var tapAction: (() -> Void)?   // Optional action when tile is tapped (e.g., navigate to detail).

    public var body: some View {
        Button(action: { tapAction?() }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    icon
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(model.accent)
                    Spacer(minLength: 0)
                    if let delta = model.deltaText, let positive = model.isPositiveDelta {
                        deltaLabel(delta, positive: positive)
                    }
                }
                Text(model.valueText)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: ShadowTokens.tile, radius: 7, x: 0, y: 4)
            )
            .contentShape(Rectangle())  // Make entire tile tappable.
        }
        .buttonStyle(.plain)
    }

    // MARK: - Components

    private var icon: some View {
        // Use custom icon if provided; otherwise derive from the metric kind.
        Image(systemName: model.systemImageName ?? iconName(for: model.kind))
    }

    private func deltaLabel(_ text: String, positive: Bool) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(positive ? .green : .red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill((positive ? .green : .red).opacity(0.15)))
    }

    private func iconName(for kind: VitalStatKind) -> String {
        switch kind {
        case .restingHeartRate: return "heart.fill"
        case .sleepDuration:    return "bed.double.fill"
        case .weightTrend:      return "scalemass.fill"
        @unknown default:       return "questionmark.circle"
        }
    }
}

// MARK: - Preview

#Preview {
    Group {
        VitalStatTileView(
            model: .init(kind: .restingHeartRate,
                         valueText: "52 bpm",
                         deltaText: "▲ 2%",
                         isPositiveDelta: true)
        )
        VitalStatTileView(
            model: .init(kind: .sleepDuration,
                         valueText: "7h 13m",
                         deltaText: "▼ 5%",
                         isPositiveDelta: false)
        )
        .preferredColorScheme(.dark)
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
