---
type: coordinator-brief
supersedes: 04-landing-page-build-20260823-1837.md (gate + current-state only)
created: 2026-08-28 11:25 +07
run_order: 2 of 2 (this restart)
agent: Codex
worktree: /Users/vchun/orca/workspaces/Ice-vc/skein-landing-page
web repo: /Users/vchun/orca/workspaces/Ice-vc/ariadnev-skein-web
---

# Coordinator brief — Skein landing page, restart

Read this file, then `plans/handoffs/04-landing-page-build-20260823-1837.md`,
then `plans/260823-1810-skein-landing-page/plan.md`. Where this file
disagrees with the older handoff, **this file wins on gates and current
state**; the older handoff remains authoritative on architecture, sections,
and guardrails.

## What actually happened since the original handoff

The last run of this stream died when the repo folder was renamed
`Ice-vc` → `Skein` out from under it. Before dying it got further than the
handoff records, and you must not redo that work:

- **`bavanchun/ariadnev-skein-web` already exists** — public, MIT, created
  2026-08-28. Cloned to `/Users/vchun/orca/workspaces/Ice-vc/ariadnev-skein-web`.
  It is a normal clone, not a git worktree, so the rename did not damage it.
- **An Astro skeleton is already committed** on branch `feat/astro-skeleton`
  as `1116288 feat(web): initialize Astro landing page`. It contains
  `src/pages/index.astro` and `src/styles/global.css`, plus
  `astro.config.mjs`, `package.json`, `pnpm-lock.yaml`, `tsconfig.json`.
- **That branch is UNPUSHED.** `origin/main` is still just
  `7d617ad Initial commit`. Push it early so the work stops living on one
  disk.

## The gate that was blocking you is now open

The original handoff said: *"the user has not yet approved the plan. DO NOT
create the repo … until the plan is `active`."* The repo was created anyway
during the last run.

The user has now explicitly directed this stream to run. Treat the plan as
**approved**. Your first repo-side action is to set
`plans/260823-1810-skein-landing-page/plan.md` frontmatter from
`status: proposed` to `status: active`.

That plan file lives in **this** worktree (the Skein app repo), not in the
web repo. The original handoff said this stream makes zero commits to the
app repo — that guardrail is narrowed, not lifted: **the only app-repo
change you may make is the plan status and its phase checkboxes**, on branch
`bavanchun/skein-landing-page`, docs-only. No source, no assets, no config.

## Still hard, still non-negotiable

- **Do not touch the `ariadnev-skein-edge` Cloudflare Worker until cutover.**
  It currently serves `skein.ariadnev.com/appcast.xml`, `/health`, and a 302
  fallback. **Sparkle auto-update for every existing Skein 1.2.0 install
  depends on it.** Breaking it strands users on a dead update feed.
- **Cutover order is not negotiable:** (1) deploy Pages to a preview URL,
  (2) `curl` `/appcast.xml` and confirm 200 *after* the route split but
  *before* any DNS change, (3) only then repoint the apex to Pages.
- **Do not touch `bavanchun/ariadnev-web`.** The plan explicitly rejected
  `ariadnev.com/skein`; that repo is mid-feature on
  `feat/beta-version-selector`.
- **Reduced motion is a hard requirement (WCAG 2.3.3)**, not polish. Every
  scroll animation needs a static fallback under
  `prefers-reduced-motion: reduce`.
- **Perf budget:** initial JS ≤ 100 KB gzipped, LCP < 2.5 s on 4G, CLS < 0.1.
- **No Ice or Frost above the fold.** Credit to Jordan Baird / Ice belongs in
  the footer LICENSE link only.
- Cloudflare Web Analytics only. No third-party trackers, no cookies.
- Tech stack is locked: Astro 5 + Tailwind 4 + GSAP 3 + ScrollTrigger +
  Lenis, deployed on Cloudflare Pages. MIT license for the web repo (the app
  stays GPL-3.0).
- Conventional commits, no AI references. Branch + PR, never straight to
  `main`. Follow `docs/DEVELOPMENT_WORKFLOW.md`.

## Two dependencies you do not control

1. **App icon artwork** — running in parallel right now in worktree
   `/Users/vchun/orca/workspaces/Ice-vc/skein-app-icon`. The hero needs it.
   Build with a placeholder and swap it in; **do not block on it, and do not
   design your own icon.**
2. **Real Skein screenshots** — Skein is *not installed on this machine*
   (verified: `/Applications/Frost.app` exists, `Skein.app` does not, and no
   `com.ariadnev.Skein` defaults domain). The install stream has not run yet.
   Sections needing real product screenshots will have to wait or use
   honest placeholders. **Do not fabricate a screenshot of the app.**

## Suggested order

1. Push `feat/astro-skeleton` to origin.
2. Set the plan to `active` in this worktree; commit docs-only.
3. Wire Cloudflare Pages to a **preview** deployment. No apex, no worker
   changes.
4. Build the section skeleton — all 9 scroll scenes, static, no animation,
   reduced-motion fallback as the baseline rather than an afterthought.
5. Layer in GSAP/ScrollTrigger/Lenis on top of the working static page.
6. Cutover, in the exact 3-step order above, only once the rest is green.

## Escalate rather than decide

- Anything that would change the worker's behaviour before step 6.
- Copy claims about what Skein does that you cannot verify from the repo.
- Dropping a locked section or a stack component to hit the perf budget.

Report progress with `orca orchestration send` if a Run is bound; otherwise
leave findings in `plans/reports/`.
