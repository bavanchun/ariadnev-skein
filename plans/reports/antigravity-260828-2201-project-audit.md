# Skein Project Comprehensive Audit Report

**Report Identifier:** `plans/reports/antigravity-260828-2201-project-audit.md`  
**Timestamp:** 2026-08-28T22:15:00+07:00  
**Repository:** [`bavanchun/ariadnev-skein`](https://github.com/bavanchun/ariadnev-skein)  
**Branch / Commit:** `main @ f1fa744` (Release 1.2.1 shipped)  
**Auditor:** Antigravity Engineering (Autonomous Parallel Multi-Agent Audit)  
**Methodology:** Integrated [`/ak:scout`](file:///Users/vchun/.gemini/config/skills/ak-scout/SKILL.md) & [`/ak:project-management`](file:///Users/vchun/.gemini/config/skills/ak-project-management/SKILL.md) running 6 specialized subagents in parallel.

---

## 1. Executive Summary

Skein is in **strong production health** following the release of v1.2.1 on 2026-08-28. The codebase has cleanly transitioned from upstream `jordanbaird/Ice` through Frost to an independent standalone identity (`com.ariadnev.Skein`), with 0 open issues, 0 open PRs, and 15 successfully merged PRs across two release cycles.

- **Top 3 Wins:**
  1. **Complete Ecosystem Rebrand & Independence:** Clean project structure, unified naming, custom rope-loop Icon Composer artwork ([`AppIcon.icon`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/AppIcon.icon)), and multi-generational settings migration ([`MigrationManager.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Utilities/MigrationManager.swift)).
  2. **Automated Packaging & Delivery:** Streamlined DMG pipeline ([`Scripts/make-dmg.sh`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Scripts/make-dmg.sh)), automated CI build and lint verification ([`.github/workflows/ci.yml`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/.github/workflows/ci.yml)), and a dedicated Sparkle update redirection proxy on Cloudflare Workers (`skein.ariadnev.com`).
  3. **Zero Active Backlog Debt:** High velocity with 100% PR merge rate and explicit, documented rationale for trade-offs (e.g. Issue #16 Gatekeeper wontfix policy).

- **Top 3 Risks:**
  1. **Memory & Concurrency Defects in Core Shims:** Critical unsafe pointer memory leak in [`ScreenCapture.swift:64`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Utilities/ScreenCapture.swift#L63-L72), loop short-circuit bug in [`MenuBarItemSpacingManager.swift:169`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift#L163-L171), and potential CGS window list slice bounds crash in [`Bridging.swift:104`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Bridging/Bridging.swift#L89-L141).
  2. **Upstream Architecture Divergence (`upstream/macos-26`):** Upstream contains 77 commits featuring an out-of-process XPC service ([`MenuBarItemService`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/reports/scout-260828-2201-upstream-drift.md)) to eliminate main UI beachballing and HID event taps for macOS 15+ click drop fixes. Direct branch merging is fatal; selective porting is required.
  3. **High-Frequency Polling & Monolithic God Classes:** [`MenuBarItemManager.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/MenuBarItems/MenuBarItemManager.swift) (1,671 LOC) handles too many disparate responsibilities; [`MenuBarOverlayPanel.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/Appearance/MenuBarOverlayPanel.swift) executes 1ms/5s/10s timer loops consuming unnecessary battery/CPU resources.

---

## 2. Codebase Scout

*Reference Report:* [`plans/reports/scout-260828-2201-codebase.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/reports/scout-260828-2201-codebase.md)

### 2.1 Architecture & Module Boundaries
The project is organized into 12 distinct subsystems under [`Skein/`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein), targeting macOS 14.0+ with Swift 5.0 in a non-sandboxed environment.

```
Skein/
├── Skein/                 # Core Swift application (116 files, 18,298 total lines)
│   ├── Main/              # App entry (@main SkeinApp), AppDelegate, AppState
│   ├── MenuBar/           # Core domain logic (Items, Appearance, ControlItem, Search, Spacing)
│   ├── UI/                # Reusable SwiftUI & AppKit components (SkeinBar, LayoutBar)
│   ├── Settings/          # Multi-pane preferences and state persistence
│   ├── Events/            # CGEventTap and universal system event monitoring
│   ├── Hotkeys/           # Carbon HIToolbox global hotkey registration
│   ├── Permissions/       # Accessibility & Screen Recording permission handlers
│   ├── Bridging/          # Private CGS/SkyLight C-bridging (@_silgen_name shims)
│   ├── Utilities/         # Migrations, WindowInfo, ScreenCapture, logging, extensions
│   ├── Updates/           # Sparkle integration (UpdatesManager)
│   ├── UserNotifications/ # Notification center delivery
│   └── Swizzling/         # AppKit runtime patching (NSSplitViewItem)
├── Resources/             # Unreferenced legacy Ice design assets (16.4 MB)
├── Scripts/               # Distribution & icon generation scripts (make-dmg.sh, generate-icon-artwork.py)
├── infra/                 # Cloudflare Worker for Sparkle appcast redirection
└── docs/                  # Project documentation & release procedures
```

### 2.2 Lines of Code (LOC) Metrics

| Subsystem | Files | Total LOC | Code LOC | Comment LOC | Blank LOC | Responsibility |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **MenuBar** | 20 | 6,604 | 4,993 | 817 | 794 | Item caching, event injection, overlay rendering, search |
| **UI** | 35 | 3,825 | 2,895 | 480 | 450 | Layout bar, floating secondary Skein Bar, custom pickers |
| **Utilities** | 20 | 2,472 | 1,557 | 592 | 323 | Version migration, screen capture, window inspection |
| **Settings** | 12 | 1,513 | 1,213 | 110 | 190 | Preference window panes and settings management |
| **Events** | 6 | 1,215 | 859 | 191 | 165 | Global mouse click, hover, drag, and scroll monitoring |
| **Hotkeys** | 6 | 1,020 | 796 | 104 | 120 | Carbon low-level key combination registration |
| **Main** | 6 | 482 | 324 | 87 | 71 | Application lifecycle and centralized app state |
| **Permissions** | 4 | 457 | 360 | 47 | 50 | TCC permission status checks and system prompts |
| **Bridging** | 3 | 419 | 295 | 67 | 57 | Private SkyLight / CGS window server APIs |
| **Updates** | 1 | 156 | 109 | 28 | 19 | Sparkle update manager & silent check suppression |
| **UserNotifications**| 2 | 99 | 65 | 19 | 15 | Local user notification delivery |
| **Swizzling** | 1 | 36 | 26 | 4 | 6 | AppKit sidebar collapse behavior override |
| **Total Swift** | **116** | **18,298** | **13,492** | **2,546** | **2,260** | **100% Swift 5 Codebase** |

### 2.3 Hotspots & Files Requiring Refactoring

1. [`MenuBar/MenuBarItems/MenuBarItemManager.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/MenuBarItems/MenuBarItemManager.swift) **(1,671 LOC)**:
   - *Problem:* Severe god-class anti-pattern. Mixes item state caching, synthetic `CGEvent` injection, drag/drop coordination, animated `slowMove` interpolation, click simulation, and async timer loops.
   - *Recommendation:* Split into `MenuBarItemCache`, `MenuBarEventSimulator`, and `MenuBarDragCoordinator`.
2. [`MenuBar/Appearance/MenuBarOverlayPanel.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/Appearance/MenuBarOverlayPanel.swift) **(793 LOC)**:
   - *Problem:* Uncontrolled timer polling (5s wallpaper capture, 10s app menu frame update, 1ms Task sleep loops).
   - *Recommendation:* Switch to event-driven updates triggered by display configuration change and active space change notifications.
3. [`MenuBar/ControlItem/ControlItem.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/ControlItem/ControlItem.swift) **(577 LOC)**:
   - *Problem:* Relies on 10,000pt status item expansion hacks and traverses private AppKit layout constraints to force 0-width dividers.
4. [`Events/EventManager.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Events/EventManager.swift) **(556 LOC)**:
   - *Problem:* System-wide event tap intercepts every mouse movement across all applications, spawning un-debounced async tasks on hover.

### 2.4 Dead Code & Leftover Artifacts

- **16.4 MB of Unreferenced Design Files in `Resources/`**:
  - `Resources/Icon.fig` (140 KB), `Resources/Icon.png` (452 KB), `Resources/rearranging.gif` (3.0 MB), `Resources/rearranging.mov` (12.7 MB). These are leftover upstream Ice media files with zero codebase references.
- **Leftover Fros Carbon Signature:** [`HotkeyRegistry.swift:55`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Hotkeys/HotkeyRegistry.swift#L55) defines `signature = OSType(1181904755)` (`Fros`). Needs rename to `Skei` (`1399874921`).
- **Unused Document:** `Skein/Resources/Acknowledgements.rtf` (superseded by `Acknowledgements.pdf`).
- **Ancient Migrations:** Migration logic for Ice `0.8.0` through `0.11.10` in [`MigrationManager.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Utilities/MigrationManager.swift) can be safely pruned.

### 2.5 Tech Debt & Modernization Posture

- **Private SkyLight CGS APIs:** 13 functions declared via `@_silgen_name` in [`Bridging/Shims/Private.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Bridging/Shims/Private.swift).
- **Deprecated `CGWindowList`:** Used in [`ScreenCapture.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Utilities/ScreenCapture.swift) and [`WindowInfo.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Utilities/WindowInfo.swift) to capture off-screen status items that ScreenCaptureKit cannot currently capture.
- **Swift 6 & Concurrency Readiness:** Project is on Swift 5.0 with strict concurrency disabled. Heavy reliance on Combine (34 imports, 56 `@Published` properties, 0 usages of `@Observable`) and only 4 `Sendable` annotations.

---

## 3. Plans Status & Alignment

*Reference Report:* [`plans/reports/scout-260828-2201-plans.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/reports/scout-260828-2201-plans.md)

### 3.1 Plan Suite Audit Matrix

| Plan Directory | Real Status | Checked / Total Boxes | Shipped Release | Dependencies / Blockers | Notes |
|---|---|:---:|:---:|---|---|
| [`260727-2348-rebrand-ice-vc-to-frost`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/260727-2348-rebrand-ice-vc-to-frost) | **Superseded** | 41 / 48 | v1.0.0 | None | Shipped in 1.0.0; fully superseded by Skein rebrand. 7 GUI/permission checkboxes left un-ticked. |
| [`260728-0123-snowflake-icon-and-sparkle-plist-comments`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/260728-0123-snowflake-icon-and-sparkle-plist-comments) | **Shipped** | 0 / 26 | v1.1.0 | None | 100% live in code. All 26 markdown checkboxes were left unticked despite shipping in 1.1.0. |
| [`260728-0156-frost-app-icon-artwork`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/260728-0156-frost-app-icon-artwork) | **Shipped** | 27 / 27 | v1.2.1 | None | Shipped via PR #10. Adopted native Icon Composer bundle ([`AppIcon.icon`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/AppIcon.icon)) + PNG fallback. |
| [`260823-1239-rebrand-frost-to-skein`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/260823-1239-rebrand-frost-to-skein) | **Shipped** | 23 / 47 | v1.2.0 | None | 100% shipped in v1.2.0. 24 phase checkboxes never marked in markdown. |
| [`260823-1810-skein-landing-page`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/260823-1810-skein-landing-page) | **In-Progress** | 0 / 7 phases | Pending | Stream 2 Screenshots + DNS Cutover | In repo `ariadnev-skein-web`. Phase 1 merged (#1), PR #2 draft. Blocked on real UI screenshots. |

### 3.2 Handoff & Stream Status

- [`plans/handoffs/02b-install-escort-restart-20260828-1155.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/handoffs/02b-install-escort-restart-20260828-1155.md) is the **primary active handoff**. It contains the 8-step escort guide for the maintainer to perform a clean local upgrade verification, delete Frost.app, verify settings migration, and capture UI screenshots for the landing page.
- [`plans/handoffs/04b-landing-page-restart-20260828-1125.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/handoffs/04b-landing-page-restart-20260828-1125.md) is active for the landing page build stream on `bavanchun/ariadnev-skein-web`.

### 3.3 Orphaned & Dangling Items

1. **AccentColor Mismatch:** [`AccentColor.colorset`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Assets.xcassets/AccentColor.colorset) remains Ice default blue, while the new app icon is warm rope orange (`#E86A33`).
2. **Dead PNG Set:** [`AppIcon.appiconset`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Assets.xcassets/AppIcon.appiconset) is bypassed by `actool` in Xcode 26 in favor of `AppIcon.icon`. Retained only for the README image link.
3. **Markdown Checkbox Backfill:** 50 checkboxes across older shipped plans require backfill to reflect production reality.

---

## 4. Documentation Consistency Audit

*Reference Report:* [`plans/reports/scout-260828-2201-docs.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/reports/scout-260828-2201-docs.md)

### 4.1 Consistency Matrix Across Docs & Code

| Dimension | [`README.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/README.md) | [`CHANGELOG.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/CHANGELOG.md) | [`docs/release-guide.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/docs/release-guide.md) | [`docs/UPSTREAM.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/docs/UPSTREAM.md) | Actual Codebase Reality |
|---|---|---|---|---|---|
| **App Name** | Skein | Skein | Skein | Skein | Skein |
| **Bundle ID** | `com.ariadnev.Skein` | `com.ariadnev.Skein` | `com.ariadnev.Skein` | `com.ariadnev.Skein` | `com.ariadnev.Skein` |
| **Sparkle Feed** | N/A | `skein.ariadnev.com` | `https://skein.ariadnev.com/appcast.xml` | `https://ariadnev.com/skein/appcast.xml` *(Drift)* | `https://skein.ariadnev.com/appcast.xml` |
| **Current Version** | `latest` | 1.2.1 | Examples: 1.0.1 *(Drift)* | Lineage: 2.0.0 *(Drift)* | `1.2.1` (Build 1122) |
| **Packaging Recommendation**| ZIP / DMG | ZIP + DMG | ZIP primary (Gatekeeper rationale) | Unsigned + codesign | [`Scripts/make-dmg.sh`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Scripts/make-dmg.sh) |

### 4.2 Document Drift & Discrepancy Findings

1. [`CHANGELOG.md:78-84`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/CHANGELOG.md#L78-L84): Missing `[1.2.1]` markdown reference link at bottom; `[Unreleased]` points to `compare/v1.2.0...HEAD`.
2. [`docs/UPSTREAM.md:30`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/docs/UPSTREAM.md#L30): Lineage table lists Skein as `2.0.0 onward` (actual release version is `1.2.0` / `1.2.1`).
3. [`docs/UPSTREAM.md:41`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/docs/UPSTREAM.md#L41): Points Sparkle URL to `https://ariadnev.com/skein/appcast.xml` instead of the active `https://skein.ariadnev.com/appcast.xml`.
4. [`docs/upgrade-frost-to-skein.md:11,13`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/docs/upgrade-frost-to-skein.md#L11-L13): Hardcodes download link to `Skein-1.2.0.zip` instead of latest 1.2.1.
5. [`FREQUENT_ISSUES.md:15,25`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/FREQUENT_ISSUES.md#L15-L25): Links issues `[#6]` and `[#26]` to upstream `jordanbaird/Ice` without indicating they are upstream Ice issue numbers.
6. [`docs/DEVELOPMENT_WORKFLOW.md:998`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/docs/DEVELOPMENT_WORKFLOW.md#L998): Docs inventory omits `docs/upgrade-frost-to-skein.md`.

---

## 5. GitHub Backlog & Triage Status

*Reference Report:* [`plans/reports/scout-260828-2201-backlog.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/reports/scout-260828-2201-backlog.md)

### 5.1 Backlog Overview
- **Repository:** `bavanchun/ariadnev-skein`
- **Open Issues:** 0 | **Closed Issues:** 1 (Issue #16)
- **Open PRs:** 0 | **Merged PRs:** 15 (100% merge rate)
- **Oldest Open Item:** None (Clean inbox)

### 5.2 Closed Issue Analysis: #16 Notarization & Gatekeeper Friction
- **Context:** macOS Gatekeeper blocks execution of unsigned/personal-team builds on first launch without user right-click bypass.
- **Resolution:** Closed as `wontfix` based on maintainer trade-off ($99/year Apple Developer account vs early stage).
- **Mitigation Strategy:** Documented in [`docs/release-guide.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/docs/release-guide.md), release notes, and web download copy. ZIP recommended over DMG to provide a simpler bypass dialog.

### 5.3 Merged PRs Velocity
- **1.2.0 Rebrand Wave (PRs #1–#8):** Standalone repo standup, Xcode project rename, symbol renames, bundle ID migration, attribution rewrite, CI gate configuration.
- **1.2.1 Asset & Distribution Wave (PRs #9–#15):** Icon Composer rope artwork (#10), DMG generation tooling (#11, #12), plan audit logs (#13), release 1.2.1 (#14), and ZIP distribution recommendation (#15).

---

## 6. Bugs, Code Smells & Security Concerns

*Reference Report:* [`plans/reports/scout-260828-2201-security-quality.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/reports/scout-260828-2201-security-quality.md)

### 6.1 High Severity Defects

#### [HIGH-01] Unsafe Pointer Memory Leak in Screen Capture
- **Location:** [`Skein/Utilities/ScreenCapture.swift:63-72`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Utilities/ScreenCapture.swift#L63-L72)
- **Impact:** Continuous memory leak on every menu bar item hover or overlay panel refresh.
- **Root Cause:** `UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: windowIDs.count)` allocates memory for `CFArrayCreate`, but `pointer.deallocate()` is never called.
- **Fix:** Add `defer { pointer.deallocate() }` immediately following allocation.

#### [HIGH-02] Premature Loop Termination with `break` in App Relauncher
- **Location:** [`Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift:169`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift#L163-L171)
- **Impact:** Changing menu bar item spacing silently skips relaunching all applications appearing after Skein or ControlCenter in the PID list.
- **Root Cause:** `guard let app = ... else { break }` aborts the entire iteration instead of skipping the current item with `continue`.
- **Fix:** Replace `break` with `continue`.

#### [HIGH-03] Potential Array Slice Index Out-of-Bounds in CGS Window List
- **Location:** [`Skein/Bridging/Bridging.swift:104,122,140`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Bridging/Bridging.swift#L89-L141)
- **Impact:** Fatal crash under high window creation churn.
- **Root Cause:** Slicing `list[..<Int(realCount)]` throws an exception if `realCount > list.count`.
- **Fix:** Use `list.prefix(Int(realCount))` or `list[..<min(Int(realCount), list.count)]`.

### 6.2 Medium Severity Smells

- **[MED-01] 1ms Polling Spin-Loop:** [`MenuBarOverlayPanel.swift:150-166`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/Appearance/MenuBarOverlayPanel.swift#L150-L166) polls accessibility frames with 1ms intervals on app switches.
- **[MED-02] Async Continuation Leak on Unkillable App:** [`MenuBarItemSpacingManager.swift:87-109`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift#L87-L109) risks leaking continuations if target process refuses to terminate.
- **[MED-03] 404 URL in About Pane:** [`AboutSettingsPane.swift:23`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Settings/SettingsPanes/AboutSettingsPane.swift#L21-L28) links to old repo `https://github.com/bavanchun/Skein` instead of `https://github.com/bavanchun/ariadnev-skein`.
- **[MED-04] Unthrottled Hover Task Spawning:** [`EventManager.swift:348-397`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Events/EventManager.swift#L348-L397) spawns un-debounced async tasks on mouse moves.

---

## 7. Upstream Ice Drift Analysis

*Reference Report:* [`plans/reports/scout-260828-2201-upstream-drift.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/reports/scout-260828-2201-upstream-drift.md)

### 7.1 Commit Delta & Remote Status
- Upstream `main` (`jordanbaird/Ice`) has **0 missing commits** (diverged @ `11edd39` on 2025-09-20).
- Upstream active development branch `upstream/macos-26` is **77 commits ahead** of fork base `81c8ef3`.
- Skein is **34 commits ahead** of fork base with branding, icon artwork, packaging, and Sparkle fixes.

### 7.2 Key Upstream Improvements in `upstream/macos-26`

1. **Out-of-Process XPC Worker (`MenuBarItemService`):**
   - *Architecture:* Moves all Accessibility API queries and item bounding rect calculations into a separate XPC background daemon.
   - *Impact:* Guarantees the main app UI will never beachball when third-party status items hang or become unresponsive.
2. **HID Event Taps (`HIDEventManager`):**
   - *Architecture:* Replaces runloop event monitors with low-level `CGEvent` taps.
   - *Impact:* Fixes dropped clicks and missed hover transitions on macOS 15+ Sequoia.
3. **Control Center `sourcePID` Resolution:**
   - *Architecture:* Resolves parent process IDs when ControlCenter acts as window owner on newer macOS versions.
4. **Direct ScreenCapture `CGImage` Initializer:**
   - *Architecture:* Bypasses broken static protocol helpers to prevent screen capture failures.

### 7.3 Integration Strategy: Selective Porting (DO NOT DIRECT MERGE)
Direct `git merge` will cause fatal merge conflicts across every file due to project-wide renames. High-value fixes must be manually cherry-ported via isolated feature branches (`feat/port-*`).

---

## 8. Next-Week Proposed Roadmap

| Priority | Task & Objective | Target Files | Effort Estimate | Rationale |
|---|---|---|:---:|---|
| **P0** | **Patch Critical Shims & Bug Fixes**<br>Fix pointer leak, loop break, CGS slice crash, and 404 About URL. Tag v1.2.2. | [`ScreenCapture.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Utilities/ScreenCapture.swift)<br>[`MenuBarItemSpacingManager.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift)<br>[`Bridging.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Bridging/Bridging.swift)<br>[`AboutSettingsPane.swift`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Settings/SettingsPanes/AboutSettingsPane.swift) | **0.5 day** | Eliminates active memory leaks and crash traps in production binary. |
| **P1** | **Complete Landing Page & Stream 2 Escort**<br>Execute manual upgrade verification escort, capture real product UI screenshots, merge PR #2 on `ariadnev-skein-web`, cutover DNS. | [`plans/handoffs/02b-install-escort-restart-20260828-1155.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/handoffs/02b-install-escort-restart-20260828-1155.md) | **1.0 day** | Unblocks public web presence and validates clean Frost→Skein user migration. |
| **P1** | **Documentation & Repo Hygiene Pass**<br>Fix CHANGELOG links, update UPSTREAM lineage, prune 16.4 MB dead `Resources/` files, backfill 50 plan checkboxes. | [`CHANGELOG.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/CHANGELOG.md)<br>[`docs/UPSTREAM.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/docs/UPSTREAM.md)<br>[`Resources/`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Resources) | **0.5 day** | Eliminates documentation drift and repository bloat. |
| **P2** | **Port Upstream HID Event Taps & sourcePID Fixes**<br>Port `HIDEventManager` and `SourcePIDCache` from `upstream/macos-26` to prevent dropped clicks on macOS 15+. | [`Skein/Events/`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Events)<br>[`Skein/MenuBar/`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar) | **2.0 days** | Improves input reliability and menu bar item detection on macOS 15+. |
| **P3** | **Architecture Spike: `SkeinMenuBarItemService` XPC**<br>Port the upstream out-of-process XPC helper to isolate slow Accessibility API calls from the main thread. | `SkeinMenuBarItemService/`<br>[`Skein/MenuBar/`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/MenuBar) | **3.0 days** | Long-term performance safeguard against main-thread beachballing. |

---

## 9. Unresolved Questions & Maintainer Decisions

1. **Accent Color Update:** Should [`AccentColor.colorset`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/Skein/Assets.xcassets/AccentColor.colorset) be updated from Ice blue to warm rope orange (`#E86A33`) in patch release v1.2.2?
2. **Stream 2 Escort Timing:** When is maintainer ready to perform the manual install & screenshot capture steps in [`02b-install-escort-restart-20260828-1155.md`](file:///Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/handoffs/02b-install-escort-restart-20260828-1155.md)?
3. **Upstream XPC Architecture Priority:** Do current users experience UI hangs on complex menu bar items that justify scheduling the XPC service port immediately after the v1.2.2 patch?

---

*Audit completed autonomously by Antigravity.*
