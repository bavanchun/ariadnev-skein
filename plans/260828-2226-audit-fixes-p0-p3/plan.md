---
title: "Audit fixes P0-P3 — three-release ship train"
description: "Ship the P0/P1/P2/P3 findings from plans/reports/antigravity-260828-2201-project-audit.md as three sequential releases (v1.2.2 patch → v1.3.0 minor → v1.4.0 minor). Claude Code is project manager, reviewer, and — since 2026-09-05 — the coder."
status: in-progress
priority: P1
effort: "5-7 days total across ~2 weeks calendar"
branch: main
tags: [audit-fixes, bugfix, upstream-port, release-train]
created: 2026-08-28
blocks: [260823-1810-skein-landing-page]
---

# Audit fixes P0-P3 — three-release ship train

## Overview

The 2026-08-28 Antigravity audit (`plans/reports/antigravity-260828-2201-project-audit.md`) surfaced four tiers of work: three critical bugs plus visual polish (P0), landing-page completion (P1a), documentation and repo hygiene (P1b), and two selective upstream ports (P2 HID/sourcePID, P3 XPC service). This plan sequences that work into three releases so blast radius stays small and users get value early.

Claude Code (this session) is the project manager **and, since 2026-09-05, the coder** — see the Resolved Decisions for that date. It executes one phase at a time, verifies the result against the phase's own checklist before merge, and owns coordination; the maintainer approves and tags. The original delegation model is described below as written; where it says `agy`, read "whoever executes the phase". `agy` never merges its own PRs, never tags, never renames files outside the phase scope, and never widens scope beyond the phase brief. Every phase invokes named `/ak:*` skills (which `agy` has installed in `~/.gemini/config/skills/ak-*/`) so behavior stays consistent with the maintainer's workflow.

## Goals

