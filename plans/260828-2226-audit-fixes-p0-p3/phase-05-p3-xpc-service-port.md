---
phase: 5
title: "P3 — Port the MenuBarItemService XPC source-PID resolver from upstream/macos-26"
status: completed
priority: P3
effort: "2.0 days"
dependencies: [3]
release: "v1.4.0 — see Release coupling below"
rescoped: 2026-09-05
rescoped-from: "P3 — Port XPC MenuBarItemService → v1.4.0"
---

# Phase 5: P3 — MenuBarItemService XPC source-PID resolver

> **Rescope note, 2026-09-05.** The previous contract described a service that
> does not exist upstream: an `@objc MenuBarItemServiceProtocol` over
> `NSXPCConnection` exposing `windowsForItem(withIdentifier:reply:)` and
> `frameForItem(withIdentifier:reply:)`, justified as "all AX queries move
> out-of-process so a hanging status item never beachballs the UI".
>
> Upstream's `MenuBarItemService` does exactly **one** thing: given a menu bar
> item window, return the pid of the process that *created* it. It uses
> Swift-native `XPCListener` / `XPCSession` carrying `Codable` enums, not
> `NSXPCConnection`. Moving blocking AX calls off the main thread is a stated
> side benefit in upstream's own header comment, not the feature.
>
> This file is rewritten against the verified upstream source. Evidence:
> [`plans/reports/scout-260905-phase-04-contract-check.md`](../reports/scout-260905-phase-04-contract-check.md),
> Finding 3. `dependencies` changed `[4]` → `[3]`: Phase 4 and Phase 5 are
> independent, and the sourcePID dependency runs Phase 4 → Phase 5, not the
> other way around.

## Overview

As of macOS 26, `kCGWindowOwnerPID` on a menu bar item window returns the
**Control Center** process, not the application that created the item. Skein
derives an item's identity from that pid:

- `MenuBarItem.owningApplication` → `NSRunningApplication(processIdentifier: window.ownerPID)`
  (`Skein/Utilities/WindowInfo.swift:55`, surfaced at `Skein/MenuBar/MenuBarItems/MenuBarItem.swift:64`)
- `MenuBarItemInfo.init(uncheckedItemWindow:)` builds the item's `Namespace`
  from `itemWindow.owningApplication?.bundleIdentifier`
  (`Skein/MenuBar/MenuBarItems/MenuBarItem.swift:228`) — this is the key used
  for section membership, `isMovable`, `canBeHidden`, and display names
- `MenuBarItemSpacingManager` relaunches apps by pid (`Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift:157`)
- `LayoutBarItemView` checks `Bridging.responsivity(for: item.ownerPID)`
  (`Skein/UI/LayoutBar/LayoutBarItemView.swift:132,161`)

The true owner can be recovered through the Accessibility API by matching an
item window's bounds against the frames of each running app's `extrasMenuBar`
children. AX calls are thread-blocking, so upstream does that work in a
dedicated XPC service and calls it asynchronously from the app.

The maintainer's machine is **macOS 26.6.2 (25G83)**, verified via `sw_vers`,
so this is live behaviour on the only machine that ships releases — not a
forward-looking port.

## Requirements

### Functional

- A new XPC service target whose product is embedded at
  `Skein.app/Contents/XPCServices/MenuBarItemService.xpc`, bundle id
  `com.ariadnev.Skein.MenuBarItemService`.
- The service answers a `sourcePID` request for a menu bar item window with the
  pid of the process that created the item, or `nil` when it cannot determine one.
- On macOS 26 and later, `MenuBarItem` carries a `sourcePID` resolved through
  the service, and item identity (`MenuBarItemInfo` namespace, display name,
  owning application) is derived from `sourcePID` rather than `ownerPID`.
- Below macOS 26, behaviour is **byte-for-byte what ships today**: `sourcePID`
  is `window.ownerPID`, no XPC session is created, no service is contacted.
- When the service is unreachable on macOS 26 — not installed, failed to
  launch, session cancelled — the app degrades to the legacy pid and keeps
  working. No item disappears, no crash, no hang.

### Non-Functional

- Bundle size increase ≤ 300 KB (baseline ZIP 6,178,231 bytes at v1.2.2).
- No new third-party dependencies. The service links **AXSwift**, which is
  already a project package dependency (`Skein.xcodeproj/project.pbxproj:406`).
- Deployment target stays `MACOSX_DEPLOYMENT_TARGET = 14.0` for both targets.
- No `NSXPCConnection`, no `@objc` protocol. Swift-native XPC only.

## What upstream actually ships

Verified by reading `upstream/macos-26` at HEAD. Line counts are `git show | wc -l`.

