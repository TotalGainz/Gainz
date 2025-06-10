// SetRowView.swift

import SwiftUI
import Domain
import CoreUI   // Color tokens, typography helpers

// MARK: - View Model

/// A draft model representing an editable set in the planner's workout editor.
public struct SetDraft: Identifiable, Hashable {
    public let id = UUID()
    public var reps: Int
    public var weight: Double    // Weight (in user’s preferred unit, kg or lb)
    public var rpe: RPE?
}

// MARK: - SetRowView

/// A single row in the planner's exercise editor list, allowing inline editing of a planned set.
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
                .foregroundStyle(Color.onSurfaceSecondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.onSurfacePrimary.opacity(0.1))
                )
                .accessibilityHidden(true)

            // Weight input field and unit
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

            // Reps input field
            TextField("0", value: $draft.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($isRepFocused)
                .frame(minWidth: 36)
                .accessibilityLabel("Repetitions")

            // Optional RPE badge (read-only)
            if let rpeValue = draft.rpe {
                Text(rpeValue.description)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.phoenixStart)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Color.phoenixStart.opacity(0.15))
                    )
                    .accessibilityLabel("R P E \(rpeValue)")
            }

            Spacer(minLength: 0)

            // (Swipe-to-delete is handled by the parent List row actions)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())  // increase tap target for focusing
        .onTapGesture {
            // Tap focuses the first empty field or weight field by default
            if draft.weight == 0 {
                isWeightFocused = true
            } else {
                isRepFocused = true
            }
        }
    }

    // MARK: Helpers

    /// 1-based index of this set row, if provided by parent environment, otherwise "0"
    private var indexDescription: String {
        let index = Environment(\.rowIndex).wrappedValue ?? 0
        return index + 1 == 0 ? "?" : "\(index + 1)"
    }

    /// Unit symbol for weight (e.g., "kg" or "lb") based on user preferences.
    private var unitSymbol: String {
        UserPreferences.shared.weightUnit.symbol    // returns "kg" or "lb"
    }
}

// MARK: - Previews

#Preview("Planned Set Row") {
    @State var draft = SetDraft(reps: 8, weight: 100.0, rpe: .eight)
    return SetRowView(draft: $draft)
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color.black)
        .preferredColorScheme(.dark)
}
