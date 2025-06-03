//
//  PlannerFeatureInterface.swift
//  FeatureInterfaces
//
//  Public contract that allows the AppCoordinator (and other features)
//  to present or deep-link into the Planner feature without importing its
//  concrete implementation.  Lives in its own SwiftPM module so it can be
//  depended on by any target—iOS, watchOS, server side—without a UIKit
//  or SwiftUI requirement.
//
//  Created for Gainz on 27 May 2025.
//

import Foundation
import Combine

// MARK: - PlannerFeatureInterface

/// Abstracts the Planner feature’s capabilities so callers can
/// (a) present the screen  and (b) observe planning events.
///
/// Conforming types are provided by the concrete Planner module
/// (iOS: `PlannerViewCoordinator`, watchOS: `PlannerWatchCoordinator`, …).
public protocol PlannerFeatureInterface: AnyObject {

    // MARK: Presentation

    /// Opens the Planner’s root view (e.g., a calendar).
    ///
    /// - Parameters:
    ///   - animated: Flag indicating whether to animate the transition.
    ///   - completion: Optional closure executed after the Planner is shown.
    func openPlanner(animated: Bool, completion: (() -> Void)?)

    /// Deep-links directly to a mesocycle editor for the specified plan.
    ///
    /// - Parameter planID: Domain identifier for `MesocyclePlan`.
    func openMesocycleEditor(planID: UUID)

    // MARK: Events

    /// Publisher that emits whenever the user creates, updates,
    /// or deletes a plan. Consumers can react to refresh dashboards, etc.
    var planEventsPublisher: AnyPublisher<PlanEvent, Never> { get }
}

// MARK: - PlanEvent

/// Emits granular changes so other features can stay in sync
/// without tight coupling to CorePersistence.
public enum PlanEvent {
    case created(planID: UUID)
    case updated(planID: UUID)
    case deleted(planID: UUID)
}
