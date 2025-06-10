// RestTimerOverlay.swift

import SwiftUI
import Combine

// MARK: - RestTimerOverlay

/// Full-screen overlay that counts down a rest interval and notifies the caller when the interval ends or is skipped.
public struct RestTimerOverlay: View {
    // MARK: Input
    public let duration: TimeInterval       // total rest duration (seconds)
    @Binding public var isPresented: Bool
    public var onFinish: () -> Void        // called when timer naturally completes
    public var onSkip: () -> Void = {}     // called when user skips early

    // MARK: State
    @State private var remaining: TimeInterval
    @State private var timerCancellable: Cancellable?

    // MARK: Init
    public init(duration: TimeInterval,
                isPresented: Binding<Bool>,
                onFinish: @escaping () -> Void,
                onSkip: @escaping () -> Void = {}) {
        // Ensure duration is at least 1 second
        self.duration = max(duration, 1)
        self._isPresented = isPresented
        self.onFinish = onFinish
        self.onSkip = onSkip
        // Initialize remaining time to full duration
        self._remaining = State(initialValue: duration)
    }

    // MARK: Body
    public var body: some View {
        ZStack {
            // Translucent background to dim underlying content
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Circular progress indicator for remaining time
                progressRing
                // Remaining time label
                countdownLabel

                // Action buttons (Skip and Cancel)
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

// MARK: - Subviews & Components

private extension RestTimerOverlay {
    // Circular progress ring showing elapsed vs remaining time
    var progressRing: some View {
        // Calculate progress fraction (1.0 = full duration elapsed)
        let progress = 1 - remaining / duration
        return ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .foregroundColor(Color.gray.opacity(0.3))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [Color.indigo, Color.purple]),
                                    center: .center),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: remaining)
        }
        .frame(width: 160, height: 160)
        .accessibilityHidden(true)
    }

    // Countdown timer text
    var countdownLabel: some View {
        Text(timeString(from: remaining))
            .font(.system(.largeTitle, design: .rounded).weight(.bold))
            .foregroundColor(.white)
            .monospacedDigit()
            .accessibilityLabel("Remaining rest: \(Int(remaining)) seconds")
    }

    // "Skip" button to skip the rest period early
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
        .accessibilityLabel("Skip rest")
    }

    // "Cancel" button to close the overlay without completing rest
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
    /// Start the countdown timer, updating every second.
    func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard remaining > 0 else {
                    finish()
                    return
                }
                remaining -= 1
            }
    }

    /// Stop and invalidate the timer.
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Finish the rest period naturally.
    func finish() {
        stopTimer()
        isPresented = false
        onFinish()
    }

    /// Skip the rest period early.
    func skip() {
        stopTimer()
        isPresented = false
        onSkip()
    }

    /// Dismiss the overlay without triggering completion action.
    func dismiss() {
        stopTimer()
        isPresented = false
    }
}

// MARK: - Time Formatting Helper

private extension RestTimerOverlay {
    /// Format seconds into MM:SS string.
    func timeString(from seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
