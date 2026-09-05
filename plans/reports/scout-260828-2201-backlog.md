---
title: "Skein GitHub backlog scout"
type: scout
created: 2026-08-28
---

# Scout Report — GitHub Issues and PRs Backlog

## Overview

- **Repository**: `bavanchun/ariadnev-skein`
- **Scout Date**: 2026-08-28
- **Latest Releases**: `v1.2.1` (2026-08-28), `v1.2.0` (2026-08-23)
- **Active Backlog**: 0 open issues, 0 open PRs.

---

## Metrics Summary

| Metric | Issues | Pull Requests | Total / Combined |
|---|---|---|---|
| **Open** | 0 | 0 | 0 |
| **Closed / Merged** | 1 | 15 (all merged) | 16 |
| **Total Tracked** | 1 | 15 | 16 |
| **Open : Closed Ratio** | 0 : 1 (0%) | 0 : 15 (0%) | 0 : 16 (0%) |
| **Closure / Merge Rate** | 100.0% | 100.0% (15/15 merged, 0 rejected) | 100.0% |
| **Oldest Open Item** | None | None | None |
| **Backlog Velocity** | N/A (zero active queue) | High (15 PRs shipped across 2 release cycles) | Clean inbox |

---

## Issues Breakdown

| # | Title | Created | Closed | Status | State Reason / Resolution |
|---|---|---|---|---|---|
| **#16** | Notarize releases so the first launch stops being blocked | 2026-08-28 | 2026-08-28 | Closed | `COMPLETED` (Won't fix: maintainer trade-off on $99/yr Apple Developer fee vs early user scale; documented mitigations in place) |

### Issue Triage & Priority Classification

- **#16 (Notarization / Gatekeeper friction)**:
  - **Priority**: Low / Deferred (Cost-benefit decision).
  - **Context**: Apps built with personal Apple Development certificates trigger macOS Gatekeeper quarantine prompt (`spctl` rejection).
  - **Mitigation Implemented**: Website download instructions, release notes unblock guides (ZIP + DMG), and `docs/release-guide.md` documentation.
  - **Reopen Conditions**: User drop-off reports, public roadmap scaling, or sponsorship covering Apple Developer Program fee ($99/yr).

---

## Pull Requests Breakdown

| # | Type / Title | Created | Merged | Author | Focus Area |
|---|---|---|---|---|---|
| **#15** | `docs(release): make the ZIP the recommended download` | 2026-08-28 | 2026-08-28 | bavanchun | Distribution / Packaging docs |
| **#14** | `release: 1.2.1` | 2026-08-28 | 2026-08-28 | bavanchun | Release tag & artifacts |
| **#13** | `docs(plans): record what each plan actually shipped` | 2026-08-28 | 2026-08-28 | bavanchun | Project tracking |
| **#12** | `fix(release): put make-dmg.sh in Scripts/ to match the existing directory` | 2026-08-28 | 2026-08-28 | bavanchun | Build / Packaging script fix |
| **#11** | `chore(release): package a DMG for the website download` | 2026-08-28 | 2026-08-28 | bavanchun | Release automation |
| **#10** | `feat(icon): draw the Skein app icon and mark from the rope loop` | 2026-08-28 | 2026-08-28 | bavanchun | Brand visual assets & icon |
| **#9** | `docs(plan): activate Skein landing page` | 2026-08-28 | 2026-08-28 | bavanchun | Landing page roadmap |
| **#8** | `chore(plans): close the Skein rebrand plan` | 2026-08-23 | 2026-08-23 | bavanchun | Plan completion |
| **#7** | `release: 1.2.0` | 2026-08-23 | 2026-08-23 | bavanchun | Release tag & artifacts |
| **#6** | `docs(skein): rewrite attribution and consolidate CI behind a change gate` | 2026-08-23 | 2026-08-23 | bavanchun | Attribution & CI pipelines |
| **#5** | `feat(identity): adopt the Skein bundle identity and migrate saved settings` | 2026-08-23 | 2026-08-23 | bavanchun | App bundle ID & migration |
| **#4** | `refactor(app): rename Swift symbols and filenames to Skein` | 2026-08-23 | 2026-08-23 | bavanchun | Codebase rebrand |
| **#3** | `fix(lint): point SwiftLint at the renamed source folder` | 2026-08-23 | 2026-08-23 | bavanchun | CI / Lint config |
| **#2** | `refactor(project): rename the Xcode project and source folder to Skein` | 2026-08-23 | 2026-08-23 | bavanchun | Project structure |
| **#1** | `chore(plans): mark the repository standup phase complete` | 2026-08-23 | 2026-08-23 | bavanchun | Repository setup |

---

## Key Themes & Backlog Insights

1. **Rebrand & Codebase Standup (PRs #1–#8, Release 1.2.0)**:
   - Full migration from upstream Ice to Skein (`com.ariadnev.skein`).
   - Swift symbol renaming, file reorganizations, Xcode project structure, attribution rewrite, and CI optimizations complete.

2. **Asset Delivery & Packaging Refinement (PRs #9–#15, Release 1.2.1)**:
   - Custom rope-loop app icon designed and integrated (#10).
   - DMG and ZIP packaging pipelines built (#11, #12). ZIP adopted as recommended binary download (#15) to minimize quarantine friction.
   - Plan delivery logs and landing page docs synchronized (#9, #13).

3. **Distribution & Gatekeeper Friction (Issue #16)**:
   - macOS quarantine on unsigned/personal team binaries remains known constraint.
   - Intentionally resolved as won't fix for current phase; workarounds documented for end users.

---

## Unresolved Questions

1. **Gatekeeper User Telemetry**: Are there mechanisms or support channels to measure if potential users abandon installation due to Gatekeeper quarantine warnings?
2. **Issue Triage Automation**: Should issue/PR templates and GitHub labels (`bug`, `enhancement`, `triage`, `wontfix`) be formalized in `.github/` for future external community contributors?
3. **Upstream Sync Tracking**: Should upstream (`jordanbaird/Ice`) changes/releases be tracked via a scheduled GitHub Action or a tracked issue in this repo?
