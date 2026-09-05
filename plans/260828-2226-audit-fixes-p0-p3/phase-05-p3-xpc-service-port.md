---
phase: 5
title: "P3 — Port XPC MenuBarItemService → v1.4.0"
status: pending
priority: P3
effort: "3.0 days"
dependencies: [4]
release: "v1.4.0 (tags Phase 4 + Phase 5 together)"
---

# Phase 5: P3 — Port XPC MenuBarItemService

## Overview

Selectively port the upstream `MenuBarItemService` out-of-process XPC daemon from `upstream/macos-26`. All Accessibility API queries and menu bar item bounding-rect calculations move into a background helper process; if a third-party status item hangs, the main UI never beachballs. This is the largest architectural port in the plan train — split across a distinct helper target in the Xcode project, wired via XPC, with graceful degradation when the service is unavailable.

## Requirements

### Functional
- New target `SkeinMenuBarItemService` in the Xcode project: XPC service, embedded in `Skein.app/Contents/XPCServices/`.
- Main app's `MenuBarItemManager` (and any other AX-touching site) proxies AX queries through XPC when the service is reachable; falls back to in-process AX calls when service unreachable (do NOT degrade user visibility if XPC fails).
- If a third-party status item hangs (simulated by a long AX call), Skein's main UI stays responsive (menu bar overlay renders, settings pane opens, quit works within 1 second).

### Non-Functional
- Bundle size increase ≤ 300 KB.
- No new third-party dependencies; XPC via Apple's `NSXPCConnection`.
- macOS 14 compatible.

## Architecture

Three architectural changes, all in one PR because splitting mid-way leaves the app in a broken state:

1. **New Xcode target `SkeinMenuBarItemService`** — a `com.ariadnev.Skein.MenuBarItemService` XPC service, embedded, sandbox-off (matches main app), same Team ID, Hardened Runtime on.
2. **XPC protocol** — `MenuBarItemServiceProtocol` (`@objc` protocol) with methods: `windowsForItem(withIdentifier:reply:)`, `frameForItem(withIdentifier:reply:)`, plus enumeration methods matching upstream.
3. **Client shim in main app** — `MenuBarItemManager` (or a new `MenuBarItemXPCClient`) creates `NSXPCConnection`, invalidates on quit, retries once on interruption, falls back to synchronous in-process AX after 2 failures.

## Related Code Files

- Create: `SkeinMenuBarItemService/main.swift` (service entry)
- Create: `SkeinMenuBarItemService/Info.plist`
- Create: `SkeinMenuBarItemService/MenuBarItemServiceProtocol.swift` (shared protocol; add to both targets)
- Create: `SkeinMenuBarItemService/MenuBarItemService.swift` (service implementation)
- Create: `SkeinMenuBarItemService/SkeinMenuBarItemService.entitlements`
- Create: `Skein/MenuBar/MenuBarItems/MenuBarItemXPCClient.swift` (client shim)
- Modify: `Skein.xcodeproj/project.pbxproj` (new target, embed rule, dependency, signing)
- Modify: `Skein/MenuBar/MenuBarItems/MenuBarItemManager.swift` (route AX calls through client shim, fallback path)
- Modify: `Skein.entitlements` (if XPC service inclusion requires — verify)
- Modify: `Skein.xcodeproj/project.pbxproj` — version bump (Phase 4 + Phase 5) 1.3.0→1.4.0, build 1130→1140
- Modify: `CHANGELOG.md` — `[1.4.0]` entry covering Phase 4 + Phase 5

## OUT OF SCOPE

- Moving anything else out-of-process. Only AX / item-bounds queries.
- Rewriting `MenuBarItemManager` beyond the routing shim. Its god-class refactor stays deferred.
- Any UI change.
- Any additional upstream commit that isn't part of the XPC service extraction.

## Implementation Steps

1. Branch `feat/phase-05-p3-xpc-service-port` from `main` (after Phase 4 merged).
2. `/ak:scout` upstream: `git log --oneline upstream/macos-26 -- Ice/MenuBarItemService/ | head -30` → identify commits.
3. In Xcode: create new XPC Service target `SkeinMenuBarItemService`, bundle id `com.ariadnev.Skein.MenuBarItemService`, embed in app.
4. Copy upstream `MenuBarItemService/` files, apply Skein renames, add to new target.
5. Create `MenuBarItemXPCClient.swift` in main app with NSXPCConnection wire-up + fallback path.
6. Wire `MenuBarItemManager` call sites (audit says 1671 LOC — sub-30 call sites, PM estimate ≤15) through the client.
7. Build both targets — must exit 0.
8. Bump pbxproj version 1.4.0 / 1140. CHANGELOG `[1.4.0]` entry covers Phase 4 + Phase 5.
9. Package (Scripts/make-dmg.sh — verify signature on XPC service too).
10. **Manual test protocol** (agy writes, maintainer runs):
    - Install a real third-party status item that occasionally hangs (or simulate via a debug hang injected at AX call site during test build).
    - Confirm main UI stays responsive.
    - Confirm menu bar overlay renders correctly when service is up.
    - Kill the XPC service process externally (`launchctl kickstart -k gui/501/com.ariadnev.Skein.MenuBarItemService` or similar): main app must not crash, fallback path activates.
11. Open PR titled `release: 1.4.0 (macOS 15+ reliability — HID event taps + XPC MenuBarItemService)`. Body cross-references Phase 4 and Phase 5 outcomes.

