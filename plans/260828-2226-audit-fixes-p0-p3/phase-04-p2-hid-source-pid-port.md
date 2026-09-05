---
phase: 4
title: "P2 — Port HID event taps + sourcePID from upstream/macos-26"
status: pending
priority: P2
effort: "2.0 days"
dependencies: [3]
release: "merges to main, does NOT tag alone — Phase 5 tags v1.4.0 together"
---

# Phase 4: P2 — Port HID event taps + sourcePID resolution

## Overview

Selectively cherry-port two upstream `jordanbaird/Ice` improvements that fix real Skein bugs on macOS 15+ Sequoia: (a) `HIDEventManager` replacing runloop event monitors with low-level `CGEvent` taps to stop click drops and missed hover transitions, and (b) `sourcePID` resolution to correctly identify window owner when Control Center is the immediate owner on newer macOS. Direct `git merge upstream/macos-26` is fatal due to project-wide Frost/Skein renames — every commit must be cherry-picked, then adapted.

## Requirements

### Functional
- After merge, on macOS 15+, clicking a menu bar item Skein manages must land on that item every time (no dropped clicks under moderate usage).
- Hover-driven interactions (menu bar item bounding rect refresh, tooltip surface) must not skip frames when the user sweeps the mouse across the menu bar rapidly.
- When Control Center owns a window Skein needs to identify, `sourcePID` resolution returns the real client PID, not `ControlCenter`'s PID.

### Non-Functional
- No new Swift dependencies.
- No behavior change on macOS 14 (per project deployment target).
- Diff must stay under 500 lines of Swift, split across at most 6 files.

## Architecture

Two logical sub-ports, PR'd together because they interact:

**Sub-port A: `HIDEventManager`**
- Upstream file: `upstream/macos-26:Ice/Ice/Events/HIDEventManager.swift` (or the equivalent path — agy resolves via `git log`).
- Adopts `CGEvent.tapCreate(...)` at `.hidEventTap` location with the appropriate event mask. Wires into Skein's existing `EventManager`.
- Fallback path: if `AXIsProcessTrusted()` returns false (permissions not granted), fall back to the current runloop monitor behavior — do NOT crash.

**Sub-port B: `sourcePID` resolution**
- Upstream file: `upstream/macos-26:Ice/Ice/Utilities/WindowInfo.swift` new `sourcePID` computed property.
- Uses `_CGSCopyWindowProperty` (or the closest available API upstream chose) to walk from immediate owner to source client.
- Adopted at every WindowInfo call site that currently trusts `windowOwnerPID`.

## Related Code Files

- Create: `Skein/Events/HIDEventManager.swift` (new file, ported)
- Modify: `Skein/Events/EventManager.swift` (thread HID manager in, fallback path)
- Modify: `Skein/Utilities/WindowInfo.swift` (add sourcePID property, wire call sites)
- Modify: `Skein/Bridging/Shims/Private.swift` (add any missing `@_silgen_name` for CGS APIs the port needs)
- Modify: `Skein.xcodeproj/project.pbxproj` (add HIDEventManager.swift to synced group — synced folders may auto-pick it, verify)
- Modify: `CHANGELOG.md` (Unreleased section — do not bump version)

## OUT OF SCOPE

- Any refactor of `MenuBarItemManager.swift` (deferred to a separate plan even though it lives in the same subsystem).
- XPC service extraction (Phase 5).
- `ScreenCaptureKit` migration for `ScreenCapture.swift` (separate concern, upstream still uses `CGWindowList` too).
- Any additional upstream improvements beyond the two named sub-ports even if they look "quick" — scope discipline. PM will not accept surprise ports.

## Implementation Steps

