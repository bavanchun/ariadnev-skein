---
title: "Audit fixes P0-P3 — three-release ship train"
description: "Ship the P0/P1/P2/P3 findings from plans/reports/antigravity-260828-2201-project-audit.md as three sequential releases (v1.2.2 patch → v1.3.0 minor → v1.4.0 minor). Claude Code is the project manager and reviewer; agy (Antigravity CLI) executes each phase as the coder."
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

Claude Code (this session) is the project manager: it delegates one phase at a time to `agy` running in an Orca terminal, verifies the result independently before merge, tags releases, and owns coordination. `agy` never merges its own PRs, never tags, never renames files outside the phase scope, and never widens scope beyond the phase brief. Every phase invokes named `/ak:*` skills (which `agy` has installed in `~/.gemini/config/skills/ak-*/`) so behavior stays consistent with the maintainer's workflow.

## Goals

| # | Goal | Priority | Release |
|---|------|----------|---------|
| 1 | Fix 3 HIGH defects (memory leak, loop break, slice crash) and correct About URL; update AccentColor to rope orange | P0 | **completed** |
| 2 | Ship landing page (finalize PR #2, capture real screenshots, verify Frost→Skein install migration) | P1 | v1.3.0 window |
| 3 | Fix documentation drift, prune 16.4 MB of dead upstream Ice assets, backfill 50 stale plan checkboxes | P1 | v1.3.0 |
| 4 | Cherry-port HIDEventManager + sourcePID resolution from `upstream/macos-26` to fix macOS 15+ click drops | P2 | v1.4.0 |
| 5 | Cherry-port XPC MenuBarItemService from `upstream/macos-26` to remove main-thread beachball risk | P3 | v1.4.0 |

## Phases

| # | Phase | Release | Effort | Status |
|---|-------|---------|--------|--------|
| 1 | [P0 — v1.2.2 patch](./phase-01-p0-v1.2.2-patch.md) | v1.2.2 | 0.5 day | Pending |
| 2 | [P1a — Landing ship & escort install](./phase-02-p1a-landing-ship.md) | v1.3.0 window | 1.0 day | Pending |
| 3 | [P1b — Docs hygiene & repo cleanup → v1.3.0](./phase-03-p1b-docs-hygiene.md) | v1.3.0 | 0.5 day | Pending |
| 4 | [P2 — Port HID event taps + sourcePID](./phase-04-p2-hid-source-pid-port.md) | v1.4.0 | 2.0 days | Pending |
| 5 | [P3 — Port XPC MenuBarItemService → v1.4.0](./phase-05-p3-xpc-service-port.md) | v1.4.0 | 3.0 days | Pending |

## Release Sequence

```
Phase 1 → cut v1.2.2 (patch: crash + leak fixes + accent)
   ↓
Phase 2 (landing ship, no version change — content only, deploys via Cloudflare Pages)
   ↓
Phase 3 → cut v1.3.0 (docs cleanup, no user-facing app behavior change but tag anyway to close the docs delta cleanly)
   ↓
Phase 4 → merge to main, do NOT tag yet
   ↓
Phase 5 → cut v1.4.0 (P2 + P3 together — both are upstream ports touching MenuBar/Events subsystems, safer to ship together with one round of user regression testing)
```

## Success Criteria

- [ ] v1.2.2 tagged, released, `spctl`-verifiable, appcast enclosure byte-matched, ZIP + DMG uploaded, release notes call out the 3 crash/leak fixes.
- [ ] Landing page PR #2 merged with real product screenshots (not placeholder cubes/rectangles) and Frost→Skein migration verified on maintainer's own Mac end-to-end.
- [ ] v1.3.0 tagged; `CHANGELOG.md`, `docs/UPSTREAM.md`, `docs/upgrade-frost-to-skein.md`, `FREQUENT_ISSUES.md`, `docs/DEVELOPMENT_WORKFLOW.md` all match reality; `Resources/` slimmed by ≥16 MB; 50 stale plan checkboxes reconciled.
- [ ] HID event taps + sourcePID resolution ported, tested on macOS 15+, dropped-click regression reproduced-then-verified-fixed.
- [ ] XPC `SkeinMenuBarItemService` scaffolded and wired for Accessibility API queries; main thread never touches AX calls that block for a hung third-party status item.
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

## Open Questions still standing

1. **Phase 3 checkbox backfill policy.** Hybrid (`[x]` for shipped, `[ ]` + record note for not-applicable) is provisional. Confirm during Phase 3 kickoff, or ask me to switch to record-note-only.
2. **Kongming availability.** Each phase's kongming checkpoint assumes `/ak:advise` is reachable. If unreachable at run time, PM proceeds without and notes the skip in the phase PR. Acceptable soft-gate?

<!-- slug: audit-fixes-p0-p3 -->
