# Security & Code Quality Review: Skein (Menubar Manager)

**Target**: `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein`  
**Reviewer**: Agent F (Security and Quality Code Reviewer)  
**Report Destination**: `plans/reports/scout-260828-2201-security-quality.md`  
**Date**: 2026-08-28

---

## 1. Executive Summary & Scope

A comprehensive security, memory safety, concurrency, and code quality audit was performed on the Skein macOS codebase, focusing on Skein-specific customizations, the Frost → Skein rebrand divergence, IPC/private bridging shims, permissions subsystems, process execution, and event handling.

### Key Metrics & Findings Summary
- **Critical / High Issues**: 3 (Unsafe pointer memory leak, Relaunch loop termination bug, CGS window list slice bounds crash risk)
- **Medium Priority Issues**: 4 (1ms AX query spin-loop, Unhandled async continuation hang in process quit, Broken repository URLs in UI, Unthrottled hover task spawning race)
- **Low Priority / Code Smells**: 4 (Force-unwraps on Bundle metadata/resources, Legacy 'Fros' Carbon signature, @ObservedObject on App root, Unchecked process exit status)
- **Overall Posture**: Architecture is modular and sandboxing is intentionally disabled for menu bar control. However, manual memory management in bridging shims contains a critical memory leak that degrades long-running instances.

---

## 2. Skein-Specific Delta & Subsystem Analysis

### 2.1 Identity, Entitlements & Code Signing
- **Bundle ID**: Updated to `com.ariadnev.Skein` across project configs (`Skein.xcodeproj/project.pbxproj:328,360`).
- **Entitlements** (`Skein/Skein.entitlements`):
  - `com.apple.security.app-sandbox`: `false` (Required for private WindowServer / CGS connection and cross-process menu bar accessibility control).
  - `com.apple.security.files.user-selected.read-only`: `true`.
- **Sparkle Configuration** (`Skein/Info.plist`, `Skein/Updates/UpdatesManager.swift`):
  - `SUFeedURL`: Configured to `https://skein.ariadnev.com/appcast.xml` (Cloudflare Worker proxy routing to GitHub Releases, preventing URL lock-in).
  - `SUPublicEDKey`: Retained Ed25519 public key (`bmSMi+6/ONtryIpi0NiU5f4FSWYiAr+eFH5VjP9jdqE=`).
  - `SUEnableAutomaticChecks`: Enabled upfront with custom UI suppression in `UpdatesManager` to prevent unclickable permission dialogs in menu bar accessory mode.

### 2.2 Packaging & CI/CD
- **`Scripts/make-dmg.sh`**:
  - Uses `set -euo pipefail`. Correctly validates app bundle existence, extracts version via `defaults read`, creates UDZO compressed disk image, and conditionally codesigns if `Apple Development` identity is present. Safe and idempotent.
- **`Scripts/generate-icon-artwork.py`**:
  - Parametric rope icon generation using `ictool` and Pillow. Clean file handling with temporary directory cleanup (`shutil.rmtree(tmp)` in `finally`).
- **`.github/workflows/ci.yml`**:
  - Path filtering via `dorny/paths-filter`. macOS runner builds unsigned binary (`CODE_SIGNING_ALLOWED=NO`), runs strict SwiftLint, and uses change gate pattern.

### 2.3 Migration Logic
- **`Skein/Utilities/MigrationManager.swift` (`migrate2_0_0`)**:
  - Reads `com.vchun.Frost` persistent domain via `UserDefaults.standard.persistentDomain(forName:)`.
  - Maps 6 renamed keys (`ShowFrostIcon` → `ShowSkeinIcon`, `FrostIcon` → `SkeinIcon`, `CustomFrostIconIsTemplate` → `CustomSkeinIconIsTemplate`, `UseFrostBar` → `UseSkeinBar`, `FrostBarLocation` → `SkeinBarLocation`, `FrostBarPinnedLocation` → `SkeinBarPinnedLocation`).
  - Refiles saved hotkey from `EnableFrostBar` to `EnableSkeinBar`.
  - Preserves existing values without clobbering (`guard UserDefaults.standard.object(forKey: newKey) == nil`).
  - **Limitation**: Only migrates from `com.vchun.Frost`. Any legacy `com.jordanbaird.Ice` installs jumping directly to Skein will not have domain migration applied.