| # | Goal | Priority | Release |
|---|------|----------|---------|
| 1 | Fix 3 HIGH defects (memory leak, loop break, slice crash) and correct About URL; update AccentColor to rope orange | P0 | **completed** |
| 2 | Ship landing page (finalize PR #2, capture real screenshots, verify Frost→Skein install migration) | P1 | v1.3.0 window |
| 3 | Fix documentation drift, prune 16.4 MB of dead upstream Ice assets, backfill 50 stale plan checkboxes | P1 | **completed** |
| 4 | Port upstream's mouse-moved event tap (`292556f`) so hover detection survives a disabled tap | P2 | v1.4.0 |
| 5 | Port the XPC MenuBarItemService so menu bar items resolve to their real owning app on macOS 26 | P3 | v1.4.0 |
| 6 | Size the dropped-click / item-movement work before contracting it — scout and re-plan, no code | P2 | none |

## Phases

| # | Phase | Release | Effort | Status |
|---|-------|---------|--------|--------|
| 1 | [P0 — v1.2.2 patch](./phase-01-p0-v1.2.2-patch.md) | v1.2.2 | 0.5 day | **Completed** — PR #19, v1.2.2 shipped |
| 2 | [P1a — Landing ship & escort install](./phase-02-p1a-landing-ship.md) | v1.3.0 window | 1.0 day | **Partial** — workstream A shipped (PR #20); B blocked on maintainer screenshots |
| 3 | [P1b — Docs hygiene & repo cleanup → v1.3.0](./phase-03-p1b-docs-hygiene.md) | v1.3.0 | 0.5 day | **Completed** — PR #21 merged; v1.3.0 tag pending maintainer |
| 4 | [P2 — Port the mouse-moved event tap](./phase-04-p2-hid-source-pid-port.md) | v1.4.0 | 0.25 day | Pending — rescoped 2026-09-05 |
| 5 | [P3 — Port the XPC source-PID resolver](./phase-05-p3-xpc-service-port.md) | v1.4.0 | 2.0 days | Pending — rescoped 2026-09-05, **do this first** |
| 6 | [P2 — Re-plan dropped-click and item-movement handling](./phase-06-p2-re-plan-dropped-click-and-item-movement-handling.md) | none | 1.0 day | Pending — scout + plan only, ships no code |

## Release Sequence

```
Phase 1 → cut v1.2.2 (patch: crash + leak fixes + accent)          [DONE]
   ↓
Phase 2 (landing ship, no version change — content only)            [workstream A done]
   ↓
Phase 3 → cut v1.3.0 (docs cleanup)                                 [merged, tag pending]
   ↓
Phase 5 and Phase 4 — independent, either order.
   The version bump to 1.4.0 belongs to whichever merges SECOND,
   and that PR's CHANGELOG entry describes both.
   ↓
v1.4.0 tagged by the maintainer once both have landed.

Phase 6 runs after Phase 5 and produces a plan, not a release.
```

**Ordering, decided 2026-09-05:** Phase 5 goes first. The macOS 26 window-ownership
bug is live on the maintainer's own machine (26.6.2), and `sourcePID` — which the
old Phase 4 claimed to deliver — is produced by Phase 5's XPC service, not by
Phase 4. Phase 4 is now a 0.25-day, one-file port that can land whenever.

## Success Criteria

- [ ] v1.2.2 tagged, released, `spctl`-verifiable, appcast enclosure byte-matched, ZIP + DMG uploaded, release notes call out the 3 crash/leak fixes.
- [ ] Landing page PR #2 merged with real product screenshots (not placeholder cubes/rectangles) and Frost→Skein migration verified on maintainer's own Mac end-to-end.
- [ ] v1.3.0 tagged; `CHANGELOG.md`, `docs/UPSTREAM.md`, `docs/upgrade-frost-to-skein.md`, `FREQUENT_ISSUES.md`, `docs/DEVELOPMENT_WORKFLOW.md` all match reality; `Resources/` slimmed by ≥16 MB; 50 stale plan checkboxes reconciled.
- [ ] Upstream's mouse-moved event tap ported (`292556f`), and a tap disabled by timeout re-enables itself instead of leaving hover detection dead.
- [ ] `MenuBarItemService.xpc` embedded and signed, and on macOS 26 menu bar items in Settings → Menu Bar Layout show their real owning application instead of Control Center — verified by the maintainer against a 1.3.x build.
- [ ] Killing the XPC service process degrades the app to legacy pids without a crash or a hang.
- [ ] Dropped-click work is sized and a maintainer decision recorded, rather than contracted unsized.
- [ ] v1.4.0 tagged, appcast rolls forward cleanly, no Sparkle byte-length mismatch.
- [ ] No phase branch left orphaned; every worktree removed after its phase ships.

## Non-Negotiable Guardrails (apply to every phase)

These are hard rules the PM (Claude Code) enforces regardless of what agy proposes:

1. **Tags are the maintainer's call.** agy never runs `git tag`. It stops at "release candidate ready", the PM presents the version number and diff summary to the maintainer, the maintainer approves, and the PM tags. This mirrors `docs/release-guide.md` line 100.
2. **PRs are single-phase.** One phase = one PR. agy never lumps two phases into one PR to "save time".
3. **agy never touches `/Applications/*.app`, never `sudo`, never `defaults delete com.vchun.Frost`, never `tccutil reset`.** The escort in Phase 2 is a step-by-step guide for the maintainer to run; agy only prepares and verifies.
4. **agy never edits the Cloudflare Worker (`ariadnev-skein-edge`) or its route bindings.** Every existing 1.2.0/1.2.1 install's Sparkle feed depends on it. If a phase needs an edge change, agy proposes the change in the PR body, the PM applies it manually after approval.
5. **agy never uses `--force` on push, `--no-verify` on commits, `--force` on git reset, `git rebase --onto` on a shared branch, or `--all` on `git add`.** If agy hits a merge conflict it stops and asks.
6. **agy never touches `com.ariadnev.Skein` user defaults.** MigrationManager is one-shot; a scripted defaults touch during dev can silently poison the maintainer's local install.
7. **agy invokes `/ak:*` skills, never inline substitutes.** Scouting → `/ak:scout`. Bug fix → `/ak:fix`. Docs update → `/ak:docs`. Testing → `/ak:test`. Code review → `/ak:code-review`. Shipping prep → `/ak:ship`. Named skill = named behavior.
8. **agy's session ends when its phase PR is opened and CI is green.** agy does not merge. The PM reviews the PR against the phase's DoD before merging.
9. **PM verification is source-of-truth verification.** For every claim agy makes ("leak fixed", "screenshots captured", "77 upstream commits reduced to 6 relevant"), PM independently checks the artefact (diff, screenshot dimensions, cherry-pick log) before believing it.
10. **When agy is stuck**, it MUST use `/ak:advise` to ask kongming, then report kongming's counsel to the PM — not silently pivot to a different approach.

## agy Delegation Protocol

For each phase, PM does the following in order:

1. **Prepare worktree.** `orca terminal create` with `--worktree` pointing at a fresh `feat/phase-NN-<slug>` branch (spawned from `main`), title `AGY-P<N> <slug>`.
2. **Send the phase brief.** The entire phase file's "AGY BRIEF" section is fed to agy verbatim (not summarized) as its first prompt, plus a one-line context header ("You are working on Phase N of plan …").
3. **Watch for the DONE sentinel.** Each phase brief ends with a required sentinel line agy prints when the PR is opened. PM polls for that sentinel (or for the terminal exit) via a background watcher script; while waiting, PM works on other things or reports status to the maintainer.
4. **Verify independently.** PM checks out agy's branch locally, runs the phase's PM VERIFICATION CHECKLIST (each phase file has one), inspects the diff.
5. **Present to maintainer.** PM writes a one-screen summary: what agy did, what PM verified, what PM could not verify, proposed version bump. Maintainer decides merge/reject/revise.
6. **Merge, tag if a release phase, journal.** PM runs `gh pr merge`, then `git tag` if applicable (only with maintainer approval), then `/ak:journal` to record the outcome.

## Cross-Plan Relationships

- **`260823-1810-skein-landing-page`** (in-progress): this plan supersedes its Phase 5 (Ship & Cutover). That plan is now `blockedBy` this plan's Phase 2; PM will close it out with a record note pointing at Phase 2's outcome after v1.3.0 ships.

## Risks

- **Xcode 26 breaking build.** Upstream `macos-26` targets newer SDK. Port phases (4, 5) must confirm build still passes on the maintainer's current Xcode. Mitigation: each port phase includes a `pnpm-free` local `xcodebuild` gate before opening PR.
- **Sparkle appcast byte mismatch on release.** Historic pattern. Mitigation: `/ak:ship` skill enforces byte-match; Phase 1 and Phase 5 explicitly call it out in DoD.
- **agy widening scope.** Repeated observation. Mitigation: every phase file has an explicit "OUT OF SCOPE" section and PM's verification checklist explicitly counts `git diff --stat` lines against declared file list.
- **Kongming advisory drift.** kongming's counsel is advisory only — the PM does not blindly apply it. If kongming and the phase brief conflict, PM asks maintainer.

## References

- Audit report: [`plans/reports/antigravity-260828-2201-project-audit.md`](../reports/antigravity-260828-2201-project-audit.md)
- Per-domain scout reports: `plans/reports/scout-260828-2201-*.md`
- Release procedure: [`docs/release-guide.md`](../../docs/release-guide.md)
- Upstream compare surface: `git range-diff main..upstream/macos-26`
- Superseded landing plan: [`plans/260823-1810-skein-landing-page/`](../260823-1810-skein-landing-page/)


## Resolved Decisions (maintainer approved 2026-08-28)

- **Phase 3 semver:** v1.3.0 minor. Docs-drift chapter closed cleanly.
- **Phase 5 XPC bundle id:** `com.ariadnev.Skein.MenuBarItemService` (nested, Apple convention).
- **agy warm-up:** skipped. Phase 1 spec + PM verification checklist + kongming pre-merge counsel are the safety net.

## Resolved Decisions (maintainer approved 2026-09-05)

- **Coder identity: Claude Code writes the code directly.** The agy/Antigravity
  delegation model in the Overview and in "agy Delegation Protocol" below is no
  longer how phases are executed. **The Non-Negotiable Guardrails still bind
  unchanged** — read "agy" there as "whoever is executing the phase". Nothing in
  that list was waived; in particular tags stay the maintainer's call, and one
  phase is still one PR.
- **Scope:** phases 2-5 of this plan, executed in sequence.
- **Phase 4/5 rescope.** See the record note below.

## Record note — 2026-09-05 rescope of phases 4 and 5

A contract check against `upstream/macos-26`
([`plans/reports/scout-260905-phase-04-contract-check.md`](../reports/scout-260905-phase-04-contract-check.md))
found the Phase 4 and Phase 5 contracts were written against an imagined
upstream rather than the real one. Three findings drove the rescope:

1. **Phase 4 named commits that are not event-tap work.** Of the commits it
   listed, only `292556f` replaces a monitor with a tap. It is one file,
   +34/−9.
2. **The dropped-click fix is not in Phase 4's file list.** It lives in
   `MenuBarItemManager.swift`, which every phase marks OUT OF SCOPE, and
   upstream reworked it across `8d4b6a5`, `e3c63f2` and `b0a1942` — roughly
   1,800 lines of churn in that one file.
3. **The `sourcePID` dependency ran backwards.** Phase 4 was written as though
   it delivered `sourcePID` and Phase 5 depended on it. In upstream, `sourcePID`
   is produced by the XPC service — Phase 5's work. Phase 4 never touches it.

Phase 5's contract additionally described an `@objc` `NSXPCConnection` protocol
with `windowsForItem(withIdentifier:reply:)` and `frameForItem(withIdentifier:reply:)`.
No such protocol exists upstream; the real service is Swift-native
`XPCListener`/`XPCSession` carrying `Codable` enums, and it resolves a source pid
and nothing else.

**Outcome:** Phase 4 shrunk to `292556f` alone (0.25 day, independent). Phase 5
rewritten against the verified upstream source and moved ahead of Phase 4.
Dropped-click split out as Phase 6, which produces a plan rather than code.
Both phase files carry `rescoped: 2026-09-05` in their frontmatter.

## Open Questions still standing

1. **Phase 3 checkbox backfill policy.** Hybrid (`[x]` for shipped, `[ ]` + record note for not-applicable) is provisional. Confirm during Phase 3 kickoff, or ask me to switch to record-note-only.
2. **Kongming availability.** Each phase's kongming checkpoint assumes `/ak:advise` is reachable. If unreachable at run time, PM proceeds without and notes the skip in the phase PR. Acceptable soft-gate?

<!-- slug: audit-fixes-p0-p3 -->
