---
type: scout-report
created: 2026-09-05
plan: plans/260828-2226-audit-fixes-p0-p3/phase-04-p2-hid-source-pid-port.md
verdict: contract does not match upstream — phase cannot be executed as written
---

# Phase 4 contract check against `upstream/macos-26`

Read-only scout. No branch created, no files changed. Run because the phase's own
hard rule 5 says to stop and report rather than open a PR that breaches the
500-Swift-LOC / 6-file gate, and its Risk Assessment repeats that for the
cherry-pick manifest.

Fork point: `81c8ef3` "Update project files to latest Xcode".
17 upstream commits touch `Ice/Events/` since then; 22 touch
`Ice/MenuBar/MenuBarItems/MenuBarItemManager.swift`.

## Finding 1 — `HIDEventManager` is not a tap-based rewrite

The contract (line 15) describes sub-port A as "`HIDEventManager` replacing
runloop event monitors with low-level `CGEvent` taps to stop click drops and
missed hover transitions."

`upstream/macos-26:Ice/Events/HIDEventManager.swift` declares five monitors.
**Exactly one is an `EventTap`:**

| Monitor | Type upstream |
|---|---|
| `mouseDownMonitor` | `EventMonitor.universal(for: [.leftMouseDown, .rightMouseDown])` |
| `mouseUpMonitor` | `EventMonitor.universal(for: .leftMouseUp)` |
| `mouseDraggedMonitor` | `EventMonitor.universal(for: .leftMouseDragged)` |
| `mouseMovedTap` | **`EventTap(type: .mouseMoved, location: .hidEventTap, …)`** |
| `scrollWheelMonitor` | `EventMonitor.universal(for: .scrollWheel)` |

Every click path is still an NSEvent runloop monitor upstream. The one tap is
the hover path, and upstream's own commit message for it says why:

> `292556f` — "Replace `mouseMoved` event monitor with an event tap. This should
> fix some performance issues that occur during mouse tracking operations
> (e.g. highlighting a button on hover)."

Hover performance, not dropped clicks.

`HIDEventManager.swift` (577 lines) is `EventManager.swift` renamed and reworked
across 17 commits, not a new file added alongside it. A faithful port also drags
in `Ice/Events/EventMonitor.swift` (396 lines, replacing our four
`Skein/Events/EventMonitors/*.swift`, 396 lines total) and the reworked
`EventTap.swift`. That is ~1200 changed Swift lines across 7+ files — past both
gates on its own.

## Finding 2 — the dropped-click fix is in a file the phase puts out of scope

Functional requirement 1 ("clicking a menu bar item Skein manages must land on
that item every time") is delivered by the item-event-handling work, not by the
event manager:

| Commit | Date | Size |
|---|---|---|
| `8d4b6a5` Improve menu bar item movement | 2025-08-07 | 9 files, +642 / −481 |
| `e3c63f2` Improve menu bar item event handling | 2025-08-17 | 5 files, +510 / −329 |
| `b0a1942` Improve menu bar item handling | 2025-08-22 | 4 files, +298 / −430 |

All three centre on `MenuBarItemManager.swift`, which the phase's OUT OF SCOPE
section explicitly defers: *"Any refactor of `MenuBarItemManager.swift`
(deferred to a separate plan even though it lives in the same subsystem)."*

So the phase forbids the only code that satisfies its own first functional
requirement, and that code is ~1450 insertions — three times the phase's budget.

## Finding 3 — sub-port B's premise is false, and its dependency runs backwards

The contract (line 39) names "`upstream/macos-26:Ice/Ice/Utilities/WindowInfo.swift`
new `sourcePID` computed property" using `_CGSCopyWindowProperty`.

`git show upstream/macos-26:Shared/Utilities/WindowInfo.swift | grep -c sourcePID`
returns **0**. There is no such property, and `_CGSCopyWindowProperty` is not how
upstream solves it.

What upstream actually does: `sourcePID` is a **stored** property on
`MenuBarItem`, filled by an async XPC round-trip —

```swift
// Ice/MenuBar/MenuBarItems/MenuBarItem.swift:249
let sourcePID = await MenuBarItemService.Connection.shared.sourcePID(for: window)
```

— answered inside the XPC service by `SourcePIDCache.shared.pid(for: window)`
(`MenuBarItemService/Listener.swift:35`), which walks the **Accessibility** API
(`AXHelpers.extrasMenuBar`, `AXHelpers.children`) rather than CGS. Upstream's own
comment in `SourcePIDCache.swift` explains the choice:

> "Since calls to Accessibility are thread blocking, we do most of the heavy
> lifting in a dedicated XPC service, which we then call asynchronously from the
> main app."

That service is `MenuBarItemService` — **the subject of Phase 5**. Phase 4
declares `dependencies: [3]` and puts "XPC service extraction (Phase 5)" out of
scope, so as written sub-port B depends on a phase that is scheduled after it.

(`AXSwift` is already a Skein dependency, used in `MenuBarManager.swift` and
`Permission.swift`, so the AX approach adds no new package — it needs the XPC
*target*, which is what Phase 5 creates.)

## What is genuinely deliverable inside the phase's gates

`292556f` alone, adapted onto `Skein/Events/EventManager.swift`:

- upstream stat: **1 file, +34 / −9**
- our local `EventTap` init is byte-identical to upstream's at `292556f^`
  (`label:options:location:place:types:callback:`), our `EventTap` already has
  `Location.hidEventTap` and `enable()`/`disable()`, and our
  `UniversalEventMonitor` already has `start()`/`stop()` — so the diff applies
  with one adaptation: our `handleShowOnHover()` takes no arguments where
  upstream's takes `appState:screen:` (upstream refactored that in `f17729e`,
  which we have not taken).

That delivers functional requirement 2 (hover transitions) and nothing else it
promises.

## Recommendation

Phase 4 cannot ship as written. The maintainer's call is between narrowing it to
the hover tap, resequencing it behind Phase 5, or re-planning the whole macOS 15+
reliability effort against what upstream actually did.

## One more thing the contract mis-frames: which macOS this is for

The phase is titled and justified as fixing "real Skein bugs on macOS 15+
Sequoia". But upstream's `SourcePIDCache.swift` says the ownership problem it
solves is specific to a later OS:

> "Originally, we used the CGWindowList API to get the window's owning process
> (`kCGWindowOwnerPID`), which was always the source process. However, **as of
> macOS 26**, item windows are owned by the Control Center."

The maintainer's own machine reports `macOS 26.6.2 (25G83)`. So sub-port B is not
a forward-looking nicety for a future OS — it is the mechanism that makes menu
bar item identification correct on the machine Skein is developed and used on
today. That raises its priority relative to the hover tap, and it is the sub-port
that structurally cannot be built until Phase 5 exists.
