---
phase: 1
title: "Decide format and produce artwork"
status: pending
priority: P1
effort: "unknown — design work, not engineering"
dependencies: []
---

# Phase 1: Decide format and produce artwork

## Overview

Two decisions and one deliverable. Nothing in phases 2 or 3 can start until this
closes, and no honest estimate exists for the rest of the plan until it does.

## Decision A — what Skein's mark is

> **Reopened 2026-08-23.** This decision was written while the app was named
> Frost, and the options below still argue from that name — snowflakes, ice
> crystals, frost formation. The app is now **Skein**, so the naming tie-in the
> table weighs has changed entirely: a skein is a coiled length of thread,
> Ariadne's thread through the labyrinth. Re-evaluate from there; the options as
> written are stale, not merely renamed.


Blocking, and not answerable from the repo. Options, with the argument against each:

| Direction | Against |
|---|---|
| Snowflake | Repeats the menu bar control item icon exactly. Coherent, but the app icon and the menu bar icon doing the same thing may read as unimaginative — and the menu bar icon is user-changeable, so the pairing breaks the moment someone picks Door. |
| Skein/ice crystal formation, not a discrete snowflake | Keeps the name's meaning without duplicating the control item. Harder to make legible at 16 pt. |
| Abstract mark unrelated to weather | Most distinctive, least self-explanatory. Loses the naming tie-in that makes "Skein" memorable. |
| Keep a geometric solid, restyled and de-Iced | Cheapest continuity with the existing mark, but the cube is Ice's identity — carrying its silhouette forward defeats the point of the rebrand. |

**Recommendation: skein/crystal formation.** It earns the name without making the
app icon a copy of a setting the user can change. Not a decision this plan can
make alone.

## Decision B — Icon Composer or the classic PNG set

Verified: `Icon Composer.app` ships with Xcode 26.6 on this machine; the toolchain
is macOS 26.5.2; deployment target is macOS 14.0.

| | Classic `.appiconset` (10 PNGs) | Icon Composer `.icon` |
|---|---|---|
| macOS 14 target | Exactly what ships today | Xcode generates the fallback set |
| macOS 26 look | Flat, no Liquid Glass treatment | Native tinting, dark/clear variants |
| Effort | Export ten PNGs | Compose layers, tune material |
| Reversibility | Trivial | Artwork lives in a format the PNG pipeline cannot round-trip |
| Risk | None new | New format on a macOS 14 target; needs checking on the oldest supported OS |

**Decided 2026-08-23 — the classic `.appiconset` PNG set.** The goal of this plan
is removing Ice's artwork, and shipping a correct icon on the supported floor
(macOS 14) beats a nicer one on the newest OS. Icon Composer stays available as a
separate, later change once the artwork itself is settled: keeping a format
migration and a redesign out of the same PR keeps two independent risks apart,
and the 1024×1024 master this phase produces is the input either way.

Phases 2 and 3 therefore target the ten-slot `.appiconset` and the single-slot
`SkeinMarkStroke.imageset` exactly as they stand today. No project file change is
needed — `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` continues to resolve.

## Requirements

**Functional**

- A master image at **1024×1024** with transparency, from which every slot is exported.
- A separate **16 pt-first silhouette** for `SkeinMarkStroke` — solid black on transparent, no gradients, no colour, no interior detail.
- Both read as the same identity, not two designs that happen to ship together.

**Non-functional**

- Master is archived outside the asset catalog so future re-exports do not have to reverse-engineer a PNG.
- Icon follows Apple's macOS app icon geometry: the rounded-square grid with its standard inset, not a full-bleed square. Ice's current icon already does; matching it keeps the Dock rhythm right.

## Implementation Steps

1. Settle Decision A. Nothing else proceeds first.
2. Decision B is closed above; no further action. Classic `.appiconset`.
3. Produce the 1024×1024 master.
4. Produce the 16 pt template silhouette. Design at 16 pt and scale up.
5. Check both at final size before exporting anything: the icon at 16 pt in a
   simulated Dock, the mark at 16 pt against light and dark backgrounds.
6. Archive the master. Suggested: `docs/assets/` or a design file kept outside the
   repo — decide when the format is known and note it here.

## Success Criteria

- [ ] Decision A recorded in this file with its reasoning
- [x] Decision B recorded in this file with its reasoning
- [ ] 1024×1024 master exists with transparency
- [ ] 16 pt template silhouette exists, pure black on transparent
- [ ] Both reviewed at 16 pt, not only at full size
- [ ] Master archived at a recorded path

## Risk Assessment

**Designing at 512 pt and hoping 16 pt works.** The single most common way icon
work has to be redone. Step 4 inverts the order deliberately.

**A template image with any colour or gradient in it.** The system tints template
images wholesale; anything but a silhouette renders as a smudge. This is why the
mark is a separate deliverable rather than a downscale of the icon.

**Deciding Icon Composer implicitly** by opening the app and starting there.
Decision B is cheap to make on purpose and expensive to reverse afterwards.
