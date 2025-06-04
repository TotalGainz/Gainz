//
//  SettingsCoordinator.swift
//  Gainz – Settings Feature
//
//  Created by AI Auto-Generated on 2025-06-04.
//
//  Coordinator-pattern implementation for the Settings module.
//  Best-practice references:
//  • Mastering Navigation in SwiftUI Using Coordinator Pattern  [oai_citation:0‡medium.com](https://medium.com/%40dikidwid0/mastering-navigation-in-swiftui-using-coordinator-pattern-833396c67db5?utm_source=chatgpt.com)
//  • Proper Navigation in SwiftUI with Coordinators  [oai_citation:1‡medium.com](https://medium.com/%40ivkuznetsov/proper-navigation-in-swiftui-with-coordinators-ee33f52ebe98?utm_source=chatgpt.com)
//  • SwiftUI SOLID Navigation — The coordinator pattern  [oai_citation:2‡medium.com](https://medium.com/%40ales.dieo/swiftui-solid-navigation-the-coordinator-pattern-part-1-a58dc976a13e?utm_source=chatgpt.com)
//  • ObservableObject + Coordinator overview  [oai_citation:3‡medium.com](https://medium.com/%40paponsmc/swiftui-understand-about-observableobject-observedobject-stateobject-and-environmentobject-by-do-f46f75e92c92?utm_source=chatgpt.com)
//  • AnyCancellable store pattern (Combine)  [oai_citation:4‡stackoverflow.com](https://stackoverflow.com/questions/63939436/anycancellable-storein-with-combine?utm_source=chatgpt.com)
//  • How to use Coordinator Pattern in SwiftUI (SwiftAnytime)  [oai_citation:5‡swiftanytime.com](https://www.swiftanytime.com/blog/coordinator-pattern-in-swiftui?utm_source=chatgpt.com)
//  • Coordinators & SwiftUI (vbat.dev)  [oai_citation:6‡vbat.dev](https://vbat.dev/coordinators-swiftui?utm_source=chatgpt.com)
//  • Improving AnyCancellable store pattern  [oai_citation:7‡geekanddad.wordpress.com](https://geekanddad.wordpress.com/2019/12/05/improving-on-the-common-anycancellable-store-pattern/?utm_source=chatgpt.com)
//  • Coordinator Pattern for iOS Apps (Medium)  [oai_citation:8‡medium.com](https://medium.com/appcent/coordinator-pattern-for-ios-apps-52d4627373bf?utm_source=chatgpt.com)
//  • How to use SwiftUI + Coordinators (Medium)  [oai_citation:9‡medium.com](https://medium.com/%40michaelmavris/how-to-use-swiftui-coordinators-1011ca881eef?utm_source=chatgpt.com)
//
//  NOTE: No HRV or Velocity-Tracking code is present by design.

import SwiftUI
import Combine
import CoreUI
import DesignSystem

// MARK: - Coordinator

@MainActor
public final class SettingsCoordinator: ObservableObject {

    // Navigation path bound to a NavigationStack
    @Published public var path = NavigationPath()

    // Injected view-model
    public let viewModel: SettingsViewModel

    // MARK: – Init
    public init(viewModel: SettingsViewModel = .init()) {
        self.viewModel = viewModel
    }

    // MARK: – Entry Point

    /// Returns the root view controlled by this coordinator.
    public func start() -> some View {
        NavigationStack(path: $path) {
            SettingsView()
                .environmentObject(viewModel)
                .navigationDestination(for: Destination.self,
                                        destination: destinationView)
        }
    }

    // MARK: – Destinations

    public enum Destination: Hashable {
        case licenses
        case web(URL)
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .licenses:
            LicenseListView()
        case .web(let url):
            WebView(url: url)
        }
    }

    // MARK: – Public Navigation API

    public func showLicenses() {
        path.append(Destination.licenses)
    }

    public func openURL(_ url: URL) {
        path.append(Destination.web(url))
    }
}
