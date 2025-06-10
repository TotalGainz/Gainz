//
//  MuscleVolumeBarView.swift
//  Features – Planner
//
//  Horizontal stacked-bar visualising relative set volume per muscle group.
//  Shows planned vs completed sets with an animated overlay to indicate progress.
//  Useful for quick feedback on training volume distribution.
//
import SwiftUI
import CoreUI   // Design tokens for colors/gradients

public struct MuscleVolumeBarView: View {
    // Injected data (assumed sorted highest→lowest planned sets for readability).
    public let data: [MuscleVolumeDatum]

    // Design constants for bar appearance.
    private struct Const {
        static let barHeight: CGFloat = 12
        static let cornerRadius: CGFloat = 6
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(data) { datum in
                HStack {
                    // LABEL: muscle group name
                    Text(datum.id.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .leading)
                    // BAR: background and overlay indicating completed portion
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Planned volume background bar (gray base)
                            Capsule()
                                .fill(Color.primaryBlack.opacity(0.18))
                            // Completed volume overlay – width animated as completedSets changes.
                            Capsule()
                                .fill(Gradient.purplePhoenix)
                                .frame(width: geo.size.width * datum.completionRatio)
                                .animation(.easeInOut(duration: 0.35), value: datum.completedSets)
                        }
                    }
                    .frame(height: Const.barHeight)
                    // NUMBERS: completed vs planned sets in monospaced for alignment
                    Text("\(datum.completedSets)/\(datum.plannedSets)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)  // combine custom label/value for accessibility
                .accessibilityLabel("\(datum.id.displayName) volume")
                .accessibilityValue("\(datum.completedSets) of \(datum.plannedSets) sets")
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

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
