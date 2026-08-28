---
title: "Skein landing page — skein.ariadnev.com"
description: "Cinematic scroll-driven landing page for Skein, first title in the ariadnev ecosystem, deployed on Cloudflare Pages under skein.ariadnev.com root."
status: proposed
priority: P2
effort: "1–2 weeks (design + build), gated on artwork and content"
tags: [landing, marketing, cloudflare-pages, astro, gsap]
created: 2026-08-23
---

# Skein landing page

## Outcome

`skein.ariadnev.com` becomes a **standalone brand site** for Skein — not a
route on `ariadnev.com`, not raw HTML in a Worker. It sells Skein as a new
macOS product, does not mention Frost or Ice above the fold, and uses
scroll-driven cinematic animation as the primary storytelling device.

## Architectural picks (decided)

Chosen without a further round-trip because the user asked for the "most
polished option" and every viable path narrows to the same one:

| Decision | Pick | Why the others lose |
|---|---|---|
| **Domain** | `skein.ariadnev.com` root | `ariadnev.com/skein` would drag every future ecosystem app into one Next.js repo and one deploy queue. Subdomain-per-app is the ecosystem pattern. |
| **Runtime** | Cloudflare Pages | Cinematic scroll needs a real framework, real image pipeline, real preview deploys. Cramming HTML/CSS into `ariadnev-skein-edge` worker turns every content edit into a Worker deploy and blocks framework tooling. |
| **`/appcast.xml`** | Kept on the existing Worker, via Workers Route `skein.ariadnev.com/appcast.xml*` | Sparkle is load-bearing — installed users depend on this URL. It stays under the Worker that already serves it; only `/` and everything else falls through to Pages. |
| **Framework** | Astro 5 | SSG, ships almost no JS by default, plays nicely with GSAP islands, first-class Cloudflare Pages adapter. Next.js is overkill; a pure static build is under-tooled for content changes. |
| **Styling** | Tailwind CSS 4 | Zero-runtime, class-based, fastest to iterate. |
| **Motion** | GSAP 3 + ScrollTrigger, Lenis for smooth scroll | Industry standard for scroll-driven cinematic sites (every Awwwards site of this type uses it). Framer Motion is React-only and heavier. |
| **Repo** | New public repo `bavanchun/ariadnev-skein-web` | Keeps app repo (`ariadnev-skein`) focused on the macOS product. `ariadnev-web` is mid-feature on another branch — sharing it would entangle two release cycles. |
| **CI/deploy** | Cloudflare Pages Git integration, auto-deploy on push to `main`, preview deploy per PR | Zero Actions minutes, matches the pattern established by the appcast Worker. |

## Non-goals

- Mention of Ice, Frost, or the rebrand. Skein is presented as a new product.
- Blog, docs site, or user account system. Not this pass.
- i18n. English only for v1.
- Analytics beyond Cloudflare Web Analytics (privacy-preserving, no cookies).
- Payment / license flow. Skein is free and GPL-3.0; the source link is
  attribution enough.

## Scope — sections in scroll order

1. **Hero.** Full-viewport. Animated Skein mark drawing itself from a single
   thread. One-line tagline. Two CTAs: `Download for macOS` (direct link to
   the latest release ZIP) and `View on GitHub`.
2. **The problem.** Scroll-triggered scene showing a cluttered macOS menu
   bar; icons overflow off-screen as the user scrolls.
3. **The skein — solution reveal.** The mark from the hero coils around the
   overflow and organises it into Skein's hidden bar.
4. **Features (3–5 scenes).** Each is a pinned scroll section with a
   product screenshot and a one-sentence promise:
   - Hide icons behind a click
   - Always-hidden section for sensitive apps
   - Second bar under the main one
   - Global hotkeys
   - Search across every icon
5. **Appearance customisation.** Parallax gallery of the appearance
   settings — tint, shadow, split, colours.
6. **Requirements strip.** macOS 14+, Apple Silicon and Intel, free, open
   source (GPL-3.0), signed and notarised.
7. **What's changing.** Compact latest-changelog block, link to full
   changelog on GitHub, one-line roadmap teaser.
8. **FAQ.** 4–6 items: does it launch at login, does it use much memory,
   what permissions and why, how do updates work, where's the source.
9. **Download CTA + footer.** Big download button, small footer with
   GitHub, licence, ariadnev ecosystem link.

Upgrade guidance for Frost users lives in `docs/upgrade-frost-to-skein.md`
inside the app repo — the landing page does not surface it. Users landing
from Frost's in-app link will get a direct GitHub release link, not a
message about migration.

## Content dependencies

Every phase below is gated on real content that does not exist yet:

- **App icon** (`plans/260728-0156-frost-app-icon-artwork/`) — the mark is
  the visual centrepiece of the hero. Cannot build the hero without it.
- **Screenshots** — need real Skein UI screenshots at 2x for retina. Cannot
  build the features section without them.
- **Copy** — tagline, feature one-liners, FAQ answers. Draft copy will come
  from this plan; final polish is the user's call.

## Phases (draft — awaiting approval)

| # | Phase | Depends on | Estimate |
|---|---|---|---|
| 1 | Repo + Astro + Tailwind + Cloudflare Pages skeleton, deployed to `skein.ariadnev.com` staging path | — | 0.5 day |
| 2 | Worker route split — Pages serves `/`, Worker keeps `/appcast.xml*` and `/health` | Phase 1 | 0.5 day |
| 3 | Static shell of all 9 sections with placeholder art and locked copy | Phases 1–2 | 1 day |
| 4 | GSAP + Lenis integration; hero animation | Phase 3 + icon artwork | 1–2 days |
| 5 | Scroll-triggered scenes for problem/solution/features | Phase 4 + screenshots | 2–3 days |
| 6 | Performance pass (LCP, CLS, JS budget) + accessibility pass (reduced-motion fallback, keyboard nav) | Phase 5 | 1 day |
| 7 | Cutover: repoint apex `skein.ariadnev.com` to Pages, Worker route to `/appcast.xml*` only | All | 0.5 day |

Total: ~7–9 working days once artwork and screenshots exist.

## Risk

- **Reduced-motion users.** Cinematic scroll is hostile to users with
  vestibular sensitivity. Every scroll animation must have a static
  fallback triggered by `prefers-reduced-motion`.
- **Sparkle break.** Getting the Worker route split wrong will 404 the
  appcast for every installed user. Phase 2 must ship with a curl test
  that hits the live URL before cutover.
- **Icon dependency.** If the app icon artwork slips, the hero either
  ships with a placeholder or the landing page slips with it. Prefer the
  latter.

## Branch and PR

New repo, so this plan runs entirely in `bavanchun/ariadnev-skein-web`.
Each phase = one branch = one PR into that repo's `main`.

## Approval gate

This plan is **proposed**, not `active`. Waiting on:

1. Sign-off on the architectural picks (they're stated as decisions but
   they burn a domain and stand up a Worker route — worth a checkpoint).
2. Sign-off on the scope (9 sections above).
3. Green-light to create `bavanchun/ariadnev-skein-web` and start phase 1.
