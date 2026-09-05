---
phase: 4
title: "P2 — Port the mouse-moved event tap from upstream/macos-26"
status: pending
priority: P2
effort: "0.25 day"
dependencies: [3]
release: "v1.4.0 — this phase never tags; see Release coupling"
rescoped: 2026-09-05
rescoped-from: "P2 — Port HID event taps + sourcePID from upstream/macos-26"
---

# Phase 4: P2 — Port the mouse-moved event tap

> **Rescope note, 2026-09-05.** This phase originally claimed two sub-ports: a
> `HIDEventManager` rewrite "replacing runloop event monitors with low-level
> `CGEvent` taps to stop click drops", and a `sourcePID` computed property on
> `WindowInfo`. Scouting `upstream/macos-26` found both descriptions false —
> see [`plans/reports/scout-260905-phase-04-contract-check.md`](../reports/scout-260905-phase-04-contract-check.md)
> for the evidence. In short: upstream turned exactly one monitor into a tap and
> it is the hover one; the dropped-click work lives in `MenuBarItemManager.swift`,
> which this phase's own OUT OF SCOPE section forbids; and `sourcePID` is an XPC
> round-trip that structurally depends on Phase 5's service. The maintainer chose
> on 2026-09-05 to narrow this phase to the one change that is real and in-gate,
> move `sourcePID` into Phase 5 where its dependency actually points, and re-plan
> the dropped-click work as Phase 6.

## Overview

Port upstream commit `292556f` — "Replace `mouseMoved` event monitor with an
event tap" — onto `Skein/Events/EventManager.swift`. It moves the show-on-hover
trigger off an `NSEvent` runloop monitor and onto a listen-only `CGEvent` tap at
`.hidEventTap`. Upstream's stated motivation is the one this phase adopts:

> "This should fix some performance issues that occur during mouse tracking
> operations (e.g. highlighting a button on hover)."

Nothing else from upstream is in this phase.

## Requirements

### Functional

- Show-on-hover keeps working exactly as it does today: sweeping the mouse into
  the menu bar reveals the hidden section under the same conditions and after
  the same delay.
- Hover-driven work does not skip frames when the mouse sweeps the menu bar
  rapidly.
- If the tap's mach port cannot be created, the app still launches and every
  other feature still works. `EventTap` already logs and returns without a port
  in that case (`Skein/Events/EventTap.swift:132`), so this is a check, not new
  code.
- A hover tap that the system disables must come back on its own. macOS disables
  an event tap whose callback overruns, and `.mouseMoved` at `.hidEventTap` is
  the highest-volume stream in the app, so this is the one new failure mode the
  change introduces.

### Non-Functional

- No new Swift dependencies, no new files.
- Diff confined to `Skein/Events/EventManager.swift`, `Skein/Events/EventTap.swift`
  and `CHANGELOG.md`.
- Under 80 lines of Swift.
- No behavior change on macOS 14.

## Architecture

`Skein/Events/EventTap` is already present and is byte-identical in its
initializer to upstream's at `292556f^`:

```swift
init(
    label: String = #function,
    options: CGEventTapOptions,
    location: Location,
    place: CGEventTapPlacement,
    types: [CGEventType],
    callback: @MainActor @escaping (_ proxy: Proxy, _ type: CGEventType, _ event: CGEvent) -> CGEvent?
)
```

It already has `Location.hidEventTap` and `enable()` / `disable()`;
`UniversalEventMonitor` already has `start()` / `stop()`. So the port is three
edits inside one file:

1. Replace `mouseMovedMonitor` (a `UniversalEventMonitor(mask: .mouseMoved)`)
   with `mouseMovedTap`, an `EventTap(options: .listenOnly, location:
   .hidEventTap, place: .tailAppendEventTap, types: [.mouseMoved])`.
2. Type `allMonitors` as `[any EventMonitorProtocol]` so the array can hold both
   kinds.
3. Add the private `EventMonitorProtocol` (`start()` / `stop()`) at the bottom of
   the file, with conformances for `UniversalEventMonitor` and `EventTap`.

A fourth edit is needed in `Skein/Events/EventTap.swift`, which `292556f` did
not carry because upstream had not written it yet:

4. In `performCallback` (`Skein/Events/EventTap.swift:152`), re-enable the tap
   when the system hands back `.tapDisabledByUserInput` or
   `.tapDisabledByTimeout`, and swallow that notification event. Upstream added
   exactly this later, in `eb5d14a`:

   ```swift
   if type == .tapDisabledByUserInput || type == .tapDisabledByTimeout {
       tap.enable()
       return nil
   }
   ```

   Without it a timed-out hover tap stays dead until the app is relaunched, and
   the user sees show-on-hover silently stop working. Skein's three existing
   `EventTap` users in `MenuBarItemManager.swift` are short-lived taps for click
   synthesis and are barely exposed to this; a long-lived `.mouseMoved` tap is.

**Two adaptations from upstream.**

- Upstream's pre-image had already refactored handlers to take `appState:` and
  `screen:` (commit `f17729e`, which Skein has not taken). Skein's
  `handleShowOnHover()` takes no arguments. Keep Skein's call shape; do not pull
  `f17729e` in to make the diff match.
- Upstream's `EventTap` is not `@MainActor`; Skein's is
  (`Skein/Events/EventTap.swift:11`), and `performCallback` is
  `nonisolated static`. Reach `enable()` through `MainActor.assumeIsolated`, not
  a `Task`: the tap's run loop source is added to the `CFRunLoopGetCurrent()`
  captured at init on the main actor, so the callback already runs on the main
  thread, and a `Task` hop would let events arrive before the tap is back.

