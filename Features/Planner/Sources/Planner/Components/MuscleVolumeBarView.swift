//
//  MuscleVolumeBarView.swift
//  Features – Planner
//
//  Horizontal stacked-bar visualising relative set volume per muscle
//  for the current mesocycle week. Colours match the Gainz gradient;
//  layout is Dynamic-Type friendly and VoiceOver describable.
//
//  ⟡  No HRV, recovery, or velocity data – hypertrophy only.
//  ⟡  Uses CoreUI tokens (`Color.primaryBlack`, `Gradient.purplePhoenix`).
//  ⟡  Zero UIKit; pure SwiftUI so it compiles on watchOS / visionOS.
//
//  Created by Gainz UI Team on 27 May 2025.
//

import SwiftUI
import Domain   // MuscleGroup enum; Mesocycle analytics

// MARK: - Data Model ----------------------------------------------------------

public struct MuscleVolumeDatum: Identifiable, Hashable {
    public let id: MuscleGroup
    public let plannedSets: Int           // Weekly planned sets
    public let completedSets: Int         // Logged sets so far

    // Convenience
    public var completionRatio: Double {
        guard plannedSets > 0 else { return 0 }
        return Double(completedSets) / Double(plannedSets)
    }

    public init(id: MuscleGroup,
                plannedSets: Int,
                completedSets: Int) {
        self.id = id
        self.plannedSets = plannedSets
        self.completedSets = completedSets
    }
}

// MARK: - View ----------------------------------------------------------------

public struct MuscleVolumeBarView: View {

    // Injected data (sorted highest→lowest planned sets for readability)
    public let data: [MuscleVolumeDatum]

    // Design constants
    private struct Const {
        static let barHeight: CGFloat = 12
        static let cornerRadius: CGFloat = 6
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(data) { datum in
                HStack {
                    // LABEL
                    Text(datum.id.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)

                    // BAR
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Planned volume background
                            Capsule()
                                .fill(Color.primaryBlack.opacity(0.18))

                            // Completed volume overlay – animates width
                            Capsule()
                                .fill(Gradient.purplePhoenix)
                                .frame(
                                    width: geo.size.width
                                        * datum.completionRatio
                                )
                                .animation(.easeInOut(duration: 0.35),
                                           value: datum.completedSets)
                        }
                    }
                    .frame(height: Const.barHeight)

                    // NUMBERS
                    Text("\(datum.completedSets)/\(datum.plannedSets)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore) // Custom AX
                .accessibilityLabel("\(datum.id.displayName) volume")
                .accessibilityValue(
                    "\(datum.completedSets) of \(datum.plannedSets) sets"
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview -------------------------------------------------------------

#if DEBUG
struct MuscleVolumeBarView_Previews: PreviewProvider {

    static let sample: [MuscleVolumeDatum] = [
        .init(id: .chest,          plannedSets: 20, completedSets: 12),
        .init(id: .quads,          plannedSets: 18, completedSets: 18),
        .init(id: .lats,           plannedSets: 15, completedSets:  9),
        .init(id: .biceps,         plannedSets:  9, completedSets:  3),
        .init(id: .posteriorChain, plannedSets: 12, completedSets: 12)
    ]

    static var previews: some View {
        Group {
            MuscleVolumeBarView(data: sample)
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
            MuscleVolumeBarView(data: sample)
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.light)
        }
    }
}
#endif
