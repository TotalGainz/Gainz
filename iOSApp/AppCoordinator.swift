//
//  AppCoordinator.swift
//  Gainz
//
//  Created by Broderick Hiland on 2025-06-04.
//  Mission: Advanced, logical, intelligently designed, world-class navigation core.
//

import SwiftUI
import Combine

// MARK: - Coordinator Protocol
/// A type-erased coordinator contract driving a navigation flow.  Inspired by modern
/// SwiftUI Coordinator implementations that decouple state & routing. :contentReference[oaicite:0]{index=0}
protocol Coordinator: AnyObject, ObservableObject {
    associatedtype Destination: Hashable
    var path: NavigationPath { get set }
    func push(_ destination: Destination)
    func pop()
    func popToRoot()
}

// MARK: - AppCoordinator
/// Top-level coordinator governing the entire SwiftUI `NavigationStack`,
/// surfacing Combine publishers for deep-link & modal events. :contentReference[oaicite:1]{index=1}
@MainActor
final class AppCoordinator: Coordinator {
    // MARK: Typealiases
    enum Destination: Hashable {
        case workoutDetail(id: UUID)
        case plannerDay(date: Date)
        case settings
    }

    // MARK: Published State
    @Published var path = NavigationPath()

    // MARK: Dependencies
    private let deepLinkSubject: PassthroughSubject<URL, Never> = .init()
    private var cancellables = Set<AnyCancellable>()

    init() {
        bindDeepLinks()
    }

    // MARK: Navigation API
    func push(_ destination: Destination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    // MARK: Deep-Link Handling
    /// Converts incoming URLs to `Destination`s.  Pattern follows SwiftLee’s
    /// deep-link article adapted to Combine. :contentReference[oaicite:2]{index=2}
    func handle(_ url: URL) {
        deepLinkSubject.send(url)
    }

    private func bindDeepLinks() {
        deepLinkSubject
            .compactMap(Self.mapToDestination(_:))            // map URL → Destination
            .sink { [weak self] in self?.push($0) }
            .store(in: &cancellables)
    }

    private static func mapToDestination(_ url: URL) -> Destination? {
        guard url.scheme == "gainz" else { return nil }
        switch url.host {
        case "workout":
            if let id = url.toUUIDQueryItem("id") {          // helper extension below
                return .workoutDetail(id: id)
            }
        case "planner":
            if let date = url.toDateQueryItem("date") {
                return .plannerDay(date: date)
            }
        case "settings":
            return .settings
        default:
            break
        }
        return nil
    }
}

// MARK: - View Wrapper
/// Root view exported to the app, embedding `NavigationStack` and child destinations.
/// Inspired by QuickBird & SwiftAnytime demos. :contentReference[oaicite:3]{index=3}
struct AppCoordinatorView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DashboardView()
                .navigationDestination(for: AppCoordinator.Destination.self) { dest in
                    switch dest {
                    case .workoutDetail(let id):
                        WorkoutDetailView(workoutID: id)
                    case .plannerDay(let date):
                        PlannerDayView(date: date)
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .environmentObject(coordinator)   // expose to sub-views
        .onOpenURL { coordinator.handle($0) }
    }
}

// MARK: - URL Helpers
/// URL parsing utilities leveraging Combine & modern Swift APIs.  Technique based
/// on responder-chain blog & Combine guide. :contentReference[oaicite:4]{index=4}
private extension URL {
    func toUUIDQueryItem(_ name: String) -> UUID? {
        UUID(uuidString: queryItem(name))
    }

    func toDateQueryItem(_ name: String) -> Date? {
        guard let iso = queryItem(name) else { return nil }
        return ISO8601DateFormatter().date(from: iso)
    }

    func queryItem(_ name: String) -> String {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value ?? ""
    }
}

// MARK: - Preview
#if DEBUG
struct AppCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        AppCoordinatorView()
            .preferredColorScheme(.dark)
            .previewDisplayName("AppCoordinator • Dark")
    }
}
#endif

// MARK: - CITATIONS
// 1. Coordinator pattern overview – Medium. :contentReference[oaicite:5]{index=5}
/* 2. Deep-link handling in SwiftUI – SwiftLee. :contentReference[oaicite:6]{index=6} */
/* 3. Comprehensive Guide to Coordinator Pattern – Medium. :contentReference[oaicite:7]{index=7} */
/* 4. Coordinator Pattern in SwiftUI – SwiftAnytime. :contentReference[oaicite:8]{index=8} */
/* 5. Proper Navigation with Coordinators – Medium. :contentReference[oaicite:9]{index=9} */
/* 6. Navigation via Coordinator Pattern – Medium. :contentReference[oaicite:10]{index=10} */
/* 7. Using SwiftUI + Coordinators – Medium (Mavris). :contentReference[oaicite:11]{index=11} */
/* 8. Navigation & Deep-Links – QuickBird Studios. :contentReference[oaicite:12]{index=12} */
/* 9. Understanding Combine in Swift – Medium. :contentReference[oaicite:13]{index=13} */
/* 10. Practical Guide to Coordinator Pattern – Medium. :contentReference[oaicite:14]{index=14} */
