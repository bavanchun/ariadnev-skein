---
type: coordinator-brief
supersedes: coordinator-brief.md (format decision only)
created: 2026-08-28 11:25 +07
run_order: 1 of 2 (this restart)
agent: Claude Code
worktree: /Users/vchun/orca/workspaces/Ice-vc/skein-app-icon
branch: bavanchun/skein-app-icon
---

# Coordinator brief v2 — Skein app icon, Apple-native

Read this file first. Where it disagrees with `coordinator-brief.md` or
`plan.md`, **this file wins**. Everything it does not mention still applies
from those two.

## Why v2 exists

The previous run of this stream died when the repo folder was renamed
`Ice-vc` → `Skein` out from under it. Nothing it produced was lost; nothing
it produced was artwork either. The worktree is repaired and back on
`bavanchun/skein-app-icon` @ `2a32776`.

## The one decision that changed

The user has explicitly chosen **Apple's own icon tooling, targeting the
macOS 26 icon system**. That resolves a contradiction that blocked the last
run:

- `plan.md` "Decision B" locked *classic `.appiconset` PNG set only, no Icon
  Composer*. **Decision B is superseded — do not follow it.**
- The old `coordinator-brief.md` asked for Icon Composer + PNG fallback.
  That is now the confirmed direction.

**Deliver both, and understand why both:**

| Artifact | Serves | Why it is mandatory |
|---|---|---|
| `AppIcon.icon` (Icon Composer bundle) | macOS 26 | The user's stated goal — native Liquid Glass, system-applied material, specular, shadow, and dark/tinted/clear variants |
| `AppIcon.appiconset` (10 PNGs) | macOS 14–25 | `MACOSX_DEPLOYMENT_TARGET = 14.0` (verified in `Skein.xcodeproj/project.pbxproj`). Users below 26 get **no icon at all** without this |

Do not propose dropping the PNG set "because Icon Composer handles it". It
does not handle a macOS 14 deployment target. If you believe raising the
deployment target is the better call, that is a **user decision** — open a
gate, do not decide it yourself.

## The artwork

Locked concept, already in this directory:
`plans/260728-0156-frost-app-icon-artwork/reference-concept.png`
(1024×1024) — a warm-orange squircle with a rope tied into an infinity /
figure-eight loop, drawn as multiple parallel strands with visible twist.

The user re-sent this exact file today; it is byte-identical to the
committed one. The concept is **approved and not up for redesign**.

**Reproduce the concept, not the file.** The PNG is an AI-rendered comp and
carries artifacts you must not carry forward:

- A baked drop shadow around the squircle, plus red/green fringing at the
  outer edge. In the macOS 26 model the **system** draws the shadow and the
  squircle mask — you supply flat layers. Baking a shadow in produces a
  double shadow.
- Soft raster gradients on the rope. Author the rope as **vector** so it
  stays crisp at 16 pt, where a 3D-rendered rope turns to mud.

**Read the 16 pt case as a first-class requirement, not a downscale.** At 16
pt the multi-strand rope must not collapse into a solid blob. Simplify
strand count at small sizes if the tooling allows it; if it does not, that
is a finding worth reporting.

## Layer model to aim for

Author the `.icon` as separate layers so macOS 26 can light and mask them:

1. **Background** — the warm orange gradient (deep red-orange at the edges,
   brighter orange toward the upper-left light source). No squircle path of
   your own; the system supplies the shape.
2. **Rope** — the infinity loop, vector, warm amber/gold. Its own layer so
   the system can apply specular and depth.
3. Optional shadow/occlusion layer *only* if Icon Composer's own model calls
   for it — never a hand-painted one.

Verify the real layer schema before authoring. Two ways in:

- **Icon Composer.app** — `/Applications/Xcode.app/Contents/Applications/Icon Composer.app`,
  version 1.6. GUI only; there is **no `xcrun icon-composer` CLI** (verified —
  `xcrun --find icon-composer` fails). Create a blank document there, inspect
  the resulting bundle's internals, and mirror that structure.
- If the GUI is unavoidable, this host has Orca computer-use available
  (`orca computer list-apps`, `orca computer click`, `orca computer get-app-state`).
  Use it rather than guessing at the format.
- Confirm against current Apple documentation (Human Interface Guidelines →
  App icons; "Creating your app icon using Icon Composer"). Your training
  data predates this tooling — **look it up, do not recall it**.

## Hard constraints — unchanged, non-negotiable

- **Do not touch** `Skein/Assets.xcassets/ControlItemImages/`. Those are the
  menu bar item icons (Snowflake, Door, …), settled by a shipped plan and
  user-facing.
- **Do not change** `AccentColor.colorset`. Separate decision.
- **No letter "S", no word "Skein"** as text anywhere in the mark.
- **Never commit to `main`.** Branch + PR only, per `docs/DEVELOPMENT_WORKFLOW.md`.
- Conventional commits, no AI references in messages.
- **Filename contract:** the 10 PNGs must match the names already in
  `Skein/Assets.xcassets/AppIcon.appiconset/Contents.json` exactly —
  `icon_16x16.png`, `icon_16x16@2x.png`, `icon_32x32.png`, `icon_32x32@2x.png`,
  `icon_128x128.png`, `icon_128x128@2x.png`, `icon_256x256.png`,
  `icon_256x256@2x.png`, `icon_512x512.png`, `icon_512x512@2x.png`. The
  catalog references them literally; a wrong name is a silent failure, not a
  build error.

## Second deliverable — `SkeinMarkStroke`

`Skein/Assets.xcassets/SkeinMarkStroke.imageset/` is still Ice's black
isometric wireframe cube (single @2x slot, ~1.4 KB, template-rendered). It
appears in Settings → About and the search panel settings button.

Redraw it from the same rope-infinity design: monochrome, stroke-based,
**template rendering preserved** (it is tinted by the system — any baked
colour breaks it). It must read as the same family as the app icon, not a
leftover.

## Definition of done

1. `AppIcon.icon` builds and renders on macOS 26 (this host is 26.6.2 — you
   can actually look at it).
2. `AppIcon.appiconset` PNGs replaced, correct names, icon renders on a
   macOS 14 target.
3. `SkeinMarkStroke` redrawn, template rendering intact.
4. `xcodebuild build` succeeds. Per `docs/release-guide.md`, `xcodebuild
   archive` is **known broken** on this Personal team — do not treat its
   failure as your regression, and do not try to fix it.
5. Visually verify at 16 pt and 1024 pt before claiming done. Screenshot
   evidence in the PR body.
6. PR `feat/skein-app-icon-artwork` → `main`. Update `plan.md` status and
   check off phases 1–3.

## Escalate rather than decide

- Any push to raise `MACOSX_DEPLOYMENT_TARGET` above 14.
- The rope being illegible at 16 pt after honest attempts.
- Icon Composer's format turning out to require something this brief forbids.

Report progress with `orca orchestration send` if a Run is bound; otherwise
leave findings in `plans/reports/`.