---

## 3. High Severity Findings

### [HIGH-01] Memory Leak in Unsafe Pointer Allocation (`ScreenCapture.swift:64`) — **RESOLVED** in [PR #17](https://github.com/bavanchun/ariadnev-skein/pull/17), shipped in [v1.2.2](https://github.com/bavanchun/ariadnev-skein/releases/tag/v1.2.2)
- **File**: `Skein/Utilities/ScreenCapture.swift` (Lines 63–72)
- **Impact**: Memory leak every time menu bar items or overlay window images are captured or cached.
- **Root Cause**: `UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: windowIDs.count)` allocates heap memory for the `CFArrayCreate` call, but `pointer.deallocate()` is **never called**.
```swift
// Skein/Utilities/ScreenCapture.swift:63-72
static func captureWindows(_ windowIDs: [CGWindowID], screenBounds: CGRect? = nil, option: CGWindowImageOption = []) -> CGImage? {
    let pointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: windowIDs.count)
    // BUG: Missing `defer { pointer.deallocate() }`
    for (index, windowID) in windowIDs.enumerated() {
        pointer[index] = UnsafeRawPointer(bitPattern: UInt(windowID))
    }
    guard let windowArray = CFArrayCreate(kCFAllocatorDefault, pointer, windowIDs.count, nil) else {
        return nil
    }
    return .windowListImage(from: screenBounds ?? .null, windowArray: windowArray, imageOption: option)
}
```
- **Remediation**: Add `defer { pointer.deallocate() }` immediately after allocation, or use `windowIDs.map { UnsafeRawPointer(bitPattern: UInt($0)) }.withUnsafeBufferPointer { ... }`.

---

### [HIGH-02] Premature Loop Termination with `break` in App Relauncher (`MenuBarItemSpacingManager.swift:169`) — **RESOLVED** in [PR #17](https://github.com/bavanchun/ariadnev-skein/pull/17), shipped in [v1.2.2](https://github.com/bavanchun/ariadnev-skein/releases/tag/v1.2.2)
- **File**: `Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift` (Lines 163–171)
- **Impact**: Applying item spacing offsets silently fails to restart remaining menu bar applications.
- **Root Cause**: The loop iterating over menu bar owner PIDs encounters a `guard ... else { break }`. If the first or intermediate PID belongs to Skein itself (`app == .current`) or ControlCenter (`app.bundleIdentifier == "com.apple.controlcenter"`), the loop executes `break` instead of `continue`, instantly terminating the task group dispatch for all subsequent applications.
```swift
// Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift:163-171
await withTaskGroup(of: Void.self) { group in
    for pid in pids {
        guard
            let app = NSRunningApplication(processIdentifier: pid),
            app.bundleIdentifier != "com.apple.controlcenter",
            app != .current
        else {
            break // <--- DEFECT: Must be `continue`, NOT `break`
        }
        group.addTask { @MainActor in ... }
    }
}
```
- **Remediation**: Replace `break` with `continue`.

---

### [HIGH-03] Potential Buffer Overflow / Out-of-Bounds Crash in CGS Window List Shims (`Bridging.swift:104,122,140`) — **RESOLVED** in [PR #17](https://github.com/bavanchun/ariadnev-skein/pull/17), shipped in [v1.2.2](https://github.com/bavanchun/ariadnev-skein/releases/tag/v1.2.2)
- **File**: `Skein/Bridging/Bridging.swift` (Lines 89–141)
- **Impact**: Fatal crash (`Array slice index out of range`) under high window churn.
- **Root Cause**: `getWindowList()` queries `getWindowCount()` to allocate an array of size `windowCount`, then invokes `CGSGetWindowList(..., &list, &realCount)`. If another process creates a window in the microsecond interval between the two CGS calls, `realCount` can exceed `windowCount`. Slicing `list[..<Int(realCount)]` will cause an uncaught index out-of-bounds trap.
```swift
// Skein/Bridging/Bridging.swift:104
return [CGWindowID](list[..<Int(realCount)]) // If realCount > list.count -> CRASH
```
- **Remediation**: Bound slice with `list.prefix(Int(realCount))` or `list[..<min(Int(realCount), list.count)]`.

