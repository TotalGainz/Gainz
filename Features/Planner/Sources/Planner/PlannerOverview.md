# PlannerOverview.md  
_Features ▸ Planner ▸ Components_  
_Last updated: 2025-05-27_

---

## 1  Purpose  
Planner is the athlete’s **mission control**: it visualises the current mesocycle, lets users re-order upcoming workouts, and drags exercises onto specific days without ever exposing database jargon. All decisions resolve to Domain models (`MesocyclePlan`, `ExercisePlan`, `WorkoutSession`) so analytics works off pure data.

---

## 2  Anatomy  

| Layer | SwiftUI View | Role |
|-------|--------------|------|
| Surface | **`PlannerScreen`** | Tab-level entry; renders calendar grid + context sheet. |
| Mid-tier | **`WeekCarousel`** | Horizontally scrollable 7-day clusters, each tile reacts to drop gestures. |
| Cell | **`DayCard`** | Shows day label, volume badges, and completion ring animation. |
| Overlay | **`WorkoutPreviewSheet`** | Peek at an exercise stack; swipe up to edit or start. |

All visuals tap **DesignSystem** tokens—black base (#121212), indigo-to-violet gradient for active day, 24 pt rounded cards, gentle 120 ms spring motion.

---

## 3  Data Flow  

MesocyclePlan  →  PlannerViewModel  →  SwiftUI View
▲                │
ExercisePlan  ←──────────┘  drag-drop updates

* `PlannerViewModel` exposes:
  * `@Published var weekStates: [WeekState]`  
  * `func moveExercise(_ id: UUID, toDay: Date)`  
  * `func markWorkoutDone(_ id: UUID)`  
* Every mutation calls `PlanRepository` which persists via CorePersistence, then broadcasts through Combine.

_No HRV, recovery-score, or velocity metrics are stored or displayed._

---

## 4  User Interactions  

| Gesture | Feedback | Result |
|---------|----------|--------|
| Long-press exercise | Haptic “lift” | Enters drag. |
| Drag over DayCard   | Card lifts 4 pt, gradient border pulses | `moveExercise()` fires. |
| Tap DayCard         | Sheet glides up | `WorkoutPreviewSheet` shows sets & notes. |
| Swipe right on card | Checkmark tick + green flash | Marks workout complete. |
| Pull-down on sheet  | Shrinks back | Cancels preview. |

---

## 5  Accessibility  

* VoiceOver labels for every DayCard (“Tuesday: Push Day, 4 exercises, status done”).  
* Dynamic Type up to XXL; cards adopt vertical stacking when sizeCategory ≥ `.accessibilityMedium`.  
* Drag targets expand hit-area by +20 pt in accessibility mode.  

---

## 6  Performance Budgets  

| Metric | Target |
|--------|--------|
| First contentful paint | < 300 ms |
| Scroll FPS (WeekCarousel) | ≥ 90 on A17 chip |
| Memory spike opening sheet | < 0.5 MB |

All achieved by `.drawingGroup()` offloading gradient layers to the GPU and diffable data sources for DayCards.

---

## 7  Extension Points  

1. **Deload Injection** – when `PlanGenerator` flags deload week, Planner surfaces a banner and auto-reduces sets on drag.
2. **External Calendars** – future module can subscribe to the same Combine pipeline to push workouts to Apple Calendar.
3. **watchOS Mirroring** – WeekCarousel can down-scale to a `PageTabViewStyle` on Watch; share `PlannerViewModel`.

---

_Build everything to this blueprint; divergence must be documented in a follow-up ADR._
