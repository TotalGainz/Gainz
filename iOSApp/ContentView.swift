//
//  ContentView.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Mission: Advanced, logical, intelligently designed, world-class root view.
//

import SwiftUI

// MARK: - Root Navigation View
struct RootNavigationView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home / Dashboard
            DashboardView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.dashboard)

            // Planner
            PlannerView()
                .tabItem { Label("Planner", systemImage: "calendar") }
                .tag(Tab.planner)

            // Profile
            ProfileOverviewView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
        .tint(Palette.phoenixPurple)          // Global accent   🟣
        .environmentObject(container.router) // Inject router for deep-links
        .onOpenURL { url in container.router.handle(url) } // Universal links
    }
}

// MARK: - Supported Tabs
extension RootNavigationView {
    enum Tab: String, CaseIterable, Identifiable {
        case dashboard
        case planner
        case profile

        var id: String { rawValue }
    }
}

// MARK: - Previews
#if DEBUG
struct RootNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RootNavigationView()
                .environmentObject(AppContainer())        // dark mode
                .preferredColorScheme(.dark)

            RootNavigationView()
                .environmentObject(AppContainer())        // increased contrast
                .preferredColorScheme(.dark)
                .environment(\.accessibilityContrast, .increased)
        }
        .previewDisplayName("Root Navigation • Gainz")
    }
}
#endif
