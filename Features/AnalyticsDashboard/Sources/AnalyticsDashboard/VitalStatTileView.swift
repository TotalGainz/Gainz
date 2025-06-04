//
//  VitalStatTileView.swift
//  Gainz – AnalyticsDashboard Feature
//
//  Created by AI-Assistant on 2025-06-03.
//  Licensed to Echelon Commerce LLC.
//

import SwiftUI
import Domain   // VitalStatKind
import CoreUI   // ColorPalette, ShadowTokens

// MARK: - Display Model

/// Descriptor injected by ViewModel → View for concise, testable UI glue.
public struct VitalStatTileModel: Identifiable, Hashable {
    public let id = UUID()
    public let kind: VitalStatKind
    public let valueText: String        // e.g. “52 bpm”, “7 h 13 m”
    public let deltaText: String?       // e.g. “▲ 2 %”, “▼ 0.4 kg”
    public let isPositiveDelta: Bool?   // nil = no delta
    public let accent: Color
    
    public init(kind: VitalStatKind,
                valueText: String,
                deltaText: String? = nil,
                isPositiveDelta: Bool? = nil,
                accent: Color = ColorPalette.phoenix) {
        self.kind = kind
        self.valueText = valueText
        self.deltaText = deltaText
        self.isPositiveDelta = isPositiveDelta
        self.accent = accent
    }
}

// MARK: - View

public struct VitalStatTileView: View {
    
    // MARK: Injection
    public let model: VitalStatTileModel
    public var tapAction: (() -> Void)?
    
    // MARK: Body
    public var body: some View {
        Button {
            tapAction?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    icon
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(model.accent)
                    Spacer(minLength: 0)
                    if let delta = model.deltaText,
                       let positive = model.isPositiveDelta {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Private Helpers

private extension VitalStatTileView {
    
    var icon: some View {
        Image(systemName: iconName(for: model.kind))
    }
    
    func deltaLabel(_ text: String, positive: Bool) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(positive ? .green : .red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill((positive ? .green : .red).opacity(0.15))
            )
    }
    
    func iconName(for kind: VitalStatKind) -> String {
        switch kind {
        case .restingHeartRate: return "heart.fill"
        case .sleepDuration:    return "bed.double.fill"
        case .weightTrend:      return "scalemass.fill"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct VitalStatTileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VitalStatTileView(
                model: .init(kind: .restingHeartRate,
                             valueText: "52 bpm",
                             deltaText: "▲ 2 %",
                             isPositiveDelta: true)
            )
            VitalStatTileView(
                model: .init(kind: .sleepDuration,
                             valueText: "7 h 13 m",
                             deltaText: "▼ 5 %",
                             isPositiveDelta: false)
            )
            .preferredColorScheme(.dark)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
