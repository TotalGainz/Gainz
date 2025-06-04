# Profile Feature — Technical & UX Overview  
_Gainz · Phoenix Build_  

## 1. Purpose  
The **Profile** feature centralises everything about the athlete: identity, body-metric snapshots, lifetime training résumé, data-export utilities, and privacy settings. It does **not** surface HRV or bar-velocity analytics, keeping scope aligned with v8 roadmap.  

## 2. High-Level Anatomy  

| Layer | Component | Responsibility |
|-------|-----------|----------------|
| **UI** | `ProfileView`, `StatsSummaryView`, `HistoryListView`, `DataExportView` | Declarative SwiftUI surfaces |
| **State** | `ProfileViewModel`, `HistoryListViewModel`, `DataExportViewModel` | @Published bindings + async/await side-effects |
| **Navigation** | `ProfileCoordinator` (`NavigationStack` + `path`) | Routes between profile root, edit, settings, history, and export screens, enabling deep-links |
| **Domain** | `UserProfile`, `BodyMetrics`, `WorkoutSession`, `StatsSummary` | Immutable structs from **Domain** module |
| **Services** | `UserProfileRepository`, `CalculateMetricsUseCase`, `WorkoutSessionRepository`, `ExportDataUseCase`, `HealthKitSyncManager` | Persistence, analytics, HealthKit, and file export logic |

### 2.1 View Hierarchy  

ProfileCoordinator
└─ ProfileView
├─ StatsSummaryView
├─ HistoryListView  → WorkoutDetailView
└─ DataExportView   → iOS share-sheet

## 3. UX & Visual Design  

* **Human-centred defaults** — Typography and spacing follow Apple HIG tokens for readability. [oai_citation:0‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines?utm_source=chatgpt.com)  
* **Responsive grids** (`LazyVGrid`) adapt from 2→3 columns based on width, keeping metric cards legible on iPad. Performance tuning leverages item culling guidance. [oai_citation:1‡medium.com](https://medium.com/%40wesleymatlock/tuning-lazy-stacks-and-grids-in-swiftui-a-performance-guide-2fb10786f76a?utm_source=chatgpt.com)  
* **Conversational dates** via `RelativeDateTimeFormatter` (“3 weeks ago”) improve cognitive load in history headers. [oai_citation:2‡holyswift.app](https://holyswift.app/simplify-time-comparisons-in-swift-with-relativedatetimeformatter/?utm_source=chatgpt.com)  
* **Swipe actions** mirror Apple Mail for destructive flows, creating instant affordance recognition. [oai_citation:3‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/privacy?utm_source=chatgpt.com)  
* **File export** uses `fileExporter` + `FileDocument`, matching system privacy patterns. [oai_citation:4‡swiftwithmajid.com](https://swiftwithmajid.com/2023/05/10/file-importing-and-exporting-in-swiftui/?utm_source=chatgpt.com)  
* **Accessibility**: custom labels on metric tiles and history rows expose combined value + unit via `accessibilityLabel`, following new SwiftUI accessibility APIs. [oai_citation:5‡swiftwithmajid.com](https://swiftwithmajid.com/2021/10/06/custom-accessibility-content-in-swiftui/?utm_source=chatgpt.com)  

## 4. Navigation & Coordinator Pattern  

The module adopts MVVM-C to separate navigation from view state. A `@Published var path: [ProfileRoute]` drives `NavigationStack`, providing type-safe deep-linking and unit-testable flow logic. [oai_citation:6‡swiftanytime.com](https://www.swiftanytime.com/blog/coordinator-pattern-in-swiftui?utm_source=chatgpt.com) [oai_citation:7‡medium.com](https://medium.com/%40michaelmavris/how-to-use-swiftui-coordinators-1011ca881eef?utm_source=chatgpt.com)  

## 5. State Management  

`@StateObject` instantiation retains view-model identity across tab switches, while Combine pipelines broadcast updates (e.g., HealthKit authorisation) to both UI and services. Use of `@Published` follows best-practice guidelines to avoid over-notification. [oai_citation:8‡paigeshin1991.medium.com](https://paigeshin1991.medium.com/understanding-published-in-swiftui-risks-and-best-practices-e4a799981c35?utm_source=chatgpt.com)  

## 6. Data Flow  

1. **Load** — `ProfileViewModel.load()` concurrently pulls profile + body metrics with async/await.  
2. **Transform** — Metric calculations (`BMI`, `FFMI`, weight trend) run in `CalculateMetricsUseCase`.  
3. **Present** — Results propagate to metric tiles via `@Published`.  
4. **Export** — User chooses CSV/JSON ➞ `ExportDataUseCase` serialises domain structs ➞ `FileDocument` ➞ share-sheet. [oai_citation:9‡swiftwithmajid.com](https://swiftwithmajid.com/2023/05/10/file-importing-and-exporting-in-swiftui/?utm_source=chatgpt.com)  

## 7. Extensibility & Constraints  

* Adding new body metrics merely updates `BodyMetrics` and `MetricTile` factory; UI auto-binds.  
* History sectioning uses `Calendar.startOfWeek` helper—localisable without logic change.  
* **Out-of-scope** until v9: HRV charts, Velocity badges, social profile badges.  

## 8. Testing Strategy  

| Target | Approach |
|--------|----------|
| **ViewModels** | XCTest with mock repositories; validate state transitions & error paths. |
| **Coordinators** | Snapshot navigation path after simulated deep-link. |
| **Views** | XCUI screenshot snapshots in light/dark & Dynamic Type. |
| **Export** | Temp-dir write/read round-trip, asserting byte-equality across formats. |

## 9. Key References & Further Reading  

* SwiftUI pitfalls & performance tuning. [oai_citation:10‡medium.com](https://medium.com/%40veeranjain04/best-practices-in-swiftui-avoiding-common-pitfalls-15461027e777?utm_source=chatgpt.com) [oai_citation:11‡medium.com](https://medium.com/%40wesleymatlock/tuning-lazy-stacks-and-grids-in-swiftui-a-performance-guide-2fb10786f76a?utm_source=chatgpt.com)  
* Coordinator pattern deep-dive. [oai_citation:12‡swiftanytime.com](https://www.swiftanytime.com/blog/coordinator-pattern-in-swiftui?utm_source=chatgpt.com) [oai_citation:13‡medium.com](https://medium.com/%40michaelmavris/how-to-use-swiftui-coordinators-1011ca881eef?utm_source=chatgpt.com)  
* Apple HIG — profile & privacy. [oai_citation:14‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines?utm_source=chatgpt.com) [oai_citation:15‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/privacy?utm_source=chatgpt.com)  
* Lazy grid performance. [oai_citation:16‡medium.com](https://medium.com/%40wesleymatlock/tuning-lazy-stacks-and-grids-in-swiftui-a-performance-guide-2fb10786f76a?utm_source=chatgpt.com)  
* File import/export APIs. [oai_citation:17‡swiftwithmajid.com](https://swiftwithmajid.com/2023/05/10/file-importing-and-exporting-in-swiftui/?utm_source=chatgpt.com)  
* Custom accessibility. [oai_citation:18‡swiftwithmajid.com](https://swiftwithmajid.com/2021/10/06/custom-accessibility-content-in-swiftui/?utm_source=chatgpt.com)  
* RelativeDateTimeFormatter guide. [oai_citation:19‡holyswift.app](https://holyswift.app/simplify-time-comparisons-in-swift-with-relativedatetimeformatter/?utm_source=chatgpt.com)  

---

**Phoenix Principle**: every interaction should spark motivation—avatars, gradients, and rich stats combine to make progress feel tangible without cognitive overload.  