| Upstream path | Lines | Role |
|---|---|---|
| `Shared/Services/MenuBarItemService.swift` | 22 | service name + `Codable` `Request`/`Response` enums; compiled into **both** targets |
| `MenuBarItemService/main.swift` | 10 | `SourcePIDCache.shared.start()`, `Listener.shared.activate()`, `RunLoop.current.run()` |
| `MenuBarItemService/Listener.swift` | 91 | `XPCListener`, decodes `Request`, answers `Response` |
| `MenuBarItemService/SourcePIDCache.swift` | 230 | the AX work: per-app `extrasMenuBar` children matched by frame centre |
| `MenuBarItemService/Resources/Info.plist` | — | `XPCService` dict: `JoinExistingSession=true`, `RunLoopType=NSRunLoop`, `ServiceType=Application` |
| `Ice/MenuBar/MenuBarItems/MenuBarItemServiceConnection.swift` | 163 | client: `XPCSession` wrapper behind `OSAllocatedUnfairLock` |

The wire contract is 22 lines:

```swift
enum MenuBarItemService {
    static let name = "com.jordanbaird.Ice.MenuBarItemService"
}

extension MenuBarItemService {
    enum Request: Codable { case start; case sourcePID(WindowInfo) }
    enum Response: Codable { case start; case sourcePID(pid_t?) }
}
```

### Availability, verified against the SDK

- `XPCListener`, `XPCSession`, `XPCReceivedMessage` are
  `@available(macOS 14.0, macCatalyst 17.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)`
  in the `MacOSX26.5.sdk` swiftinterface — they clear Skein's 14.0 floor.
- `XPCPeerRequirement` and `isFromSameTeam()` are
  `@available(macOS 26.0, macCatalyst 26.0, *)`.
- Upstream therefore gates the **listener** at runtime: `XPCListener(service:requirement:)`
  under `if #available(macOS 26.0, *)`, plain `XPCListener(service:)` otherwise.
- Upstream gates the whole **client** at compile time:
  `MenuBarItemService.Connection` is `@available(macOS 26.0, *)`, because it
  calls `session.setPeerRequirement(.isFromSameTeam())` unconditionally.

Keep both gates exactly as upstream has them. The service is only ever used on
macOS 26+, which is also the only place the bug exists.

### Xcode target scaffolding, verified from upstream's `project.pbxproj`

This removes the old contract's "STOP, do not guess at Xcode surgery"
uncertainty for the parts below. The mechanism is fully readable in upstream's
project file:

- `Shared` is a `PBXFileSystemSynchronizedRootGroup` (`path = Shared`) listed in
  `fileSystemSynchronizedGroups` of **both** the app target and the service
  target. That is how one copy of a source file compiles into two targets —
  there is no shared framework and no duplicated file reference.
- The service target is `productType = "com.apple.product-type.xpc-service"`,
  product `MenuBarItemService.xpc`
  (`explicitFileType = "wrapper.xpc-service"`, `sourceTree = BUILT_PRODUCTS_DIR`).
- The app embeds it through a `PBXCopyFilesBuildPhase` named
  `Embed XPC Services`, with `dstPath = "$(CONTENTS_FOLDER_PATH)/XPCServices"`,
  `dstSubfolderSpec = 16`, and the build file carrying
  `settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }`.
- The app target gains a `PBXTargetDependency` on the service target.
- Service build settings, both configurations:
  `ENABLE_APP_SANDBOX = NO`, `ENABLE_HARDENED_RUNTIME = YES`,
  `GENERATE_INFOPLIST_FILE = YES`, `INFOPLIST_FILE = MenuBarItemService/Resources/Info.plist`,
  `SKIP_INSTALL = YES`, `CODE_SIGN_STYLE = Automatic`, `PRODUCT_NAME = "$(TARGET_NAME)"`.
  There is **no** `CODE_SIGN_ENTITLEMENTS` and no `.entitlements` file — the old
  contract's `SkeinMenuBarItemService.entitlements` does not exist upstream and
  must not be invented.
- The service's synced group carries a `PBXFileSystemSynchronizedBuildFileExceptionSet`
  with `membershipExceptions = (Resources/Info.plist,)`, i.e. the Info.plist is
  **excluded** from the compile membership, matching the existing exception set
  Skein already has at `Skein.xcodeproj/project.pbxproj:22`.
- `AXSwift` is attached to the service target via `packageProductDependencies`.

## Architecture for Skein

Skein's codebase has diverged from upstream in ways that change the port. Each
decision below is a deliberate adaptation with its verified reason.

### 1. The wire payload is a minimal struct, not `WindowInfo`

Upstream sends the whole `WindowInfo` because upstream's `WindowInfo` was
slimmed to seven natively-`Codable` stored properties, so
`extension WindowInfo: Codable { }` costs one line.

