# Docs/Architecture.md
Gainz ▸ **Clean-Swift + Modular SPM**  
_Last updated: 2025-05-27_

## 1. High-Level Overview
The codebase is carved into three strata that never invert their dependency arrows:


┌───────────────────────┐
│       APP LAYER       │ ← SwiftUI (feature bundles)
├───────────────────────┤
│     CORE SERVICES     │ ← Networking, Persistence, Analytics
├───────────────────────┤
│  DOMAIN / PLATFORM-A  │ ← Pure business logic (no UIKit)
└───────────────────────┘


* **App Layer** – one SwiftUI feature package per tab (`Home`, `Planner`, `WorkoutLogger`,  
  `AnalyticsDashboard`, `Profile`, `Settings`, `Onboarding`). Each feature imports CoreUI for
  visuals and depends on *public* interfaces only—never directly on another feature. Navigation
  is orchestrated by `AppCoordinator` and lightweight feature co-ordinators. :contentReference[oaicite:0]{index=0}
* **Core Services** – fat-free utilities shared by all features:  
  `CoreNetworking`, `CorePersistence`, `AnalyticsService`, `ServiceHealth` (HealthKit, local
  notifications), plus design tokens in `CoreUI`. All are pure SwiftPM libraries with zero UI.
* **Domain** – platform-agnostic models (`MesocyclePlan`, `WorkoutSession`, etc.), use-cases
  (`PlanMesocycleUseCase`, `LogWorkoutUseCase`), and deterministic services
  (`PlanGenerator`, `AnalyticsCalculator`). It compiles on macOS, iOS, watchOS, and the server.

## 2. Dependency Rules
* **Features → Core Services → Domain** – never the reverse.
* **Domain** must not import Combine, SwiftUI, or Foundation networking; it stays test-first and
  portable.
* **Interfaces over concretes:** every Core Service exposes `public protocol`s consumed by
  features; default implementations live in the same module, but tests can inject mocks.  
  Example: `WorkoutRepository` protocol ⇢ `CorePersistence.WorkoutRepositoryImpl`.  
* **Generated code** (SwiftGen assets / strings) lives in `Generated/Resources/SwiftGen`.
  No human edits; CI regenerates on every push.

## 3. Data Flow for a Typical Set Log
1. **WorkoutLogger** logs a set → `WorkoutViewModel` calls
   `LogWorkoutUseCase` (Domain) with an `ExerciseLog`.
2. `LogWorkoutUseCase` persists via `WorkoutRepository`.
3. `WorkoutRepositoryImpl` writes to Core Data (sync) and publishes a Combine event.
4. `AnalyticsService` listens, updates strength PRs, emits `AnalyticsEvent.setLogged`.
5. `AnalyticsDashboard` observes published metrics and animates heat-map updates.  
   _No HRV, recovery scores, or velocity measurements are ever recorded._ :contentReference[oaicite:1]{index=1}

## 4. Build-Time Toolchain
| Tool            | Purpose                                 | Invocation                           |
|-----------------|-----------------------------------------|--------------------------------------|
| **XcodeGen**    | Declarative `project.yml` → `.xcodeproj`| `./Tools/build-setup/generate_project.sh` |
| **SwiftGen**    | Type-safe assets & strings              | `./Tools/codegen/swiftgen_run.sh`    |
| **SwiftLint**   | Style & complexity gates                | `./Tools/linting/lint.sh`            |
| **SwiftFormat** | Auto-format on commit                   | pre-commit hook                      |
| **GitHub CI**   | Lint → Build → Test → Snapshot diff     | `.github/workflows/ci.yml`           |
| **Fastlane**    | TestFlight & App Store deploy           | `.github/workflows/release.yml`      |

## 5. Testing Pyramid
* **Domain Unit Tests** – invariants on plan generation & analytics maths.
* **Feature ViewModel Tests** – state machine transitions, mock repos.
* **Snapshot UI Tests** – light/dark, dynamic-type snapshots in `Snapshots/`.
* **Integration (Flow) Tests** – happy-path workout logging & planner drag-drop.

Coverage gate: **≥ 90 %** for Domain, **≥ 80 %** overall. Snapshot diffs must be pixel-perfect.

## 6. Scalability & Future Targets
* **watchOS** – recompile `WorkoutLogger` package with watchOS-specific UI; Domain layer already portable.
* **macOS Catalyst / visionOS** – SwiftUI views auto-adapt; only tweak layouts & input paradigms.
* **Android** – Domain layer can be exported to Kotlin Multiplatform; Core Services swap for Ktor/SQLDelight.

---

_This document defines the architectural contract—any new code must fit these layers, respect dependency rules, and keep the build-time toolchain green._
