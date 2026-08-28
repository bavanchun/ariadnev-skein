---
title: "Skein app icon — designer brief"
description: "Handoff spec for designing the Skein app icon and SkeinMarkStroke template mark."
status: ready-for-design
priority: P1
tags: [design-brief, artwork, icon]
created: 2026-08-23
---

# Skein app icon — designer brief

Deliverable brief you can hand to a designer (or use yourself in Figma / Affinity
/ Sketch). Everything below is fixed by the plan and the codebase; only the art
itself is open.

## 1. Product context (the story the icon should tell)

Skein is a **macOS menu bar manager**. It hides overflow menu bar icons behind a
secondary bar and lets you re-arrange, pin, and search them.

The name is chosen deliberately:

> **A skein** is a loosely coiled length of yarn or thread — the shape yarn takes
> when it's wound off a reel for storage. In myth, it's the coil Ariadne handed
> Theseus so he could find his way back out of the labyrinth.

That's the whole metaphor: **a menu bar full of icons is a tangled thread;
Skein is the coil that keeps it in order and the guide back out of the mess.**

Ecosystem: Skein belongs to **ariadnev** (from Ariadne). Any visual family with
future ariadnev apps is welcome but not required — Skein ships first, so it
sets the tone.

## 2. Two artefacts to produce

| # | Asset | Where it shows | Style |
|---|---|---|---|
| A | **App icon** | Dock, Finder, notifications, Sparkle update dialog, Settings → About, README | Full-colour, macOS squircle |
| B | **`SkeinMarkStroke`** template mark | Settings → About tab, search panel settings button | **Monochrome silhouette**, template-rendered (system tints it) |

Both are **derivatives of the same drawing** — B is A stripped to a single
silhouette that still reads at 16 pt. Design A first, then reduce.

## 3. Concept direction (recommended, not locked)

**A coil / loop of thread**, drawn as a clean geometric mark rather than a
literal photo of yarn. Concretely, options ranked by fit:

1. **A stylised skein**: an elongated hank of thread with the characteristic
   figure-eight twist in the middle. Reads as "thread, organised". Best fit
   for the name.
2. **A continuous loop** (Möbius-adjacent): a single thread tracing a closed
   path. Reads as "one thread through everything". Strong ecosystem mark.
3. **A spool with a thread trailing off**: literal but obvious. Good silhouette.

Avoid: snowflakes (that's the menu bar control-item icon, user-changeable —
the app icon must be distinct); cubes (Ice's identity — the whole rebrand is
about not being that); any labyrinth drawing (too on-the-nose and hard to
render at 16 pt).

**Colour:** one primary hue + one accent. The current `AccentColor` is
`Skein/Assets.xcassets/AccentColor.colorset` — pick whatever reads best, don't
feel bound to it. Warm rope-ish tones (amber, terracotta) or cool
saturated (indigo, teal) both work; avoid Ice's cyan blues so the two apps
never look confusable in a screenshot.

## 4. macOS icon style requirements (hard constraints)

- **Squircle shape** — the standard macOS Big Sur+ rounded rectangle. Do NOT
  clip to a circle or a hard square. Use Apple's macOS icon template (the
  bezier of the squircle is not a plain rounded rect).
- **Subtle depth is fine**, hard skeuomorphism is not — soft inner shadow, a
  gentle highlight edge is the current idiom. Look at the built-in macOS
  Reminders / Notes / Freeform icons for the current-era treatment.
- **The mark lives INSIDE the squircle**, with roughly 12–15% padding on all
  sides. Bleeding to the edge fights the system's grid.
- **Full-bleed background** — the squircle itself is coloured; the mark sits on
  top of it. Do not deliver a transparent squircle.
- **sRGB colour space**, PNG with alpha for edges.
- Design at **1024 × 1024**; export the ten sizes below from that master.

## 5. Deliverables — App icon (`AppIcon.appiconset`)

Ten PNG files. Filenames must match exactly — the asset catalog references
them by name (`Skein/Assets.xcassets/AppIcon.appiconset/Contents.json`):

```
icon_16x16.png       16 × 16
icon_16x16@2x.png    32 × 32
icon_32x32.png       32 × 32
icon_32x32@2x.png    64 × 64
icon_128x128.png     128 × 128
icon_128x128@2x.png  256 × 256
icon_256x256.png     256 × 256
icon_256x256@2x.png  512 × 512
icon_512x512.png     512 × 512
icon_512x512@2x.png  1024 × 1024
```

Design at 1024. Export each size **from the 1024 master**, do not upscale
smaller ones. At the 16 pt and 32 pt sizes, look at the export and hand-touch
if the mark turns to mush — Apple's own icons carry per-size overrides.

Also please deliver the **1024 × 1024 layered source** (Figma / Sketch / .afdesign
/ .psd) so future edits and Icon Composer migration have a starting point.

## 6. Deliverables — `SkeinMarkStroke` template mark

**One PNG**, template-rendered (system tints it, do not colour it):

```
SkeinMarkStroke.png     ~ 40 × 40 (@2x slot; catalog only fills the 2x)
```

Rules:

- **Pure black on transparent.** No greys, no gradients, no colour.
- **Silhouette only.** Interior detail collapses to noise when the system
  tints and shrinks it — imagine printing it at 8 mm wide in one colour of
  ink. If it still reads, it works.
- **Same core shape as the app icon** so the two feel like one design. Not
  identical — the app icon can carry depth and colour the template can't.
- Delivered at **~40 pt (80 px @2x)**. If in doubt, err larger and let the
  system downsize; upscaling this asset is the failure mode.

Reference the current placeholder to see how it's used:
`Skein/Assets.xcassets/SkeinMarkStroke.imageset/Contents.json`. Only the 2x
slot needs a file.

## 7. What NOT to do

- Do not touch the menu bar control-item icons — those are a separate,
  user-changeable set (Snowflake, Door, etc.) that was finalised in a
  previous plan.
- Do not change `AccentColor.colorset` — that's a separate design decision.
- Do not deliver `.icon` (Icon Composer) files. The plan explicitly chose the
  PNG set for the first landing; Icon Composer is a later, separate change.
- Do not embed the name "Skein" as text in the icon.
- Do not include the letter "S" as the mark — it collapses at 16 pt and
  competes with every other app that took the same shortcut.

## 8. Handoff checklist

When artwork is ready, hand back:

- [ ] `AppIcon/` folder containing the ten PNGs at the exact filenames above
- [ ] `SkeinMarkStroke.png` at the size stated
- [ ] The 1024 × 1024 layered source file for the app icon
- [ ] A single-frame PNG mockup of the icon on a dark Dock and a light Dock
      (so we can eyeball it against the OS before shipping)

Drop them into a folder anywhere — the engineering side will install them
into `Skein/Assets.xcassets/AppIcon.appiconset/` and
`Skein/Assets.xcassets/SkeinMarkStroke.imageset/` as phases 2 and 3 of the
parent plan describe.

## 9. Approvals gate

Before starting export work, share the **1024 master + a 16 pt preview** for
sign-off. The 16 pt preview is where most icon concepts die; catching it
before you cut ten slots saves the round-trip.
