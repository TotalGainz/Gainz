//
//  LastWeightView.swift
//  HomeFeature → Widgets
//
//  Compact card that shows the athlete’s last logged body-weight.
//  Designed for reuse in Home tab & small WidgetKit timeline entries.
//
//  • Typography & colors come from CoreUI tokens.
//  • No HRV, recovery, or velocity data—just weight & delta.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import CoreUI               // Color tokens, Font tokens
import FeatureSupport       // UnitConversion

// MARK: - LastWeightView

public struct LastWeightView: View {

    // MARK: Dependencies

    private let weightKg: Double        // last log in kilograms
    private let deltaKg: Double?        // change vs previous log

    // MARK: Init

    public init(weightKg: Double, deltaKg: Double? = nil) {
        self.weightKg = weightKg
        self.deltaKg  = deltaKg
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Body-Weight")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CoreUI.Color.secondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(weightString)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(CoreUI.Color.primaryText)

                if let deltaKg {
                    DeltaBadge(delta: deltaKg)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CoreUI.Color.cardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityString)
    }

    // MARK: Computed

    private var weightString: String {
        let lbs = UnitConversion.kgToLb(weightKg, roundedTo: 1)
        return String(format: "%.1f kg / %.1f lb", weightKg, lbs)
    }

    private var accessibilityString: String {
        if let deltaKg {
            let sign = deltaKg > 0 ? "up" : "down"
            return "\(weightKg) kilograms, \(sign) \(abs(deltaKg)) kilograms since last log."
        } else {
            return "\(weightKg) kilograms."
        }
    }
}

// MARK: - DeltaBadge

private struct DeltaBadge: View {
    let delta: Double

    var body: some View {
        let symbol = delta > 0 ? "arrow.up" : "arrow.down"
        let color  = delta > 0 ? CoreUI.Color.positive : CoreUI.Color.negative

        return HStack(spacing: 2) {
            Image(systemName: symbol)
            Text(deltaText)
        }
        .font(.caption2)
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }

    private var deltaText: String {
        String(format: "%.1f kg", abs(delta))
    }
}

// MARK: - Preview

#if DEBUG
struct LastWeightView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LastWeightView(weightKg: 83.2, deltaKg: 0.4)
                .previewLayout(.sizeThatFits)
                .padding()
            LastWeightView(weightKg: 83.2, deltaKg: -0.5)
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
#endif
