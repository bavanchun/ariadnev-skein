---
title: "CI/CD audit — Cloudflare fit and GitHub Actions optimization"
type: audit
created: 2026-08-23
---

# CI/CD Audit

## 1. Detected architecture

| Property | Value |
|---|---|
| Type | Single app, not a monorepo |
| Language | Swift 100% (116 files, ~18.2k LOC) |
| Build system | Xcode / `xcodebuild`, `Frost.xcodeproj` |
| Package manager | Swift Package Manager (SPM), via `Package.resolved` |
| Deps | AXSwift, CompactSlider, Ifrit, Sparkle |
| Target | Native macOS app bundle, macOS 14+, arm64 |
| Distribution | GitHub Releases + Sparkle appcast, signed locally |
| Repo visibility | **public** |

Absent, verified by filesystem scan: `wrangler.{toml,json,jsonc}`, `package.json`,
`pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `Dockerfile`,
`docker-compose.y{a,}ml`, `*.csproj`, `*.sln`. No Node runtime, no container, no
database, no migrations, no server-side component, no E2E suite.

## 2. Cloudflare fit — none

**No workload in this repository can run on Cloudflare.** Not a preference; a
platform incompatibility:

- Workers Builds executes Linux containers producing JS/TS/WASM for the Workers
  V8-isolate runtime.
- This project invokes `xcodebuild` against the macOS SDK and emits a `.app`
  bundle. That requires macOS on Apple hardware, which Xcode's licence confines
  to Apple machines.
- The project ships no HTTP surface, no static site, and no artifact a Worker
  could serve or execute.

The prompt's own § 13 governs: workloads that do not belong on Cloudflare must
not be forced there.

### The one genuine Cloudflare option, and why to decline it

Sparkle's appcast and release zips could be served from R2 or a Worker rather
than GitHub Releases. Declined: GitHub Releases already works, costs nothing,
and `docs/release-guide.md` is built around it. Moving adds a failure mode to the
update path — the one path where breakage is silent and user-visible — in
exchange for nothing.

### Where the Cloudflare plan does pay off

`ariadnev-web` already runs the ecosystem's Cloudflare Worker on `ariadnev.com`.
A Skein landing page or docs surface belongs **there**, in that repository, not
in this one.

## 3. Current CI/CD

### Workflow A — `Build` (`.github/workflows/build.yml`)

```text
Trigger:      push[main], pull_request (all branches, no path filter)
Runner:       macos-latest  (10x minutes multiplier)
Purpose:      verify the project compiles, unsigned
Expensive:    xcodebuild Release + SPM resolve, ~1m41s-2m35s observed
Concurrency:  present, group build-${{ github.ref }}
Cache:        none
Required:     YES - "Build (unsigned)" is the only required status check
Move to CF:   impossible
Keep:         yes, this is the entire quality gate
```

### Workflow B — `Lint Swift Files` (`.github/workflows/lint.yml`)

```text
Trigger:      push[main], pull_request - both filtered to **/*.swift, .swiftlint.yml, self
Runner:       ubuntu-latest  (1x multiplier, already optimal)
Purpose:      SwiftLint --strict
Expensive:    ~46s
Concurrency:  ABSENT
Cache:        n/a, containerised action
Required:     no
Move to CF:   impossible
Keep:         yes
```

## 4. Problems found

| # | Problem | Evidence | Severity |
|---|---|---|---|
| 1 | Documentation-only pull requests run a full macOS build | PR #5 was four markdown files; ran `Build` for 1m41s. Two of ten observed `Build` runs were on the markdown-only `docs/frost-app-icon-plan` branch | High waste, no correctness impact |
| 2 | `lint.yml` has no `concurrency` block | `build.yml` has one, `lint.yml` does not | Medium |
| 3 | `lint.yml` pins `actions/checkout@v3` and `norio-nomura/action-swiftlint@3.2.1`, a third-party action on a mutable tag | `lint.yml:16,18` | Supply chain + deprecation |
| 4 | `if: '!github.event.pull_request.merged'` is dead code | `merged` is only populated on `closed` events, which the trigger list omits | Cosmetic |
| 5 | SPM dependencies re-resolved every run, uncached | `build.yml:29`, four remote packages | Low-medium |
| 6 | Squash-merge to `main` rebuilds a tree the pull request just verified | `concurrency` groups differ between `refs/pull/N/merge` and `refs/heads/main` | Low, arguably intentional |

### The constraint problem 1 must respect

`build.yml` opens with a comment rejecting a naive `paths` filter, and **it is
correct**: a required check that is filtered out never reports, leaving the pull
request pending forever. Any fix must keep a status named by branch protection
reporting on every pull request.

## 5. Cost reality

The repository is **public**, so GitHub-hosted standard runners are free and
unmetered. Reducing minutes therefore saves **no money**. The real returns are
wall-clock feedback, and closing the supply-chain items in problem 3.

Estimated reduction in billable minutes: **none applicable** — public repository.
Estimated reduction in wasted runner wall-clock: **medium**, roughly a fifth to a
quarter of `Build` runs are documentation-only.

## 6. Proposed target architecture

```text
Pull request
     |
     v
[changes] ubuntu, ~5s, ALWAYS runs
     |  dorny/paths-filter computes: code? docs-only?
     +--> code changed -----> Build (macos)  +  SwiftLint (ubuntu)
     +--> docs only --------> both skipped
     |
     v
[ci] ubuntu, if: always(), aggregates results   <-- REQUIRED CHECK
     |
   merge
     |
     v
   main --> Build (verify the merged tree)
```

The required status check moves from `Build (unsigned)` to the always-running
aggregator `ci`. That keeps merges unblocked on documentation pull requests while
still failing hard when a skipped-but-needed job did not pass.

## 7. Implementation plan

**Files to modify**
- `.github/workflows/build.yml` — add `changes` gate job, gate the macOS job on
  it, add the `ci` aggregator, add SPM cache
- `.github/workflows/lint.yml` — add `concurrency`, bump `actions/checkout` to
  v4, drop the dead `if`, gate on the same filter

**Files to create** — none
**Files to delete** — none
**Workflows to preserve** — both; neither is replaced, both are amended

**Cloudflare configuration required outside the repository** — none

**Repository settings required (recommendation only, not applied)**
- Branch protection on `main`: replace required check `Build (unsigned)` with
  `ci`. Until this is changed, the new workflow leaves merges blocked.

**Risks**
- Changing the required check name is the one step that can block all merges if
  done out of order. Land the workflow first, confirm `ci` reports on a live
  pull request, then switch branch protection, then remove the old requirement.
- `dorny/paths-filter` is another third-party action. It is widely used and
  should be pinned to a commit SHA, not a tag.

## 8. Interaction with the Frost to Skein rebrand

`build.yml:29,37,38` hardcode `-scheme Frost -project Frost.xcodeproj`. The
rebrand's phase 5 rewrites those. More useful: the rebrand moves the project to a
new repository whose branch protection is created from scratch, so the required
check rename in § 7 costs nothing if the CI change lands **in the new repository**
rather than in `bavanchun/Frost`.

Recommended order: stand up `ariadnev-skein` (rebrand phase 1), then apply this
CI change there, then continue the rebrand.

## Unresolved questions

1. Apply the CI change now in `bavanchun/Frost`, or after the move to
   `ariadnev-skein` so branch protection is configured once?
2. Given the repository is public and minutes are free, is the wall-clock and
   supply-chain gain worth the added workflow complexity, or keep CI as is?
3. Should a Skein landing page be added to `ariadnev-web` — the only real use for
   the Cloudflare plan in this ecosystem?
