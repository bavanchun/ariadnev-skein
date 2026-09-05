# Upstream Drift Analysis: Skein vs jordanbaird/Ice

**Date:** 2026-08-28  
**Author:** Agent E (Upstream Drift Analyzer)  
**Target:** `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein`  
**Upstream Repository:** `https://github.com/jordanbaird/Ice.git`  

---

## 1. Git State & Remote Commit Delta

### 1.1 Remote Configuration
- `origin`: `git@github.com:bavanchun/ariadnev-skein.git` (active fork / standalone repo)
- `upstream`: `https://github.com/jordanbaird/Ice.git` (fetched 2026-08-28)
- Fork base commit: `11edd39115f3f43a83ae114b5348df6a0e1741cf` ("Update issue templates", 2025-09-20)

### 1.2 Commit Comparison Matrix

| Branch Comparison | Missing in Skein (`main..ref`) | Missing Upstream (`ref..main`) | Merge Base | Description / Status |
|---|---|---|---|---|
| `main` vs `upstream/main` | **0** | **34** | `11edd39` | Skein contains all upstream `main` commits. `upstream/main` is idle since 2025-09-20. |
| `main` vs `upstream/0.12.0` | **0** | **71** | `f24e08a` | Fully merged into `upstream/main` prior to fork base. |
| `main` vs `upstream/macos-26` | **77** | **36** | `81c8ef3` | Major active development branch (June–Sept 2025) containing macOS compatibility, XPC helper, and architecture refactors. Never merged to `upstream/main`. |
| `main` vs `upstream/macos-26-old` | **44** | **36** | `81c8ef3` | Early prototype of `macos-26` branch; superseded by `upstream/macos-26`. |
| `main` vs `upstream/profiles` | **7** | **71** | `f24e08a` | Experimental menu bar item profile switching branch (Oct 2024); unmerged/stalled. |

### 1.3 Upstream Release Tags
- `0.11.12` (2024-10-29): Last stable release in upstream `main`.
- `0.11.13-dev.1` (`7771686`, 2025-06-20): First developer preview on `upstream/macos-26`.
- `0.11.13-dev.2` (`da2dd23`, 2025-09-16): Second developer preview on `upstream/macos-26`.

---

## 2. Upstream Features & Fixes Analysis (`upstream/macos-26`)

Although `upstream/main` has 0 missing commits, upstream development shifted to `upstream/macos-26` (77 commits, 182 files touched, +10,620 / -8,413 lines). Key changes breakdown:

### 2.1 macOS Compatibility & System Integration
| Commit | Component | Technical Change & Rationale |
|---|---|---|
| `bd49603`, `de6e3af` | `MenuBarItemTag`, `SourcePIDCache` | **Control Center Ownership Fix:** On newer macOS (macOS 15/16 Tahoe), Control Center owns menu bar item window IDs (`ownerPID`). Introduced `sourcePID` resolution to trace back to originating application. |
| `28712ea` | `MenuBarAppearanceManager` | **Dynamic Insets:** Added OS check `menuBarInsetAmount: CGFloat = if #available(macOS 26.0, *) { 3.5 } else { 5 }` to prevent visual clipping. |
| `075581c`, `292556f`, `f8828cd` | `HIDEventManager`, Event Taps | **Mouse Event Drops:** `RunLoopLocalEventMonitor` caused button click drops on newer macOS betas. Replaced with `CGEvent` event taps and renamed `EventManager` -> `HIDEventManager`. |
| `38d344f` | `ScreenCapture.swift` | **Capture Failure Fix:** Reverted static protocol wrapper back to direct `CGImage` initializer to resolve screen capture failures. |
| `ac313f2` | `Entitlements` | **Sandbox Disabled:** Disabled App Sandbox due to strict Accessibility API and cross-process XPC requirements. |

