# Onboarding Module – Technical Overview

The Gainz onboarding flow translates evidence-based fitness guidance and HIG-compliant UX into a six-screen experience that asks only the questions needed to build a personalised mesocycle while maximising first-week retention—apps that execute this pattern see up to **50 % higher 30-day retention** than those that defer profile setup.  [oai_citation:0‡uxcam.com](https://uxcam.com/blog/mobile-app-retention-benchmarks/?utm_source=chatgpt.com) [oai_citation:1‡nudgenow.com](https://www.nudgenow.com/blogs/mobile-app-retention-rate?utm_source=chatgpt.com)  

## 1. Flow & Screen Sequence
| Step | View                               | Purpose | Key Output |
|------|------------------------------------|---------|------------|
| 1    | `OnboardingView`                   | Warm intro carousel | None |
| 2    | `OnboardingGoalView`               | Capture primary goal | `TrainingGoal` enum |
| 3    | `OnboardingExperienceView`         | Gauge lifting tenure | `TrainingExperience` enum |
| 4    | `OnboardingFrequencyView`          | Commit weekly days   | `TrainingFrequency` enum (2-7) |
| 5    | `OnboardingPreferencesView`        | Fine-tune reminders, HealthKit, units | `UserPreferences` struct |
| 6    | `OnboardingPlanPreviewView`        | Confirm summary, route to main app | `PlanPreview` struct |

The order aligns with Apple’s recommendation to keep early steps inspirational and push permission-granular questions later, preventing cognitive overload.  [oai_citation:2‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines?utm_source=chatgpt.com) [oai_citation:3‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/launching?utm_source=chatgpt.com)  

## 2. Data Flow & Persistence
* **Transient state** lives in each view’s `@State` or `@Observable` ViewModel.  
* **Cross-screen state** is centralised in `OnboardingCoordinator`, exposing a `RootRoute` publisher for navigation.  
* **Long-term flags** (e.g., `hasCompletedOnboarding`, unit system) persist via `@AppStorage` in `UserDefaults`, enabling instant relaunch routing without CoreData overhead.  [oai_citation:4‡perpet.io](https://perpet.io/blog/what-should-be-ui-ux-design-of-fitness-app/?utm_source=chatgpt.com)  

## 3. Personalisation Logic
* **Volume seed** – Compound-lift set targets scale by `(experience × frequency)` table inside `OnboardingPlanPreviewView` (e.g., 12 sets for intermediate/3-day).  
* **Frequency guardrails** – Options cap at 7 d to respect WHO & ACSM guidance: adults should strength-train ≥2 d · wk⁻¹.  [oai_citation:5‡acsm.org](https://acsm.org/resistance-exercise-health-infographic/?utm_source=chatgpt.com) [oai_citation:6‡who.int](https://www.who.int/initiatives/behealthy/physical-activity?utm_source=chatgpt.com)  
* **Plan start day** – Calendar rotates to user locale so training days mirror first weekday.  

## 4. Design & UX Principles
| Principle | Implementation |
|-----------|----------------|
| Brand cohesion | Phoenix purple gradient `#8C3DFF → #4925D6` on CTAs & selection borders. |
| Touch targets  | All buttons ≥ 56 pt high; toggles respect 44 × 44 pt min.  [oai_citation:7‡eleken.co](https://www.eleken.co/blog-posts/toggle-ux?utm_source=chatgpt.com) |
| Choice count   | ≤ 7 options per view to optimise recognition speed.  [oai_citation:8‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines?utm_source=chatgpt.com) |
| Micro-copy     | Each screen has ≤ 120 chars of body text for rapid scanning. |

## 5. Accessibility & Compliance
* **VoiceOver** – Custom `accessibilityLabel` & `.isSelected` traits on all controls for state context.  [oai_citation:9‡acsm.org](https://acsm.org/education-resources/trending-topics-resources/physical-activity-guidelines/?utm_source=chatgpt.com)  
* **Dynamic Type** – `font(.system(: , design: .rounded))` scales with system settings.  
* **Motion-safe** – Animations use spring damping ≥ 0.8 to minimise vestibular discomfort.  

## 6. Analytics & Success Metrics
Metric | Target | Rationale
------ | -------|-----------
Onboarding completion rate | ≥ 85 % | Industry leaders hit 80–90 % after iterative polish.  [oai_citation:10‡sendbird.com](https://sendbird.com/blog/mobile-app-onboarding?utm_source=chatgpt.com)
Day-7 retention            | ≥ 50 % | Smooth onboarding can double baseline retention.  [oai_citation:11‡uxcam.com](https://uxcam.com/blog/mobile-app-retention-benchmarks/?utm_source=chatgpt.com)
Push-opt-in rate           | ≥ 60 % | Asking after value explanation lifts acceptance.  [oai_citation:12‡sendbird.com](https://sendbird.com/blog/mobile-app-onboarding?utm_source=chatgpt.com)  

## 7. File Manifest

Features/
└─ Onboarding/
└─ Sources/
└─ onboarding/
├─ OnboardingView.swift
├─ OnboardingViewModel.swift
├─ OnboardingGoalView.swift
├─ OnboardingExperienceView.swift
├─ OnboardingFrequencyView.swift
├─ OnboardingPreferencesView.swift
├─ OnboardingPlanPreviewView.swift
└─ OnboardingOverview.md ← you’re here

Maintain this document as a living spec; update sections when business logic or HIG revisions change.  

---

### References  
1. Apple HIG – Launching & Onboarding  [oai_citation:13‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines?utm_source=chatgpt.com) [oai_citation:14‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/launching?utm_source=chatgpt.com)  
2. UXCam – Retention benchmarks 2025  [oai_citation:15‡uxcam.com](https://uxcam.com/blog/mobile-app-retention-benchmarks/?utm_source=chatgpt.com)  
3. NudgeNow – Mobile retention stats 2024  [oai_citation:16‡nudgenow.com](https://www.nudgenow.com/blogs/mobile-app-retention-rate?utm_source=chatgpt.com)  
4. Perpetio – Fitness app onboarding best practices  [oai_citation:17‡perpet.io](https://perpet.io/blog/what-should-be-ui-ux-design-of-fitness-app/?utm_source=chatgpt.com)  
5. ACSM – Resistance Exercise for Health 2024  [oai_citation:18‡acsm.org](https://acsm.org/resistance-exercise-health-infographic/?utm_source=chatgpt.com)  
6. WHO – Muscle-strengthening 2 d · wk⁻¹  [oai_citation:19‡who.int](https://www.who.int/initiatives/behealthy/physical-activity?utm_source=chatgpt.com)  
7. Eleken – Toggle UX touch target sizes  [oai_citation:20‡eleken.co](https://www.eleken.co/blog-posts/toggle-ux?utm_source=chatgpt.com)  
8. Sendbird – Onboarding conversion goals  [oai_citation:21‡sendbird.com](https://sendbird.com/blog/mobile-app-onboarding?utm_source=chatgpt.com)  
9. JUX – Toggle usability design guidelines  [oai_citation:22‡uxpajournal.org](https://uxpajournal.org/design-user-interface-toggles-usability/?utm_source=chatgpt.com)  
10. Apple Dev – Accessibility labels for segmented controls  [oai_citation:23‡acsm.org](https://acsm.org/education-resources/trending-topics-resources/physical-activity-guidelines/?utm_source=chatgpt.com)  
11. Health.com – Exercise volume guidelines  [oai_citation:24‡health.com](https://www.health.com/fitness/how-much-exercise-you-need?utm_source=chatgpt.com)  
12. VerywellHealth – Vigorous 1.5 min activity study  [oai_citation:25‡verywellhealth.com](https://www.verywellhealth.com/short-bursts-of-vigorous-exercise-heart-disease-risk-8760538?utm_source=chatgpt.com)  