1. Branch `feat/phase-04-p2-hid-source-pid-port` from `main` (must include Phase 3's merged v1.3.0 tag).
2. `git fetch upstream` — must complete cleanly.
3. `git log --oneline upstream/macos-26 -- Ice/Events/ Ice/Utilities/WindowInfo.swift | head -50` to identify the exact commits to cherry-pick.
4. Draft a cherry-pick list (2–8 commits, agy justifies each in PR body).
5. For each commit: `git cherry-pick <SHA>` with rename resolution: expect conflicts on every path due to Ice→Skein renames; resolve by moving Ice/* content to Skein/* mechanically, then applying the upstream diff on top.
6. Post-cherry-pick: rename all `Ice`/`Frost` symbols the upstream files still reference to their Skein equivalents (use `git grep` to find residual references).
7. `xcodebuild ... build` exit 0.
8. **Manual test protocol** (agy writes; maintainer executes and reports back):
   - macOS 15+ target Mac.
   - Add 5 real menu bar items.
   - Click each 20 times in rapid succession — count drops. Expected: 0.
   - Sweep hover across bar for 30 seconds. Watch for tooltip artefacts / stale highlights.
   - Open Control Center, invoke a Skein feature that needs sourcePID (e.g. menu bar item search including Control Center children).
9. Open PR titled `feat(events): port HIDEventManager + sourcePID from upstream/macos-26 for macOS 15+ reliability`. Body includes the cherry-pick manifest and the test protocol result.

## PM VERIFICATION CHECKLIST

- [ ] `git log --oneline main..HEAD` cherry-picks are only from `upstream/macos-26` and each references its upstream SHA in the trailer.
- [ ] `git diff main..HEAD --stat` under 500 Swift LOC, ≤6 files.
- [ ] `rg -q "class Ice" Skein/` returns nothing (no residual Ice symbol names).
- [ ] `rg -q "com.jordanbaird" Skein/` returns nothing.
- [ ] New `HIDEventManager.swift` has a fallback path when AX permission not granted (grep for `AXIsProcessTrusted` in that file).
- [ ] `EventManager.swift` diff shows HID wiring behind a compile-time or runtime gate that keeps macOS 14 behavior intact.
- [ ] `WindowInfo.sourcePID` implementation matches upstream semantically; PM cross-reads.
- [ ] `xcodebuild ... build` exit 0.
- [ ] Manual test protocol results attached in PR body — maintainer confirms.

## Success Criteria

- [ ] PR merged. NO tag yet — Phase 5 tags v1.4.0 together.
- [ ] Dropped-click regression fixed (maintainer-confirmed reproduce-then-verify).
- [ ] sourcePID returns non-ControlCenter PID for a Control Center-child window in a spot test.

## Risk Assessment

- **HID event tap requires Accessibility permission at a stricter level.** Signal: launch app on a fresh Mac, HID tap fails to install. Response: fallback path activates; app degrades to macOS-14-level behavior. Add UI hint in Permissions pane telling user they need to re-grant.
- **Cherry-pick chain drift.** Signal: an upstream commit depends on another commit not in the cherry-pick list. Response: expand the manifest, re-justify. If manifest exceeds 8 commits or 500 LOC, STOP and ask PM whether to split into two phases.
- **Xcode 26 SDK compatibility.** Signal: build fails on `@_silgen_name` or CGS bridging headers. Response: agy invokes `/ak:advise` for kongming counsel; PM makes the go/no-go call.

---

## AGY BRIEF (feed this verbatim to agy)

Bạn thực thi Phase 4. Đọc `phase-04-p2-hid-source-pid-port.md`.

CWD: `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein`
Branch: `feat/phase-04-p2-hid-source-pid-port` từ `main` (sau khi v1.3.0 đã merge).

### Skills bắt buộc
- `/ak:scout` — đọc `plans/reports/scout-260828-2201-upstream-drift.md` để có bối cảnh 77 commits ahead. Cross-reference vào `git log upstream/macos-26`.
- `/ak:fix` — apply cherry-pick + adapt.
- `/ak:test` — build + manual test protocol setup.
- `/ak:code-review` — self-review diff, đặc biệt symbol rename residuals.
- `/ak:advise` — bắt buộc dùng nếu manifest > 6 commits, OR nếu cherry-pick > 3 conflict, OR nếu build không pass sau adapt.

### Hard rules
1. KHÔNG `git merge upstream/macos-26`. Chỉ `git cherry-pick`.
2. KHÔNG port thêm commit nào ngoài 2 sub-port đã đặt tên. Thấy commit "hay" khác → note trong PR body, không cherry-pick.
3. KHÔNG rename thêm file trong Skein/ ngoài file mới `HIDEventManager.swift`.
4. Manual test bạn KHÔNG chạy được (bạn không dùng UI). Bạn viết test protocol trong PR body, maintainer chạy.
5. Nếu diff > 500 Swift LOC hoặc > 6 file: DỪNG, không open PR, báo PM để split.
6. KHÔNG `git tag`, KHÔNG merge.

### Deliverables
1. PR với cherry-pick manifest + test protocol trong body.
2. CI xanh.
3. Diff trong ngưỡng.
4. In: `PHASE_4_DONE: <PR URL> | commits: <N> | LOC: <N>`

## Kongming checkpoint (PM run)

**Before agy starts cherry-picking:** PM asks kongming: "Given the Skein fork's project-wide rename to `com.ariadnev.Skein` and Skein/ path convention, what's the safest cherry-pick strategy for these 2 sub-ports, and which conflicts should agy expect to hit?" Pass: upstream commit list, current renamed file tree.

**After PR opened, before merge:** PM asks kongming to spot-check the ported HIDEventManager for permission fallback correctness and CGEvent tap lifecycle (memory, invalidation on quit).
