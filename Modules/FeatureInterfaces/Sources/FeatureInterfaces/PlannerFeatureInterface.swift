//  PlannerFeatureInterface.swift
//  FeatureInterfaces
//
//  Public contract that allows the AppCoordinator (and other features)
//  to present or deep-link into the Planner feature without importing its
//  concrete implementation. Lives in its own SwiftPM module so it can be
//  depended on by any target—iOS, watchOS, server side—without a UIKit
//  or SwiftUI requirement.
//
//  Created for Gainz on 27 May 2025.
//
import Foundation
import Combine

// MARK: - PlannerFeatureInterface

/// Abstracts the Planner feature’s capabilities so callers can
/// (a) present the screen and (b) observe planning events.
///
/// Conforming types are provided by the concrete Planner module
/// (iOS: `PlannerViewCoordinator`, watchOS: `PlannerWatchCoordinator`, etc).
public protocol PlannerFeatureInterface: AnyObject {

    // MARK: Presentation

    /// Opens the Planner’s root view (e.g., the calendar UI).
    ///
    /// - Parameters:
    ///   - animated:   Pass `true` to animate the transition.
    ///   - completion: Optional closure executed after the Planner is shown.
    func openPlanner(animated: Bool, completion: (() -> Void)?)

    /// Deep-links directly to a mesocycle editor for the specified plan.
    ///
    /// - Parameter planID: The identifier for the target `MesocyclePlan`.
    func openMesocycleEditor(planID: UUID)

    // MARK: Events

    /// Publisher that emits whenever the user creates, updates,
    /// or deletes a plan. Consumers can subscribe to refresh dashboards, etc.
    var planEventsPublisher: AnyPublisher<PlanEvent, Never> { get }
}

// MARK: - PlanEvent

/// Describes changes in plans so other features can stay in sync
/// without tight coupling to persistence layers.
public enum PlanEvent {
    case created(planID: UUID)
    case updated(planID: UUID)
    case deleted(planID: UUID)
}

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Environment Key

private struct PlannerInterfaceKey: EnvironmentKey {
    static let defaultValue: PlannerFeatureInterface? = nil
}

public extension EnvironmentValues {
    /// Dependency-injection hook for the Planner feature.
    /// ```swift
    /// @Environment(\.plannerFeature) private var plannerFeature
    /// ```
    var plannerFeature: PlannerFeatureInterface? {
        get { self[PlannerInterfaceKey.self] }
        set { self[PlannerInterfaceKey.self] = newValue }
    }
}
#endif