Skein's `WindowInfo` (`Skein/Utilities/WindowInfo.swift`, 319 lines) has twelve
stored properties, including `sharingState: CGWindowSharingType` and
`backingStoreType: CGWindowBackingType`. Making it `Codable` requires
**retroactive conformances on two imported CoreGraphics types**; a `swiftc
-typecheck` probe confirms it compiles but emits
`extension declares a conformance of imported type … to imported protocols
'Decodable', 'Encodable'` for each, and it would drag `WindowInfo.swift` into
the shared folder.

`SourcePIDCache` reads exactly two fields off the window: `windowID` and
`bounds`. So the shared contract carries only those:

```swift
enum MenuBarItemService {
    static let name = "com.ariadnev.Skein.MenuBarItemService"
}

extension MenuBarItemService {
    /// The window information the service needs to resolve a source pid.
    struct ItemWindow: Codable {
        let windowID: CGWindowID
        let bounds: CGRect
    }

    enum Request: Codable { case start; case sourcePID(ItemWindow) }
    enum Response: Codable { case start; case sourcePID(pid_t?) }
}
```

Skein's `WindowInfo` names the rectangle `frame`, not `bounds`
(`Skein/Utilities/WindowInfo.swift:17`), so the app builds
`ItemWindow(windowID: window.windowID, bounds: window.frame)`.

### 2. `Shared/` holds the minimum needed by both targets

`SourcePIDCache` needs `Bridging` for four things: `getWindowFrame(for:)`
(upstream calls it `getWindowBounds`), `getWindowList(option: .menuBarItems)`,
`responsivity(for:)`, and a process-unresponsive timeout setter. `Bridging`
in turn needs the CGS shims and `CGError.logString`.

| New path | Origin | Kind |
|---|---|---|
| `Shared/Bridging/Bridging.swift` | move of `Skein/Bridging/Bridging.swift` (277 lines) | move, unchanged except the one addition below |
| `Shared/Bridging/Shims/Private.swift` | move of `Skein/Bridging/Shims/Private.swift` (129 lines) | move, unchanged |
| `Shared/Bridging/Shims/Deprecated.swift` | move of `Skein/Bridging/Shims/Deprecated.swift` | move, unchanged |
| `Shared/Utilities/Logging.swift` | move of `Skein/Utilities/Logging.swift` (37 lines) | move; swap `Constants.bundleIdentifier` for `Bundle.main.bundleIdentifier ?? ""` so the service logs under its own subsystem |
| `Shared/Utilities/SharedExtensions.swift` | new | `CGError.logString` moved out of `Skein/Utilities/Extensions.swift:58-76`, plus `CGPoint.distance(to:)`, `CGRect.center`, `DispatchQueue.targetingGlobal` ported from upstream `Shared/Utilities/SharedExtensions.swift` |
| `Shared/Utilities/AXHelpers.swift` | new, ported verbatim from upstream (48 lines) | serialises every AX call onto one concurrent queue |
| `Shared/Services/MenuBarItemService.swift` | new | the contract in §1 |

One addition to `Bridging`: a `setProcessUnresponsiveTimeout(_:)` wrapping
`CGSEventSetAppIsUnresponsiveNotificationTimeout`, which needs a new
`@_silgen_name` declaration in `Shims/Private.swift`. Skein already has
`CGSEventIsAppUnresponsive` (`Skein/Bridging/Shims/Private.swift:57`) and
`Bridging.responsivity(for:)` (`Skein/Bridging/Bridging.swift:260`), so the
service uses `responsivity(for:) == .unresponsive` where upstream writes
`isProcessUnresponsive(_:)`. **Do not** rename `responsivity` to match upstream.

`Skein/Utilities/Extensions.swift` keeps everything except `CGError.logString`;
`Skein/Utilities/MouseCursor.swift:26,34` also use it and must still compile.

### 3. The service files

Ported into a new synced root group `MenuBarItemService/`, member of the
service target only:

- `MenuBarItemService/main.swift` — verbatim from upstream (10 lines).
- `MenuBarItemService/Listener.swift` — from upstream (91 lines). Substitute
  Skein's `Logger` API: Skein's `Logger` is a **struct wrapping `os.Logger`**
  (`Skein/Utilities/Logging.swift:9`), not an `extension` on `os.Logger`, and
  its methods take a plain `String` with no `privacy:` argument. Upstream's
  `Logger.default` has no Skein equivalent — declare one in the service.
  Upstream's `listener.take()?.cancel()` uses an `Optional.take()` helper that
  does not exist in Skein; write the two-line equivalent rather than porting
  the helper.
- `MenuBarItemService/SourcePIDCache.swift` — from upstream (230 lines), with
  `window.currentBounds()` replaced by `Bridging.getWindowFrame(for: windowID)`
  (Skein has no `WindowInfo.currentBounds()`), `Bridging.getMenuBarWindowList(option: .itemsOnly)`
  replaced by `Bridging.getWindowList(option: .menuBarItems)`, and
  `Bridging.isProcessUnresponsive(pid)` replaced by
  `Bridging.responsivity(for: pid) == .unresponsive`.
