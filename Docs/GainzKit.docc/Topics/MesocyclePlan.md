# Domain/MesocyclePlan.md

Gainz ▸ **Mesocycle Planning Model & API**
*Last updated: 2025-05-27*

---

## 1. Conceptual Primer

A **mesocycle** is a 4‑to‑6‑week block inside a larger macrocycle that pursues a single strategic objective—here: **hypertrophy‑biased progressive overload**. Gainz treats the mesocycle as the atomic planning unit that the Planner, WorkoutLogger, and AnalyticsDashboard all reference. *No HRV, recovery scores, or bar‑speed velocity factors are considered in this model.*

---

## 2. Key Design Goals

1. **Deterministic** – identical inputs always yield the same schedule.
2. **Composable** – can be chained to form macrocycles or split into microcycles.
3. **Data‑light** – pure structs + value semantics; JSON‑serialisable.
4. **Extendable** – tolerates new periodisation strategies via `Strategy` protocol.

---

## 3. Core Types

```swift
public struct MesocyclePlan: Equatable, Codable {
    public let id: UUID
    public let createdAt: Date
    public let weeks: [WeekPlan]            // length = weeks.count
    public let focus: MuscleGroup?          // optional primary emphasis
    public let strategy: Strategy.Kind      // e.g. .linear, .undulating
}

public struct WeekPlan: Equatable, Codable {
    public let index: Int                   // 0‑based
    public let sessions: [WorkoutSession]
}

public struct WorkoutSession: Equatable, Codable {
    public let day: Weekday                 // M‑Su
    public let blocks: [ExerciseBlock]
}

public struct ExerciseBlock: Equatable, Codable {
    public let exercise: ExerciseID         // canonical catalog id
    public let sets: Int
    public let reps: ClosedRange<Int>
    public let rpe: Double                  // target RPE 6‑10
    public let progression: ProgressionRule // see below
}
```

### `ProgressionRule`

Rules that mutate **weight** *or* **reps** across weeks:

```swift
enum ProgressionRule: Codable, Hashable {
    case linear(start: Double, increment: Double)
    case doubleProgression(startReps: Int, endReps: Int, loadIncrement: Double)
    case wave(waveSize: Int, increment: Double)
}
```

---

## 4. Invariants & Validation

| Invariant                          | Enforcement                                                             |
| ---------------------------------- | ----------------------------------------------------------------------- |
| Volume Escalation                  | `totalSets(week[i+1]) ≥ totalSets(week[i])`                             |
| Deload Insertion (optional)        | If `strategy.includesDeload == true` then week\[ last ] volume is −40 % |
| Exercise Uniqueness within Session | Duplicate `exercise` ids in the same session are merged at build‑time   |
| Reps Range Validity                | `1 ≤ reps.lowerBound ≤ reps.upperBound ≤ 30`                            |
| RPE Window                         | `5.5 ≤ rpe ≤ 10`                                                        |

`MesocycleValidator` throws descriptive errors on plan construction.

---

## 5. Strategy Protocol

```swift
public protocol Strategy {
    static var kind: Kind { get }
    func build(for template: Template, seed: Seed) throws -> MesocyclePlan

    enum Kind: String, Codable { case linear, undulating, strengthFocused }
}
```

New periodisation styles implement `Strategy` and are registered via `StrategyRegistry` at runtime.

---

## 6. API Usage Example

```swift
let template = HypertrophyTemplate.defaultPushPullLegs
let seed     = MesocycleSeed(startDate: .now, weeks: 6)

let plan = try LinearProgressionStrategy()
                .build(for: template, seed: seed)

planner.apply(plan) // binds to Planner view & persistence
```

---

## 7. Volume & Intensity Queries

Utility extensions allow introspection:

```swift
extension MesocyclePlan {
    func volume(for group: MuscleGroup) -> Int { /* total sets */ }
    func maxRPE() -> Double { weeks.flatMap { $0.sessions }.flatMap { $0.blocks }.map(\ .rpe).max() ?? 0 }
    func isDeloadWeek(_ week: Int) -> Bool { weeks[week].totalVolume < weeks[week-1].totalVolume * 0.65 }
}
```

All queries are pure and performant (O(n) over sets list).

---

## 8. Persistence Schema (JSON)

```json
{
  "id": "F26E4E90-...",
  "createdAt": "2025-05-27T14:21:33Z",
  "weeks": [
    {
      "index": 0,
      "sessions": [
        {
          "day": "monday",
          "blocks": [
            { "exercise": "BARBELL_BENCH_PRESS", "sets": 4, "reps": [8,12], "rpe": 8, "progression": {"linear": {"start": 100,"increment": 2.5}} }
          ]
        }
      ]
    }
  ],
  "focus": "chest",
  "strategy": "linear"
}
```

### Versioning

`_schemaVersion` is appended when breaking changes occur; loaders migrate at runtime.

---

## 9. Extension Points

* **Strategy plug‑in**: register `Strategy.Kind` + builder.
* **Template Catalog**: JSON files under `Resources/Templates` become selectable starting points.
* **Analytics Hooks**: `AnalyticsService` observes `planApplied` events (no HRV/recovery analytics).

---

## 10. Future Work

* **Auto‑Scaling Volume by Training Age** – linear model fed via onboarding questionnaire.
* **In‑app Plan Browser** – live preview with interactive muscle volume heatmap.

---

*This document is the single source of truth for MesocyclePlan semantics. All evolution PRs must update this file.*

