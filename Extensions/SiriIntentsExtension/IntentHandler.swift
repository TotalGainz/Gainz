//
//  IntentHandler.swift
//  Gainz • SiriIntentsExtension
//
//  Routes incoming Siri or Shortcuts requests to dedicated handlers.
//  Supports:
//    • StartWorkoutIntent – "Hey Siri, start Push workout"
//    • LogSetIntent      – "Log 8 reps of bench at 225"
//  Brand constraints: no HRV / velocity tracking.
//  © 2025 Echelon Commerce LLC.
//

import Intents
import CorePersistence                // DatabaseManager for workout data

// MARK: – Root dispatcher

final class IntentHandler: INExtension {
    /// Returns a handler object for the specific intent.
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is StartWorkoutIntent: return StartWorkoutHandler()
        case is LogSetIntent:       return LogSetHandler()
        default:                    return self          // fallback (shouldn’t occur)
        }
    }
}

// MARK: – StartWorkoutIntent

final class StartWorkoutHandler: NSObject, StartWorkoutIntentHandling {
    
    func resolveWorkoutName(for intent: StartWorkoutIntent,
                            with completion: @escaping (INStringResolutionResult) -> Void) {
        if let name = intent.workoutName, !name.isEmpty {
            completion(.success(with: name))
        } else {
            completion(.needsValue())
        }
    }
    
    func confirm(intent: StartWorkoutIntent,
                 completion: @escaping (StartWorkoutIntentResponse) -> Void) {
        completion(.init(code: .ready, userActivity: nil))
    }
    
    func handle(intent: StartWorkoutIntent,
                completion: @escaping (StartWorkoutIntentResponse) -> Void) {
        let ok = DatabaseManager.shared.startWorkout(named: intent.workoutName ?? "Workout")
        completion(.init(code: ok ? .success : .failure, userActivity: nil))
    }
}

// MARK: – LogSetIntent

final class LogSetHandler: NSObject, LogSetIntentHandling {
    
    func resolveExercise(for intent: LogSetIntent,
                         with completion: @escaping (INStringResolutionResult) -> Void) {
        if let ex = intent.exercise, !ex.isEmpty {
            completion(.success(with: ex))
        } else {
            completion(.needsValue())
        }
    }
    
    func resolveReps(for intent: LogSetIntent,
                     with completion: @escaping (INIntegerResolutionResult) -> Void) {
        if let reps = intent.reps?.intValue, reps > 0 {
            completion(.success(with: reps))
        } else {
            completion(.needsValue())
        }
    }
    
    func resolveWeight(for intent: LogSetIntent,
                       with completion: @escaping (INDoubleResolutionResult) -> Void) {
        if let w = intent.weight?.doubleValue, w >= 0 {
            completion(.success(with: w))
        } else {
            completion(.success(with: 0)) // weight optional
        }
    }
    
    func confirm(intent: LogSetIntent,
                 completion: @escaping (LogSetIntentResponse) -> Void) {
        completion(.init(code: .ready, userActivity: nil))
    }
    
    func handle(intent: LogSetIntent,
                completion: @escaping (LogSetIntentResponse) -> Void) {
        let ok = DatabaseManager.shared.logSet(
            exercise: intent.exercise ?? "",
            reps: intent.reps?.intValue ?? 0,
            weight: intent.weight?.doubleValue ?? 0
        )
        completion(.init(code: ok ? .success : .failure, userActivity: nil))
    }
}
