---
title: "Frost project state"
type: scout
created: 2026-08-23
---

# Scout Report — Frost project state

## What this is

`Frost` — personal fork of [jordanbaird/Ice](https://github.com/jordanbaird/Ice), a macOS menu bar manager (GPL-3.0). Swift/SwiftUI, macOS 14+, Xcode project (no SPM manifest at root). 116 Swift files, ~18.2k LOC under `Frost/`.

- origin: `git@github.com:bavanchun/Frost.git`
- upstream: `https://github.com/jordanbaird/Ice.git`
- Divergence: `main...upstream/main` = **17 / 0** — 17 fork-only commits, zero unmerged upstream commits.

## Current state

| Item | Value |
|---|---|
| Branch | `main`, clean working tree |
| Version | `MARKETING_VERSION = 1.1.0`, build `1120`, bundle `com.vchun.Frost` |
| Latest tag | `v1.1.0` (2026-07-28) |
| CI | `.github/workflows/build.yml` + `lint.yml` — all recent runs green |
| Open PR | **#5** `docs(plans): plan the Frost app icon artwork` (`docs/frost-app-icon-plan`) |

The Ice → Frost rebrand is effectively finished. `grep -rn "\bIce\b" Frost/ --include=*.swift --include=*.plist` returns **1 hit**, and it is an intentional comment in `Frost/Info.plist:8`.

## Layout

- `Frost/` — app source. Subsystems: `MenuBar/` (Appearance, ControlItem, MenuBarItems, Search, Spacing), `UI/` (FrostBar, FrostUI, LayoutBar, Pickers, Shapes, Views), `Settings/`, `Events/`, `Hotkeys/`, `Bridging/`, `Swizzling/`, `Permissions/`, `Updates/` (Sparkle), `Utilities/`
- `docs/` — `DEVELOPMENT_WORKFLOW.md` (28 sections: branching, commits, PR, upstream sync, release, semver), `release-guide.md` (unsigned build + manual inside-out codesign, Sparkle appcast), `UPSTREAM.md` (sync state, conflict areas)
- `plans/` — two completed plans (rebrand, snowflake icon), one pending on PR #5 (app icon artwork), `plans/reports/`
- `.ci-output/` — local build artifacts, gitignored

## Work in flight

1. **PR #5 — Frost app icon artwork** (`plans/260728-0156-frost-app-icon-artwork/`, status `pending`). Plan doc only, no artwork. `AppIcon.appiconset` is still Ice's blue cube and `FrostMarkStroke.imageset` is still the isometric wireframe cube — the last Ice-branded artwork in the repo. Blocked on a design decision (Icon Composer vs. classic 10-PNG set) plus the artwork itself; phases 2–3 are mechanical.
   - The branch predates the 1.1.0 release commit, so its diff against `main` shows a spurious `-2` on `CHANGELOG.md` and `-8` on `project.pbxproj`. Rebase before merge.
2. **`CHANGELOG.md` `[Unreleased]` is empty** — nothing shipped since 1.1.0.

## Unresolved questions

- Does PR #5 merge as a plan-only doc, or wait until artwork exists?
- Icon Composer vs. classic PNG set — still undecided (plan goal #4).
