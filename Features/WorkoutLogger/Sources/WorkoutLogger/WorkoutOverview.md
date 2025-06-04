# Features/Planner/Components/WorkoutOverview.md  
Gainz ▸ **WorkoutOverview** UI/UX‐spec  
_Last updated: 2025-05-27_

---

## 1. Purpose  
`WorkoutOverview` presents a single, succinct card that previews the athlete’s programmed workout for any given day. It answers three questions at a glance:

| Question                      | UI Element                                  |
|-------------------------------|---------------------------------------------|
| **What am I training?**       | Primary muscle-group tags and workout title |
| **How heavy / long is it?**   | Set-count, rep-span, estimated time badge   |
| **Where do I start?**         | “Begin Session” CTA, deep-links to Logger   |

> **Scope:** strictly hypertrophy programming—no HRV, readiness, or velocity badges.

---

## 2. Component Hierarchy  

WorkoutOverviewCard
├─ HeaderStack
│  ├─ WorkoutTitleLabel          // e.g. “PPL – Push A”
│  └─ DateBadge                  // “Mon 27 May”
├─ TagGrid
│  ├─ MuscleTagView              // “Chest”, “Triceps”, “Delts”
│  └─ SchemeTagView?             // Optional (e.g. “Strength”)
├─ MetricsRow
│  ├─ SetsBadge                  // “24 sets”
│  ├─ RepsBadge                  // “8–12 reps”
│  └─ TimeEstimateBadge          // “≈ 72 min”
└─ BeginButton                   // Primary gradient CTA

---

## 3. Public API (SwiftUI)

```swift
struct WorkoutOverviewCard: View {

    // Domain model representing the full workout template
    let workoutPlan: WorkoutPlan

    // Fired when user taps CTA
    let onBegin: (WorkoutPlan) -> Void

    var body: some View { … }
}


⸻

4. Visual & Interaction Design

Attribute    Spec
Card surface    Color.surfaceElevated (≈ #121212) with 24 pt corner radius, soft shadow 0 0 12 rgba(0,0,0,0.6)
CTA style    ButtonStyle.primaryGradient (Indigo▶︎Violet 11°)
Typography    Title: SFProRounded-Semibold 17, badges: 13
Tag grid    4-pt spacing, capsule tags using CoreUI.TagStyle
Animation    On appear: card fades & moves +6 pt Y over 0.2 s
Dynamic Type    Supports up to XXL; card expands vertically
VoiceOver    Combines title + first three tags into a single element

Gesture shortcuts:
    •    Haptic: light impact on tap.
    •    Context Menu (long-press): “Edit Workout”, “Duplicate”, “Skip”.

⸻

5. State Rules

State    Trigger    UI Change
Default    Upcoming date with an active plan    Full card
Completed    Session logged with ≥1 set    Card dimmed 40 % + ✔ badge
Skipped    User chose “Skip”    Card italic title + ⤭ arrow icon
Rest Day    No WorkoutPlan for date    Show RestDayView placeholder


⸻

6. Data-Flow Contract
    1.    PlannerViewModel publishes @Published var dailyPlans: [WorkoutPlan].
    2.    PlannerScreen maps each plan → WorkoutOverviewCard.
    3.    Tapping CTA fires onBegin; delegate pushes WorkoutLoggerScreen(plan:).
    4.    On session save, WorkoutRepository posts .workoutLogged Combine event.
    5.    PlannerViewModel receives event → updates card state to Completed.

⸻

7. Metrics Calculation
    •    Set badge → sum of ExercisePlan.sets.
    •    Rep badge → min/max across all ExercisePlan.repRange.
    •    Time estimate

estimateMinutes = (
    sets × 75 s avgSet +
    (sets - exercises) × 120 s rest
) ÷ 60

Rounded to nearest 5 min.

⸻

8. Accessibility Checklist
    •    Title declared as Level 2 heading.
    •    All badges accessibilityLabel + accessibilityValue.
    •    BeginButton uses .accessibilityHint("Starts your Push A workout").
    •    Contrast ≥ 4.5:1 against darkest background.

⸻

9. Unit Snapshot Tests

Variation    Device    Snapshot Name
Default – light mode    iPhone 15 Pro    WorkoutOverview_default
Completed – dark mode    iPhone 15 Pro    WorkoutOverview_completed
Dynamic Type XXL    iPhone SE 3    WorkoutOverview_DTXT_XXL
VoiceOver on (mocked)    iPhone 15 Pro    WorkoutOverview_voiceover

Snapshot baseline lives in __Snapshots__/Planner/WorkoutOverview/.

⸻

Commit this file alongside the Swift component; updates require UI/UX sign-off plus snapshot re-regeneration.

