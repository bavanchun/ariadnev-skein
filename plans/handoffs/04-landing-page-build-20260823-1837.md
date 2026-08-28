---
type: handoff
task: "Build the Skein landing page at skein.ariadnev.com (cinematic scroll, Astro + Cloudflare Pages)"
priority: P2 (biggest engineering scope; gated on artwork + screenshots)
created: 2026-08-23 18:37 +07
run_order: 4 of 4
---

# Handoff — Skein landing page build

## Mission and current status

**Outcome desired:** `skein.ariadnev.com` serves a polished, scroll-driven
cinematic landing page that presents Skein as a brand-new macOS product in
the ariadnev ecosystem, with no mention of Ice or Frost above the fold.
Sparkle's appcast (`/appcast.xml`) continues to work uninterrupted.

**Done:** planning only.
- Plan written: `plans/260823-1810-skein-landing-page/plan.md` (status
  `proposed`).
- Architectural picks locked in that plan: Cloudflare Pages on the
  `skein.ariadnev.com` root, Astro 5 + Tailwind 4 + GSAP 3 + ScrollTrigger
  + Lenis, new repo `bavanchun/ariadnev-skein-web`, worker keeps
  `/appcast.xml*` via a Workers Route.
- Sections locked: 9 scroll scenes, no Frost/Ice above the fold.

**Remaining:** the user has not yet approved the plan. **DO NOT create
the repo, DO NOT open a Cloudflare Pages project, DO NOT modify the
existing worker** until the plan is `active`.

Then, in order: create the repo, wire Cloudflare Pages, build the
skeleton, layer in animation, cutover.

**Urgency:** medium. This is the biggest ticket. It parallelises with
session 1 (icon) once the skeleton lands.

## Scope and guardrails

- **Repo (new):** `bavanchun/ariadnev-skein-web` — created only after user
  approval.
- **App repo (do NOT touch):** `bavanchun/ariadnev-skein`. This landing
  work makes zero commits there.
- **ariadnev-web repo (do NOT touch):** the plan explicitly rejected the
  `ariadnev.com/skein` option — that repo is mid-feature on
  `feat/beta-version-selector` and merging into it entangles two release
  cycles.
- **Existing Cloudflare Worker `ariadnev-skein-edge` on
  `skein.ariadnev.com`:** currently serves `/appcast.xml`, `/health`, and
  a 302 fallback to the repo on all other paths. Sparkle depends on this.
  The cutover MUST land Pages at `/` **at the same time** as narrowing the
  worker route to `/appcast.xml*` and `/health` — order matters:
    1. Deploy Pages on a preview URL first.
    2. Curl-test `/appcast.xml` still returns 200 from the worker after
       the route split, BEFORE flipping DNS/route.
    3. Only then repoint `skein.ariadnev.com` apex to Pages.
- **Reduced motion (WCAG 2.3.3):** every scroll animation MUST have a
  static fallback keyed on `prefers-reduced-motion: reduce`. This is a
  hard requirement, not polish.
- **Perf budget:** initial JS ≤ 100 KB gzipped; LCP < 2.5s on 4G; CLS < 0.1.
- **Analytics:** Cloudflare Web Analytics only. No third-party trackers,
  no cookies.
- **No mention of Ice or Frost above the fold.** Ice/Baird credit
  restricted to the footer LICENSE link.
- **License file** in the new repo: MIT (the marketing site is not
  derived from Ice — it's original marketing prose + code; Skein the app
  stays GPL-3.0 and its repo is unchanged).

## Current state

- **App repo branch:** `main` @ `1f523236bcdba4bdb40438989c40e6f25aad5ca9`
  (clean except three untracked planning files, all owned by other
  sessions).
- **Landing repo:** does not exist yet.
- **Cloudflare Pages project:** does not exist yet.
- **Existing worker:** `ariadnev-skein-edge` — source in
  `infra/appcast-worker/` in the app repo; deployed on account VChun's;
  wrangler.toml wired to `skein.ariadnev.com`.

## Decisions and rationale

Full detail lives in `plans/260823-1810-skein-landing-page/plan.md`
"Architectural picks" table. Summary:

- **Subdomain over path** (`skein.ariadnev.com` root, not
  `ariadnev.com/skein`): ecosystem = subdomain per app.
- **Cloudflare Pages over Worker-hosted HTML:** framework support,
  preview deploys, image pipeline, real content workflow.
