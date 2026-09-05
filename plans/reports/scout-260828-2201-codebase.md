# Swift Codebase Scout Report: Skein

**Date:** 2026-08-28  
**Scope:** Architectural structure, LOC metrics, hot spots, dead/obsolete code, and technical debt across the Skein codebase.

---

## 1. Architectural Structure & Module Boundaries

```
Skein/
├── Skein.xcodeproj/       # Xcode project: macOS 14.0 target, Swift 5.0, 5 SPM dependencies
├── Skein/                 # Core Swift application source (12 subsystems)
│   ├── Main/              # App entry (@main SkeinApp), AppDelegate, AppState, Navigation
│   ├── MenuBar/           # Core domain logic (Items, Appearance, ControlItem, Search, Spacing)
│   ├── UI/                # Reusable SwiftUI & AppKit components (SkeinBar, LayoutBar, Pickers, SkeinUI)
│   ├── Settings/          # Settings window, view, panes, and manager backends
│   ├── Events/            # Event taps (CGEventTap) and universal event monitoring
│   ├── Hotkeys/           # Carbon HIToolbox hotkey management & keycode mapping
│   ├── Permissions/       # Accessibility & Screen Recording permission handlers
│   ├── Bridging/          # Private CGS/SkyLight C-bridging (@_silgen_name shims)
│   ├── Utilities/         # Migrations, WindowInfo, ScreenCapture, logging, extensions
│   ├── Updates/           # Sparkle integration (UpdatesManager)
│   ├── UserNotifications/ # User notifications manager
│   ├── Swizzling/         # AppKit runtime patching (NSSplitViewItem)
│   ├── Assets.xcassets/   # Color sets, AppIcon, ControlItemImages, SkeinMarkStroke
│   ├── AppIcon.icon/      # macOS Icon Composer asset package
│   └── Info.plist         # Sparkle feed URL and public Ed25519 key
├── Resources/             # Unreferenced legacy Ice design assets (16 MB)
├── Scripts/               # Distribution & icon generation scripts (make-dmg.sh, generate-icon-artwork.py)
├── infra/                 # Cloudflare Worker for Sparkle appcast redirection (appcast-worker/)
└── docs/                  # Upstream tracking, workflow, and release guides
```

### Module Responsibilities & Key Types

| Module / Folder | Primary Responsibilities | Key Types |
| :--- | :--- | :--- |
| **`Main/`** | Lifecycle coordination, window management, shared root state | `SkeinApp`, `AppDelegate`, `AppState`, `AppNavigationState` |
| **`MenuBar/`** | Menu bar inspection, item positioning, overlay panels, search | `MenuBarManager`, `MenuBarItemManager`, `MenuBarOverlayPanel`, `ControlItem`, `MenuBarSearchPanel` |
| **`UI/`** | UI components, drag-and-drop layout bar, secondary Skein Bar | `SkeinBarPanel`, `LayoutBarContainer`, `LayoutBarItemView`, `CustomGradientPicker`, `SkeinForm` |
| **`Settings/`** | Multi-pane preference window and persistent configuration | `SettingsWindow`, `SettingsView`, `GeneralSettingsPane`, `SettingsManager` |
| **`Events/`** | System-wide event tracking (clicks, scrolls, hovers, drags) | `EventManager`, `EventTap`, `UniversalEventMonitor` |
| **`Hotkeys/`** | Low-level global keyboard shortcut registration via Carbon | `HotkeyRegistry`, `Hotkey`, `KeyCode`, `KeyCombination` |
| **`Permissions/`** | Permission gating, state monitoring, system settings linking | `PermissionsManager`, `AccessibilityPermission`, `ScreenRecordingPermission` |
| **`Bridging/`** | Private SkyLight/CGS window server and space APIs | `Bridging`, CGS function shims (`CGSGetWindowList`, `CGSGetActiveSpace`) |
| **`Utilities/`** | Window introspection, screen capture, version migrations | `WindowInfo`, `ScreenCapture`, `MigrationManager`, `Defaults`, `StatusItemDefaults` |
| **`Updates/`** | Software update scheduling, background checks via Sparkle | `UpdatesManager` |
| **`UserNotifications/`** | Local notification requests and delivery handling | `UserNotificationManager` |
| **`Swizzling/`** | Runtime method exchange for AppKit sidebar collapse fix | `NSSplitViewItem+swizzledCanCollapse` |

