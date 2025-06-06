
# ``Domain``

Gainz **Domain** is the platform-agnostic core that models training knowledge and workflow logic.  
It defines pure Swift types and orchestration use-cases with **zero** UI, HealthKit, or storage
dependencies so the same code compiles on iOS, macOS, server-side Swift, or future platforms.

## Design Principles
* **Clean Architecture** – entities ➔ use-cases ➔ repositories; outward arrows depend only on protocols.  
* **Value Types First** – `struct` everywhere for thread-safety and predictable mutation.  
* **Deterministic & Testable** – no global state, no singletons; every function is pure or side-effect
  injected.  
* **No HRV / Velocity Tracking** – workload is captured via sets, load, reps, and RIR only.

## Models
| Entity | Purpose |
| ------ | ------- |
| `Exercise` | Uniquely identifiable movement with primary & secondary muscles. |
| `MuscleGroup` | Enum of anatomical groups (Chest, Quads, Triceps…). |
| `ExercisePlan` | Prescribed sets × reps × RIR for one exercise in a template. |
| `WorkoutPlan` | Ordered list of `ExercisePlan`s executed together. |
| `MesocyclePlan` | Multi-week array of `WorkoutPlan`s plus periodisation tags. |
| `WorkoutSession` | Runtime log of an executed workout (date, exercise logs). |
| `SetRecord` | Single set result: load, reps, RIR. Velocity intentionally omitted. |
| `UserProfile` | Static metrics (height) + dynamic stats (weight, training age). |

## Use Cases
* ``PlanMesocycleUseCase`` – creates or mutates a `MesocyclePlan` from goal input.  
* ``GenerateInitialPlanUseCase`` – one-tap jump-start planner for onboarding.  
* ``LogWorkoutUseCase`` – validates and persists a `WorkoutSession`.  
* ``CalculateAnalyticsUseCase`` – aggregates history into dashboard metrics.

## Repositories
Protocols abstract persistence and networking so callers never touch frameworks:

* ``ExerciseRepository`` – CRUD for `Exercise`.  
* ``WorkoutRepository`` – CRUD for `WorkoutPlan` & `WorkoutSession`.  
* ``AnalyticsRepository`` – time-series fetch for analytics dashboards.

## Services
* ``PlanGenerator`` – pure algorithm deriving weekly volume & progression.  
* ``AnalyticsCalculator`` – computes strength scores, muscle stimulus, fatigue.

## Example

```swift
import Domain

let goal = GoalInput(
    split: .pushPullLegs,
    weeks: 4,
    experienceLevel: .intermediate
)

let mesocycle = PlanMesocycleUseCase(
    planGenerator: PlanGenerator(),
    workoutRepo: InMemoryWorkoutRepository()
).execute(goal: goal)

print("Week 1 – \(mesocycle.weeks[0].workouts.count) workouts planned.")
Topics
Essentials
Exercise

WorkoutPlan

MesocyclePlan

Use Cases
PlanMesocycleUseCase

LogWorkoutUseCase

Services
PlanGenerator

AnalyticsCalculator
eof
#eof



