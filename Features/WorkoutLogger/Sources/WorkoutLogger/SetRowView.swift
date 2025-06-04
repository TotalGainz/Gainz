//
//  SetRowView.swift
//  Planner – Components
//
//  A compact, swipe-ready row that displays an editable “planned set”
//  inside the Planner’s ExercisePlan editor.
//
//  ────────────────────────────────────────────────────────────
//  • SwiftUI-only, no UIKit.
//  • Uses DesignSystem tokens via CoreUI.
//  • No HRV, recovery, or velocity badges.
//  • Accessibility: Dynamic Type, VoiceOver labels, high-contrast.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Domain
import CoreUI   // Color tokens, typography helpers

// MARK: - View Model

/// Light view-model for two-way binding with the planner editor.
public struct SetDraft: Identifiable, Hashable {
    public let id = UUID()
    public var reps: Int
    public var weight: Double   // kg or lb (respect user settings)
    public var rpe: RPE?
}

// MARK: - SetRowView

public struct SetRowView: View {

    // MARK: State

    @Binding public var draft: SetDraft
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepFocused: Bool

    // MARK: Body

    public var body: some View {
        HStack(spacing: 12) {

            // Index badge
            Text("#\(indexDescription)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.6))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                )
                .accessibilityHidden(true)

            // Weight TextField
            HStack(spacing: 2) {
                TextField("0", value: $draft.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($isWeightFocused)
                    .frame(minWidth: 44)
                    .accessibilityLabel("Weight")

                Text(unitSymbol)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }

            Divider()
                .frame(maxHeight: 18)

            // Reps TextField
            TextField("0", value: $draft.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($isRepFocused)
                .frame(minWidth: 36)
                .accessibilityLabel("Repetitions")

            // Optional RPE picker
            if let rpe = draft.rpe {
                Text(rpe.description)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.indigo)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.indigo.opacity(0.15))
                    )
                    .accessibilityLabel("R P E \(rpe.rawValue)")
            }

            Spacer(minLength: 0)

            // Swipe-to-delete handled by parent List
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle()) // increases tap target
        .onTapGesture {
            // Focus first empty field or weight by default
            if draft.weight == 0 {
                isWeightFocused = true
            } else {
                isRepFocused = true
            }
        }
    }

    // MARK: Helpers

    private var indexDescription: String {
        // Provided by parent List row index via environment or default to “?”
        (Environment(\.rowIndex).wrappedValue ?? 0) + 1
    }

    private var unitSymbol: String {
        // Respect global settings (metric / imperial)
        UserPreferences.shared.weightUnit.symbol   // “kg” or “lb”
    }
}

// MARK: - Previews

#Preview("Set Row – KOM") {
    @State var draft = SetDraft(reps: 8, weight: 100, rpe: .eight)
    return SetRowView(draft: $draft)
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color.black)
}