- `MenuBarItemService/Resources/Info.plist` — the `XPCService` dict, excluded
  from compile membership via the exception set.

### 4. The client and the sync/async split

`MenuBarItem.getMenuBarItems(on:onScreenOnly:activeSpaceOnly:)`
(`Skein/MenuBar/MenuBarItems/MenuBarItem.swift:174`) is **synchronous** and has
**ten** call sites. Upstream made its equivalent `async`. Skein cannot do that
wholesale: three of the ten sit in synchronous contexts, two of them hot.

| Call site | Enclosing context | Reads owner identity? | Verdict |
|---|---|---|---|
| `MenuBarItemManager.swift:336` | `cacheItemsIfNeeded() async` | yes — the master item cache | async |
| `MenuBarItemManager.swift:1328` | `tempShowItem(_:clickWhenFinished:mouseButton:)`, **sync** | yes | async — wrap the tail in a `Task`, as upstream did for the drag handler |
| `MenuBarItemManager.swift:1426` | `rehideTempShownItems() async` | yes | async |
| `MenuBarItemSpacingManager.swift:157` | `applyOffset() async throws` | yes — relaunches apps by pid | async |
| `MenuBarManager.swift:189` | inside a `Task` | yes | async |
| `LayoutBarPaddingView.swift:102` | `performDragOperation(_:) -> Bool`, **sync** | yes — matches `$0.info == .hiddenControlItem` | async — wrap that branch in a `Task`; upstream does exactly this at `Ice/MenuBar/LayoutBar/LayoutBarPaddingView.swift:78` |
| `MenuBarOverlayPanel.swift:573` | `pathForSplitShape(in:info:isInset:screen:) -> NSBezierPath`, **sync** | no — sums `item.frame.width` only | stays sync |
| `EventManager.swift:493` | `isMouseInsideMenuBarItem: Bool`, **sync**, runs per mouse-moved event | no — `$0.frame.contains(mouseLocation)` only | stays sync |
| `ScreenCapture.swift:13` | `checkPermissions() -> Bool`, **sync** | yes — `item.owningApplication == .current` | stays sync; see Risk below |

So:

- Keep the existing synchronous `getMenuBarItems` unchanged, for the three
  geometry-only callers.
- Add `static func getMenuBarItems(on:onScreenOnly:activeSpaceOnly:) async -> [MenuBarItem]`
  which, under `if #available(macOS 26.0, *)`, resolves each item's `sourcePID`
  through the connection, and otherwise calls the synchronous version.
- Add `let sourcePID: pid_t?` as a stored property on `MenuBarItem`. The
  existing `init(uncheckedItemWindow:)` (`MenuBarItem.swift:128`) sets it to
  `itemWindow.ownerPID` — today's behaviour, unchanged. A second
  `@available(macOS 26.0, *) init(uncheckedItemWindow:sourcePID:)` takes the
  resolved value, mirroring upstream `Ice/MenuBar/MenuBarItems/MenuBarItem.swift:182`.
- Add `MenuBarItemInfo.init(uncheckedItemWindow:sourcePID:)` deriving the
  namespace from `NSRunningApplication(processIdentifier: sourcePID)` when one
  is present. **This is the user-visible fix** — without it the service resolves
  a pid nobody reads.
- `Skein/MenuBar/MenuBarItems/MenuBarItemServiceConnection.swift` — the client,
  ported from upstream (163 lines), `@available(macOS 26.0, *)`.
- Start the connection once at launch, as upstream does at
  `Ice/Main/AppState.swift:66`.

## Related Code Files

Create:

- `Shared/Services/MenuBarItemService.swift`
- `Shared/Utilities/AXHelpers.swift`
- `Shared/Utilities/SharedExtensions.swift`
- `MenuBarItemService/main.swift`
- `MenuBarItemService/Listener.swift`
- `MenuBarItemService/SourcePIDCache.swift`
- `MenuBarItemService/Resources/Info.plist`
- `Skein/MenuBar/MenuBarItems/MenuBarItemServiceConnection.swift`

Move (rename-detectable, content otherwise unchanged):

- `Skein/Bridging/Bridging.swift` → `Shared/Bridging/Bridging.swift`
- `Skein/Bridging/Shims/Private.swift` → `Shared/Bridging/Shims/Private.swift`
- `Skein/Bridging/Shims/Deprecated.swift` → `Shared/Bridging/Shims/Deprecated.swift`
- `Skein/Utilities/Logging.swift` → `Shared/Utilities/Logging.swift`

Modify:

- `Skein/MenuBar/MenuBarItems/MenuBarItem.swift` — `sourcePID`, the second
  initializer, the async getter, the `MenuBarItemInfo` namespace fix
