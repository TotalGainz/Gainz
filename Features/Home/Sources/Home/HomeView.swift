// MARK: - HomeView.swift

import SwiftUI
import CoreUI          // Color & Font tokens for brand styling
import Domain          // WorkoutSession model
import FeatureSupport  // UnitConversion, Date formatters, etc.

public struct HomeView: View {
    // ViewModel state is bound for UI updates; actions are sent via closure
    @Binding private var state: HomeViewModel.State
    private let send: (HomeViewModel.Action) -> Void

    @Environment(\.openURL) private var openURL  // for deep link navigation

    // Predefined deep links for navigation to other features
    private let workoutURL   = URL(string: "gainz://workout/today")!   // opens Workout Logger (today's workout)
    private let plannerURL   = URL(string: "gainz://planner")!         // opens Planner feature
    private let quickLogURL  = URL(string: "gainz://workout/quick")!   // opens Quick Log in Workout Logger
    private let analyticsURL = URL(string: "gainz://analytics")!       // opens Analytics dashboard

    public init(state: Binding<HomeViewModel.State>,
                send: @escaping (HomeViewModel.Action) -> Void) {
        self._state = state
        self.send = send
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    greetingSection
                    todayWorkoutSection
                    metricsSection
                    quickActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(CoreUI.Color.background.ignoresSafeArea())
            .navigationTitle("")           // hide large nav bar title
            .navigationBarHidden(true)
        }
    }

    // MARK: - Subviews

    /// Greeting header with dynamic message and current date.
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(state.greeting)
                .font(CoreUI.Font.headingXL)
            Text(formattedDate)
                .font(CoreUI.Font.bodyM)
                .foregroundColor(CoreUI.Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(when: state.isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.greeting). \(formattedDate).")
    }

    /// Card showing today's workout or a prompt to plan one.
    private var todayWorkoutSection: some View {
        TodayWorkoutCardView(plan: state.todayWorkout) {
            // Navigate: if a workout is planned, start it; otherwise, go to planner
            if state.todayWorkout != nil {
                openURL(workoutURL)
            } else {
                openURL(plannerURL)
            }
        }
        .redacted(when: state.isLoading)
    }

    /// Grid of key metrics (weekly volume, sessions, body-weight, streak).
    private var metricsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Weekly Volume (planned volume this week, in kg)
            MetricCell(title: NSLocalizedString("Week Volume", comment: "Weekly volume label"),
                       value: "\(state.weeklyVolume)",
                       unit: "kg")
                .accessibilityLabel("Week volume \(state.weeklyVolume) kilograms")

            // Sessions (completed/planned this week)
            MetricCell(title: NSLocalizedString("Sessions", comment: "Workout sessions label"),
                       value: "\(state.sessionsCompleted)",
                       unit: "/\(state.sessionsPlanned)")
                .accessibilityLabel("Sessions \(state.sessionsCompleted) out of \(state.sessionsPlanned)")

            // Last Body-Weight (last logged weight and delta)
            if let weight = state.lastWeight {
                LastWeightView(weightKg: weight, deltaKg: state.bodyWeightTrend)
            } else {
                LastWeightView(weightKg: nil, deltaKg: nil)
            }

            // Workout Streak (consecutive days)
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("Workout Streak", comment: "Workout streak label"))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(CoreUI.Color.secondaryText)
                    .accessibilityHidden(true)  // hide label since badge provides context
                StreakBadgeView(streakCount: state.streakCount)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(CoreUI.Color.cardBackground)
            )
            .accessibilityElement(children: .combine)
            // The flame badge itself has an accessibility label with streak info.
        }
        .redacted(when: state.isLoading)
    }

    /// Row of quick-action buttons for primary user tasks.
    private var quickActionsSection: some View {
        HStack(spacing: 16) {
            QuickAction(icon: "plus.circle",
                        label: NSLocalizedString("Log Set", comment: "Log set quick action")) {
                openURL(quickLogURL)
            }
            QuickAction(icon: "calendar",
                        label: NSLocalizedString("Planner", comment: "Open planner quick action")) {
                openURL(plannerURL)
            }
            QuickAction(icon: "chart.bar",
                        label: NSLocalizedString("Analytics", comment: "Open analytics quick action")) {
                openURL(analyticsURL)
            }
        }
    }

    // MARK: - Helpers

    /// Formatted current date (e.g., "Monday, June 8").
    private var formattedDate: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day(.defaultDigits))
    }
}

// MARK: - MetricCell and QuickAction (UI Components)

/// A single metric tile displaying a title, value, and optional unit.
private struct MetricCell: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(CoreUI.Font.bodyS)
                .foregroundColor(CoreUI.Color.secondaryText)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(CoreUI.Font.headingL)
                if !unit.isEmpty {
                    Text(unit)
                        .font(CoreUI.Font.bodyS)
                        .foregroundColor(CoreUI.Color.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CoreUI.Color.cardBackground)
        )
        .accessibilityElement(children: .combine)
    }
}

/// A button for a primary action, showing an icon and label.
private struct QuickAction: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(CoreUI.Color.accent.opacity(0.15), in: Circle())
                Text(label)
                    .font(CoreUI.Font.bodyS)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}
