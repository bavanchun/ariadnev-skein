---
title: "Skein app icon — coordinator report"
description: "Findings from reproducing the locked rope-infinity concept in Icon Composer, shipping the PNG fallback set, and redrawing the template mark."
status: complete
created: 2026-08-28
tags: [icon, icon-composer, findings]
---

# Skein app icon — coordinator report

Branch `bavanchun/skein-app-icon`, PR into `main`. Built against Xcode 26.6 on
macOS 26.6.2, deployment target macOS 14.0.

## What shipped

| Path | What it is |
|---|---|
| `Skein/AppIcon.icon/` | Icon Composer bundle — `icon.json` plus one vector layer. What the build compiles |
| `Skein/Assets.xcassets/AppIcon.appiconset/` | Ten PNGs, original filenames, regenerated |
| `Skein/Assets.xcassets/SkeinMarkStroke.imageset/SkeinMarkStroke.png` | Template mark, 40 × 40, redrawn |
| `Scripts/generate-icon-artwork.py` | Generates all of the above from one parametric description |

No project file change: `Skein/` is a `PBXFileSystemSynchronizedRootGroup`, so
Xcode picks the bundle up on its own, and
`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` still resolves.

## Findings

### 1. `ictool` exists — Icon Composer is drivable without the GUI

The v2 brief noted `xcrun --find icon-composer` fails and suggested GUI
automation. There is a command-line tool one level in:

```
/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool
```

It renders a `.icon` to PNG at any size, platform, and rendition
(`Default`, `Dark`, `TintedLight`, `TintedDark`, `ClearLight`, `ClearDark`).
That gave a render-and-compare loop against the reference concept, and it is
what generates the PNG fallback set — so the two artifacts cannot drift.

The `.icon` bundle itself was hand-authored: a directory holding `icon.json` and
`Assets/`. No GUI session was needed.

### 2. A `.icon` inside an `.xcassets` is silently ignored

The original brief put the bundle at `Skein/Assets.xcassets/AppIcon.icon`.
`actool` emits **no `Assets.car` and no `.icns` at all** for that layout — no
error, no warning. The bundle must sit beside the catalog, not inside it. It is
now at `Skein/AppIcon.icon`.

### 3. `actool` back-deploys the `.icon` on its own

Compiling the bundle with `--minimum-deployment-target 14.0` produces:

- `AppIcon.icns` with the classic slots, on the standard 824-of-1024 grid;
- `Assets.car` carrying the same `MultiSized Image` / `Icon Image` asset types
  the old `.appiconset` compiled to — not a new type macOS 14 would fail to read;
- an `Info.plist` with both `CFBundleIconName` and `CFBundleIconFile`.

Compiling the *existing* `.appiconset` alone yields an `.icns` with the same four
slots, so the `.icon` route loses nothing on the back-deployment path.

This is reported as a fact, not as a proposal to drop the PNG set — the brief
requires it and it ships.

### 4. Where both exist, the `.icon` wins, silently

With `AppIcon.icon` and `AppIcon.appiconset` both present and both named
`AppIcon`, `actool` takes the `.icon` and says nothing. Confirmed by inspecting
the built `Assets.car`, which contains `AppIcon_Assets/rope`.

The precedence is undocumented, but harmless here: both sources are generated
from the same description, so whichever wins draws the same picture.

### 5. Icon Composer has no per-size layer specialisation — 16 pt is tight

The brief asked to simplify strand count at small sizes "if the tooling allows
it". It does not. The format's specialisations are by *appearance*
(`fill-specializations`, `dark-color`, `light-tint`, and so on); there is no size
axis. One layer serves 16 pt and 1024 pt alike.

What was done instead: the loops are pitched taller than the reference comp, so
the two holes — the thing that makes the figure read as a loop rather than a lump
— survive the downscale. Measured against the flatter first cut, the holes go
from 114 px to 176 px at the 1024 master.

Result: **32 pt reads clearly. 16 pt reads as a loop, but the four cords merge
into a single band.** That is an honest limit of a four-cord rope at 16 pt, not a
bug. Dropping to three cords was tried and did not help — the win came from the
taller loops, and three cords made the 1024 art noticeably less faithful to the
concept.

### 6. Dark Mode drops the orange ground — this is Apple's behaviour, not a defect

`NSWorkspace.icon(forFile:)` on the built app returns the **Dark** rendition on
this host, and Icon Composer replaces the warm-orange background with the system
neutral dark material. That matches Apple's own macOS 26 icons.

A branded dark background was attempted via a `fill-specializations` entry with
`appearance: dark`. It had **no effect** on the rendered output, and the real
schema for that key is not documented anywhere reachable, so nothing speculative
was shipped — the repo's `icon.json` carries no such key.

**Worth a user decision:** if the orange ground should persist in Dark Mode, that
is a separate change and needs the correct specialisation key. The current
behaviour is the native default.

## Verification

- `xcodebuild build` succeeds from clean. No asset catalog warnings. The only
  warning in the log is the pre-existing `CustomColorPicker.swift` switch
  exhaustiveness one, untouched by this change.
- Built `Skein.app` carries `CFBundleIconName = AppIcon` and
  `CFBundleIconFile = AppIcon`; the `.icns` inside holds the new artwork.
- `NSWorkspace.icon(forFile:)` returns the new icon — the same path the Dock and
  Finder resolve through.
- All six macOS renditions render.
- Evidence sheet: [`../260728-0156-frost-app-icon-artwork/icon-evidence.png`](../260728-0156-frost-app-icon-artwork/icon-evidence.png).

`xcodebuild archive` was not run — `docs/release-guide.md` records it as broken
on this Personal team.

## Constraints honoured

- `Skein/Assets.xcassets/ControlItemImages/` untouched.
- `AccentColor.colorset` untouched.
- No letter "S", no word "Skein" in either mark.
- All ten PNG filenames unchanged, so `README.md:2` still resolves.
- `Contents.json` unchanged in both asset sets — `git diff` shows pixels only.
- No commit to `main`.

## Open questions

1. Should Dark Mode keep a branded orange ground rather than the system neutral
   dark? Native default shipped; changing it needs the undocumented
   specialisation key. See finding 6.
2. `AccentColor.colorset` is still Ice's. The icon is now warm orange, so the
   pairing is worth a deliberate look in its own change.