- `Skein/MenuBar/MenuBarItems/MenuBarItemManager.swift` — three call sites
- `Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift` — one call site
- `Skein/MenuBar/MenuBarManager.swift` — one call site
- `Skein/UI/LayoutBar/LayoutBarPaddingView.swift` — one call site
- `Skein/Main/AppState.swift` — start the connection at launch
- `Skein/Utilities/Extensions.swift` — remove `CGError.logString` (moved)
- `Skein.xcodeproj/project.pbxproj` — new target, synced groups, embed phase,
  dependency, package product, version bump
- `CHANGELOG.md`
- `docs/release-guide.md` — the signing step (see Release coupling)

## OUT OF SCOPE

- Any AX query other than source-pid resolution. The service does one thing.
- Refactoring `MenuBarItemManager` beyond the listed call sites. Its god-class
  refactor stays deferred.
- The dropped-click / item-movement work — that is the new Phase 6, re-planned
  against upstream `8d4b6a5`, `e3c63f2`, `b0a1942`.
- Phase 4's hover event tap. Independent PR, independent branch.
- Any UI change.
- Making `Skein/Utilities/WindowInfo.swift` `Codable` or moving it to `Shared/`.
- Renaming `Bridging.responsivity` or `WindowInfo.frame` to match upstream names.

## Implementation Steps

1. Branch `feat/phase-05-p3-xpc-service-port` from `main`.
2. Create `Shared/` and `git mv` the four files listed above. Build the app
   target alone — it must still compile and the diff for those files must be a
   pure rename under `git diff -M`.
3. Add `Shared/Utilities/SharedExtensions.swift`; move `CGError.logString` into
   it and delete it from `Skein/Utilities/Extensions.swift`. Build again.
4. Add `Shared/Services/MenuBarItemService.swift` and `Shared/Utilities/AXHelpers.swift`.
5. Add `setProcessUnresponsiveTimeout` to `Shared/Bridging/Bridging.swift` and
   its `@_silgen_name` declaration to `Shared/Bridging/Shims/Private.swift`.
6. **Xcode project surgery.** Create the XPC service target following the
   verified structure above. Add `Shared` to `fileSystemSynchronizedGroups` of
   *both* targets. If any step does not match what upstream's `project.pbxproj`
   shows, STOP — do not improvise; report to PM.
7. Port `main.swift`, `Listener.swift`, `SourcePIDCache.swift`, `Info.plist`
   into the service target with the substitutions listed in §3.
8. Build the service target alone — exit 0.
9. Add `MenuBarItemServiceConnection.swift` to the app; start it from `AppState`.
10. Wire `MenuBarItem`: stored `sourcePID`, second initializer, async getter,
    `MenuBarItemInfo` namespace fix.
11. Update the six async call sites from the table; leave the three sync ones alone.
12. Build both targets — exit 0, warning delta zero against `main`.
13. Bump version and write the CHANGELOG entry per Release coupling below.
14. Update `docs/release-guide.md` step 3 to sign the new nested `.xpc` first.
15. Write the manual test protocol into the PR body (the maintainer runs it).
16. Open the PR. Stop there — no tag, no merge.

### Manual test protocol (written here, run by the maintainer)

On macOS 26.6.2, with a signed build installed:

1. Open Settings → Menu Bar Layout. Every third-party item shows **its own**
   app name and icon, not "Control Center". Capture a before/after screenshot
   pair against 1.3.x.
2. Drag an item between sections; it lands and persists across a relaunch.
3. `pgrep -f MenuBarItemService` returns a pid while Skein is running.
4. `kill` that pid. Skein must not crash; items must still render; a
   subsequent item refresh must still work (degraded to legacy pids is fine).
5. `codesign -dv --verbose=4 /Applications/Skein.app/Contents/XPCServices/MenuBarItemService.xpc`
   shows the same Team ID as the main app and `flags=0x10000(runtime)`.
6. Settings → Appearance and the overlay still render correctly — this is the
   regression check on the three call sites that stayed synchronous.

## Release coupling

Phase 4 and Phase 5 are independent and may land in either order. **The version
bump to 1.4.0 belongs to whichever of the two merges second**, and that PR's
`CHANGELOG.md` entry must describe both. If only one has merged when a release
is cut, the entry describes only what is on `main`.

`v1.4.0` is tagged and published by the **maintainer**, not by this phase — see
guardrail 1. This phase stops at an open PR with green CI.

### Signing impact

`docs/release-guide.md:150` signs nested bundles inside-out and today lists only
Sparkle's own `Downloader.xpc`, `Installer.xpc`, `Updater.app`, and
`Sparkle.framework`. `Skein.app/Contents/XPCServices/MenuBarItemService.xpc`
becomes a **new innermost bundle** and must be signed before the main app, or
`codesign --verify` on the app will fail on mismatched sealed resources — the
exact failure mode the guide already warns about at line 366. Add it to the
script block and to the checklist at line 348.

