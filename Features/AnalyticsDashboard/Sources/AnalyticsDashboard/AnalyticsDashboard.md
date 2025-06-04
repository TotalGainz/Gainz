# Analytics Dashboard – Feature Doc

Gainz’s Analytics Dashboard distills complex training telemetry into a glance-able, motivational hub that drives daily decision-making without overwhelming the athlete. It marries Apple-style data-viz rules with strength-sport heuristics, delivering punchy visuals (radial PR rings, muscle heatmaps) backed by a clean, test-driven architecture. [oai_citation:0‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/charting-data?utm_source=chatgpt.com) [oai_citation:1‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/charts?utm_source=chatgpt.com)

## 1. Functional Overview  
The dashboard answers three questions every lifter cares about: **“How am I trending?”**, **“Where am I sore/under-trained?”**, and **“How do I stack up to peers?”** Each tile, chart, and leaderboard row is tappable, routing deeper via `AnalyticsCoordinator`. [oai_citation:2‡developer.apple.com](https://developer.apple.com/tutorials/swiftui/building-lists-and-navigation?utm_source=chatgpt.com)

### Core tiles  
| Tile | Purpose | Data Source |
| --- | --- | --- |
| Vital Stat | RHR, sleep, weight trend | `MetricsStore` |
| Strength Scorecard | PR progress vs targets | `PRRepository` |
| Muscle Heatmap | Volume balance & fatigue | `SessionAnalyzer` |
| Leaderboard | Social comparison | `FriendsAPI` |

## 2. Architecture  
Feature follows **MV-VM-C** + **Clean Modules**:  
``App → Features (UI) → Interactors (UseCases) → Repositories → DataStores``  
Routing lives in `AnalyticsCoordinator`, while each sub-view owns a lightweight ViewModel that exposes plain structs for previewability. [oai_citation:3‡swiftwithmajid.com](https://swiftwithmajid.com/2023/09/26/mastering-charts-in-swiftui-pie-and-donut-charts/?utm_source=chatgpt.com)

### Rendering pipeline  
1. **Store publisher** emits metric deltas.  
2. ViewModel formats to presentation models (_e.g._ `VitalStatTileModel`).  
3. SwiftUI view tree animates diffed collections (implicit `List`/`Grid` transitions). [oai_citation:4‡developer.apple.com](https://developer.apple.com/videos/all-videos/?q=SharePlay&utm_source=chatgpt.com)

## 3. UI Standards  
* **Charts:** Radial rings use **Swift Charts SectorMark** for crisp 120 fps arcs. [oai_citation:5‡swiftwithmajid.com](https://swiftwithmajid.com/2023/09/26/mastering-charts-in-swiftui-pie-and-donut-charts/?utm_source=chatgpt.com) [oai_citation:6‡lyvennithasasikumar.medium.com](https://lyvennithasasikumar.medium.com/ios-17-updates-enhancing-swift-charts-dca213155187?utm_source=chatgpt.com)  
* **Grids:** `LazyVGrid` with size-class-aware columns; tuned per performance guide. [oai_citation:7‡reddit.com](https://www.reddit.com/r/SwiftUI/comments/11mu1ur/bad_performance_with_lazyvgrid_in_ios_16/?utm_source=chatgpt.com) [oai_citation:8‡medium.com](https://medium.com/%40wesleymatlock/tuning-lazy-stacks-and-grids-in-swiftui-a-performance-guide-2fb10786f76a?utm_source=chatgpt.com)  
* **Colors & Typography:** Centralised in `ColorPalette.swift`; WCAG 2.2 AA contrast.  
* **Motion:** Spring animations capped at 0.4 s to avoid distraction.

## 4. Navigation & Deep Linking  
`AnalyticsRoute` enum enumerates every destination; `handleDeepLink` lets widgets/notifications push directly to a chart or PR card. The stack is wrapped in `NavigationStack` for state-restoration compliance. [oai_citation:9‡developer.apple.com](https://developer.apple.com/tutorials/swiftui/building-lists-and-navigation?utm_source=chatgpt.com)

## 5. Social Sharing  
`ShareCardGenerator` captures an off-screen branded card via **ImageRenderer** on iOS 16+ (fallback to `UIGraphicsImageRenderer`), then presents `UIActivityViewController` through a SwiftUI wrapper. [oai_citation:10‡youtube.com](https://www.youtube.com/watch?v=nQNnHOeGmU4&utm_source=chatgpt.com) [oai_citation:11‡hoyelam.medium.com](https://hoyelam.medium.com/share-sheet-uiactivityviewcontroller-within-swiftui-c2fb481663e6?utm_source=chatgpt.com) [oai_citation:12‡stackoverflow.com](https://stackoverflow.com/questions/58286344/presenting-uiactivityviewcontroller-from-swiftui-view?utm_source=chatgpt.com)

## 6. Accessibility & Inclusivity  
All custom rows expose `accessibilityLabel`/`Value` and respect Dynamic Type. VoiceOver hints announce rank movement in the leaderboard. [oai_citation:13‡developer.apple.com](https://developer.apple.com/documentation/swiftui/view-accessibility?utm_source=chatgpt.com) [oai_citation:14‡medium.com](https://medium.com/%40federicoramos77/making-custom-ui-elements-in-swiftui-accessible-for-voiceover-3e161365b5df?utm_source=chatgpt.com)

## 7. Performance & Testing  
* **Snapshot tests** via `iPhone 16, iOS 18.5` light/dark.  
* **SwiftLint + SwiftFormat** gate.  
* **Instruments»SwiftUI** checks diff-driven redraw cost for grids.  
* **Unit tests** mock repositories to hit 90 %+ coverage.

## 8. Extension Points  
* **Nutrition tiles** can slot next to Vital Stats when Gainz integrates food logs.  
* **Compare‐With-Coach** mode: inject coach-provided benchmarks into Leaderboard.  
* **Widgets**: lock-screen rings reuse `StrengthRingView`.

## 9. Related Apple Guidance  
* [Human Interface Guidelines – Charting Data] [oai_citation:15‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/charting-data?utm_source=chatgpt.com)  
* [HIG – Charts] [oai_citation:16‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/charts?utm_source=chatgpt.com)  
* [WWDC 24 – Advanced NavigationStack] [oai_citation:17‡developer.apple.com](https://developer.apple.com/tutorials/swiftui/building-lists-and-navigation?utm_source=chatgpt.com)  
* [Game Center Leaderboards & Highlights] [oai_citation:18‡developer.apple.com](https://developer.apple.com/help/app-store-connect/configure-game-center/configure-leaderboards/?utm_source=chatgpt.com) [oai_citation:19‡developer.apple.com](https://developer.apple.com/videos/play/wwdc2020/10619/?utm_source=chatgpt.com)  
