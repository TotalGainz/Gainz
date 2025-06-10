// MARK: - LastWeightView.swift

import SwiftUI
import CoreUI               // Color & Font tokens
import FeatureSupport       // UnitConversion for unit conversions

/// A compact card showing the athlete’s last logged body weight and delta.
public struct LastWeightView: View {
    // MARK: Properties

    private let weightKg: Double
    private let deltaKg: Double?
    private let hasNoData: Bool

    // MARK: Init

    public init(weightKg: Double?, deltaKg: Double? = nil) {
        self.hasNoData = (weightKg == nil)
        self.weightKg  = weightKg ?? 0.0
        // Only use delta if weight data exists
        self.deltaKg   = weightKg == nil ? nil : deltaKg
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(NSLocalizedString("Body-Weight", comment: "Body weight label"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CoreUI.Color.secondaryText)
            if hasNoData {
                // No weight data: show placeholder
                Text("— kg")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(CoreUI.Color.primaryText)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(weightString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(CoreUI.Color.primaryText)
                    if let deltaKg = deltaKg {
                        DeltaBadge(delta: deltaKg)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CoreUI.Color.cardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    // MARK: - Computed Text

    /// Combined weight in kg and lb (e.g., "83.2 kg / 183.4 lb").
    private var weightString: String {
        let lbs = UnitConversion.kgToLb(weightKg, roundedTo: 1)
        return String(format: "%.1f kg / %.1f lb", weightKg, lbs)
    }

    /// Accessibility description for VoiceOver.
    private var accessibilityLabelText: String {
        if hasNoData {
            return NSLocalizedString("No recent body-weight log.", comment: "No weight data message")
        } else if let delta = deltaKg {
            let direction = delta > 0 ? NSLocalizedString("up", comment: "Weight increased")
                                      : NSLocalizedString("down", comment: "Weight decreased")
            return String(format: NSLocalizedString("%.1f kilograms, %@ %.1f kilograms since last log.", comment: "Weight with change since last log"),
                          weightKg, direction, abs(delta))
        } else {
            return String(format: NSLocalizedString("%.1f kilograms.", comment: "Weight with no change data"), weightKg)
        }
    }
}

// MARK: - DeltaBadge (subview for weight delta indicator)

private struct DeltaBadge: View {
    let delta: Double

    var body: some View {
        let symbol = delta > 0 ? "arrow.up" : "arrow.down"
        let color  = delta > 0 ? CoreUI.Color.positive : CoreUI.Color.negative

        return HStack(spacing: 2) {
            Image(systemName: symbol)
            Text(String(format: "%.1f kg", abs(delta)))
        }
        .font(.caption2)
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.12))
        )
    }
}
