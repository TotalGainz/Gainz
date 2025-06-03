# HomeOverview.md
Gainz ▸ **Home Feature Design Synopsis**  
_Last updated: 2025-05-27_

---

## 1. Mission
The **Home tab** is the athlete’s launchpad: a single-glance dashboard that answers three questions the moment the app opens:

1. **“What’s on deck today?”** – shows the next scheduled workout or a prompt to plan one.  
2. **“How am I trending?”** – surfaces high-signal metrics (7-day volume, body-weight delta, PR streak).  
3. **“What should I tap next?”** – exposes primary CTAs (Start Workout, Log Body-Weight, Plan Week).

The screen must **never expose recovery, HRV, or bar-velocity data**—our scope is hypertrophy, not readiness.

---

## 2. Visual Hierarchy
| Zone | Component                      | Notes                                               |
|------|--------------------------------|-----------------------------------------------------|
| A    | Greeting header                | Dynamic (“Good morning, Brody”) w/ phoenix icon.    |
| B    | *Today* card                   | Workout summary **or** “Plan Workout” placeholder.  |
| C    | Metric trio                    | Volume, Weight Trend, PR Streak (tap → detail).     |
| D    | Quick actions                  | Start Workout · Log Weight · Plan Week.             |
| E    | Coach tip strip (optional)     | Rotates training cues; dismissible; 90-day memory.  |

Layout adapts with `AdaptiveStack` to support iPhone SE → iPad split view.

---

## 3. Data Flow
```mermaid
graph TD
  A[HomeView] -->|send(.onAppear)| VM(HomeViewModel)
  VM -->|Combine| Planner[PlanRepository]
  VM --> WorkoutRepo
  VM --> AnalyticsSvc
  Planner --> CoreData
  WorkoutRepo --> CoreData
  AnalyticsSvc --> CoreData

All Combine pipelines deliver on @MainActor; Domain calls run on a background executor.

⸻

4. Empty & Error States

Scenario    UI Treatment
No workout planned today    Illustration + “Plan Workout” CTA
No weight logs last 7 days    Body-weight tile shows “— kg”; tap = Log flow
Analytics fetch failure    Toast error; tiles greyed; pull-to-refresh


⸻

5. Accessibility & Localization
    •    VoiceOver: announces greeting → today workout → metrics left-to-right.
    •    Dynamic Type: scales up to XXXL; metric tiles wrap into 2×2 grid.
    •    RTL: swaps metric order, respects SF Symbol mirroring.
    •    Locales: numbers via NumberFormatter with user region units (kg ↔ lb via UnitConversion).

⸻

6. Dependencies
    •    Domain – models & use-cases (no UI).
    •    CoreUI – typography, phoenix gradient, ButtonStyles.
    •    FeatureSupport – UnitConversion, DateFormatter+Gainz.
    •    CorePersistence – read-only for Home (no writes outside quick actions).

⸻

7. Testing Matrix

Layer    Tool    Coverage Goal    Notes
ViewModel    XCTest    ≥ 90 %    Mock repos w/ Combine test helpers
Snapshot (UI)    iOS 17–    all states    Dark/Light, Dynamic Type XXL
Integration    XCUITest    happy path    Start Workout flow instrumentation


⸻

8. Future Enhancements
    •    watchOS glance pulling the same ViewModel via shared Framework.
    •    visionOS panoramic board with spatial charts (requires SceneKit).
    •    Widgets (iOS 18 WidgetKit) – “Today’s Workout” and “Weekly Volume”.

Keep this overview in sync with code changes; update the timestamp on major UX shifts.