---

## 2. LOC Counts & Codebase Metrics

### Swift LOC by Subsystem

| Subsystem | Files | Total LOC | Code LOC | Comment LOC | Blank LOC |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **MenuBar** | 20 | 6,604 | 4,993 | 817 | 794 |
| **UI** | 35 | 3,825 | 2,895 | 480 | 450 |
| **Utilities** | 20 | 2,472 | 1,557 | 592 | 323 |
| **Settings** | 12 | 1,513 | 1,213 | 110 | 190 |
| **Events** | 6 | 1,215 | 859 | 191 | 165 |
| **Hotkeys** | 6 | 1,020 | 796 | 104 | 120 |
| **Main** | 6 | 482 | 324 | 87 | 71 |
| **Permissions** | 4 | 457 | 360 | 47 | 50 |
| **Bridging** | 3 | 419 | 295 | 67 | 57 |
| **Updates** | 1 | 156 | 109 | 28 | 19 |
| **UserNotifications** | 2 | 99 | 65 | 19 | 15 |
| **Swizzling** | 1 | 36 | 26 | 4 | 6 |
| **Total Swift** | **116** | **18,298** | **13,492** | **2,546** | **2,260** |

### Top 15 Largest Swift Files

| File | Total LOC | Code LOC | Subsystem | Responsibility / Notes |
| :--- | :---: | :---: | :--- | :--- |
| `MenuBar/MenuBarItems/MenuBarItemManager.swift` | 1,671 | 1,201 | MenuBar | Item caching, synthetic event posting, drag/drop movement |
| `MenuBar/Appearance/MenuBarOverlayPanel.swift` | 793 | 629 | MenuBar | Overlay window rendering, wallpaper capture, polling loops |
| `MenuBar/ControlItem/ControlItem.swift` | 577 | 450 | MenuBar | `NSStatusItem` section controllers, length expansion hacks |
| `Events/EventManager.swift` | 556 | 399 | Events | Mouse click/drag/hover/scroll monitoring and routing |
| `Utilities/MigrationManager.swift` | 548 | 404 | Utilities | Legacy migrations (v0.8.0 through v2.0.0 defaults import) |
| `Utilities/Extensions.swift` | 495 | 316 | Utilities | Geometry, AppKit, Combine, and Foundation helper extensions |
| `UI/SkeinBar/SkeinBar.swift` | 490 | 393 | UI | Secondary floating menu bar panel and layout |
| `MenuBar/Search/MenuBarSearchPanel.swift` | 469 | 388 | MenuBar | Floating search HUD panel using Ifrit fuzzy match |
| `UI/Pickers/CustomGradientPicker/CustomGradientPicker.swift` | 446 | 395 | UI | Gradient editor and color stop controls |
| `MenuBar/MenuBarManager.swift` | 420 | 301 | MenuBar | Central menu bar section & app menu visibility controller |
| `Settings/SettingsPanes/GeneralSettingsPane.swift` | 346 | 313 | Settings | General preference pane UI |
| `MenuBar/Appearance/MenuBarAppearanceEditor/MenuBarAppearanceEditor.swift` | 326 | 285 | MenuBar | Menu bar styling popover interface |
| `Utilities/WindowInfo.swift` | 319 | 208 | Utilities | Window list query and dictionary wrapper |
| `MenuBar/MenuBarSection.swift` | 309 | 252 | MenuBar | Visible/Hidden/AlwaysHidden section coordinator |
| `Main/AppState.swift` | 309 | 217 | Main | Central application state container and lazy managers |

