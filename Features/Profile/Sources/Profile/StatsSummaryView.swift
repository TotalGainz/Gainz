//  StatsSummaryView.swift
//  Gainz – Profile Feature
//
//  Created by AI-Assistant on 2025-06-03.
//
//  This view renders a concise résumé of lifetime workout stats
//  (sessions, sets, reps, tonnage, PRs, active days) using a
//  responsive LazyVGrid.  Design references:
//  – Grid vs. LazyVGrid best-practices
//    [oai_citation:0‡avanderlee.com](https://www.avanderlee.com/swiftui/grid-lazyvgrid-lazyhgrid-gridviews/?utm_source=chatgpt.com)
//  – Flexible column sizing in LazyVGrid  [oai_citation:1‡swiftuifieldguide.com](https://www.swiftuifieldguide.com/layout/lazyvgrid/?utm_source=chatgpt.com)
//  – RoundedRectangle + background material  [oai_citation:2‡stackoverflow.com](https://stackoverflow.com/questions/65202061/swiftui-apply-background-color-to-rounded-rectangle?utm_source=chatgpt.com) [oai_citation:3‡developer.apple.com](https://developer.apple.com/documentation/swiftui/material?utm_source=chatgpt.com)
//  – Number formatting with fractionLength(_: )
//    [oai_citation:4‡medium.com](https://medium.com/%40jpmtech/formatting-numbers-in-swiftui-fc5ee2920a59?utm_source=chatgpt.com) [oai_citation:5‡developer.apple.com](https://developer.apple.com/documentation/foundation/numberformatstyleconfiguration/precision/fractionlength%28_%3A%29-w6fk?utm_source=chatgpt.com)
//  – Custom accessibility for composite views
//    [oai_citation:6‡kodeco.com](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/5-add-custom-accessibility-content-in-swiftui-views?utm_source=chatgpt.com)
//  – Label pattern in custom components
//    [oai_citation:7‡sarunw.com](https://sarunw.com/posts/how-to-use-label-in-swiftui-custom-view/?utm_source=chatgpt.com)
//  – Dual-scheme previews (light/dark)  [oai_citation:8‡reddit.com](https://www.reddit.com/r/Xcode/comments/z3hjae/how_do_i_force_the_swiftui_preview_to_show_both/?utm_source=chatgpt.com) [oai_citation:9‡stackoverflow.com](https://stackoverflow.com/questions/56488228/xcode-11-swiftui-preview-dark-mode?utm_source=chatgpt.com)
//

import SwiftUI
import Domain   // StatsSummary model

// MARK: – View

public struct StatsSummaryView: View {

    public let summary: StatsSummary

    // Two flexible columns to adapt across size classes.
    private let columns: [GridItem] = [
        .init(.flexible(minimum: 100, maximum: 200)),
        .init(.flexible(minimum: 100, maximum: 200))
    ]

    public init(summary: StatsSummary) {
        self.summary = summary
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            statTile(title: "Workouts", value: summary.sessionCount)
            statTile(title: "Sets",      value: summary.setCount)
            statTile(title: "Reps",      value: summary.repCount)
            statTile(title: "Volume",    value: summary.tonnage, unit: "kg")
            statTile(title: "PRs",       value: summary.prCount)
            statTile(title: "Days",      value: summary.trainingDays)
        }
        .padding(20)
        .background(.thinMaterial) // glass-morph surface [oai_citation:10‡developer.apple.com](https://developer.apple.com/documentation/swiftui/material?utm_source=chatgpt.com)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    // MARK: Tile Factory

    @ViewBuilder
    private func statTile<T: CVarArg>(title: String,
                                      value: T,
                                      unit: String? = nil) -> some View {

        let valueString: String = {
            if let dbl = value as? Double {
                // retain one fractional digit for tonnage etc.
                return dbl.formatted(.number.precision(.fractionLength(1))) // [oai_citation:11‡developer.apple.com](https://developer.apple.com/documentation/foundation/numberformatstyleconfiguration/precision/fractionlength%28_%3A%29-w6fk?utm_source=chatgpt.com)
            } else {
                return String(describing: value)
            }
        }()

        VStack(spacing: 4) {
            Text(valueString)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            if let unit {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.05))        // subtle tint [oai_citation:12‡stackoverflow.com](https://stackoverflow.com/questions/65202061/swiftui-apply-background-color-to-rounded-rectangle?utm_source=chatgpt.com)
        )
        .accessibilityLabel("\(title) \(valueString) \(unit ?? "")")
    }
}

// MARK: – Preview

#if DEBUG
struct StatsSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StatsSummaryView(summary: .preview)
                .previewDisplayName("Light")

            StatsSummaryView(summary: .preview)
                .preferredColorScheme(.dark) // dual-scheme test [oai_citation:13‡stackoverflow.com](https://stackoverflow.com/questions/56488228/xcode-11-swiftui-preview-dark-mode?utm_source=chatgpt.com)
                .previewDisplayName("Dark")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
