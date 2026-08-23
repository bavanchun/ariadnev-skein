---
phase: 5
title: "Documentation, attribution, and CI"
status: pending
priority: P1
effort: "2h"
dependencies: [4]
---

# Phase 5: Documentation, attribution, and CI

## Overview

Make the written record match the code, get the licence posture right, and land
the CI optimisation now that branch protection is being configured for the first
time in this repository.

## Part A — Attribution and licence

Skein stays **GPL-3.0**. Roughly 18.2k lines originate with Jordan Baird.

- `LICENSE` keeps both copyright notices; only the fork-maintainer line is
  renamed to Skein.
- `README.md` carries the derivation in one short paragraph — the user-visible
  home for it.
- `docs/UPSTREAM.md` is reframed from a *sync policy* into a *provenance record*:
  what Skein derives from, what diverged, and how to cherry-pick Ice security
  fixes. The `upstream` remote stays configured.
- **Do not copy `ariadnev`'s claim** that it "shares no code, assets, names, or
  trade dress with any other product". For Skein that is false.

## Part B — Documentation sweep

`README.md`, `CHANGELOG.md`, `FREQUENT_ISSUES.md`, `CODE_OF_CONDUCT.md`,
`docs/DEVELOPMENT_WORKFLOW.md`, `docs/release-guide.md`, `docs/UPSTREAM.md`, and
`.github/ISSUE_TEMPLATE/{bug_report,feature_request}.yml` (both link
`github.com/bavanchun/Frost/issues`).

Also retarget the app icon plan: `plans/260728-0156-frost-app-icon-artwork/`
references `FrostMarkStroke`, and its open Decision A asks "what is Frost's
mark?" — now answerable as Skein's. Retarget the asset names and reopen the
question under the new name; the artwork itself stays out of scope.

## Part C — CI optimisation

Audited in
[`plans/reports/audit-260823-1239-cicd-cloudflare-fit.md`](../reports/audit-260823-1239-cicd-cloudflare-fit.md).
No workload here can run on Cloudflare — `xcodebuild` needs macOS on Apple
hardware, and Workers Builds runs Linux containers for the V8 runtime. The
Cloudflare surface this project does use is the Sparkle feed route in phase 4.

Problems to fix:

| # | Problem |
|---|---|
| 1 | Documentation-only pull requests run a full macOS build. Two of ten observed `Build` runs were markdown-only |
| 2 | `lint.yml` has no `concurrency` block |
| 3 | `lint.yml` pins `actions/checkout@v3` and a third-party action on a mutable tag |
| 4 | `if: '!github.event.pull_request.merged'` is dead — `merged` only exists on `closed` events |
| 5 | SPM dependencies re-resolved uncached each run |

The existing comment in `build.yml` correctly rejects a naive `paths` filter: a
filtered required check never reports and blocks the merge forever. The fix keeps
an always-reporting status:

```text
[changes]  ubuntu, always runs, computes code-vs-docs
   ├── code  -> Build (macos) + SwiftLint (ubuntu)
   └── docs  -> both skipped
[ci]       if: always(), aggregates   <- the required check
```

Pin `dorny/paths-filter` to a commit SHA, not a tag.

## Implementation Steps

1. Rewrite `LICENSE`'s maintainer line; leave Baird's notices verbatim.
2. Rewrite `README.md`, including the header image path now under `Skein/`.
3. Reframe `docs/UPSTREAM.md` as provenance.
4. Sweep the remaining documentation and issue templates.
5. Retarget the app icon plan's asset names and Decision A.
6. Rework both workflows per Part C.
7. Open the pull request, confirm `ci` reports, **then** set branch protection on
   `main` requiring `ci` — deferred from phase 1 precisely so it is set once.

## Success Criteria

- [ ] No `Frost` in any tracked file except historical `CHANGELOG.md` entries and
      completed plans under `plans/`
- [ ] `LICENSE` retains Jordan Baird's copyright verbatim
- [ ] `README.md` credits Ice and links it
- [ ] A markdown-only pull request skips `Build` yet still reports `ci` green
- [ ] A Swift change still runs `Build` and `SwiftLint`
- [ ] Branch protection requires `ci`, and `enforce_admins` stays on

## Risk Assessment

**Switching the required check can block every merge if ordered wrong.** Land the
workflow, watch `ci` report on a live pull request, then change protection.

**Trimming attribution to look cleaner is a licence violation.** The README
paragraph is a minimum, not a ceiling.
