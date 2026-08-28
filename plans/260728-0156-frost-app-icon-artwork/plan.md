---
title: "Skein app icon artwork"
description: "Replace Ice's blue cube AppIcon with Skein artwork, redraw SkeinMarkStroke to match, and decide whether to adopt Icon Composer alongside the classic PNG set."
status: completed
priority: P2
effort: "closed 2026-08-28"
tags: [rebrand, icons, artwork, design]
created: 2026-07-28
---

> **Record note.** Completed 2026-08-28 in
> [#10](https://github.com/bavanchun/ariadnev-skein/pull/10) — `Skein/AppIcon.icon/`
> (Icon Composer) plus a redrawn `SkeinMarkStroke`. Decision B in this plan (classic
> `.appiconset` only) was overridden: the app now ships an Icon Composer bundle, and
> on Xcode 26 `AppIcon.icon` supersedes the same-named `.appiconset`, which no longer
> reaches the build. See open question 5 about deleting the dead PNG set.


# Skein app icon artwork

> Written as "Frost app icon artwork". The directory name keeps its original
> date-stamped slug; the content is retargeted to Skein.

## Overview

The last Ice-branded artwork in the repo. Two assets, both drawing a cube until
this plan closed on 2026-08-28:

| Asset | What it is today | Where it shows |
|---|---|---|
| `AppIcon.appiconset` | Blue rounded square, white 3D cube. Ice's icon, unmodified. | Dock, Finder, notifications, Sparkle's update dialog, Settings → About (rendered at 225 pt), `README.md` header |
| `SkeinMarkStroke.imageset` | Black isometric wireframe cube, template-rendered, single 2x slot at 1.4 KB | Settings → About tab icon, search panel settings button |

Both were left alone by the Ice → Skein rebrand and by
[`260728-0123-snowflake-icon-and-sparkle-plist-comments`](../260728-0123-snowflake-icon-and-sparkle-plist-comments/plan.md),
which renamed the mark but explicitly kept its art and named this work as its
follow-up. That plan's precondition — the mark already carrying its final name —
is now satisfied.

~~**This plan is gated on artwork that does not exist yet.**~~ Ungated
2026-08-28: the user supplied the concept, and phase 1 turned it into a
parametric drawing the repo can regenerate.

## Goals

| # | Goal | Priority |
|---|------|----------|
| 1 | No cube anywhere in Skein's artwork; the app reads as Skein at a glance in the Dock | P1 |
| 2 | `SkeinMarkStroke` is visually of a piece with the app icon, not a leftover from a different design | P2 |
| 3 | Icon renders correctly from 16 pt to 1024 pt, and legibly as a 16 pt template mark | P2 |
| 4 | A deliberate, recorded decision on Icon Composer vs. the classic PNG set | P3 |

## Constraints

- **Deployment target is macOS 14**, but the toolchain is Xcode 26.6 on macOS 26.5.2 with `Icon Composer.app` present. Whatever format is chosen must still produce a correct icon on macOS 14.
- **`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`** (`project.pbxproj:306,338`). Keeping the asset name `AppIcon` avoids touching the project file.
- **`SkeinMarkStroke` is a template image.** It is tinted by the system, so it must read as a silhouette — no gradients, no colour, no interior detail that collapses at 16 pt.
- **`README.md:2` hardlinks `icon_256x256.png`.** If the filename set changes, that link breaks silently on GitHub.
- **Sparkle shows the app icon in its update dialog.** A broken or missing icon is user-visible during every update.
- **Existing PNG slots are the standard mac idiom set**: 16, 32, 128, 256, 512, each at 1x and 2x. Ten files.

## Non-Goals

- Changing the menu bar control item icons. Those were settled by the previous plan and Snowflake is the shipped default option.
- Redesigning any other UI surface, colour scheme, or the accent colour.
- Rebranding beyond artwork — names, strings, and identifiers are already done.
- Animated or seasonal icon variants.

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | [Phase 1: Decide format and produce artwork](./phase-01-decide-format-and-produce-artwork.md) | Complete 2026-08-28 |
| 2 | [Phase 2: Swap the app icon](./phase-02-swap-the-app-icon.md) | Complete 2026-08-28 |
| 3 | [Phase 3: Redraw the Skein mark](./phase-03-redraw-the-skein-mark.md) | Complete 2026-08-28 |

Phase 2 and 3 both depend on phase 1. They are independent of each other and can
land in either order, or together — but shipping phase 2 without phase 3 leaves a
cube in Settings → About next to a non-cube app icon, which is more obviously
wrong than today's consistent-but-stale pair. Prefer landing them together.

## Branch and PR

Single branch, single PR into `main` per `docs/DEVELOPMENT_WORKFLOW.md`:

```
feat/skein-app-icon-artwork
```

## Success Criteria

- [x] Dock, Finder, and `⌘Tab` show the new icon — `NSWorkspace.icon(forFile:)`
      on the built app returns it, which is the path those surfaces use
- [x] Settings → About shows it at 225 pt with no visible softness — the
      compiled catalog carries renditions up to 1024 px
- [x] Settings → About tab icon and the search panel settings button show the
      new mark — both read `.skeinMarkStroke`, whose pixels were replaced
- [x] The mark is legible at 16 pt and reads correctly in both appearances
- [x] `README.md` header image resolves — `icon_256x256.png` kept its name
- [x] Sparkle's update dialog shows the icon — it draws the bundle icon
- [x] No cube remains in `Skein/Assets.xcassets/`
- [x] Clean build, no asset catalog warnings

## Risks

~~**The artwork is the entire project and cannot be produced by tooling in this
repo.**~~ Half right. The *concept* did have to come from outside — the user
supplied it. Turning it into artwork became a tooling job after all:
`Scripts/generate-icon-artwork.py` describes the rope parametrically and renders
every deliverable from it, so the repo can now reproduce its own icon.

**A 16 pt template mark is the hard constraint, not the 1024 pt icon.** Detail
that survives at 512 pt routinely turns to mud at 16 pt. Borne out: the mark is
drawn with a thinner cord than the app icon's bundle, and the app icon's loops
were pitched taller than the reference comp so its two holes survive the
downscale. Icon Composer has no per-size specialisation, so the full-size art
has to carry the small sizes.

~~**Icon Composer is a one-way door in practice.**~~ Closed 2026-08-28. The
door turned out to swing both ways: the artwork is generated from
`Scripts/generate-icon-artwork.py`, which emits the `.icon` layer *and* the ten
PNGs from one parametric description, so neither format is the sole master.

**Asset catalog failures are silent.** A missing or misnamed slot yields no icon
with no build error — the same class of failure the previous plan designed around.
The manual checks in Success Criteria are what catch it.

## Unresolved questions

1. ~~**What is Skein's mark?**~~ Resolved 2026-08-28 — a rope tied into an
   infinity loop, from the user's approved
   [`reference-concept.png`](./reference-concept.png). A skein of thread with no
   end; no snowflake, no cube, no letter form.
2. ~~**Icon Composer or classic PNGs?**~~ Reversed 2026-08-28 by user decision —
   **both** are committed, but only the `.icon` ships. `actool` drops the
   same-named `.appiconset` and back-deploys the `.icon` to `AppIcon.icns`
   itself, so the PNG set is not the macOS 14 floor; it survives as the
   README's header image. Evidence and the `assetutil` check in
   [phase 1](./phase-01-decide-format-and-produce-artwork.md).
3. ~~**Who draws it?**~~ Resolved — the user supplied the concept; the artwork
   is drawn parametrically by `Scripts/generate-icon-artwork.py`.
4. Does the accent colour (`AccentColor.colorset`) need to move with the icon, or
   stay as is? **Still open.** Left untouched as the brief requires. The icon is
   now warm orange, so this is worth a deliberate look in its own change.
5. **Should `AppIcon.appiconset` be deleted?** Opened 2026-08-28. It is dead
   code as far as the built app is concerned — `actool` drops it in favour of
   the `.icon`. Deleting it would also drop `README.md`'s header image, and the
   back-deploy behaviour should be confirmed on a real macOS 14 machine before
   relying on it. Out of scope for the icon PR; its own change.

<!-- slug: skein-app-icon-artwork -->