- **Astro over Next.js:** SSG, ships minimal JS, right tool for a
  content site with animation islands.
- **GSAP + ScrollTrigger + Lenis:** industry standard for cinematic
  scroll; Framer Motion is React-only and heavier.
- **New repo `ariadnev-skein-web`:** keeps app repo focused; ecosystem
  pattern is one repo per app.
- **Worker keeps `/appcast.xml`:** cannot break Sparkle — installed
  users depend on this URL byte-for-byte.

## Work performed

- Wrote the plan (126 lines). No repo created, no Cloudflare resource
  touched.

## Verification

Not applicable yet. Verification checkpoints per phase:

- **Phase 1** — `pnpm run dev` serves at localhost; empty Astro page
  renders; TypeScript check clean.
- **Phase 2** — `curl -I https://skein.ariadnev.com/appcast.xml` returns
  200 with the expected `Content-Length`; `curl -I
  https://skein.ariadnev.com/` returns 200 from Pages, not the worker.
- **Phase 6** — Lighthouse ≥ 90 Performance, ≥ 95 Accessibility;
  reduced-motion test passes (open in Safari with Reduce Motion on;
  all scroll scenes fall back to static).
- **Phase 7** — 24-hour soak test on the appcast endpoint via a cron
  ping before declaring cutover complete.

## Open risks and blockers

- **Plan not approved yet.** Blocker. Do not create anything until user
  says OK.
- **Icon artwork slip.** Hero animation depends on the Skein mark from
  session 1. If artwork slips, phases 1–3 can still ship with a
  placeholder mark; phase 4 (hero) waits.
- **Screenshots missing.** Phases 4–5 (feature scenes) need real Skein
  UI at 2x. Blocked on session 2 completing.
- **Cloudflare account risk.** The user's account is the same one that
  hosts `ariadnev-edge` (production). Wrong wrangler/route config could
  break `ariadnev.com`. Every wrangler command needs a dry-run first and
  targets the `ariadnev-skein-edge` worker explicitly by name.
- **DNS propagation window.** Cutover in phase 7 has a ~5-min DNS TTL
  window during which existing installs may hit a stale answer. Schedule
  cutover during low-traffic hours.

## Exact next actions

1. **First safe step** — user reads `plans/260823-1810-skein-landing-page/plan.md`
   and explicitly approves (or requests changes to) the Architectural
   picks table and the Sections list. Do NOT proceed on implied consent.
2. On approval, mark the plan `status: active` and start phase 1:
   ```
   gh repo create bavanchun/ariadnev-skein-web --public \
     --description "Landing page for Skein, macOS menu bar manager (ariadnev ecosystem)." \
     --license MIT --clone
   cd ariadnev-skein-web
   pnpm create astro@latest . -- --template minimal --typescript strict --no-install
   pnpm add -D tailwindcss @tailwindcss/vite gsap lenis @astrojs/cloudflare
   ```
3. Wire Cloudflare Pages Git integration for the new repo, deploy the
   empty Astro build to a staging URL. Do NOT bind `skein.ariadnev.com`
   yet.
4. Split the worker route on the Cloudflare dashboard — narrow
   `ariadnev-skein-edge` to `skein.ariadnev.com/appcast.xml*` and
   `skein.ariadnev.com/health`. Verify with `curl -I` before flipping
   apex to Pages.
5. Build phases 3–5 (skeleton → hero → scenes) in parallel with icon
   session 1 and screenshot delivery from session 2.
6. Phase 6 perf/a11y pass, then phase 7 cutover.
7. Update the plan status to `complete` and this handoff status when
   the site is live.

## Source pointers

- Plan: `plans/260823-1810-skein-landing-page/plan.md`
- Existing worker source: `infra/appcast-worker/index.js`,
  `infra/appcast-worker/wrangler.toml`
- Sparkle URL contract: `Skein/Info.plist` (`SUFeedURL`)
- Release download link (for the hero CTA):
  <https://github.com/bavanchun/ariadnev-skein/releases/latest>
- App repo: <https://github.com/bavanchun/ariadnev-skein>
- Cloudflare docs — Pages + Workers Routes:
  <https://developers.cloudflare.com/pages/> and
  <https://developers.cloudflare.com/workers/configuration/routing/routes/>
- Icon dependency: `plans/handoffs/01-icon-artwork-coordination-20260823-1837.md`
- Screenshot dependency: `plans/handoffs/02-install-skein-remove-frost-20260823-1837.md`