### Remote Dependencies (SPM)

| Dependency | Repository | Pinned Version | Purpose |
| :--- | :--- | :---: | :--- |
| **AXSwift** | `tmandry/AXSwift` | `0.3.2` | Swift wrapper for macOS Accessibility (`AXUIElement`) APIs |
| **Sparkle** | `sparkle-project/Sparkle` | `2.6.4` | In-app software update framework |
| **LaunchAtLogin-Modern** | `sindresorhus/LaunchAtLogin-Modern` | `1.1.0` | `SMAppService` wrapper for launch on login |
| **CompactSlider** | `buh/CompactSlider` | `1.1.6` | Compact slider UI control for settings panes |
| **Ifrit** | `ukushu/Ifrit` | `2.0.3` | Fuzzy search scoring engine for menu bar search |

---

## 3. Hotspots & Architectural Complexities

### 1. `MenuBarItemManager` (1,671 LOC) — Monolithic Item Orchestrator
- **Responsibility Overload:** Combines in-memory item caching, status item identification, CGEvents generation (`menuBarItemEvent`), drag-and-drop movement execution, animated interpolation (`slowMove`), click simulation, temporary item expansion (`tempShowItem`), auto-rehide timer scheduling, and control item order enforcement.
- **Complex Concurrency & Async Waiters:** Implements custom polling loops (`waitForItemsToStopMoving`, `waitForMouseToStopMoving`, `waitForNoModifiersPressed`) with tick intervals (`Task.sleep`) and cancellation error handling (`FrameCheckCancellationError`).

### 2. `MenuBarOverlayPanel` (793 LOC) — Heavy Background Polling
- **Timer Polling Overload:**
  - 5-second `Timer.publish` polling loop refreshing desktop wallpaper capture.
  - 10-second `Timer.publish` polling loop refreshing application menu frame.
  - `UpdateTaskContext` spawns continuous detached background tasks with 1ms/1s sleep intervals checking frame deltas against `displayID`.
- **Battery & CPU Impact:** Continuous window captures and Accessibility queries run even when the menu bar is static.

### 3. `ControlItem` (577 LOC) — Status Item Layout Hacks
- **Length Expansion Trick:** Toggles `statusItem.length` between standard variable length and `10_000` points (`Lengths.expanded`) to push adjacent items off-screen.
- **Brittle Layout Constraint Traversal:** Inspects `button.window?.contentView?.constraintsAffectingLayout(for: .horizontal)` and matches private AppKit constraints (`Predicates.controlItemConstraint`) to force 0-width items when section dividers are hidden.

### 4. `EventManager` (556 LOC) & `EventTap` (263 LOC) — System Event Interception
- **System-Wide Event Monitoring:** Maintains global `UniversalEventMonitor` instances capturing every mouse movement, drag, click, and scroll wheel event across the entire OS.
- **Mach Port CGEventTap:** Installs a low-level Mach Port event tap (`CFMachPortCreateRunLoopSource`) into the current run loop with C callback trampoline (`handleEvent`).

### 5. `AppState` (309 LOC) — Central Monolith & Combine Publisher Cascade
- **Forwarding Boilerplate:** Manually forwards nested `objectWillChange` events from 5 child managers (`menuBarManager`, `permissionsManager`, `settingsManager`, `updatesManager`, etc.) to trigger root updates.
- **Activation Workaround:** Contains workaround activating Dock via bundle ID (`com.apple.dock`) on first launch to force proper window activation policy transition from accessory to regular mode.

---

## 4. Dead Code & Leftover / Obsolete Code

- **Unreferenced Root `Resources/` Assets (16.4 MB):**
  - `Resources/Icon.fig` (140 KB) — Upstream Ice Figma design file.
  - `Resources/Icon.png` (452 KB) — Upstream Ice icon artwork.
  - `Resources/rearranging.gif` (3.0 MB) — Upstream Ice screencast GIF.
  - `Resources/rearranging.mov` (12.7 MB) — Upstream Ice screencast video.
  - *Status:* Zero references in Swift code, Xcode project, or active documentation.
