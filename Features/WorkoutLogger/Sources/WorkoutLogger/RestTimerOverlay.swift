//
//  RestTimerOverlay.swift
//  Planner – Components
//
//  Appears after a set is logged, counting down the prescribed rest.
//  Dark-mode-first UI with Gainz gradient accent on the progress ring.
//  Zero HRV / recovery metrics; entirely local timer logic.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Combine

// MARK: - RestTimerOverlay

/// Full-screen overlay that counts down a rest interval and notifies the
/// caller when the interval elapses or the user skips early.
///
/// Usage:
/// ```swift
/// RestTimerOverlay(duration: 90, isPresented: $showTimer) {
///     // Rest complete – unlock next set
/// }
/// ```
public struct RestTimerOverlay: View {

    // MARK: Input
    public let duration: TimeInterval             // seconds
    @Binding public var isPresented: Bool
    public var onFinish: () -> Void               // called on natural completion
    public var onSkip:  () -> Void = {}           // called when user taps “Skip”

    // MARK: State
    @State private var remaining: TimeInterval
    @State private var timerCancellable: Cancellable?

    // MARK: Init
    public init(
        duration: TimeInterval,
        isPresented: Binding<Bool>,
        onFinish: @escaping () -> Void,
        onSkip:   @escaping () -> Void = {}
    ) {
        self.duration     = max(duration, 1)      // guard against 0 / negatives
        self._isPresented = isPresented
        self.onFinish     = onFinish
        self.onSkip       = onSkip
        self._remaining   = State(initialValue: duration)
    }

    // MARK: View
    public var body: some View {
        ZStack {
            // Semi-transparent blur behind content
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                progressRing
                countdownLabel

                HStack(spacing: 24) {
                    skipButton
                    cancelButton
                }
            }
            .padding(32)
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
        .transition(.opacity.combined(with: .scale))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Subviews

private extension RestTimerOverlay {

    var progressRing: some View {
        let progress = 1 - remaining / duration
        return ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .foregroundColor(Color.gray.opacity(0.3))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(
                            gradient: Gradient(colors: [Color.indigo, Color.purple]),
                            center: .center),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: remaining)
        }
        .frame(width: 160, height: 160)
    }

    var countdownLabel: some View {
        Text(timeString(from: remaining))
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .monospacedDigit()
            .accessibilityLabel("Remaining rest: \(Int(remaining)) seconds")
    }

    var skipButton: some View {
        Button(action: skip) {
            Text("Skip")
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
        }
        .foregroundColor(.white)
    }

    var cancelButton: some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .font(.headline)
                .padding()
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
        .foregroundColor(.white)
        .accessibilityLabel("Cancel timer")
    }
}

// MARK: - Timer Logic

private extension RestTimerOverlay {

    func startTimer() {
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard remaining > 0 else {
                    finish()
                    return
                }
                remaining -= 1
            }
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func finish() {
        stopTimer()
        isPresented = false
        onFinish()
    }

    func skip() {
        stopTimer()
        isPresented = false
        onSkip()
    }

    func dismiss() {
        stopTimer()
        isPresented = false
    }
}

// MARK: - Helpers

private extension RestTimerOverlay {
    func timeString(from seconds: TimeInterval) -> String {
        let intSec = Int(seconds)
        return String(format: "%02d:%02d", intSec / 60, intSec % 60)
    }
}
