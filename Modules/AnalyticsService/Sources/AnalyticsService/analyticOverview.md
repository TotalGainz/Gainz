# AnalyticsService Overview
Gainz ▸ Modules/AnalyticsService  
_Last updated: 2025-05-27_

---

## 1. Purpose
AnalyticsService captures **training-centric telemetry** and app lifecycle events, transforms them into actionable insights for the athlete, and—when permitted—uploads anonymised batches to the Gainz cloud for aggregate modelling.  
⚠️ **Scope limits**: we do **not** collect HRV, recovery scores, velocity metrics, or any personally identifying physiological data.

---

## 2. Event Taxonomy
| Category        | Event                                | Payload Snapshot (keys → types)                                  |
|-----------------|--------------------------------------|------------------------------------------------------------------|
| **Workout**     | `setLogged`                          | `exerciseId: UUID`, `weight: Double`, `reps: Int`, `rpe: Int`    |
|                 | `workoutCompleted`                   | `sessionId: UUID`, `duration: TimeInterval`, `totalVolume: Int`  |
| **Planner**     | `mesocycleCreated`                   | `planId: UUID`, `weeks: Int`, `goal: String`                     |
| **AppLifecycle**| `appOpened`                          | `timestamp: Date`                                                |
|                 | `onboardingCompleted`                | `daysToComplete: Int`                                            |
| **UX**          | `navigationTabChanged`               | `from: Tab`, `to: Tab`                                           |

All events conform to `AnalyticsEvent` protocol (see `Sources/AnalyticsEvent.swift`). Payloads are **immutable structs**—no `[String: Any]` dictionaries allowed.

---

## 3. Local Pipeline

Combine Publisher ─▶ EventBuffer (Deque) ─▶ Reducers ─▶ CorePersistence.AnalyticsStore

* **Publishers** emit on a background queue to avoid blocking UI.  
* **Reducers** update rolling metrics (e.g., weekly volume per muscle group).  
* **Store** persists to Core Data with a write-coalescing throttle (250 ms).

---

## 4. Remote Pipeline

Batcher (≤ 50 events / 60 s) ─▶ HMAC-signed JSON ─▶ HTTPS POST /v1/ingest

* **Batcher** flushes on size or time window—whichever hits first.  
* **Signing**: SHA-256 HMAC using device-scoped key from Keychain.  
* **Retry**: exponential back-off (1 s → 64 s) with jitter, max 5 attempts.

---

## 5. Privacy & GDPR
* Device UUID is hashed (SHA-256) **client-side** before upload.  
* No ad identifiers, e-mail, or real names are transmitted.  
* Users can toggle **“Share Anonymous Usage”** in Settings → Privacy.  
* `DELETE /v1/data/{hash}` endpoint supports right-to-erasure within 30 days.

---

## 6. Performance Budgets
| Stage               | Budget        |
|---------------------|---------------|
| Event publish cost  | < 0.2 ms      |
| Reducer pass        | < 0.5 ms      |
| Batch encode (50)   | < 3 ms        |
| Network upload      | < 20 kB/req   |

---

## 7. Extending the Event Schema
1. **Create** a new struct conforming to `AnalyticsEventPayload`.  
2. **Add** a `case` to `AnalyticsEvent.Name`.  
3. **Document** the payload in this file’s table.  
4. **Ship** behind a `RemoteConfig.flag("analytics_vNext")` if uncertain.

---

_AnalyticsService must remain lean, privacy-respecting, and athlete-centric—collect only what improves training decisions and nothing more._