- **Frost OSType Signature in `HotkeyRegistry.swift:55`:**
  - `private let signature = OSType(1181904755) // OSType for 'Fros'`
  - *Status:* Leftover 4-character code from Frost rebrand (`'Fros'`). For Skein, this should be `'Skei'` (`1399481705` / `0x536b6569`).
- **Unused `Acknowledgements.rtf` in `Skein/Resources/`:**
  - `Skein/Resources/Acknowledgements.rtf` (12 KB) sits alongside `Acknowledgements.pdf` (33 KB).
  - *Status:* `AboutSettingsPane.swift` strictly references the `.pdf` version (`Bundle.main.url(forResource: "Acknowledgements", withExtension: "pdf")!`).
- **Obsolete Migration Routines in `MigrationManager.swift`:**
  - Contains migrations for Ice versions `0.8.0`, `0.10.0`, `0.10.1`, and `0.11.10`.
  - `migrate0_10_1()` hardcodes an alert string: `"Due to a bug in the 0.10.0 release, the data for Skein's menu bar items was corrupted..."` (rebranded text for an ancient upstream bug).
  - `ControlItem.Identifier.deprecatedRawValue` maps `.skeinIcon` to `"IceIcon"`.

---

## 5. Technical Debt & Modernization Analysis

### Deprecated API Usage

1. **`CGWindowList` vs `ScreenCaptureKit` (`ScreenCapture.swift` & `WindowInfo.swift`):**
   - Uses `CGWindowListCopyWindowInfo` and `CGWindowListCreateDescriptionFromArray` (deprecated in macOS 14.0+).
   - Uses `CGWindowListCreateImage` wrapped inside private protocol `WindowListImage` specifically to silence compiler deprecation warnings.
   - *Rationale:* ScreenCaptureKit still lacks native support for capturing composite images of off-screen status items across spaces.
2. **`CGPreflightScreenCaptureAccess` / `CGRequestScreenCaptureAccess` (`ScreenCapture.swift`):**
   - Contains explicit `#available(macOS 15.0, *)` workaround because `CGRequestScreenCaptureAccess()` is broken on macOS 15, invoking `SCShareableContent.getWithCompletionHandler` as a fallback.
3. **Deprecated Carbon Process API (`Bridging/Shims/Deprecated.swift`):**
   - `@_silgen_name("GetProcessForPID")` used to resolve `ProcessSerialNumber` for `CGSEventIsAppUnresponsive`.
4. **Deprecated UserDefaults Keys (`Defaults.swift:188-202`):**
   - 11 deprecated `Defaults.Key` declarations retained for legacy migration compatibility (`menuBarAppearanceConfiguration`, `sections`, `menuBarHasBorder`, etc.).

### Private API Usage & AppKit Swizzling

1. **Private SkyLight / CGS APIs (`Bridging/Shims/Private.swift`):**
   - 13 CGS APIs declared via `@_silgen_name`:
     - `CGSMainConnectionID`, `CGSCopyConnectionProperty`, `CGSSetConnectionProperty`
     - `CGSEventIsAppUnresponsive`, `CGSGetActiveSpace`, `CGSCopySpacesForWindows`, `CGSSpaceGetType`
     - `CGSGetWindowList`, `CGSGetOnScreenWindowList`, `CGSGetProcessMenuBarWindowList`
     - `CGSGetWindowCount`, `CGSGetOnScreenWindowCount`, `CGSGetScreenRectForWindow`
   - *Risk:* Private APIs can change or break without notice in future macOS major releases (e.g. macOS 15+ Sequoia).
2. **Runtime Method Swizzling (`NSSplitViewItem+swizzledCanCollapse.swift`):**
   - Swizzles `NSSplitViewItem.canCollapse` via `method_exchangeImplementations` to prevent settings window sidebar collapse.
