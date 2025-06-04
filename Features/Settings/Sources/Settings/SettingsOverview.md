# Settings Feature — Overview

Gainz’s **Settings** module centralises all end-user preferences—dark mode, haptics, and push-notification consent—behind a clean SwiftUI Form that conforms to Apple’s Human-Interface-Guidelines (HIG) for toggles and grouped lists. [oai_citation:0‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines/toggles?utm_source=chatgpt.com) [oai_citation:1‡developer.apple.com](https://developer.apple.com/design/human-interface-guidelines?utm_source=chatgpt.com)

---

## 1. Module Purpose

* Provide a single location for global UX toggles (appearance, feedback, notifications).  
* Persist choices via `@AppStorage`, guaranteeing automatic two-way sync with `UserDefaults`. [oai_citation:2‡medium.com](https://medium.com/%40ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c?utm_source=chatgpt.com)  
* Route deeper flows (e.g., licence list, web links) through a Coordinator for testable navigation. [oai_citation:3‡medium.com](https://medium.com/%40dikidwid0/mastering-navigation-in-swiftui-using-coordinator-pattern-833396c67db5?utm_source=chatgpt.com) [oai_citation:4‡swiftanytime.com](https://www.swiftanytime.com/blog/coordinator-pattern-in-swiftui?utm_source=chatgpt.com)  
* **Explicit non-goals:** HRV dashboards, velocity tracking, or any training analytics—those live in separate features.

---

## 2. Architecture

| Layer | File | Responsibility |
|-------|------|----------------|
| **View** | `SettingsView.swift` | SwiftUI Form & section layouts |
| **View-Model** | `SettingsViewModel.swift` | ObservableObject, persistence, DI |
| **Coordinator** | `SettingsCoordinator.swift` | Owns `NavigationStack` & deep links |
| **Sub-View** | `NotificationSettingsView.swift` | Permission flow & system redirects |

The ViewModel injects `AppearanceManaging` and `FeedbackManaging` protocols, decoupling UI code from concrete singletons and enabling fast unit tests. State changes are published on the main actor, satisfying Swift’s strict concurrency rules. [oai_citation:5‡stackoverflow.com](https://stackoverflow.com/questions/3639859/handling-applicationdidbecomeactive-how-can-a-view-controller-respond-to-the?utm_source=chatgpt.com)

---

## 3. Preference Keys

| Key | Default | Notes |
|-----|---------|-------|
| `darkModeEnabled` | `false` | Immediately flips `UITraitCollection` via `AppearanceManager`. [oai_citation:6‡stackoverflow.com](https://stackoverflow.com/questions/61912363/swiftui-how-to-implement-dark-mode-toggle-and-refresh-all-views?utm_source=chatgpt.com) [oai_citation:7‡medium.com](https://medium.com/%40husnainali593/implementing-dark-mode-in-your-ios-app-with-swiftui-646e33ee34ad?utm_source=chatgpt.com) |
| `hapticsEnabled` | `true` | Propagated to `FeedbackManager`. |
| `notificationsEnabled` | `true` | Mirrors UNNotification status on launch. |

All three keys are namespaced inside an enum to avoid typo bugs and simplify refactor searches.

---

## 4. Notification Flow

1. **Status Fetch** – `UNUserNotificationCenter.current().getNotificationSettings` hydrates `authorizationStatus` on view appearance. [oai_citation:8‡developer.apple.com](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications?utm_source=chatgpt.com)  
2. **Request** – The user taps **Enable Notifications**, triggering `requestAuthorization(options:)` with `.alert`, `.badge`, `.sound`. [oai_citation:9‡developer.apple.com](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization%28options%3Acompletionhandler%3A%29?utm_source=chatgpt.com)  
3. **Deep Link** – If permission is denied, we present an alert plus a button that opens **Settings › Notifications** with `UIApplication.openNotificationSettingsURLString`. [oai_citation:10‡developer.apple.com](https://developer.apple.com/documentation/uikit/uiapplication/opennotificationsettingsurlstring?utm_source=chatgpt.com) [oai_citation:11‡developer.apple.com](https://developer.apple.com/documentation/uikit/uiapplication/opennotificationsettingsurlstring?changes=_4_10&utm_source=chatgpt.com)  
4. **Live Updates** – A Combine subscription listens for `UIApplication.didBecomeActiveNotification` and refreshes status whenever the user returns from background. [oai_citation:12‡stackoverflow.com](https://stackoverflow.com/questions/3639859/handling-applicationdidbecomeactive-how-can-a-view-controller-respond-to-the?utm_source=chatgpt.com) [oai_citation:13‡medium.com](https://medium.com/better-programming/swiftui-tips-detecting-a-swiftui-apps-active-inactive-and-background-state-a5ff8acf5db1?utm_source=chatgpt.com)  

---

## 5. Styling & Theming

* Tint colour is `DesignSystem.Colors.phoenixAccent`, maintaining brand identity across interactive elements.  
* Forms use grouped-inset style on iOS 17+, matching modern HIG aesthetics. [oai_citation:14‡developer.apple.com](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization%28options%3Acompletionhandler%3A%29?utm_source=chatgpt.com)  
* Light/dark palettes rely on dynamic asset catalog entries governed by `darkModeEnabled`.

---

## 6. Package & Build

The feature ships as a dynamic Swift package (`Settings/Package.swift`) declaring explicit dependencies on `CoreUI`, `CorePersistence`, and `DesignSystem`. Strict concurrency is enabled via `-enable-bare-slash concurrency` to future-proof for Swift 5.10. [oai_citation:15‡medium.com](https://medium.com/%40guycohendev/local-spm-part-2-mastering-modularization-with-swift-package-manager-xcode-15-16-d5a11ddd166c?utm_source=chatgpt.com) [oai_citation:16‡forums.swift.org](https://forums.swift.org/t/use-a-dynamic-library-in-a-swift-package-on-linux/59510?utm_source=chatgpt.com)

---

## 7. Testing Strategy

* **Unit** – Verify default values, persistence round-trips, and dependency mocks (e.g., appearance toggling).  
* **UI** – Snapshot tests for both Light and Dark modes.  
* **Integration** – Simulator automation for notification-permission flows, ensuring deep link opens correct bundle path.

---

## 8. Extensibility

* Add future preferences (e.g., **Language**, **Analytics Opt-Out**) by extending `SettingsKey` and injecting new rows into `SettingsView`.  
* Coordinator enum scales linearly for new destinations—no changes required to root stack. [oai_citation:17‡medium.com](https://medium.com/%40dikidwid0/mastering-navigation-in-swiftui-using-coordinator-pattern-833396c67db5?utm_source=chatgpt.com) [oai_citation:18‡swiftanytime.com](https://www.swiftanytime.com/blog/coordinator-pattern-in-swiftui?utm_source=chatgpt.com)

---

© Gainz Coaching 2025. All rights reserved.
