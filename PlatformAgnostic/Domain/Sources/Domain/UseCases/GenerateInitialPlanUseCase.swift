/// GenerateInitialPlanUseCase.swift

import Foundation

// MARK: - Use-Case Protocol

/// Use case for generating a brand-new initial training plan for a user based on onboarding inputs.
public protocol GenerateInitialPlanUseCase: Sendable {
    /// Build an initial `MesocyclePlan` given the user's onboarding survey responses.
    func execute(_ request: GenerateInitialPlanRequest) throws -> MesocyclePlan
}

// MARK: - Request DTO

/// Immutable request containing a new user's training preferences and experience.
public struct GenerateInitialPlanRequest: Hashable, Sendable {
    public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
        case novice, intermediate, advanced
    }
    /// Preferred training frequency (days per week).
    public let weeklyFrequency: Int
    /// Whether the user has access to barbell equipment.
    public let ownsBarbell: Bool
    /// Training experience level.
    public let experience: ExperienceLevel
    /// Optional seed for randomization (for deterministic testing).
    public let randomSeed: UInt64?

    public init(weeklyFrequency: Int,
                ownsBarbell: Bool,
                experience: ExperienceLevel,
                randomSeed: UInt64? = nil) {
        precondition((2...7).contains(weeklyFrequency), "weeklyFrequency must be 2–7.")
        self.weeklyFrequency = weeklyFrequency
        self.ownsBarbell = ownsBarbell
        self.experience = experience
        self.randomSeed = randomSeed
    }
}

// MARK: - Default Implementation

public final class GenerateInitialPlanUseCaseImpl: GenerateInitialPlanUseCase {
    // Dependencies
    private let exerciseRepo: ExerciseRepository
    private let uuidProvider: () -> UUID
    private let rng: RandomNumberGenerator

    public init(exerciseRepo: ExerciseRepository,
                uuidProvider: @escaping () -> UUID = { UUID() },
                randomSeed: UInt64? = nil) {
        self.exerciseRepo = exerciseRepo
        if let seed = randomSeed {
            self.rng = SeededGenerator(seed: seed)
        } else {
            self.rng = SystemRandomNumberGenerator()
        }
        self.uuidProvider = uuidProvider
    }

    public func execute(_ request: GenerateInitialPlanRequest) throws -> MesocyclePlan {
        // 1. Get all available exercises
        let catalog = try awaitResult(execute: exerciseRepo.fetchAll())
        // 2. Determine appropriate split pattern
        let splitFocuses = SplitPlanner.chooseSplit(frequency: request.weeklyFrequency,
                                                   experience: request.experience)
        // 3. Create one WorkoutPlan per day in the split
        var workouts: [WorkoutPlan] = []
        for (dayIndex, focus) in splitFocuses.enumerated() {
            let exercises = ExerciseSelector.select(focus: focus,
                                                    catalog: catalog,
                                                    ownsBarbell: request.ownsBarbell,
                                                    rng: rng)
            workouts.append(WorkoutPlan(
                id: uuidProvider(),
                name: focus.displayName,
                week: 0,
                dayOfWeek: dayIndex,
                exercises: exercises
            ))
        }
        // 4. Assemble a MesocyclePlan (default 4 weeks for initial plan)
        return MesocyclePlan(
            objective: .hypertrophy,
            weeks: 4,
            workouts: workouts
        )
    }

    // MARK: - Helper: Wrap async call into sync (since protocol is not async)

    /// Utility to synchronously wait for an async operation (only used here to adapt to protocol signature).
    private func awaitResult<T>(execute asyncFunc: @autoclosure () async throws -> T) throws -> T {
        var result: Result<T, Error>!
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                result = .success(try await asyncFunc())
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }
        semaphore.wait()
        return try result.get()
    }

    // MARK: - Nested Helpers

    /// Determines an appropriate split (exercise focus per training day) based on frequency and experience.
    private enum SplitPlanner {
        static func chooseSplit(frequency: Int,
                                experience: GenerateInitialPlanRequest.ExperienceLevel) -> [MuscleFocus] {
            switch (frequency, experience) {
            case (2, _):
                return [.fullBody, .fullBody]
            case (3, _):
                return [.push, .pull, .legs]
            case (4, .novice):
                return [.upper, .lower, .upper, .lower]
            case (4, _):
                return [.push, .pull, .legs, .accessory]
            case (5...7, _):
                // Default for high frequencies: 5-day rotating split (push/pull/legs/upper/lower)
                return [.push, .pull, .legs, .upper, .lower]
            default:
                return [.fullBody, .fullBody]
            }
        }
    }

    /// Selects specific exercises for a given day's focus.
    private enum ExerciseSelector {
        static func select(focus: MuscleFocus,
                           catalog: [Exercise],
                           ownsBarbell: Bool,
                           rng: RandomNumberGenerator) -> [ExercisePrescription] {
            // Filter exercises matching the focus and equipment availability
            let filtered = catalog.filter { exercise in
                focus.matches(exercise: exercise) &&
                (ownsBarbell || exercise.equipment != .barbell)
            }
            // Shuffle and take up to 5 exercises for variety
            let chosen = filtered.shuffled(using: rng).prefix(5)
            // Map to ExercisePrescription with default sets and rep range
            return chosen.map {
                ExercisePrescription(
                    exerciseId: $0.id,
                    sets: 3,
                    repRange: RepRange(min: 8, max: 12),
                    targetRIR: 1,
                    percent1RM: nil
                )
            }
        }
    }

    /// Deterministic RNG for testing.
    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { self.state = seed }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1
            return state
        }
    }
}

/// Represents broad categories for daily workout focus (for split planning).
private enum MuscleFocus {
    case fullBody, push, pull, legs, upper, lower, accessory

    /// Determine if an exercise fits this focus category.
    func matches(exercise: Exercise) -> Bool {
        switch self {
        case .fullBody:
            return true
        case .push:
            // Push day: chest, shoulders, triceps
            return exercise.primaryMuscles.contains(where: { [.chest, .frontDelts, .lateralDelts, .triceps].contains($0) })
        case .pull:
            // Pull day: back, rear delts, biceps
            return exercise.primaryMuscles.contains(where: { [.upperBack, .lats, .rearDelts, .biceps].contains($0) })
        case .legs:
            // Leg day: quads, hamstrings, glutes, calves
            return exercise.primaryMuscles.contains(where: { [.quads, .hamstrings, .glutes, .calves].contains($0) })
        case .upper:
            return exercise.primaryMuscles.contains(where: { $0.isUpperBody })
        case .lower:
            return exercise.primaryMuscles.contains(where: { !$0.isUpperBody })
        case .accessory:
            // Accessory: arms, calves, abs (smaller muscle groups)
            return exercise.primaryMuscles.contains(where: { [.biceps, .triceps, .forearms, .calves, .abs].contains($0) })
        }
    }

    /// A display name for the focus (used as workout name).
    var displayName: String {
        switch self {
        case .fullBody:  return "Full Body"
        case .push:      return "Push"
        case .pull:      return "Pull"
        case .legs:      return "Legs"
        case .upper:     return "Upper Body"
        case .lower:     return "Lower Body"
        case .accessory: return "Accessory"
        }
    }
}