---

## 4. Medium Severity Findings

### [MED-01] 1ms Polling Spin-Loop on Accessibility Queries (`MenuBarOverlayPanel.swift:150-166`)
- **File**: `Skein/MenuBar/Appearance/MenuBarOverlayPanel.swift` (Lines 150–166)
- **Impact**: Excessive CPU usage and battery drain during application switching or when menu bar frames fail to resolve.
- **Root Cause**: In `updateTaskContext.setTask(for: .applicationMenuFrame)`, when `latestFrame` is nil or unchanged before `hasDoneInitialUpdate` is true, the loop sleeps for `1 millisecond` (`Task.sleep(for: .milliseconds(1))`) and immediately re-executes IPC Accessibility API traversals.
- **Remediation**: Increase initial backoff to at least 50–100ms or use event-driven frame change notifications.

---

### [MED-02] Potential Indefinite Continuation Hang & Leak in App Quit Signaling (`MenuBarItemSpacingManager.swift:87-109`)
- **File**: `Skein/MenuBar/Spacing/MenuBarItemSpacingManager.swift` (Lines 87–109)
- **Impact**: UI lockup / hung async tasks when changing menu bar item spacing if an application refuses to quit.
- **Root Cause**: `signalAppToQuit` uses `withCheckedThrowingContinuation`. If a target process is unkillable (kernel wait, D-state zombie, modal dialog deadlock), `app.publisher(for: \.isTerminated)` never fires. The timeout task calls `app.forceTerminate()`, but if termination fails, `continuation.resume()` is never called. Also, `[weak self]` in `.sink` drops the continuation without resuming if manager is deallocated.
- **Remediation**: In `timeoutTask`, if the app remains unterminated after a hard grace period (e.g. 2s post-force-terminate), resume continuation with `RelaunchError()` and cancel subscription.

---

### [MED-03] 404 URL in About Pane (`AboutSettingsPane.swift:23`)
- **File**: `Skein/Settings/SettingsPanes/AboutSettingsPane.swift` (Lines 21–28)
- **Impact**: User clicking "Contribute" or "Report a Bug" hits GitHub 404.
- **Root Cause**: Hardcoded URL points to `https://github.com/bavanchun/Skein` instead of the renamed canonical repo `https://github.com/bavanchun/ariadnev-skein`.
```swift
// Skein/Settings/SettingsPanes/AboutSettingsPane.swift:23
URL(string: "https://github.com/bavanchun/Skein")! // Should be bavanchun/ariadnev-skein
```
- **Remediation**: Update repository URL to `https://github.com/bavanchun/ariadnev-skein`.

---

### [MED-04] Unthrottled Async Task Spawning on Mouse Hover (`EventManager.swift:368-397`)
- **File**: `Skein/Events/EventManager.swift` (Lines 348–397)
- **Impact**: Spawns dozens of concurrent un-debounced background tasks on mouse movement over empty menu bar areas, causing potential show/hide race conditions.
- **Root Cause**: `mouseMovedMonitor` calls `handleShowOnHover()` directly on every event without cancelling or debouncing existing in-flight sleep tasks.
- **Remediation**: Track an active `hoverTask: Task<Void, Never>?` in `EventManager` and cancel prior task before creating a new one.

---

## 5. Low Priority & Quality Smells

