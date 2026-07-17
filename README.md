
[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)]()
[![macOS Support](https://img.shields.io/badge/macOS-13.0+-green)]()
[![iOS Support](https://img.shields.io/badge/iOS-16.0+-green)]()
[![tvOS Support](https://img.shields.io/badge/tvOS-16.0+-green)]()
[![watchOS Support](https://img.shields.io/badge/watchOS-9.0+-green)]()
[![visionOS Support](https://img.shields.io/badge/visionOS-1.0+-green)]()

## RateBoi

Getting a user to do something at the wrong moment — write a review, grant a permission, try a feature — is how you lose them. **RateBoi** is an open-source dependency [(GNU v3)](https://github.com/thebarbican19/RateBoi?tab=GPL-3.0-1-ov-file) for Apple platforms that fires a callback **when the timing is right** — **Orrivo - Life Intelligence made by Joe Barbour**.

You register **named triggers**. Each trigger fires once (or re-arms on a cooldown) when its conditions are met — a number of **distinct active days**, a number of **days since first use**, and/or a **score threshold** you feed with positive actions. When a trigger fires you get a callback, a Combine event, and a `@Published` set you can bind to. Use it for an App Store review prompt, an onboarding nudge, a "try this feature" hint — anything timed.

### Install

Swift Package Manager:

`https://github.com/thebarbican19/RateBoi`

### Configure

Call once at launch. Pass an App Group suite to share state across your app and its extensions:

```swift
RateBoi.main.configure(suite: "group.com.yourapp", debug: true)
```

Suite is optional (defaults to `.standard`). Debug prints trigger activity.

### Register triggers

```swift
RateBoi.main.register([
    // Nudge to enable a feature after 3 distinct days of use, re-ask every 4 days.
    RateTrigger(id: "recording_nudge", days: 3, cooldown: 4 * 86_400),

    // Ask for a review once a "delight" score of 30 is reached.
    RateTrigger(id: "rating", score: 30, scoring: .delight),

    // Fire once, 7 days after install AND after 3 active days (both required).
    RateTrigger(id: "pro_upsell", days: 3, sinceInstall: 7, mode: .all)
])
```

A trigger only checks the conditions you set (non-zero). `mode` (`.all` / `.any`) combines them when you set more than one.

### Drive it

```swift
RateBoi.main.active()                       // call on app active — stamps a distinct day + re-evaluates
RateBoi.main.increment("rating")            // positive action (delight auto-weights by momentum)
RateBoi.main.increment("rating", points: 5) // or add explicit points
RateBoi.main.penalize("rating")             // an error happened — cool the score down
```

### React

```swift
RateBoi.main.on("rating") {
    RateBoi.main.review()                   // StoreKit review prompt convenience
}

RateBoi.main.on("recording_nudge") {
    // present your own UI…
    RateBoi.main.resolve("recording_nudge") // …and stop asking once they do it
}

// Or observe the stream / bound state:
RateBoi.main.events.sink { id in … }
// @Published var fired: Set<String>
```

### Lifecycle

- `resolve(id)` — the user did the thing; never fire again.
- `snooze(id, days:)` — hold off for a while.
- `reset(id)` / `reset()` — clear a trigger (or everything). Handy for a debug menu.

### Scoring modes

- `.manual` — you own the points. `increment(id)` adds 1; `increment(id, points:)` adds any amount.
- `.delight` — momentum-weighted: positive actions in quick succession score more, a recent `penalize` softens the next gain. Great for review timing.

### Persistence

Everything lives in `UserDefaults` (your suite), namespaced per trigger (`rateboi.<id>.*`) plus global `rateboi.install` / `rateboi.days`. No server, no tracking.
