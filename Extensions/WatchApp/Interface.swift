//
//  Interface.swift
//  Gainz • WatchApp
//
//  Root entry point for the Apple Watch companion. Displays an active rest
//  timer with a ring animation and cues the next set in the workout.
//  Brand-consistent accent colors & haptics. No HRV / velocity tracking.
//  © 2025 Echelon Commerce LLC. All rights reserved.
//

import SwiftUI
import CoreUI              // ProgressRingView, ColorPalette
import CorePersistence     // DatabaseManager
import ServiceHealth       // NotificationManager for rest alerts
import Combine
import WatchKit

// MARK: - App

@main
struct GainzWatchApp: App {
    @StateObject private var vm = WatchWorkoutViewModel(repository: DatabaseManager.shared,
                                                        notifier: NotificationManager.shared)
    var body: some Scene {
        WindowGroup {
            InterfaceView()
                .environmentObject(vm)
        }
    }
}

// MARK: - ViewModel

final class WatchWorkoutViewModel: ObservableObject {
    @Published var nextExerciseName: String = "No Workout"
    @Published var restRemaining: TimeInterval = 0
    @Published var isResting: Bool = false

    private let repository: WorkoutRepository
    private let notifier: NotificationManager
    private var cancellables = Set<AnyCancellable>()

    private var timer: AnyCancellable?

    init(repository: WorkoutRepository, notifier: NotificationManager) {
        self.repository = repository
        self.notifier   = notifier
        refreshState()
    }

    // Called by view when user taps skip / start
    func toggleRest() {
        if isResting {
            endRest()
        } else {
            startRest(seconds: 120) // default 2 min
        }
    }

    private func startRest(seconds: TimeInterval) {
        restRemaining = seconds
        isResting = true
        notifier.scheduleRestAlert(after: seconds)
        WKInterfaceDevice.current().play(.start) // haptic cue
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func endRest() {
        timer?.cancel()
        restRemaining = 0
        isResting = false
        WKInterfaceDevice.current().play(.success)
    }

    private func tick() {
        guard restRemaining > 0 else { endRest(); return }
        restRemaining -= 1
        if restRemaining <= 0 { endRest() }
    }

    private func refreshState() {
        // Simplified fetch; production taps Combine publisher from repository
        if let session = repository.fetchActiveSession() {
            nextExerciseName = session.nextExercise?.name ?? "Next Set"
        }
    }
}

// MARK: - View

struct InterfaceView: View {
    @EnvironmentObject private var vm: WatchWorkoutViewModel
    @Environment(\.scenePhase) private var phase

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ProgressRingView(progress: vm.isResting ? progress : 1.0,
                                 ringWidth: 10)
                    .frame(width: 90, height: 90)
                    .overlay(timerLabel)

                Text(vm.nextExerciseName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)

                Button(action: vm.toggleRest) {
                    Text(vm.isResting ? "Skip Rest" : "Start Rest")
                        .font(.caption2.bold())
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Gainz")
        }
        .onChange(of: phase) { if $0 == .active { vm.objectWillChange.send() } }
    }

    private var progress: Double {
        guard vm.restRemaining > 0 else { return 1 }
        return max((120 - vm.restRemaining) / 120, 0)   // assumes 2 min cycle
    }

    private var timerLabel: some View {
        Text(timeString)
            .font(.title3.monospacedDigit())
            .foregroundStyle(ColorPalette.accent)
    }

    private var timeString: String {
        let intVal = Int(vm.restRemaining)
        return String(format: "%d:%02d", intVal / 60, intVal % 60)
    }
}

// MARK: - Previews

struct InterfaceView_Previews: PreviewProvider {
    static var previews: some View {
        InterfaceView()
            .environmentObject(WatchWorkoutViewModel(repository: DatabaseManager.preview,
                                                     notifier: NotificationManager.shared))
    }
}