### [LOW-01] Force Unwrapping Bundle & Resource URLs
- `Skein/Utilities/Constants.swift:11-20`: Force unwraps `Bundle.main.versionString!`, `Bundle.main.buildString!`, `Bundle.main.copyrightString!`, `Bundle.main.bundleIdentifier!`. Prevents clean unit-testing without mock bundles.
- `Skein/Settings/SettingsPanes/AboutSettingsPane.swift:18`: `Bundle.main.url(forResource: "Acknowledgements", withExtension: "pdf")!` will cause runtime crash if PDF asset packaging fails.

### [LOW-02] Legacy 'Fros' Carbon Hotkey Signature (`HotkeyRegistry.swift:55`)
- `HotkeyRegistry.swift:55` defines `signature = OSType(1181904755)` (`'Fros'`). Harmless for functionality, but should be updated to `'Skei'` (`1399874921`) for ecosystem consistency.

### [LOW-03] `@ObservedObject` Instantiation on Root App Struct (`SkeinApp.swift:11`)
- `SkeinApp.swift:11` declares `@ObservedObject var appState = AppState()`. In SwiftUI, creating an object instance with `@ObservedObject` on root struct can cause redundant instantiation if parent view hierarchy invalidates. Should be `@StateObject var appState = AppState()`.

### [LOW-04] Unchecked Exit Status in Shell Command Execution (`MenuBarItemSpacingManager.swift:47-59`)
- `runCommand` calls `process.waitUntilExit()` without checking `process.terminationStatus`. Failure errors are not propagated.

---

## 6. Security Posture Assessment

| Vector | Status | Notes |
|---|---|---|
| **App Sandbox** | Disabled | Required for CGS WindowServer private API integration and global event monitoring. |
| **Permissions** | Guarded | Accessibility (`AXIsProcessTrusted`) and Screen Capture (`CGPreflightScreenCaptureAccess` + `SCShareableContent`) strictly checked before queries. |
| **Process Exec** | Controlled | Only executes `/usr/bin/env defaults` with static argument strings for item spacing adjustment. |
| **IPC / Schemes** | Minimal | No custom URL schemes registered in Info.plist. Listens only to system `AppleInterfaceThemeChangedNotification`. |
| **Sparkle Security** | Enforced | Strict Ed25519 verification (`SUPublicEDKey`), TLS required (`https://skein.ariadnev.com`), Sparkle updater prompt bypassed cleanly. |
| **Memory / Pointers**| Action Needed | Pointer leak in `ScreenCapture.swift` (HIGH-01) must be patched. |

---

## 7. Recommended Action Plan

1. **Fix `ScreenCapture.swift` Memory Leak** (HIGH-01): Insert `defer { pointer.deallocate() }` or use Swift buffer pointers.
2. **Fix `MenuBarItemSpacingManager.swift` Loop Bug** (HIGH-02): Change `break` to `continue` on line 169.
3. **Protect CGS Array Slices** (HIGH-03): Replace `list[..<Int(realCount)]` with `list.prefix(Int(realCount))`.
4. **Fix About Pane URLs** (MED-03): Update `AboutSettingsPane.swift:23` to `https://github.com/bavanchun/ariadnev-skein`.
5. **Debounce Hover Tasks & Overlay Polling** (MED-01, MED-04): Add task cancellation in `EventManager` and increase AX sleep backoff in `MenuBarOverlayPanel`.

---

## 8. Unresolved Questions

1. **Ice → Skein Direct Upgrade Support**: Should `MigrationManager` also look for legacy `com.jordanbaird.Ice` defaults domain if `com.vchun.Frost` is missing, or is migration strictly supported only from Frost?
2. **Carbon Hotkey OSType Signature**: Is there any dependency on preserving the `'Fros'` FourCharCode signature across upgrades, or can it safely transition to `'Skei'`?
3. **ScreenCaptureKit Migration**: Is there a timeline to deprecate remaining legacy `CGWindowListCopyWindowInfo` calls once Apple adds offscreen status item compositing to `ScreenCaptureKit`?
