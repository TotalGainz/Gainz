//  FeatureRouting.swift
//  FeatureInterfaces
//
//  Shared routing primitives for decoupled navigation and deep-link handling.
//  Features emit `FeatureRoute` values that coordinators translate into view
//  transitions.  This keeps feature modules free of UIKit or SwiftUI details
//  and enables straightforward URL-based routing.
//
//  Created for Gainz on 21 Jun 2025.
//
import Foundation

// MARK: - NavigationRouting

/// Minimal navigation contract for pushing feature routes.
public protocol NavigationRouting {
    /// Pushes a destination onto the navigation stack.
    /// - Parameters:
    ///   - route:    Target feature and associated payload.
    ///   - animated: Pass `true` to animate the transition.
    func push(_ route: FeatureRoute, animated: Bool)
}

// MARK: - FeatureKind

/// Enumerates all top-level features that support deep linking.
public enum FeatureKind: String, CaseIterable {
    case home = "home"
    case planner = "planner"
    case workoutLogger = "workout_logger"
    case analytics = "analytics"
    case profile = "profile"
    case settings = "settings"

    /// Creates a kind from its URL host identifier.
    /// Returns `nil` if the identifier does not match a known feature.
    public init?(identifier: String) {
        self.init(rawValue: identifier)
    }

    /// String identifier used in deep-link URLs (e.g. `gainz://home`).
    public var identifier: String { rawValue }
}

// MARK: - FeatureRoute

/// Describes a navigable destination within the app.
public struct FeatureRoute: Hashable {
    /// The feature being navigated to.
    public let kind: FeatureKind
    /// Arbitrary key/value pairs forwarded to the destination.
    public let payload: [String: String]

    /// Creates a new route with the specified feature and optional payload.
    public init(kind: FeatureKind, payload: [String: String] = [:]) {
        self.kind = kind
        self.payload = payload
    }

    /// Parses a deep-link URL produced by ``url(scheme:)``.
    /// - Throws: ``URLError.badURL`` if the URL does not contain a valid host.
    public init(url: URL) throws {
        guard let host = url.host, let kind = FeatureKind(identifier: host) else {
            throw URLError(.badURL)
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var params: [String: String] = [:]
        components?.queryItems?.forEach { item in
            if let value = item.value { params[item.name] = value }
        }
        self.kind = kind
        self.payload = params
    }

    /// Serialises the route into a deep-link URL.
    /// - Parameter scheme: Custom scheme for the app (defaults to ``"gainz"``).
    /// - Returns: Fully formed URL with query items for ``payload``.
    public func url(scheme: String = "gainz") -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = kind.identifier
        components.queryItems = payload.map { URLQueryItem(name: $0.key, value: $0.value) }
        // URLComponents always yields a valid URL with these inputs.
        return components.url!
    }
}