### 2.2 Out-of-Process XPC Service (`MenuBarItemService`)
- **Commits:** `8adf5a4`, `998474c`, `2295985`
- **Architecture:** Moved `MenuBarItemSourceCache` and AX query operations (`AXUIElementCopyAttributeValue`, item bounding rects) into a standalone XPC background service target (`MenuBarItemService`).
- **Benefit:** Completely insulates the main application UI thread from beachballing/freezes caused by slow or unresponsive third-party menu bar items during Accessibility calls. Main app communicates asynchronously over high-priority concurrent queues (`MenuBarItemServiceConnection`).

### 2.3 Menu Bar Item Caching & Event Optimization
- **Commits:** `bd49603`, `4b57b4a`, `a2b8e53`, `90a0650`, `9c6740c`, `8d4b6a5`, `ea4df54`, `8c0b9bb`
- **Details:**
  - Added dirty-checking in `MenuBarItemManager` to skip cache invalidation if item list is unchanged (`ea4df54`).
  - Fixed image caching glitches during rapid hover and temporary display transitions (`4b57b4a`, `a2b8e53`).
  - Introduced `MenuBarItemTag` to encapsulate item identifier, source PID, and window layer metadata.

### 2.4 UI, Search & Settings Overhaul
- **Commits:** `a7ae7a1`, `8eaec4b`, `eaa5d93`, `b77730e`, `389588e`, `f233bf3`
- **Details:**
  - Redesigned search panel: full-screen display support, fuzzy matching improvement (`MenuBarSearchModel`), and dynamic color adaptation to average menu bar wallpaper luminance.
  - Replaced legacy custom pickers with unified SwiftUI `IceUI` design system (`IceForm`, `IceGradientPicker`, `IceGroupBox`, `IceSection`, `IceSlider`, `IceWindow`, `CalloutBox`).
  - Refactored settings storage into modular Swift structs (`AppSettings`, `GeneralSettings`, `HotkeysSettings`, `AdvancedSettings`).

---

## 3. Skein-Specific Enhancements (Missing Upstream)

Skein contains 34 commits since diverging from `upstream/main` @ `11edd39`:

| Area | Skein Feature / Change | Upstream State |
|---|---|---|
| **Branding & Identity** | Complete project-wide rebrand: `Ice` -> `Frost` (1.0/1.1) -> `Skein` (1.2+). Renamed Xcode project (`Skein.xcodeproj`), source directory (`Skein/`), Swift symbols (`SkeinApp`, `SkeinBar`, `SkeinSection`, `SkeinUI`, etc.), and bundle ID `com.ariadnev.Skein`. | Retains `Ice` naming, `com.jordanbaird.Ice`. |
| **Settings Migration** | `MigrationManager` implements multi-generational migration from `com.jordanbaird.Ice` and `com.vchun.Frost` domains to `com.ariadnev.Skein`. | Upstream has internal migrations only for older Ice versions. |
| **Visual Assets** | Custom yarn skein / rope-loop icon artwork (`Skein/AppIcon.icon`), stroke mark, Snowflake SF symbol alternative for menu bar. | Retains ice cube icon artwork. |
| **Sparkle Update Fix** | Disabled unclickable update-permission prompt on accessory startup (`6ab6fcb`), configured custom appcast feed (`https://ariadnev.com/skein/appcast.xml`) and EdDSA public key. | Unmodified Sparkle default configuration. |
| **Packaging & DMG** | Custom DMG creation tool (`Scripts/make-dmg.sh`), inside-out ad-hoc/developer signing workflow, ZIP recommendation documentation for Gatekeeper quarantine handling. | Standard Xcode archive / zip release script. |
| **CI / Quality Gate** | GitHub Actions build verification workflow (`.github/workflows/ci.yml`) with file change path filtering. | Minimal upstream CI. |
| **Landing Page & Docs** | Comprehensive documentation (`docs/UPSTREAM.md`, `DEVELOPMENT_WORKFLOW.md`, `release-guide.md`, `docs/distribution-reality/`) and web landing page integration. | Upstream README only. |

---

## 4. Integration Recommendations & Conflict Risk Assessment