## PM VERIFICATION CHECKLIST

- [ ] `git diff -M --stat main..HEAD` shows the four moved files as renames with
      zero content change (except `Logging.swift`'s one-line subsystem swap).
      — **renames yes, zero content change no.** All four are detected as
      renames (`Bridging.swift` 94%, `Deprecated.swift` 100%, `Private.swift`
      94%, `Logging.swift`). But two carry additions the service needs:
      `Bridging.swift` +11 (`setProcessUnresponsiveTimeout(_:)`) and
      `Private.swift` +6 (the `CGSEventSetAppIsUnresponsiveNotificationTimeout`
      `@_silgen_name` shim). `Logging.swift` is +3/−1 (the subsystem swap plus
      `import Foundation`); `Deprecated.swift` is clean. Disclosed as deviation
      1 in PR #23.
- [ ] New Swift LOC, excluding renames, is under 800. `git diff -M --numstat`
      is the measurement; a diff without `-M` is not. — **877 added / 105
      removed, net 772**, rename-excluded, measured with `-M` against
      `2080d2e..ef982aa`. Passes on net, fails on added lines. Both readings
      were reported rather than the passing one picked, and the gate was
      **waived by ruling on PR #23**: the 800 ceiling was set against a
      pre-rescope design (a thin `NSXPCConnection` shim) that does not exist
      upstream, this phase's own contract forbids splitting the PR, and the
      churn the gate actually bounds — existing Swift outside the new service,
      the new client, and `Shared/` — is **+211/−105 across six files**, with
      `MenuBarItemManager.swift` moving only +28/−28.
- [x] `grep -rn 'NSXPCConnection\|@objc protocol' Shared/ MenuBarItemService/ Skein/`
      returns nothing. — 0 matches.
- [x] The service target in `project.pbxproj` has
      `productType = "com.apple.product-type.xpc-service"`,
      `PRODUCT_BUNDLE_IDENTIFIER = com.ariadnev.Skein.MenuBarItemService`,
      `ENABLE_APP_SANDBOX = NO`, `ENABLE_HARDENED_RUNTIME = YES`,
      `SKIP_INSTALL = YES`, and no `CODE_SIGN_ENTITLEMENTS`. — all present: product type ×1, bundle id ×2,
      `ENABLE_APP_SANDBOX = NO` ×2, `SKIP_INSTALL = YES` ×2,
      `ENABLE_HARDENED_RUNTIME = YES` ×4 (app 2 + service 2). The only two
      `CODE_SIGN_ENTITLEMENTS` lines are `:407` and `:439`, both in main-app
      configuration blocks; the service blocks have none.
- [x] `Shared` appears in `fileSystemSynchronizedGroups` of **both** targets. — pbxproj `:132-135` (Skein) and `:160-163` (MenuBarItemService).
- [x] The `Embed XPC Services` copy phase has
      `dstPath = "$(CONTENTS_FOLDER_PATH)/XPCServices"` and `dstSubfolderSpec = 16`. — pbxproj `:33` and `:34`.
- [x] `MenuBarItemService/Resources/Info.plist` is in a
      `membershipExceptions` list, not compiled. — in the exception set targeting
      `MenuBarItemService`, pbxproj `:51`.
- [x] Every `MenuBarItem` construction site is enumerated in the PR body with a
      one-line statement of whether it resolves `sourcePID` or falls back to
      `ownerPID`, and why that is correct there. — the PR body tables all three
      (`MenuBarItem.swift:229` legacy/fallback, `:270` the resolving path,
      `MenuBarItemManager.swift:1302` liveness check that reads only
      `isOnScreen`), and notes the two `EventManager.swift` grep hits are
      `setIsDraggingMenuBarItem`, not constructions.
- [x] `MenuBarItemInfo` derives its namespace from `sourcePID` on macOS 26 —
      not just `MenuBarItem.sourcePID` being stored and unread. — `MenuBarItem.swift:354-373`: the
      macOS 26 initializer resolves `NSRunningApplication(processIdentifier:)`
      from `sourcePID` and takes its bundle identifier for the namespace,
      falling back to `itemWindow.owningApplication` only when that is nil.
      Confirmed live on hardware: with every layer-25 window reporting
      `ownerPID = 459` / Control Center, the manager still logged
      `Moving com.steipete.codexbar:codexbar-merged to left of
      com.electron.dockerdesktop:Item-0`.
- [x] The three synchronous call sites in the table are unchanged. — `MenuBarOverlayPanel.swift:573`,
      `EventManager.swift:493`, `ScreenCapture.swift:13`, all left as they were,
      and the overlay was verified still drawing on hardware.
- [x] `MenuBarItemService.Connection` and the 2-argument `MenuBarItem`
      initializer are both `@available(macOS 26.0, *)`. — `MenuBarItemServiceConnection.swift:12`
      and `:81`; `MenuBarItem.swift:146`, `:177`, `:354`.
- [x] `xcodebuild -project Skein.xcodeproj -scheme Skein -configuration Release build`
      exits 0 with zero new warnings against `main`. — exit 0, `** BUILD SUCCEEDED **`. Warning delta zero:
      2 warnings on both sides, the same `CustomColorPicker.swift:115:9`
      switch-exhaustiveness one, measured by building `main` from scratch in a
      throwaway worktree rather than assumed. CI on PR #23 green.
- [x] `find Skein.app -name '*.xpc'` finds the service inside
      `Contents/XPCServices/`, and `codesign -dv` on it reports the same Team ID
      as the app. — on hardware:
      `/Applications/Skein.app/Contents/XPCServices/MenuBarItemService.xpc`,
      `Identifier=com.ariadnev.Skein.MenuBarItemService`,
      `flags=0x10000(runtime)`, `TeamIdentifier=T8NP5XSKGL` — the app's team.
- [x] ZIP size delta against v1.3.x is ≤ 300 KB. — `main` 6,099,456 B → branch
      6,365,327 B = **+265,871 B (+259.6 KB)**, about 41 KB of headroom.
- [x] `docs/release-guide.md` signs the new `.xpc` before the main app. — `docs/release-guide.md:161-162` in the
      script block, `:351` in the checklist, `:369` in the pitfall note.
- [ ] Manual test protocol results pasted into the PR body by the maintainer,
      including the before/after Menu Bar Layout screenshots from step 1.
      — **results yes, screenshots no.** All six steps were run on hardware
      (macOS 26.6.2 / 25G83) against a signed 1.3.0 build installed over
      `/Applications`, and the full write-up is a comment on PR #23. The
      before/after screenshots could not be taken: Menu Bar Layout renders
      **empty** on this machine, on this branch and identically on shipped
      v1.2.1, so there is nothing to photograph. That defect is filed as
      issue #25 and is not caused by this phase. The layout state was instead
      read through the Accessibility API (`SA1 = 0, SA2 = 0` on both builds).

## Success Criteria

- [ ] PR opened, CI green, PM checklist complete. — PR #23 opened and CI green;
  squash-merged to `ef982aa` on 2026-09-05. The checklist is **not** complete:
  three boxes stay open with the reasons recorded against them (rename content
  additions, the LOC gate, the missing screenshots).
- [ ] On macOS 26, menu bar items in Settings → Menu Bar Layout show their real
      owning application, verified by the maintainer against a 1.3.x build.
      — **cannot be verified through that pane.** Two separate defects sit in
      front of it, both pre-existing and both now filed: Menu Bar Layout is
      empty on macOS 26 (issue #25, reproduces identically on v1.2.1), and
      `MenuBarItem.displayName` still resolves through `owningApplication`
      rather than `sourcePID`, so on macOS 26 it always lands in the
      `.controlCenter` branch and returns the raw window title (issue #26).
      What this phase actually delivers — namespacing by the creating process —
      **is** verified on hardware through the manager's own logs, recorded
      against the `MenuBarItemInfo` box above.
- [x] Killing the service process does not crash or hang the app. — verified on
      hardware with `kill -9` (SIGTERM was ignored, so the harsher case was the
      one tested). Skein stayed alive, Settings intact, no crash report, items
      kept rendering, Show the Hidden Section kept working; the disconnect was
      logged cleanly as `XPC.XPCRichError error 1` and the service respawned on
      demand at the next resolution with no user action and no app restart.
- [x] Below macOS 26 the app never opens an XPC session — verifiable by the
      `@available` gates alone, since the client type cannot be referenced there.
      — `MenuBarItemService.Connection` is `@available(macOS 26.0, *)`
      (`MenuBarItemServiceConnection.swift:12`), so a pre-26 code path cannot
      name the type and the compiler enforces it.
- [ ] After maintainer approval: v1.4.0 tagged, released, appcast enclosure
      byte-matched, Sparkle rolls 1.3.x → 1.4.0 on a real Mac. — **three of four.**
      The maintainer delegated the tagging on 2026-09-05, so `v1.4.0` is signed at
      `88d54fd`, the release carries the signed ZIP + DMG + appcast, and the
      enclosure `length="6432768"` matches the ZIP exactly. The last clause is
      still open: nobody has watched Sparkle carry a real Mac from 1.3.x to 1.4.0.

## Risk Assessment

- **Xcode project surgery is the highest-risk step.** Signal: the service builds
  but is missing from `Contents/XPCServices/`, or `Shared/` files fail to
  resolve in one target. Response: diff the generated `project.pbxproj` against
  upstream's structure section by section; the mechanism is fully documented
  above, so a mismatch is a mistake, not an unknown. If it still does not
  resolve, STOP and `/av:advise`.
- **Codesigning a second nested bundle.** Signal: `codesign --verify` on the app
  reports sealed-resource mismatch. Response: sign the `.xpc` first — this is
  the documented failure at `docs/release-guide.md:366` and the reason step 14
  exists. Do not ship an app whose `--verify` is not clean.
- **`ScreenCapture.checkPermissions()` stays on the legacy pid.** It compares
  `item.owningApplication == .current` to skip Skein's own items
  (`Skein/Utilities/ScreenCapture.swift:14-16`). On macOS 26 that comparison can
  never be true, so it falls through to the first item's `title != nil`. This is
  a pre-existing latent defect that this phase does **not** fix, because making
  it async changes a synchronous permissions check on the launch path. Record it
  in the PR body as a known follow-up; do not silently widen scope to fix it.
- **AX permission dependency.** `SourcePIDCache` returns `nil` for everything if
  the *service process* is not Accessibility-trusted. Signal: every `sourcePID`
  is nil on a machine where Skein itself has Accessibility. Response: confirm
  whether the trust grant follows the app bundle or the service bundle before
  concluding the port is broken; it is a real open question and worth
  `/av:advise` rather than a guess.
- **Bundle size.** Signal: ZIP delta over 300 KB. Response: check whether AXSwift
  is being embedded twice rather than linked once.

## Rollback

Every change is additive or a rename. Reverting the merge commit restores the
pre-phase state; no data migration, no user defaults touched, no appcast change
until the maintainer tags.

## Record — as shipped, 2026-09-05

Merged as PR #23 (`ef982aa`), squash, branch deleted. `+1092 / −111` across 22
files in one commit, no version bump — the 1.4.0 / 1140 bump went to Phase 4,
which merged second, per that phase's Release coupling.

Four deviations were disclosed in the PR body before merge, beyond the two
checklist boxes annotated above:

1. **Step 2 / step 6 ordering.** The contract has the files move at step 2 and
   `Shared` registered in the pbxproj at step 6. That cannot work: a file moved
   out of `Skein/` leaves the synchronised group and so leaves the app target
   immediately, breaking the build until `Shared` is registered. The
   registration was folded into step 2.
2. **Logger naming.** Per-file `private extension Logger` rather than one shared
   `Logger.default`, matching what the rest of this codebase already does.
3. **The §4 table is wrong about `MenuBarManager.swift:189`.** It describes that
   site as "inside a Task → async", which is why it was expected to error. It is
   actually a synchronous Combine `.sink { [weak self] }`, so it never errored —
   but it still needed the async path, because it locates control items via
   `items.firstIndex(matching: .hiddenControlItem)`, matching on `info`, which
   is exactly what breaks on macOS 26 without `sourcePID`. It was wrapped in a
   `Task` rather than left alone.
4. **`ScreenCapture.checkPermissions()` left on the legacy pid**, as the Risk
   Assessment above instructs. Recorded as a known follow-up in the PR body.

### Findings from the hardware run, filed rather than fixed

- **#25** — Menu Bar Layout stays empty for the rest of the session after a
  failed cache pass. `MenuBarItemManager.cacheItemsIfNeeded()` assigns
  `cachedItemWindowIDs` *before* the `guard let hiddenControlItem` that can
  bail, so one failed pass poisons the cache permanently: `.activeSpace`
  includes off-screen items, so showing or hiding a section never changes the ID
  set and every later call returns early. Deterministic 2/2 on this branch and
  2/2 on shipped v1.2.1, which has no XPC service — **not a Phase 5 regression.**
  Toggling `ShowSkeinIcon` 1→0→1 does not recover it. The fix is to move the
  assignment after the guard.
- **#26** — Menu bar item labels still show window titles on macOS 26 because
  `MenuBarItem.displayName` (`MenuBarItem.swift:77-115`) ignores `sourcePID` and
  resolves through `owningApplication`. Feeds `LayoutBarItemView.swift:78`,
  `SkeinBar.swift:406`/`:433`, `MenuBarSearchPanel.swift:277`/`:440`, and several
  `MenuBarItemManager` alert strings.

Two other observations from the same run, recorded here because they belong to
other phases: the Settings UI renders **green rather than rope orange `#E86A33`
because the macOS system accent overrides the AccentColor asset — which matters
for the Phase 2 landing screenshots — and Sparkle self-update 1.2.1 → 1.2.2 on
hardware is still unproven, since nothing in this run exercised it.

The machine was restored afterwards: `/Applications/Skein.app` back to v1.2.1
(1122) with a valid signature, all 38 `com.ariadnev.Skein` defaults keys
byte-identical, `codexbar-merged` returned to the visible section.
