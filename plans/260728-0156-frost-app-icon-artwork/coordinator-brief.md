---
title: "Coordinator brief — Skein app icon (Icon Composer, native macOS Tahoe look)"
description: "Handoff to an orca-spawned coordinator session that owns the Skein app icon end-to-end, targeting Apple's native Icon Composer format with the user-provided concept as source of truth."
status: ready
priority: P1
tags: [coordinator, icon, icon-composer, apple-native]
created: 2026-08-28
supersedes-decision: "phase-01 Decision B (2026-08-23 chose .appiconset only) — now Icon Composer + generated fallback."
---

# Coordinator brief — Skein app icon

You are the coordinator for the Skein app icon work. This brief and the
files it references are the entire source of truth. Read the parent plan
(`plan.md`), the designer brief (`design-brief.md`), and all three phase
files before touching anything.

## The concept — locked

The user has produced a reference concept: **an infinity-loop (∞) coiled
rope, warm orange/coral, sitting on a warm-orange squircle**. See
[`reference-concept.png`](./reference-concept.png) (1254 × 1254 PNG,
1.5 MB) in this folder. Design tone reads as:

- **Symbol:** rope tied into a horizontal infinity loop — a *skein* of
  thread that never ends. Nails the app name and the Ariadne-thread
  ecosystem metaphor in one stroke.
- **Palette:** warm orange squircle background (a single hue, subtle
  vignette darker at edges), rope in a lighter warm ochre/amber with
  soft golden highlights.
- **Depth:** noticeable 3D — rope has round-bar cross-section with soft
  side shadow underneath, squircle carries the Tahoe-era glass bevel on
  the top edge.

**Reproduce this concept.** Do not redesign it. Do not swap colours. If
you propose a change, ask the user first.

## Format decision — REVERSED

`phase-01-decide-format-and-produce-artwork.md` Decision B (2026-08-23)
chose the classic `.appiconset` PNG set and explicitly deferred Icon
Composer. **The user has now explicitly asked to use Apple's native
tools ("sử dụng lib của apple để thiết kế nó trở trên native như macos
hiện nay").** That flips the decision.

**New Decision B — 2026-08-28:**

- **Primary:** Icon Composer `.icon` bundle, authored in `Icon
  Composer.app` (ships with Xcode 26.6). Native Liquid Glass material,
  automatic light/dark/tinted/clear variants, correct on macOS 26.
- **Fallback:** Xcode 26 automatically generates the classic PNG set
  from the `.icon` bundle for the macOS 14 deployment floor. Verify
  the fallback exists and renders correctly on macOS 14 before shipping.
- **Do NOT** ship only the PNG set — the user asked for the native
  format. Do NOT ship only Icon Composer — macOS 14 is the deployment
  target and needs the fallback.

Update `phase-01-decide-format-and-produce-artwork.md` to record this
reversal with the date and the user quote as evidence, per
`~/.claude/rules/review-audit-self-decision.md` (Verified Decisions).

## What you own

1. **Rebuild the reference concept in Icon Composer.** Decompose into
   layers: background squircle → shadow beneath rope → rope loop with
   material and highlights. Aim for a visual match with
   `reference-concept.png` at 1024 pt on the Dock.
2. **Produce the `SkeinMarkStroke` template mark** — a single-colour
   silhouette derivative of the same loop, template-rendered, legible
   at 16 pt. Constraints in `design-brief.md` §6 apply verbatim.
3. **Install both into the Xcode project:**
   - `Skein/Assets.xcassets/AppIcon.icon` (the `.icon` bundle) — or
     whatever path Icon Composer emits; update
     `ASSETCATALOG_COMPILER_APPICON_NAME` in `project.pbxproj` if the
     asset name changes.
   - Regenerate `Skein/Assets.xcassets/AppIcon.appiconset/` PNGs from
     the Icon Composer export.
   - Replace `Skein/Assets.xcassets/SkeinMarkStroke.imageset/SkeinMarkStroke.png`.
4. **Verify** — build in Xcode 26.6, screenshot the Dock at
   size Large, Sparkle update dialog, Settings → About tab. All three
   must match the reference tone.
5. **Ship** — one PR into `main` on branch
   `feat/skein-app-icon-artwork` per `docs/DEVELOPMENT_WORKFLOW.md`.
   Include Dock screenshots (light + dark) in the PR body.
6. **Update plan status** — mark parent plan phases 1–3 `complete`
   with dated evidence.

## Constraints (from parent plan + design brief)

- Deployment target: **macOS 14**. Fallback set must render there.
- Toolchain: Xcode **26.6** on macOS **26.5.2**, Icon Composer.app
  present.
- **`README.md:2` hardlinks `icon_256x256.png`.** Preserve that
  filename in the fallback set or fix the README link.
- **Menu bar control-item icons are OUT OF SCOPE.** Snowflake/Door/etc.
  under `Skein/Assets.xcassets/ControlItemImages/` were settled by a
  previous plan and are user-changeable — do not touch.
- `AccentColor.colorset` — do not change.
- Never put the letter "S" or the word "Skein" as text in the mark.

## Machine environment (for your subagents / tool calls)

- Working directory (this worktree): populated by orca; run `pwd` to
  confirm.
- Git remote: `bavanchun/ariadnev-skein`.
- Base branch: `main` unless orca started you elsewhere.
- CI: GitHub Actions aggregator `CI`. Icon-only changes will trip the
  `changes` filter and run macOS build. Ensure your PR passes it before
  requesting review.

## Deliverables checklist

- [ ] `Skein/Assets.xcassets/AppIcon.icon/` — Icon Composer bundle
- [ ] `Skein/Assets.xcassets/AppIcon.appiconset/` — regenerated PNGs
      (10 files, exact filenames from Contents.json)
- [ ] `Skein/Assets.xcassets/SkeinMarkStroke.imageset/SkeinMarkStroke.png`
- [ ] `project.pbxproj` updated if `ASSETCATALOG_COMPILER_APPICON_NAME`
      changed
- [ ] `plans/260728-0156-frost-app-icon-artwork/phase-01-*.md` — record
      Decision B reversal
- [ ] `plans/260728-0156-frost-app-icon-artwork/plan.md` — phases 1–3
      set to `complete`
- [ ] PR body includes Dock light + dark screenshots and a
      before/after row against `reference-concept.png`

## Escalation

If Icon Composer cannot render one of the reference concept's traits
(specific bevel, exact shadow), do NOT redesign around it — surface
the mismatch to the user and ask for direction. The reference is
locked; the tool is the variable.

Status protocol on completion:

```
Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
Summary: one or two sentences
Concerns/Blockers: optional
```
