---
phase: 1
title: "Decide format and produce artwork"
status: complete
priority: P1
effort: "unknown — design work, not engineering"
dependencies: []
---

# Phase 1: Decide format and produce artwork

## Overview

Two decisions and one deliverable. Nothing in phases 2 or 3 can start until this
closes, and no honest estimate exists for the rest of the plan until it does.

## Decision A — what Skein's mark is

> **Closed 2026-08-28 — a rope tied into an infinity loop.** The user supplied
> and approved the concept directly: [`reference-concept.png`](./reference-concept.png),
> a warm-orange squircle carrying a figure-eight of coiled cord. It is a skein
> of thread that never ends — the name, and Ariadne's thread through the
> labyrinth, in one shape. It duplicates no control item icon and carries no
> letter form. The options below are the stale Frost-era table, kept for the
> record; none of them was chosen.


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

~~**Decided 2026-08-23 — the classic `.appiconset` PNG set.**~~ The goal of this
plan is removing Ice's artwork, and shipping a correct icon on the supported
floor (macOS 14) beats a nicer one on the newest OS. Icon Composer stays
available as a separate, later change once the artwork itself is settled.

**Reversed 2026-08-28 — Icon Composer `.icon`, with the PNG set retained.**
The user asked for Apple's own tooling in as many words: *"sử dụng lib của apple
để thiết kế nó trở trên native như macos hiện nay"*. That is a user decision on
scope, so it supersedes the 2026-08-23 call rather than being re-argued.

Both artifacts ship:

| Artifact | Serves |
|---|---|
| `Skein/AppIcon.icon` | macOS 26 — native material, specular, shadow, and the automatic dark / tinted / clear renditions |
| `Skein/Assets.xcassets/AppIcon.appiconset` | the macOS 14 floor, and `README.md`'s header image |

Two facts were established by testing the toolchain rather than assumed:

- **A `.icon` inside an `.xcassets` is ignored.** `actool` silently emitted no
  catalog at all. The bundle therefore lives at `Skein/AppIcon.icon`, beside the
  catalog. `Skein/` is a `PBXFileSystemSynchronizedRootGroup`, so Xcode picks it
  up with no project file change and
  `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` still resolves.
- **`actool` back-deploys the `.icon` itself.** Compiling with
  `--minimum-deployment-target 14.0` emits `AppIcon.icns` plus an `Assets.car`
  carrying the same `MultiSized Image` / `Icon Image` types the old
  `.appiconset` produced, and the built `Info.plist` gets both
  `CFBundleIconName` and `CFBundleIconFile`. The PNG set is kept as the brief
  requires; it is a second belt rather than the only one.

Where both exist under the name `AppIcon`, the `.icon` wins — verified by
inspecting the compiled `Assets.car`, which contains `AppIcon_Assets/rope`. The
ambiguity is harmless because both sources are generated from the same artwork
by `Scripts/generate-icon-artwork.py`.

## Requirements

**Functional**

- A master image at **1024×1024** with transparency, from which every slot is exported.
- A separate **16 pt-first silhouette** for `SkeinMarkStroke` — solid black on transparent, no gradients, no colour, no interior detail.
- Both read as the same identity, not two designs that happen to ship together.

**Non-functional**

- Master is archived outside the asset catalog so future re-exports do not have to reverse-engineer a PNG.
- Icon follows Apple's macOS app icon geometry: the rounded-square grid with its standard inset, not a full-bleed square. Ice's current icon already does; matching it keeps the Dock rhythm right.

## Implementation Steps

1. ~~Settle Decision A.~~ Closed above — the rope infinity loop.
2. ~~Decision B.~~ Closed above — Icon Composer, PNG set retained.
3. ~~Produce the 1024×1024 master.~~ The master is vector, not raster:
   `Skein/AppIcon.icon/Assets/rope.svg`, composited by Icon Composer's own
   material. Nothing is hand-painted, so there is no baked squircle or shadow
   for the system to draw twice.
4. ~~Produce the 16 pt template silhouette.~~ `SkeinMarkStroke.png`, one cord of
   the same figure-eight, pure black on transparent.
5. ~~Check both at final size.~~ See the Verification note below.
6. ~~Archive the master.~~ The artwork is parametric and lives in the repo as
   `Scripts/generate-icon-artwork.py`, which regenerates the SVG layer, all ten
   PNGs, and the mark from one description. Re-run it after any edit.

## Verification (2026-08-28)

- `xcodebuild build` clean, no asset catalog warnings. The only warning in the
  log is the pre-existing `CustomColorPicker.swift` switch exhaustiveness one.
- The built `Skein.app` carries `CFBundleIconName = AppIcon` and
  `CFBundleIconFile = AppIcon`; `Contents/Resources/AppIcon.icns` holds the new
  artwork on the classic 824-of-1024 grid.
- `NSWorkspace.icon(forFile:)` on the built app returns the new icon, so the
  system resolves it through the same path the Dock and Finder use.
- All six macOS renditions render: Default, Dark, TintedLight, TintedDark,
  ClearLight, ClearDark.
- Evidence sheet: [`icon-evidence.png`](./icon-evidence.png).

**16 pt is honest but tight.** The loops were pitched taller than the reference
comp precisely so the two holes survive the downscale; at 32 pt the figure-eight
reads clearly, and at 16 pt it reads as a loop rather than the solid lump the
flatter version produced. Icon Composer has no per-size layer specialisation —
its specialisations are by appearance only — so a simplified small-size variant
is not expressible in the format. Recorded as a finding, not worked around.

## Success Criteria

- [x] Decision A recorded in this file with its reasoning
- [x] Decision B recorded in this file with its reasoning
- [x] Master exists — vector, `Skein/AppIcon.icon/Assets/rope.svg`
- [x] 16 pt template silhouette exists, pure black on transparent
- [x] Both reviewed at 16 pt, not only at full size
- [x] Master archived at a recorded path — `Scripts/generate-icon-artwork.py`

## Risk Assessment

**Designing at 512 pt and hoping 16 pt works.** The single most common way icon
work has to be redone. Step 4 inverts the order deliberately.

**A template image with any colour or gradient in it.** The system tints template
images wholesale; anything but a silhouette renders as a smudge. This is why the
mark is a separate deliverable rather than a downscale of the icon.

**Deciding Icon Composer implicitly** by opening the app and starting there.
Decision B is cheap to make on purpose and expensive to reverse afterwards.
Closed: it was decided explicitly, by the user, and recorded above.
