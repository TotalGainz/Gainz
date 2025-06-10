/// Domain.md

# Domain

Gainz **Domain** is the platform-agnostic core that models training knowledge and workflow logic.  
It defines pure Swift types and orchestration use-cases with **zero** UI, HealthKit, or storage dependencies, so the same code compiles on iOS, macOS, server-side Swift, or future platforms.

## Design Principles
- **Clean Architecture** – Entities ➔ Use-cases ➔ Repositories. Dependencies point outward only (use-cases depend on protocols, not concrete frameworks).
- **Value Types First** – Prefer `struct` for thread-safety and predictable mutation.
- **Deterministic & Testable** – No global state, no singletons. Every side effect is injected via a protocol, making functions pure whenever possible.
- **No HRV/Velocity Tracking** – Workload is captured via sets, load, reps, and RIR only (no heart-rate variability or bar-speed metrics in Domain).

## Models
| Entity                   | Purpose                                                                       |
| ------------------------ | ----------------------------------------------------------------------------- |
| `Exercise`               | Uniquely identifiable movement with primary & secondary muscle groups.        |
| `MuscleGroup`            | Enum of anatomical groups (Chest, Quads, Triceps, etc.).                      |
| `ExercisePrescription`   | Prescribed sets × reps (or rep range) and effort target for one exercise in a workout plan. |
| `WorkoutPlan`            | Blueprint for a single planned workout (list of `ExercisePrescription`s).     |
| `MesocyclePlan`          | Multi-week collection of `WorkoutPlan`s plus cycle metadata (e.g. objective). |
| `WorkoutSession`         | Runtime log of an executed workout (date, start/end times, exercise logs).    |
| `ExerciseLog`            | Log of all sets performed for a specific exercise during a session.          |
| `SetRecord`              | Single set result: weight, reps, and RIR/RPE. (Velocity intentionally omitted.) |
| `UserProfile`            | Athlete’s static metrics (height) + dynamic stats (body weight, experience).  |

## Use Cases
- `PlanMesocycleUseCase` – Generates a new `MesocyclePlan` from high-level goal input (training split, duration, etc).
- `GenerateInitialPlanUseCase` – One-tap onboarding planner for a brand-new user (produces a starter `MesocyclePlan`).
- `LogWorkoutUseCase` – Handles live logging of a workout (`WorkoutSession`), validating and persisting each set.
- `CalculateAnalyticsUseCase` – Aggregates training history into dashboard metrics (volume per muscle, PRs, etc).

## Repositories
Protocols abstract persistence and networking so callers never touch frameworks directly:
- `ExerciseRepository` – CRUD for `Exercise` catalog.
- `WorkoutRepository` – CRUD for `WorkoutPlan` and `WorkoutSession` records.
- `AnalyticsRepository` – Query and persist analytics data (volume trends, personal records, etc).

## Services
- `PlanGenerator` – Pure algorithm converting user goals into a periodized `MesocyclePlan` (volume distribution, progression).
- `AnalyticsCalculator` – Pure functions to compute strength scores, muscle group stimulus, fatigue, etc from logged data.

## Example

```swift
import Domain

let goal = GoalInput(
    split: .pushPullLegs,
    weeks: 4,
    experienceLevel: .intermediate
)

// Prepare dependencies
let exerciseRepo = InMemoryExerciseRepository(seed: [ /* seed with some Exercise instances */ ])
let planGenerator = DefaultPlanGenerator(exerciseRepo: exerciseRepo)

// Generate a mesocycle plan based on the goal
let mesocycle = PlanMesocycleUseCaseImpl(planGenerator: planGenerator).execute(goal: goal)

print("Week 1 – \(mesocycle.workouts.filter { $0.week == 0 }.count) workouts planned.")
