---
title: "Cut the Ice fork and rebrand Frost to Skein"
description: "Move the project off GitHub's fork network into a standalone ariadnev-skein repository, rebrand every layer from Frost to Skein, migrate user settings across the bundle identifier change, and retire bavanchun/Frost."
status: pending
priority: P1
effort: "unknown — gated on phase 1 approval"
tags: [rebrand, repository, ariadnev, gpl, sparkle, migration]
created: 2026-08-23
---

# Cut the Ice fork and rebrand Frost to Skein

## Overview

Two changes that must ship together because each is meaningless without the other:

1. **Leave the fork network.** `bavanchun/Frost` is a GitHub fork of
   `jordanbaird/Ice` (`gh api repos/bavanchun/Frost` → `"fork": true`,
   `"parent": "jordanbaird/Ice"`). The repository carries a "forked from" banner,
   sits inside Ice's fork network, and routes its issues and pull requests through
   that relationship.
2. **Rebrand Frost to Skein**, joining the Ariadnev ecosystem alongside
   [`ariadnev`](https://github.com/bavanchun/ariadnev),
   [`ariadnev-kit`](https://github.com/bavanchun/ariadnev-kit), and
   [`ariadnev-web`](https://github.com/bavanchun/ariadnev-web).

A *skein* is a coiled length of thread — Ariadne's thread through the labyrinth,
and what this app does to a cluttered menu bar. The name is clear in the macOS
namespace; `Clew`, the literal mythological term, is already
[an App Store app](https://apps.apple.com/us/app/clew/id1268077870), and `Spool`
is crowded with filament trackers.

## The correction this plan encodes

The obvious approach — clone Ice fresh and push it to a new repository — **loses
all 18 fork-side commits and gains nothing.** `bavanchun/Frost` already contains
Ice's complete history; `fork: true` is GitHub metadata, not a Git property.
Pushing the existing history to a repository created with `gh repo create`
produces a `fork: false` repository with every commit intact.

Two alternatives were considered and rejected:

- **Ask GitHub Support to detach the fork.** Keeps the URL and stars, but the
  repository has zero stars and is being renamed anyway. Not worth a support
  ticket and its wait.
- **Squash history into a single initial commit.** Destroys the provenance
  GPL-3.0 asks to preserve, erases upstream authorship, and makes future
  cherry-picks of Ice security fixes impossible.

## Licensing posture — a constraint, not a goal

Skein stays **GPL-3.0**. Roughly 18.2k lines originate with Jordan Baird; the
fork-side divergence is renames, documentation, and one icon feature. Leaving the
fork network changes GitHub metadata, not copyright.

| In scope | Out of scope, permanently |
|---|---|
| Own name, brand, repository, release channel, roadmap | Relicensing to MIT, as `ariadnev-kit` is |
| No fork banner, no fork network | Removing Jordan Baird's copyright notices |
| Concise attribution in `README.md` | Claiming sole copyright or clean-room authorship |

`LICENSE` already carries both copyrights and stays that way, with the fork
maintainer line renamed to Skein.

**Do not carry `ariadnev`'s claim** — *"shares no code, assets, names, or trade
dress with any other product"* — into this repository. For Skein it is false.

Keep the `upstream` Git remote locally after the split. Leaving the fork network
does not preclude cherry-picking Ice security fixes, and Ice is actively
maintained.

## Goals

| # | Goal | Priority |
|---|------|----------|
| 1 | `bavanchun/ariadnev-skein` exists with `fork: false` and the full history, tags included | P1 |
| 2 | No `Frost` identifier, symbol, filename, or user-facing string remains | P1 |
| 3 | Existing settings, menu bar layout, and hotkeys survive the bundle identifier change | P1 |
| 4 | Attribution to Ice is correct, concise, and confined to `README.md`, `LICENSE`, and `docs/` | P1 |
| 5 | Sparkle updates flow from the new repository; the old feed does not 404 | P2 |
| 6 | `bavanchun/Frost` is archived and points at the new repository | P2 |

## Constraints

- **The bundle identifier change resets the defaults domain.** `com.vchun.Frost`
  → `com.ariadnev.Skein` means macOS treats Skein as a different application:
  preferences do not carry over, and Accessibility plus Screen Recording must be
  granted again. Phase 4 owns the settings half; the permission re-grant is
  unavoidable and belongs in the release notes.
- **Four persisted defaults keys contain the brand name.**
  `Frost/Utilities/Defaults.swift:143-146` defines `ShowFrostIcon`, `FrostIcon`,
  `CustomFrostIconIsTemplate`, and `UseFrostBar` as raw string values. These are
  persisted data, not labels — the same hazard the snowflake plan designed
  around.
- **`SUPublicEDKey` stays.** The Ed25519 keypair is unchanged, so only
  `SUFeedURL` moves. Re-keying would invalidate signatures for no benefit.
- **`SUFeedURL` currently points at `bavanchun/Frost`**
  (`Frost/Info.plist`). Installed Frost builds poll that URL, which is why the
  old repository is archived rather than deleted.
- **CI hardcodes the scheme and project name.**
  `.github/workflows/build.yml:29,37,38` pass `-scheme Frost -project
  Frost.xcodeproj`. CI breaks the moment phase 2 lands unless both move together.
- **`main` is protected and takes pull requests only**, per
  `docs/DEVELOPMENT_WORKFLOW.md` § 3. Every phase is its own pull request in the
  new repository.
- **A proven playbook exists.** `plans/260727-2348-rebrand-ice-vc-to-frost` ran
  this exact sequence for Ice → Frost. Phases 2-5 mirror it deliberately.

## CI/CD and Cloudflare scope

Audited separately in
[`plans/reports/audit-260823-1239-cicd-cloudflare-fit.md`](../reports/audit-260823-1239-cicd-cloudflare-fit.md).
Two outcomes fold into this plan rather than running as their own project:

- **No build or deploy workload here can move to Cloudflare.** `xcodebuild`
  requires macOS on Apple hardware; Workers Builds runs Linux containers for the
  V8 runtime. Verified absent: `wrangler.*`, `package.json`, `Dockerfile`,
  `*.csproj`. The repository is also public, so GitHub Actions minutes are
  unmetered and cost is not a motive.
- **The one real Cloudflare surface is the Sparkle feed.** `SUFeedURL` bakes a
  GitHub repository URL into every shipped binary, which is precisely why this
  migration strands installed Frost builds. Phase 4 moves it behind a stable
  route on the existing `ariadnev-edge` Worker so the URL inside the app never
  has to change again; phase 6 wires the route up.

The GitHub Actions cleanup lands in **phase 5**, timed so branch protection on
the new repository is configured exactly once.

## Non-Goals

- Producing the Skein app icon artwork. That is
  [`260728-0156-frost-app-icon-artwork`](../260728-0156-frost-app-icon-artwork/plan.md),
  which this plan **unblocks** rather than absorbs: its open Decision A ("what is
  Frost's mark?") only becomes answerable once the name is settled. Phase 5
  retargets that plan's asset names; the artwork stays its own work.
- Merging any upstream Ice changes. `main...upstream/main` is `17 / 0` — nothing
  upstream is pending.
- New features, refactors, or behavior changes of any kind. This plan renames and
  relocates; it does not improve.
- Adopting Icon Composer. Settled 2026-08-23 as the classic PNG set.

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | [Phase 1: Stand up ariadnev-skein as a standalone repository](./phase-01-stand-up-the-standalone-repository.md) | Complete |
| 2 | [Phase 2: Rename the Xcode project, target, scheme, and source folder](./phase-02-rename-the-xcode-project.md) | Complete |
| 3 | [Phase 3: Rename Swift symbols and filenames](./phase-03-rename-swift-symbols-and-files.md) | Complete |
| 4 | [Phase 4: Display strings, bundle identifier, Sparkle feed, and settings migration](./phase-04-strings-identity-and-settings-migration.md) | Complete |
| 5 | [Phase 5: Documentation, attribution, and CI](./phase-05-documentation-attribution-and-ci.md) | Pending |
| 6 | [Phase 6: Release 2.0.0 and retire bavanchun/Frost](./phase-06-release-and-retire-the-old-repository.md) | Pending |

Phases run in order. Phase 1 is a prerequisite for every other phase because the
remaining work lands as pull requests in the new repository. Phases 2 and 3 are
separable but must land back to back — between them the project builds under a
new name while its symbols still read `Frost`, which is coherent but ugly.

## Version

This is a **breaking change**: the bundle identifier moves, macOS sees a new
application, and permissions must be re-granted. `docs/release-guide.md` §
"Versioning Policy" makes that a major bump.

**Proposed: `2.0.0`.** Per `docs/release-guide.md`, the version is proposed here
and cut only after explicit sign-off. Phase 6 does not tag without it.

## Success Criteria

- [ ] `gh api repos/bavanchun/ariadnev-skein -q .fork` returns `false`
- [ ] `git log --oneline | wc -l` matches the old repository's count
- [ ] Tags `v1.0.0`, `v1.0.1`, `v1.1.0` present in the new repository
- [ ] `grep -rn "Frost" --include="*.swift" --include="*.plist" Skein/` returns nothing
- [ ] `grep -rn "Frost" Skein.xcodeproj/project.pbxproj` returns nothing
- [ ] Clean build from a fresh clone, both CI workflows green
- [ ] A Frost install upgraded to Skein keeps its sections, layout, and hotkeys
- [ ] `README.md` credits Ice; `LICENSE` retains both copyright notices
- [ ] Sparkle finds `2.0.0` through the Cloudflare route, not a GitHub URL
- [ ] A markdown-only pull request skips `Build` yet still reports `ci` green
- [ ] `bavanchun/Frost` is archived, its description points at the new repository,
      and its `appcast.xml` still resolves

## Risks

**The settings migration is the only phase that can lose user data.** Everything
else is a rename that either builds or does not. Phase 4 reads the old defaults
domain explicitly; getting it wrong silently discards a hand-arranged menu bar
layout, which is the most tedious thing in the app to rebuild.

**A half-applied rename still compiles.** Swift will happily build with a stale
string in a settings pane. Only the `grep` gates in Success Criteria catch that
class of miss — the same reason the Ice → Frost plan ended with them.

**Asset catalog failures are silent.** Renaming `FrostMarkStroke.imageset`
without updating its reference yields a blank image, no build error. Established
hazard; see the snowflake plan.

**The old feed is load-bearing until phase 6.** Archiving `bavanchun/Frost`
before `2.0.0` publishes leaves installed builds polling a URL whose latest
release is still Frost. Phase 6 orders this deliberately.

## Unresolved questions

1. **Repository name: `ariadnev-skein` or plain `skein`?** The plan assumes
   `ariadnev-skein`, matching `ariadnev-kit` and `ariadnev-web`. Plain `skein`
   reads better standalone but drops the ecosystem tie from the URL.
2. **Migrate settings, or accept the reset?** The plan assumes migration
   (phase 4). Accepting the reset removes the plan's only data-loss risk and
   perhaps 60 lines, at the cost of re-arranging the menu bar once by hand.
3. **Does `2.0.0` get approved**, or does the rebrand ship as `1.2.0` on the
   argument that a personal app with one known install has no compatibility
   surface to break?

<!-- slug: rebrand-frost-to-skein -->