## PM VERIFICATION CHECKLIST

- [ ] New target `SkeinMenuBarItemService` present in project.pbxproj with correct bundle id and Team ID.
- [ ] `codesign -dv Skein.app/Contents/XPCServices/SkeinMenuBarItemService.xpc` clean, same Team ID as main app.
- [ ] `MenuBarItemXPCClient.swift` implements fallback (grep for "fallback" or in-process AX path in the file).
- [ ] `MenuBarItemManager.swift` diff: all AX call sites either route through XPCClient or have an explicit inline comment justifying why they stayed synchronous.
- [ ] `xcodebuild` builds both targets, exit 0.
- [ ] Manual test protocol results attached in PR body — maintainer confirms all 3 checks (responsive, renders correctly, fallback works).
- [ ] pbxproj shows exactly `MARKETING_VERSION = 1.4.0;` twice, `CURRENT_PROJECT_VERSION = 1140;` twice for main; XPC target versions may differ per Apple convention.
- [ ] `[1.4.0]` CHANGELOG entry references Phase 4 (HID/sourcePID) and Phase 5 (XPC).
- [ ] `stat -f %z Skein-1.4.0.zip` matches appcast enclosure length exactly.

## Success Criteria

- [ ] PR merged, v1.4.0 tagged (with maintainer explicit approval — PM does not tag unilaterally).
- [ ] Release published; Sparkle rolls 1.3.0 → 1.4.0 cleanly on a real Mac.
- [ ] Beachball reproduction from a hanging third-party status item DOES NOT freeze main UI (maintainer-confirmed).

## Risk Assessment

- **XPC signing subtleties.** Signal: `codesign` on XPC service fails or `spctl` rejects. Response: agy invokes `/ak:advise`, PM asks kongming, PM makes go/no-go before merge. Do NOT ship if XPC signing is broken.
- **Bundle size explosion.** Signal: ZIP > 6 MB (baseline ~4.4 MB). Response: audit XPC service imports, remove unnecessary framework linkage.
- **Fallback path never exercised in dev.** Signal: PR CI green but fallback code has never actually run in this branch. Response: PM manually verifies by killing XPC service on a debug build and observing fallback engagement.
- **Sparkle update from 1.3.0 to 1.4.0 fails to launch XPC on first run.** Signal: user updates, next launch main app runs but AX queries all timeout. Response: XPC service must be embedded correctly with Hardened Runtime + inheriting entitlements; PM checks pkg structure.

---

## AGY BRIEF (feed this verbatim to agy)

Bạn thực thi Phase 5 (phase cuối). Đọc `phase-05-p3-xpc-service-port.md`.

CWD: `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein`
Branch: `feat/phase-05-p3-xpc-service-port` từ `main` (sau khi Phase 4 merge).

### Skills bắt buộc
- `/ak:scout` — đọc `plans/reports/scout-260828-2201-upstream-drift.md` phần XPC daemon. `git log upstream/macos-26 -- Ice/MenuBarItemService/`.
- `/ak:fix` — port + adapt.
- `/ak:test` — build 2 target, tự soạn manual test protocol.
- `/ak:code-review` — self-review, đặc biệt XPC signing + fallback path.
- `/ak:advise` — **BẮT BUỘC** dùng ít nhất 1 lần trong phase này (XPC signing subtleties là điểm dễ sai nhất), khuyến khích trước khi bắt tay vào Xcode project surgery và trước khi push PR.
- `/ak:ship` — chuẩn bị ZIP + DMG + appcast, verify byte match.

### Hard rules
1. Xcode project surgery: nếu bạn không chắc cách add XPC target đúng chuẩn Apple (embed, Copy Files build phase, dependency, signing inherit), DỪNG, `/ak:advise`, báo PM. KHÔNG mò.
2. Fallback path bắt buộc phải test được. Trong debug build thêm 1 debug menu "Force XPC failure" nếu cần, xoá trước release.
3. KHÔNG port thêm commit upstream ngoài XPC service extraction commits. Cùng nguyên tắc scope như Phase 4.
4. Diff > 800 LOC → DỪNG, báo PM.
5. KHÔNG `git tag`, KHÔNG merge.
6. Manual test bạn không chạy được, viết protocol trong PR body.

### Deliverables
1. PR title `release: 1.4.0 (macOS 15+ reliability — HID event taps + XPC MenuBarItemService)`.
2. CI xanh.
3. Body có manifest cherry-pick + test protocol + kongming counsel tóm tắt.
4. In: `PHASE_5_DONE: <PR URL> | commits: <N> | LOC: <N> | test-protocol-attached: yes`

## Kongming checkpoints (PM run)

- **Before agy touches project.pbxproj:** PM asks kongming for the exact Xcode 26 XPC service target scaffolding steps (bundle id nesting, embed rule, dependency, entitlements inheritance) for a non-sandboxed main app with Hardened Runtime + Apple Development signing.
- **After PR opened, before merge:** PM asks kongming to review the fallback engagement logic and NSXPCConnection lifecycle (invalidate on quit, no leaks, correct interruption handling) with the actual diff attached.
- **Before v1.4.0 tag:** PM asks kongming to spot-check Sparkle appcast + Hardened Runtime + XPC embedded signing chain for regression risk on 1.3.0 → 1.4.0 auto-update.