## Related Code Files

- Modify: `Skein/Events/EventManager.swift`
- Modify: `Skein/Events/EventTap.swift` (tap re-enable only — nothing else)
- Modify: `CHANGELOG.md` (`[Unreleased]` section — do not bump version)

## OUT OF SCOPE

- `Skein/Events/EventMonitors/*` — unchanged.
- Everything in `Skein/Events/EventTap.swift` except the re-enable branch. Do
  not adopt upstream's later `EventTap` rewrite (`type:location:placement:option:`
  initializer, dropped `@MainActor`, `Proxy` removal) — the existing three call
  sites in `MenuBarItemManager.swift` depend on the current signature.
- Renaming `EventManager` to `HIDEventManager`. That rename (`f8828cd`) comes
  with an enabled-state stack and reworked handler signatures; it is not needed
  for this change and would blow the diff budget.
- Upstream's `EventMonitor.swift` factory (`EventMonitor.universal(for:)`).
- `MenuBarItemManager.swift` in any form — Phase 6 owns it.
- `sourcePID` in any form — Phase 5 owns it.
- Any other upstream commit, however small it looks.

## Implementation Steps

1. Branch `feat/phase-04-p2-mouse-moved-event-tap` from `main`.
2. `git show 292556f` for the reference diff. Do not `git cherry-pick` it — the
   pre-image differs (path rename plus the `f17729e` handler signatures Skein
   never took), so a cherry-pick produces a conflict whose resolution is the
   manual edit anyway. Apply the three edits by hand and cite the upstream SHA
   in the commit body.
3. `xcodebuild build -scheme Skein -project Skein.xcodeproj -configuration Release -derivedDataPath <scratch>/DD CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO` — exit 0, warning delta zero against `main`.
4. Add a `CHANGELOG.md` `[Unreleased]` → `### Changed` line.
5. **Manual test protocol** (written here, maintainer executes):
   - Sweep the mouse into and out of the menu bar 20 times. The hidden section
     shows and rehides each time, with no missed reveal.
   - Hold the pointer still just outside the menu bar for 10 seconds. No
     spurious reveal.
   - With "Show on hover" disabled in Settings, sweep 10 times. Nothing reveals.
   - Watch Activity Monitor while sweeping continuously for 30 seconds. Skein's
     CPU should not exceed its pre-change baseline, and hover must still work at
     the end of the sweep — that is the tap-re-enable path under test.
6. Open PR `feat(events): move show-on-hover onto a CGEvent tap (upstream 292556f)`.

## PM VERIFICATION CHECKLIST

- [ ] `git diff main..HEAD --stat` shows exactly 3 files: `Skein/Events/EventManager.swift`, `Skein/Events/EventTap.swift`, `CHANGELOG.md`.
- [ ] Swift diff under 80 lines.
- [ ] `grep -n 'mouseMovedMonitor' Skein/Events/EventManager.swift` returns nothing.
- [ ] `grep -n 'mouseMovedTap' Skein/Events/EventManager.swift` returns the tap declaration and its entry in `allMonitors`.
- [ ] The tap is `options: .listenOnly` and `location: .hidEventTap` — a listen-only tap cannot swallow a user's event.
- [ ] `allMonitors` is typed `[any EventMonitorProtocol]` and still lists all five entries.
- [ ] `EventTap.performCallback` returns `nil` for `.tapDisabledByUserInput` and `.tapDisabledByTimeout` after calling `enable()`, and reaches it via `MainActor.assumeIsolated`.
- [ ] The three existing `EventTap(` call sites in `MenuBarItemManager.swift` are untouched and still compile against the unchanged initializer.
- [ ] Commit body cites upstream SHAs `292556f` and `eb5d14a`.
- [ ] `xcodebuild` exit 0, warning delta zero.
- [ ] No file outside Related Code Files touched.

## Success Criteria

- [ ] PR merged. This phase never runs `git tag`. See Release coupling below.
- [ ] Manual test protocol run by the maintainer with all four checks passing.

## Risk Assessment

- **Tap creation needs Accessibility, which a runloop monitor also needed.**
  `EventTap` logs and returns with no mach port if creation fails, so a denied
  permission degrades hover only, not the app. Signal: no reveal on hover after
  a fresh install before permissions are granted. Response: none needed — this
  matches current behavior, since `UniversalEventMonitor` is equally inert
  without permission.
- **Listen-only taps get disabled by the system under load.** macOS disables a
  tap whose callback overruns and posts `.tapDisabledByTimeout`. Verified: local
  `Skein/Events/EventTap.swift` does **not** handle those event types today —
  `grep -c tapDisabled` returns 0 — which is why the re-enable branch is part of
  this phase rather than deferred. Signal: hover stops working after sustained
  load and does not recover. Response: confirm the branch fires by checking the
  `EventTap` logger for a re-enable entry after a stress sweep.

## Release coupling

Phase 4 and Phase 5 are independent and may land in either order. **The version
bump to 1.4.0 belongs to whichever of the two merges second**, and that PR's
`CHANGELOG.md` entry describes both. If only one has merged when a release is
cut, the entry describes only what is on `main`.

`v1.4.0` is tagged and published by the **maintainer**, never by this phase —
see guardrail 1 in [`plan.md`](./plan.md). This phase stops at an open PR with
green CI.