3. **Non-Sandboxed Environment (`Skein.entitlements`):**
   - `com.apple.security.app-sandbox = false` is required due to window server inspection, global event taps, and synthetic CGEvent injection.

### Concurrency & Swift 6 Migration Readiness

| Metric / Pattern | Count | Modern Target | Status / Risk |
| :--- | :---: | :--- | :--- |
| **`SWIFT_VERSION`** | `5.0` | `6.0` | Project set to Swift 5; strict concurrency unconfigured. |
| **`SWIFT_STRICT_CONCURRENCY`** | Not set | `complete` | Enabling complete checking will yield substantial diagnostic errors. |
| **Combine Imports** | 34 files | `Observation` framework | Heavy legacy Combine reactive pipelines. |
| **`@Published` Properties** | 56 usages | `@Observable` / `@ObservationTracked` | Manual objectWillChange forwarding across managers. |
| **`@Observable` Macro** | 0 usages | Standard in macOS 14+ | Entire codebase uses `ObservableObject`. |
| **`Sendable` Annotations** | 4 usages | Universal across boundaries | Missing Sendable conformances on structs and models crossing tasks. |
| **`DispatchQueue` vs `Task`** | 67 vs 69 | Structured Concurrency | Mixed async paradigms: `DispatchQueue.main.asyncAfter` alongside `Task.sleep`. |
| **Unchecked Async Callbacks** | Event taps / timers | Isolated actors | C callbacks pass `Unmanaged<T>` pointers directly across threads. |

---

## 6. Summary Matrix of Findings

| Area | Severity | Impact | Recommendation |
| :--- | :---: | :--- | :--- |
| **Polling Loops & Timer Load** | High | Battery drain and CPU wakeups in `MenuBarOverlayPanel` and `MenuBarItemImageCache` | Replace polling timers with event-driven triggers (Space change, display reconfiguration). |
| **`MenuBarItemManager` Complexity** | High | 1,671 LOC god class; fragile synthetic event injection | Decompose into distinct services: `ItemCacheService`, `ItemMover`, `ItemEventSimulator`. |
| **Swift 6 Concurrency Gaps** | Medium | Compile breakage under Swift 6 strict mode; data race risks | Adopt `Observation` (`@Observable`), audit `Sendable` types, replace GCD dispatch queues with Tasks. |
| **Deprecated Window APIs** | Medium | Future macOS deprecation / removal of `CGWindowList` | Encapsulate ScreenCaptureKit transitions and monitor Apple API updates. |
| **Legacy Assets (16 MB)** | Low | Bloats git checkout and workspace | Delete `Resources/Icon.fig`, `Icon.png`, `rearranging.gif`, `rearranging.mov`. |
| **Leftover 'Fros' OSType** | Low | Inconsistent FourCharCode identifier in Carbon hotkey registry | Update `signature` in `HotkeyRegistry.swift` to `'Skei'`. |

---

## 7. Unresolved Questions

1. **ScreenCaptureKit Migration Path:** Does macOS 15+ ScreenCaptureKit provide a reliable alternative to `CGWindowListCreateImage` for capturing off-screen / non-active space menu bar items without requiring full screen recording approval dialogs on every launch?
2. **Retirement of Ancient Migrations:** Can migrations for Ice v0.8.0 through v0.11.10 be cleanly retired, keeping only the v2.0.0 (`com.vchun.Frost` -> `com.vchun.Skein`) settings migration to reduce technical debt in `MigrationManager`?
3. **Observation Framework Transition:** Is the deployment target permanently fixed at macOS 14.0+, allowing a full migration from Combine `ObservableObject` / `@Published` to Swift's native `@Observable` macro?
4. **Status Item 0-Width Replacement:** Has a cleaner alternative to the private layout constraint workaround in `ControlItem.swift:106-124` been identified for hiding section dividers without removing the status item?
