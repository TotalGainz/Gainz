//
//  AppClip.swift
//  Gainz • AppClip
//
//  SwiftUI entry point for the Gainz App Clip.  Presents a condensed
//  onboarding & quick-action flow, and offers seamless handoff to the
//  full iOS app.  No HRV or velocity tracking logic included.
//
//  © 2025 Echelon Commerce LLC. All rights reserved.
//

import SwiftUI
import CoreUI            // ColorPalette, BrandLogoView
import CorePersistence   // Lightweight cache for deep-link context

@main
struct GainzAppClip: App {
    // Handles deep-links like gainz://start?workout=Push
    @StateObject private var router = ClipRouter()
    
    var body: some Scene {
        WindowGroup {
            ClipRootView()
                .environmentObject(router)
                .onOpenURL { router.handle(url: $0) }      // universal-link / QR :contentReference[oaicite:0]{index=0}
        }
    }
}

// MARK: – Router / Link-Parser

final class ClipRouter: ObservableObject {
    @Published var intent: ClipIntent = .landing
    
    func handle(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        switch comps.host {
        case "start":
            if let workout = comps.queryItems?.first(where: { $0.name == "workout" })?.value {
                intent = .startWorkout(workout)
            }
        default:
            break
        }
    }
    
    enum ClipIntent {
        case landing
        case startWorkout(String)   // workout name
    }
}

// MARK: – Root View

private struct ClipRootView: View {
    @EnvironmentObject private var router: ClipRouter
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        switch router.intent {
        case .landing:
            LandingView()
        case .startWorkout(let name):
            StartWorkoutView(workoutName: name)
        }
    }
}

// MARK: – Landing (“Get the App”) View

private struct LandingView: View {
    @Environment(\.openURL) private var openURL
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id0000000000")!
    
    var body: some View {
        VStack(spacing: 24) {
            BrandLogoView()
                .frame(width: 120, height: 120)
            Text("Track sets, master nutrition, and level-up your training.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Get Full Gainz App") {
                openURL(appStoreURL)                         // system banner → App Store :contentReference[oaicite:1]{index=1}
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(ColorPalette.background.ignoresSafeArea())
    }
}

// MARK: – Quick “Start Workout” Flow

private struct StartWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    let workoutName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Ready to start?")
                .font(.title3.weight(.semibold))
            Text(workoutName)
                .font(.largeTitle.monospacedDigit())
                .foregroundStyle(ColorPalette.accent)
            Button("Begin") {
                DatabaseManager.shared.startWorkout(named: workoutName)        // lightweight write
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: – Previews

#Preview {
    ClipRootView()
        .environmentObject(ClipRouter())
}
