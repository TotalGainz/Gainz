# Docs/FeatureGuidelines.md

Gainz ▸ **Feature Creation & Review Playbook**
*Last updated: 2025-05-27*

---

## 1. Purpose

To ensure every new feature embodies Gainz’ core principles—**progress-first UX, near-invisible friction, and uncompromising code hygiene**—while preserving architectural integrity and brand cohesion.

---

## 2. Scope & Definitions

| Term                | Meaning                                                                                           |
| ------------------- | ------------------------------------------------------------------------------------------------- |
| **Feature Package** | A standalone SwiftPM module (`GainzFeatureXYZ`) delivering a single, user-visible capability.     |
| **Core Service**    | Shared utility provided by `CoreNetworking`, `CorePersistence`, `AnalyticsService`, or `CoreUI`.  |
| **Domain Layer**    | Pure business logic & data models (`MesocyclePlan`, `ExerciseLog`).                               |
| **App Layer**       | Aggregator target that assembles feature packages into the iOS binary via SwiftUI tab navigation. |

---

## 3. High-Level Checklist

1. **Problem → Outcome** clearly documented in the feature’s root `README`.
2. **User journey** mapped: entry point, happy path, alt flows, error/empty/loading states.
3. **Visuals**: follow DesignSystem tokens (`#121212` black base, gradient `Indigo-to-Violet 11°`, `SFPro-Rounded`).
4. **Accessibility**: VoiceOver labels, Dynamic Type support (up to XXL), 4.5+:1 contrast.
5. **Architecture**: MVVM + Coordinator; no UIKit dependencies; Combine publisher pipelines only.
6. **Analytics**: emit `AnalyticsEvent` with immutable schema; no HRV, recovery, or velocity metrics.
7. **Localization**: strings via SwiftGen (`L10n.FeatureXYZ.*`) and context-aware plural rules.
8. **Testing**: ≥90 % line coverage for Domain; snapshot tests for each UI variation.
9. **Performance**: <3 ms main-thread layout, <1 MB memory delta on appearance, zero leaks in Instruments.
10. **Rollout**: guarded by `RemoteConfig.flag("feature_xyz")`; staged to 5 %, 25 %, 100 %.

---

## 4. Package Layout Template

```
GainzFeatureXYZ/
├─ Sources/
│  ├─ FeatureXYZView.swift
│  ├─ FeatureXYZViewModel.swift
│  ├─ FeatureXYZCoordinator.swift
│  └─ FeatureXYZStrings.swift  // autopopulated by SwiftGen
├─ Tests/
│  ├─ FeatureXYZViewModelTests.swift
│  └─ FeatureXYZSnapshotTests.swift
└─ README.md
```

*No other top-level dirs are allowed; keep hierarchy flat.*

---

## 5. UI Guidelines

* **Dark mode first**; light mode derived by increasing luminance by exactly +6 % on neutral surfaces.
* **Gradient usage**: only on primary call-to-action buttons, active icons, or the phoenix splash.
* **Corners**: 24 pt radius for cards; 8 pt for interactive controls.
* **Motion**: 120 ms ease-in-out spring, 0.7 damping; single axis only (avoid parallax).

---

## 6. State Management & Data Flow

1. **Intent** (user gesture) → ViewModel `.Action`
2. **Use-Case** executed on a background queue
3. **Repository** persists / fetches
4. **ViewModel** receives `.Mutation` via Combine, reduces to `.State`
5. **SwiftUI View** animates diff

*The View must never hold business logic; the ViewModel must never import SwiftUI.*

---

## 7. Analytics & Telemetry

```swift
AnalyticsEvent.exerciseLogged(
    exerciseID: id,
    reps: reps,
    weight: weight,
    rpe: rpe
)
```

* Events are **fire-and-forget**; the UI never waits on analytics completion.
* Do **not** store HRV, recovery scores, or bar-speed velocity data.

---

## 8. Testing Requirements

| Layer       | Tooling                | Min Coverage | Notes                                |
| ----------- | ---------------------- | ------------ | ------------------------------------ |
| Domain      | XCTest                 | 90 %         | Pure sync tests                      |
| ViewModel   | XCTest + CombineExpect | 85 %         | Reducer logic, side-effect stubs     |
| UI          | SnapshotTesting        | Every state  | Dark/light, Dynamic Type XXL         |
| Integration | XCUITest (optional)    | Flow happy   | Use real services on local Core Data |

---

## 9. Performance Budgets

| Metric                | Budget             |
| --------------------- | ------------------ |
| Cold launch           | < 1.8 s            |
| Resume from BG        | < 0.6 s            |
| Layout pass per frame | < 4 ms main thread |
| Memory spike          | < 1 MB             |

Run `./Scripts/perf/measure.sh FeatureXYZ` before PR.

---

## 10. Review & Merge

1. **Design sign-off** (Figma link in PR description) by product designer.
2. **CI green**: lint, build, test, snapshot diff.
3. **At least one approval** from another senior engineer.
4. **Squash merge** with Conventional Commit prefix (`feat:`, `fix:`).

---

## 11. Do ✅ / Don’t 🚫

| ✅ Do                                                     | 🚫 Don’t                                      |
| -------------------------------------------------------- | --------------------------------------------- |
| Lean on `CoreUI.ButtonStyle.primary`                     | Invent bespoke button colors                  |
| Keep ViewModels stateless outside `.State` struct        | Bind `@Published` directly inside Views       |
| Inject dependencies via `EnvironmentValues` extensions   | Use singletons                                |
| Use `Task` for async workflows with cancellation support | Block the main thread with sleep / semaphores |
| Document public symbols with Markup comments             | Leave TODOs / FIXME in pushed code            |

---

*Commit every feature to this playbook. Consistency scales; divergence multiplies maintenance.*
