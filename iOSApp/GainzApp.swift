//
//  GainzApp.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Mission: Advanced, logical, intelligently designed, world-class entry point.
//

import SwiftUI
import Combine

// MARK: - Main App Entry
@main
struct GainzApp: App {
    // MARK: Dependencies
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(container)
                .environment(\.colorScheme, .dark)   // brand-wide dark UI
                .accentColor(Palette.phoenixPurple) // global accent
                .onAppear { container.bootstrap() } // cold-start prep
        }
    }
}

// MARK: - AppDelegate (legacy hooks)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Global UIAppearance — matches phoenix gradient brand
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(Palette.phoenixPurple)
        ]
        return true
    }
}

// MARK: - Dependency-Injection Container
/// Root DI container initialised once per app lifecycle.
@MainActor
final class AppContainer: ObservableObject {
    // Shared singletons
    let router = NavigationRouter()
    let workoutRepo = WorkoutRepository.live
    let settingsStore = SettingsStore.live

    /// Boot sequence: migrations, cache pre-warming, analytics, etc.
    func bootstrap() {
        workoutRepo.preload()
    }
}

// MARK: - Preview
#if DEBUG
struct GainzApp_Previews: PreviewProvider {
    static var previews: some View {
        RootNavigationView()
            .environmentObject(AppContainer())
            .preferredColorScheme(.dark)
            .previewDisplayName("Gainz • Dark Mode")
    }
}
#endif