### 4.1 Conflict Risk Matrix
- **`git merge upstream/main`**: **Zero conflict / No-op** (Skein already contains all commits up to `11edd39`).
- **`git merge upstream/macos-26`**: **100% Fatal Conflict (DO NOT MERGE)**.
  - Every single source file was renamed (`Ice/` -> `Skein/`, `Ice*.swift` -> `Skein*.swift`).
  - Project file (`project.pbxproj`) has completely diverged in UUIDs, target names, file references, and bundle settings.
  - Symbols (`IceBar`, `IceSection`, `IceApp`) renamed across entire codebase.
  - Git will fail to detect renames across massive structural changes and report hundreds of conflicting deletions/additions.

### 4.2 Cherry-Pick / Manual Porting Plan

Instead of branch merges, adopt **selective manual porting** using dedicated feature branches (`feat/port-*`):

| Priority | Feature / Patch | Upstream Commits | Implementation Strategy |
|---|---|---|---|
| **P0 (Critical)** | **XPC Worker (`MenuBarItemService`)** | `8adf5a4`, `998474c`, `2295985` | Port the XPC helper architecture to isolate AX calls. Rename target to `SkeinMenuBarItemService`, update bundle ID to `com.ariadnev.Skein.MenuBarItemService`. Prevents main thread UI freeze. |
| **P0 (Critical)** | **HID Event Tap & Click Fixes** | `075581c`, `292556f`, `f8828cd`, `8c0b9bb` | Port `HIDEventManager` event tap logic to replace `RunLoopLocalEventMonitor` to eliminate dropped clicks on macOS 15+. |
| **P1 (High)** | **Control Center `sourcePID` Resolution** | `bd49603`, `de6e3af` | Port `SourcePIDCache` and `MenuBarItemTag` logic so menu bar items correctly identify their parent apps on macOS 15/16. |
| **P1 (High)** | **Screen Capture Direct Init** | `38d344f` | Apply direct `CGImage` init in `Skein/Utilities/ScreenCapture.swift` to prevent capture errors. |
| **P2 (Medium)** | **Dynamic Menu Bar Inset** | `28712ea` | Add macOS version check for `menuBarInsetAmount` (3.5 vs 5) in `Skein/MenuBar/Appearance/MenuBarAppearanceManager.swift`. |
| **P3 (Low / Skip)** | **`IceUI` & Settings Redesign** | `b77730e`, `a7ae7a1`, `IceUI/*` | **Skip / Defer.** Skein's current UI and settings structure is functional and stable. Porting full UI would require extensive re-skinning with minimal UX gain. |
| **P3 (Skip)** | **Profiles Branch** (`upstream/profiles`) | `upstream/profiles` | **Skip.** Incomplete and unmaintained upstream experiment. |

---

## 5. Summary Table

```
+---------------------------------------------------------------------------------------+
| SKEIN vs UPSTREAM/ICE DRIFT STATUS                                                    |
+---------------------------------------------------------------------------------------+
| Upstream main status    : Fully synced (0 missing commits, fork at 11edd39)           |
| Upstream active branch  : macos-26 (77 commits ahead of base 81c8ef3)                |
| Highest value upstream  : Out-of-process XPC AX service, HID Event Tap, sourcePID fix |
| Conflict risk           : Severe (Full project & symbol rename)                       |
| Recommendation          : Never direct-merge. Selectively port XPC & HID fixes        |
+---------------------------------------------------------------------------------------+
```

---

## Unresolved Questions

1. **XPC Code Signing Requirements:** Does extracting `MenuBarItemService` into an XPC helper require special signing entitlements or notarization for ad-hoc / local developer builds under macOS 15 Gatekeeper?
2. **Current macOS 15 Sequoia Stability:** Are users currently experiencing dropped clicks or AX beachballing in Skein 1.2.1 that necessitate immediately prioritizing the P0 `MenuBarItemService` / `HIDEventManager` ports?
3. **Upstream Release Status:** Will upstream Jordan Baird officially merge `macos-26` into `main` and release `0.12.0`, or has upstream development permanently stalled as of September 2025?
