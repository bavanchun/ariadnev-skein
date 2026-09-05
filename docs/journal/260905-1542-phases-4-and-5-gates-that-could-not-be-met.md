# Phases 4 and 5 shipped, but two gates and one criterion could not be met as written

**Date**: 2026-09-05 15:42
**Component**: xpc-menu-bar-item-service
**Status**: Resolved

## What happened

Executed Phases 4 and 5 of `plans/260828-2226-audit-fixes-p0-p3/` on
2026-09-05, the same day both were rescoped against the real upstream (an
earlier scout had found their contracts written against an imagined one).
Phase 5, the XPC source-PID resolver, went first; Phase 4, the mouse-moved
event tap, carried the version bump. Both shipped — PR #23 (`ef982aa`),
PR #24 (`07df28c`), and a docs sync-back PR #27 (`32b4aff`) — and `main` now
reads 1.4.0 / build 1140, no tag, tagging being the maintainer's call.

The durable lesson: a plan contract written against an imagined upstream
produces gates that cannot be met, and the cost surfaces at merge time, not
planning time. Three instances hit in this one run.

## The Brutal Truth

Two of Phase 5's own gates could not be satisfied as written, and that only
surfaced on hardware with the PR already open — late to find out a contract
is wrong. The same-day rescope caught the wrong upstream commits and the
wrong protocol shape (`NSXPCConnection` vs. the real
`XPCListener`/`XPCSession`), but missed the LOC ceiling sized against that
same wrong design, and missed that the acceptance criterion pointed at a UI
pane that renders empty on this hardware regardless of branch. Neither was
a coding mistake; both were the plan asserting something about upstream
that was never true.

## Technical Details

1. **LOC gate vs. no-split rule, in direct conflict.** The contract capped
   new Swift LOC (excluding renames) at 800 and separately forbade splitting
   the PR. Measured with `git diff -M --numstat`, rename-excluded: 877
   added / 105 removed, net 772 — passes on net, fails on added. The 800
   ceiling was sized against a pre-rescope design (a thin `NSXPCConnection`
   shim) that does not exist upstream. Waived by written ruling on PR #23,
   after measuring what the gate actually bounds: existing Swift outside the
   new service, the new client, and `Shared/` moved only +211/−105 across
   six files, with `MenuBarItemManager.swift` at +28/−28.
2. **A criterion that could not be evaluated at all.** It read: "on macOS 26,
   menu bar items in Settings → Menu Bar Layout show their real owning
   application." On hardware (macOS 26.6.2 / 25G83) that pane renders
   completely empty — identically on shipped v1.2.1, which has no XPC
   service — so it could not be checked either way. Verified instead through
   the manager's own logs, showing correct per-app namespacing (`Moving
   com.steipete.codexbar:codexbar-merged to left of
   com.electron.dockerdesktop:Item-0`) while every layer-25 window reported
   `kCGWindowOwnerPID = 459` / Control Center.
3. **A near-miss on measurement.** The rename-excluded figure was first read
   as 896 from a `git diff --numstat` that did not actually exclude the
   renamed `Shared/` files' own content changes. Caught and re-measured (877)
   before any checkbox was ticked — the contract had warned "a diff without
   `-M` is not the measurement," and it earned that warning.

## What We Tried

Ticking the LOC box as a pass on net alone was rejected — the contract
capped added lines, not net, and picking the flattering reading is the exact
failure the plan warns against. Splitting the PR to dodge the ceiling was
rejected too: the same contract's no-split rule made that a second
violation, not a fix. The only path left was measuring what the gate
actually bounds, showing that reading clean, and waiving the literal ceiling
by written ruling instead of silently picking the pass.

## Root Cause Analysis

The Phase 4/5 contracts were drafted against upstream commits and a
protocol shape nobody had verified against the real `upstream/macos-26`
tree. The rescope fixed the wrong-commits and wrong-protocol errors but did
not re-derive the LOC ceiling or re-check the acceptance criterion against
the actual Settings UI, because neither looked load-bearing until tested
against real code and real hardware.

## Lessons Learned

A quantitative gate is only as good as the design it was sized against —
re-derive it whenever that design changes, not just the commit list. A
criterion phrased against a specific UI surface is only as good as that
surface; confirm it renders before writing the criterion, or plan a
fallback signal (logs, Accessibility API reads) up front. Re-measure before
ticking a checkbox, every time — the 896-vs-877 near-miss cost minutes here;
a less careful pass would have shipped a false pass into the record.

## Next Steps

Two pre-existing macOS 26 defects were filed rather than fixed, since both
reproduce on shipped v1.2.1 and sat outside this phase's scope: issue #25
(`MenuBarItemManager.cacheItemsIfNeeded()` assigns `cachedItemWindowIDs`
before the `guard let hiddenControlItem` that can bail, so one failed pass
poisons the cache for the rest of the session) and issue #26
(`MenuBarItem.displayName` resolves through `owningApplication`, not
`sourcePID`, so labels still show raw window titles on macOS 26). Owner:
whoever next touches `MenuBarItemManager.swift` or `MenuBarItem.displayName`.
The v1.4.0 tag and release remain the maintainer's call, not scheduled here.
