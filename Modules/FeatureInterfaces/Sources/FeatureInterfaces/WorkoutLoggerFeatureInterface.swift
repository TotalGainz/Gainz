//
//  WorkoutLoggerFeatureInterface.swift
//  FeatureInterfaces
//
//  Public façade for the Workout Logger feature.
//  ─────────────────────────────────────────────
//  • Lives in the cross-module “FeatureInterfaces” target so any other feature
//    (Home, Planner, Analytics, Siri intents) can interact with the logger
//    without creating a circular dependency.
//  • Exposes only pure-Swift protocols and type-erased SwiftUI views.
//  • Domain-layer types (`WorkoutSession`, `SetRecord`, `ExercisePlan`) are
//    passed straight through—no UI frameworks or persistence leakage.
//  • No HRV, recovery, or bar-velocity APIs—strictly hypertrophy logging.
//
//  Created for Gainz on 27 May 2025.
//

import SwiftUI
import Foundation
import Domain   // MesocyclePlan, WorkoutSession, SetRecord, etc.

// MARK: - WorkoutLoggerFeatureInterface

/// Abstracts all interactions with the Workout Logger mini-app.
public protocol WorkoutLoggerFeatureInterface: AnyObject {

    // MARK: Entry Points
    /// Renders the full screen Workout Logger flow.
    ///
    /// - Parameters:
    ///   - prefilledSession: Optional in-progress session to resume, or `nil`
    ///                       to start a brand-new workout.
    ///   - dismiss:          Callback fired when the flow completes or cancels.
    /// - Returns:            Type-erased SwiftUI view ready for navigation.
    func makeWorkoutLogger(
        prefilledSession: WorkoutSession?,
        dismiss: @escaping () -> Void
    ) -> AnyView

    // MARK: Quick-Access API
    /// Immediately records a single set—used by widgets, Siri Shortcuts, etc.
    ///
    /// - Parameters:
    ///   - set:         The set to append (weight, reps, RPE).
    ///   - exerciseId:  `Exercise.id` this set belongs to.
    /// - Throws:        `WorkoutLoggerError` if no active session exists.
    func logSet(
        _ set: SetRecord,
        for exerciseId: UUID
    ) async throws

    /// Fetches the most recent *completed* workout session.
    func latestCompletedSession() async throws -> WorkoutSession?
}

// MARK: - Default EnvironmentKey

private struct WorkoutLoggerInterfaceKey: EnvironmentKey {
    static let defaultValue: WorkoutLoggerFeatureInterface? = nil
}

public extension EnvironmentValues {
    /// Dependency-injection hook for SwiftUI views:
    /// ```swift
    /// @Environment(\.workoutLogger) private var workoutLogger
    /// ```
    var workoutLogger: WorkoutLoggerFeatureInterface? {
        get { self[WorkoutLoggerInterfaceKey.self] }
        set { self[WorkoutLoggerInterfaceKey.self] = newValue }
    }
}

// MARK: - Error

/// Finite error space for the quick-access API.
public enum WorkoutLoggerError: LocalizedError {
    case noActiveSession
    case invalidExerciseId

    public var errorDescription: String? {
        switch self {
        case .noActiveSession:   return "No active workout session."
        case .invalidExerciseId: return "The exercise ID is not part of the current session."
        }
    }
}
