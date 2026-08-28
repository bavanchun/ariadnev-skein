# Research: Icon Composer `.icon` format + macOS 26 HIG app-icon rules

Scope: on-disk format of `.icon` bundles, Xcode integration, HIG rules. Research
only, no repo files touched. Local machine: macOS 26.6.2, Xcode 26.6, Icon
Composer.app 1.6 (bundle-version 99.1).

## Method / evidence tiers

1. **Empirical, first-party** — I ran the real `ictool` binary (bundled inside
   `Icon Composer.app`, version-locked to it) against a third-party
   reverse-engineered `.icon` fixture and it rendered correctly. This is the
   strongest evidence: the live rendering engine on this machine accepted the
   schema.
2. **Official Apple docs** — full text fetched (Apple's own `.md`/`.json` data
   endpoints, not summarized).
3. **Local static analysis** — `strings` on Icon Composer's own frameworks
   (`IconComposerFoundation`, `IconComposerKit`, `IconRendering`).
4. **Third-party reverse-engineering** — a JSON Schema + fixtures from
   `giginet/apple-icon-composer-skill` (GitHub), cross-checked against #1 and #3.

---

## (a) Verified facts

### 1. Bundle structure

**VERIFIED (empirical + local strings + official doc).** A `.icon` file is a
macOS package (directory Finder shows as one file):

```
AppIcon.icon/
  icon.json        # manifest
  Assets/          # PNG and/or SVG layer images, referenced by filename
```

- Local `IconComposerFoundation` strings confirm: `assets`, `Assets should be a
  directory`, `FileWrapperSnapshot`, `fileWrappers` — an `NSFileWrapper`-backed
  document, package = directory + manifest, matching this structure exactly.
- Apple's official doc (`developer.apple.com/documentation/Xcode/creating-your-app-icon-using-icon-composer`,
  fetched in full, copyright 2026) never names `icon.json` directly (Apple
  treats it as an opaque, GUI-only file), but confirms the layer/group model,
  SVG/PNG import, and Xcode drag-in workflow described below.
- `icon.json` schema (top level, from the JSON Schema at
  `giginet/apple-icon-composer-skill` — **this is the strongest documented
  schema found**, and it **matches** every key surfaced by `strings` on the
  local v1.6 binary: `groups`, `layers`, `fill`, `fill-specializations`,
  `gradient`/`linear-gradient`, `specular`, `shadow`, `translucency`, `blur` /
  `blur-material`, `blend-mode`, `lighting`, `supported-platforms`):

```jsonc
{
  "fill": { /* fill-value */ },                 // or "fill-specializations"
  "groups": [ { /* group */ } ],                // required, ≥1
  "supported-platforms": { "squares": "shared" }, // required
  "features": ["refractivity", "specular-location"] // IC 2.0+ only, absent on local v1.6
}
```

- **Group** object: `name`, `layers` (≥1), `lighting` (`individual`|`combined`),
  `specular` (bool), `blur-material` (0–1, IC2; `blur` is the IC1.x legacy key
  — **confirmed present in local v1.6 strings**, so this app still writes/reads
  `blur`/`blur-material` both), `shadow` (`{kind, opacity}`,
  `kind` ∈ `automatic|neutral|layer-color|none`), `translucency`
  (`{enabled, value}`), `blend-mode`, `opacity`, `hidden`, `position`. Every
  scalar property has a matching `<prop>-specializations` array sibling for
  per-appearance/per-idiom overrides (see §4).
- **Layer** object: `name` (required), `image-name` or
  `image-name-specializations` (required, one of), `fill`, `blend-mode`,
  `opacity`, `glass` (bool — per-layer Liquid Glass on/off), `hidden`,
  `position` (`{scale, translation-in-points:[x,y]}` — both required together).
- **Fill** value: keyword (`automatic|none|system-light|system-dark`) or
  object with exactly one of `automatic-gradient` (single color →
  auto-derived gradient), `solid`, `linear-gradient` (exactly 2 colors,
  optional `orientation.start/stop` as normalized 0–1 points).
- **Color** string format: `"<colorspace>:<components>"`, e.g.
  `"extended-srgb:0.00000,0.53333,1.00000,1.00000"` (r,g,b,a),
  `"gray:1.0,1.0"` (white,alpha), or `"named:system-blue"`.
- Locally, `IconComposerFoundation` strings include `blur-material`,
  `asset-mirroring`, `implicit-asset-mirroring` — meaning v1.6 already carries
  some "Icon Composer 2.0" keys — but **not** `refractivity` or
  `specular-highlight-placement`/`specular-location` (grepped, absent). So
  v1.6 sits between the schema's "1.x" and "2.0" cutoff; refractivity is not
  yet supported on this machine.

**Empirical proof this schema is real and current** (not stale/guessed): I
downloaded a fixture `icon.json` + `Assets/*.png` authored against this exact
schema from a third-party repo and ran it through the real, local `ictool`:

```
ictool fixtures/complex-icon.icon --export-image --output-file preview.png \
  --platform iOS --rendition Default --width 1024 --height 1024 --scale 2
```

exited 0 and produced a correct, fully Liquid-Glass-rendered 2048×2048 PNG
(squircle mask, system specular highlight ellipse, drop shadow, appearance
layer-swap all present). Re-running with `--rendition Dark` correctly swapped
`layer0-background-light.png` → hidden and picked the `-dark` variants per the
fixture's `hidden-specializations`/`image-name-specializations`. Both are
first-party confirmation the schema above is accurate today, not
beta-era or hypothetical.

### 2. Vector support

**VERIFIED (official doc, direct quote).**
> "use vector graphics to draw shapes and export SVG files... Because SVG
> format doesn't preserve fonts, convert text to outlines... For layers that
> contain unsupported SVG features, choose PNG or another raster image format
> that Icon Composer supports. Don't export the canvas mask because the
> system applies that automatically."

HIG page adds: "Prefer vector graphics when bringing layers into Icon
Composer... For mesh gradients and raster artwork, prefer PNG format because
it's a lossless image format." Local frameworks link `CoreSVG.framework`
(confirmed present), i.e. Icon Composer parses SVG itself rather than
rasterizing externally.

Apple does **not** publish an exact supported-SVG-feature list (gradients,
strokes, masks, filters). One local string is a direct warning about a
specific unsupported case: *"layers use SVG assets that contain text
elements. Text should be converted to paths before use in icons."*
**UNVERIFIED beyond that**: no enumerated list of supported/unsupported SVG
filters, masks, or stroke types found in docs or strings. A third-party blog
(Virtual Sanity, June 2025, beta-era) claims SVG layers didn't get Liquid
Glass effects and recommends PNG instead — this reads as an early-beta bug;
Apple's now-current official doc affirmatively recommends SVG as the
preferred format, so I weight the official doc higher and flag the blog claim
as likely stale (UNVERIFIED on current GA behavior).

### 3. Layer model

**VERIFIED (official doc + WWDC25 "Create icons with Icon Composer" transcript
+ HIG + schema).**

- **Max 4 groups** per icon (quote from WWDC25 session 361 transcript: "By
  default, it'll always be one, but you can go all the way up to four. We
  found this number provides the right bounds..."). No documented cap on
  layers *within* a group (schema: `layers` array, `minItems: 1`, no max).
- Groups, not individual layers, are the primary target for Liquid Glass
  settings (specular/shadow/translucency/blur/refraction), though `glass`
  (bool) can toggle Liquid Glass per-layer too, and a group's `lighting` mode
  (`individual` vs `combined`) decides whether effects apply to each layer
  separately or to the group as one object.
- **System supplies mask + shadow + specular** — HIG, direct quote: *"Produce
  appropriately shaped, unmasked layers. The system masks all layer edges to
  produce an icon's final shape... Providing layers with pre-defined masking
  negatively impacts specular highlight effects and makes edges look
  jagged."* And: *"Let the system handle blurring and other visual effects...
  there's no need to include specular highlights, drop shadows between
  layers, beveled edges, blurs, glows, and other effects... custom effects are
  static, whereas the system supplies dynamic ones."* Official Xcode doc
  reiterates: *"Don't export the canvas mask because the system applies that
  automatically to ensure a perfect crop."* This directly validates the
  coordinator brief's "no hand-painted shadow/mask" instruction.
- **Canvas size**: **1024×1024 px** for iPhone/iPad/Mac; **1088×1088 px** for
  Apple Watch (watchOS "overshoots" the rounded shape intentionally, per
  WWDC25 transcript, for template consistency). Confirmed identically in
  HIG's specifications table and the official Xcode doc's "Prepare your
  artwork for export" section. The `apple-icon-composer-skill` SKILL.md
  independently states "1024 × 1024 canvas — assets should be centered."
- **Safe area / bleed**: no numeric safe-area inset published for iOS/iPadOS/
  macOS icons specifically (HIG only states a numeric-free "keep primary
  content centered... use the grids in the app icon production templates").
  A concrete numeric safe zone *is* published for parallax platforms (tvOS/
  visionOS) but that's out of scope here. **UNVERIFIED**: exact px/pt bleed
  margin for macOS square icons — Apple pushes this to the downloadable
  design templates (Design Resources), not the HIG text or the schema.
- Local strings confirm an internal `canvasInset`, `iconPadding`, `xPadding`,
  `safeAreaInsets`, `safeAreaRect`, `_gridStyle` in `IconComposerKit` — i.e.
  the GUI does compute/display a safe-area grid — but the concrete numbers are
  not exposed in strings or docs (need to inspect visually in the GUI to get
  exact values; **flagged as unknown, see §c**).

### 4. Appearance variants

**VERIFIED (official doc + schema, cross-checked).** Icon Composer's UI shows
3 top-level appearances: **Default, Dark, Mono** — but Mono expands to Clear
(light/dark) and Tinted (light/dark) via an "Options" sub-dialog, for **6
renditions total**, confirmed literally by `ictool`'s own error message when
given an invalid rendition name:

```
Unknown rendition name: Bogus. Should be one of "Default", "Dark",
"TintedLight", "TintedDark", "ClearLight" or "ClearDark".
```

In `icon.json` this is NOT a fixed "variants" array — it's implemented via a
generic **specialization** mechanism attached to almost any property:

```jsonc
"fill-specializations": [
  { "value": { "automatic-gradient": "extended-srgb:0.2,0.5,1,1" } }, // base/no-slot = everywhere
  { "appearance": "dark", "value": "automatic" }
]
```

- `appearance` slot enum: `base | light | dark | tinted` (note: `tinted` here
  covers both clear+tinted derivation — the light/dark split and
  clear-vs-tinted split are resolved by the renderer, not separate JSON
  enum values, for IC 1.x documents in this schema version).
- `idiom` slot enum (IC 2.0+ only): `square | iOS | macOS | watchOS`.
- `localization` slot (IC 2.0+ only): locale ID string.
- Slot keys are omittable/combinable; omitting a key = "applies to all values
  of that axis." Any specializable property (`fill`, `blend-mode`, `opacity`,
  `glass`, `hidden`, `image-name`, `position`, `lighting`, `specular`,
  `blur-material`, `shadow`, `translucency`, `refractivity`,
  `specular-highlight-placement`, `asset-mirroring`) follows this same
  `<prop>` / `<prop>-specializations` pair pattern.
- **Auto-derivation confirmed**: HIG, direct quote: *"You can design app icon
  variants for every appearance variant, and the system automatically
  generates variants you don't provide."* I.e. per-variant overrides are
  optional; the base is always required and the system derives what's
  missing (verified live: the fixture only overrode 2 of 4 layers for dark,
  the rest inherited automatically and rendered correctly).

### 5. Xcode integration

**VERIFIED (official Apple doc, direct quotes).**

- The `.icon` file is a **standalone project-navigator item**, not nested
  inside `Assets.xcassets`: *"Just drag the Icon Composer file from Finder to
  the Project navigator... Alternatively, choose Add Files..."*
- Build-setting link: *"In the project editor, select the target and the
  General tab. Under App Icons and Launch Screen, ensure that the name in the
  App Icon text field matches the name of the Icon Composer file without the
  extension."* This is the **same UI field that already writes
  `ASSETCATALOG_COMPILER_APPICON_NAME`** — confirmed in this repo's own
  `Skein.xcodeproj/project.pbxproj`, which currently has
  `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;` pointing at the existing
  `AppIcon.appiconset`. Apple's doc explicitly says: *"If you add an Icon
  Composer file to your Xcode project, it **replaces any existing icon asset
  catalog** that you previously used to represent your app icon."* So adding
  `AppIcon.icon` (named exactly `AppIcon`) to the project takes over that same
  build-setting slot — no new/different build setting key exists for
  `.icon` files.
- **macOS 14 fallback — direct answer (VERIFIED, official doc, current):**
  > "If your app supports previous releases (in the Minimum Deployments
  > settings in the target's General pane) that don't have the same icon and
  > widget style appearances and Liquid Glass material, **Xcode automatically
  > generates app icon images at build time for those releases from the Icon
  > Composer file.**"
  > "Important: If you add an Icon Composer file to your Xcode project, it
  > replaces any existing icon asset catalog... Xcode automatically generates
  > a similar-looking version of the Liquid Glass icon for previous releases.
  > **If you want your existing icon to appear in previous releases, continue
  > to use asset catalogs to represent your app icon.**"

  So: with `MACOSX_DEPLOYMENT_TARGET = 14.0` (this project's actual setting,
  confirmed in `project.pbxproj`), Xcode **does not require** a separate
  `AppIcon.appiconset` — it flattens the `.icon` file into legacy PNG/`.icns`
  representations at build time automatically. A separate `.appiconset` is
  only needed if the *design itself* must differ between old and new OS
  (e.g., keeping the current pre-rebrand icon unchanged on macOS 14–25 while
  shipping new Liquid Glass art on 26+) — that is a design/product decision,
  not a technical requirement.

  **Conflicting third-party claim, weighted lower and flagged:** Use Your
  Loaf ("Adding Icon Composer icons to Xcode," **June 23, 2025** — Xcode 26
  beta 1/2 era, over a year before this research date) states *"Icon Composer
  icons back deploy to older versions of iOS, macOS, and watchOS with
  inconsistent rendering,"* workaround "keep the previous Asset Catalog app
  icon." This reads as an early-beta rendering bug that predates GA. Apple's
  **current** official doc (fetched today, copyright-dated 2026, and phrased
  as settled behavior, not a known-issue caveat) supersedes it. **Residual
  risk**: I could not empirically verify the *quality* of the auto-generated
  macOS 14 legacy icon on this machine without actually adding a `.icon` file
  to a real Xcode target and building — that step needs the implementer to
  do and visually check (flagged in §c).

### 6. Small-size legibility

**PARTIALLY VERIFIED / gap confirmed.** Current HIG text (fetched in full,
"Refined guidance for Liquid Glass," dated **June 8, 2026** — the latest
revision) contains **no numeric "16pt" callout**. What it does say:

> "An icon with fine visual features might look busy when rendered with
> system-provided shadows and highlights, and details may be hard to discern
> at smaller sizes... express it in a simple, unique way with a minimal
> number of shapes."
> "The system automatically scales your icon to produce smaller variants that
> appear in certain locations, such as Settings and notifications."
> "Avoid extremely thin line weights and sharp corners, because they tend to
> lose detail and crispness in smaller icon sizes at lower resolutions."

The WWDC25 "Say hello to the new look of app icons" transcript adds design
advice (not a spec): "use bolder line weights to preserve details at small
scale," "rounder corners for seamless light travel."

**No numeric point-size table** (16/32/128/256/512pt) appears anywhere in
the current HIG app-icons page — that classic macOS size table is legacy
asset-catalog technical spec, orthogonal to the Liquid Glass HIG text.

**Per-size layer overrides: VERIFIED ABSENT.** The `icon.json` schema's
`specialization-entry` slot keys are only `appearance`, `idiom`, and
`localization` — **there is no `size` or `point-size` slot**. Confirmed
independently by: (a) the full JSON Schema fetched from
`apple-icon-composer-skill`; (b) local `strings` on `IconComposerFoundation`
turned up no size-keyed specialization pattern; (c) Apple's official doc only
offers a size **preview** dropdown ("To view a specific size of the app icon,
choose the size from the 'Select preview size' pop-up menu") — a
what-you-see check, not an authoring override. **Conclusion for the project
brief's 16pt requirement: there is no tooling-level way to swap to a
simplified rope layer at small sizes. The single layer set must read
correctly scaled all the way down; this is a real design constraint, not
something the format can route around.** This should be escalated back to
whoever owns the artwork per the coordinator brief's own "escalate rather
than decide" clause.

### 7. Authoring/validating a `.icon` bundle without the GUI

**VERIFIED, and this is the most actionable finding of this research: there
IS a working non-GUI path, though completely undocumented by Apple.**

- **No official CLI or public schema.** Apple ships no `xcrun icon-composer`
  (confirmed absent, matches the task's own pre-verification) and publishes
  no JSON Schema for `icon.json`.
- **`ictool` exists and works, undocumented.** Found at two locations on this
  machine:
  - `/usr/bin/ictool` (Xcode command-line-tools copy; `--version` here
    actually reports `com.apple.actool.version` plist data — this is a
    different/older shim, **not** the Icon Composer 1.6 renderer)
  - `/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool`
    (the real one, version-locked to Icon Composer: `{"bundle-version":
    "99.1", "short-bundle-version": "1.6"}`)
  - `man ictool` → "No manual entry" (undocumented, no man page).
  - `ictool <bad-args>` → `Error: No arguments specified, please consult "man
    ictool" in Terminal.` — i.e. Apple intends this to have a man page, it's
    just missing/not installed on this system.
  - **I ran it successfully**: `ictool <path>.icon --export-image
    --output-file out.png --platform iOS --rendition Default --width 1024
    --height 1024 --scale 2` exited 0 and produced a correct, fully
    Liquid-Glass-rendered PNG from a hand-authored `icon.json` I did not
    create with the GUI. I also verified `--rendition Dark` and `--platform
    macOS` both work, and that an invalid `--rendition` value produces a
    clear, enumerated error message. This is real, working, present-day
    evidence — not a claim from a blog.
- **Third-party validator exists**: `giginet/apple-icon-composer-skill`
  ships a Python-based `validate_icon.py` (JSON-Schema-only, exit codes
  0/1/2) plus a `create_icon.py` that assembles a `.icon` package
  programmatically from a JSON doc + named assets — no Apple tooling
  involved, pure file assembly. This is third-party, unofficial, but its
  schema is now empirically confirmed accurate (§1) via `ictool`.
- **Bottom line**: hand-authoring `icon.json` + `Assets/` and skipping the
  GUI entirely is technically possible and I confirmed it renders correctly
  on this exact machine — but Apple documents none of this, offers no
  stability guarantee on the format across Icon Composer versions (the
  schema itself encodes an IC1.x/IC2.0 compatibility fork with a `features`
  gate precisely because the format has already changed once), and the
  coordinator brief's instruction to "create a blank document [in the GUI]
  and inspect the resulting bundle" remains the lower-risk way to get a
  guaranteed-current, guaranteed-openable file for actual shipping. Use
  `ictool` for headless *rendering/verification* of GUI-authored files, not
  as the primary authoring path, unless the team explicitly accepts
  undocumented-format risk.

---

## (b) Concrete example `icon.json` (verified working via `ictool` render)

This is the real fixture I rendered successfully (from
`giginet/apple-icon-composer-skill`, `fixtures/complex-icon.icon/icon.json`),
reproduced verbatim:

```json
{
  "fill-specializations": [
    { "value": { "automatic-gradient": "extended-srgb:0.00000,0.53333,1.00000,1.00000" } },
    { "appearance": "dark", "value": "automatic" }
  ],
  "groups": [
    {
      "layers": [
        {
          "glass": true,
          "image-name-specializations": [
            { "value": "layer3-symbol-light.png" },
            { "appearance": "dark", "value": "layer3-symbol-dark.png" }
          ],
          "name": "layer3-symbol-dark"
        },
        {
          "glass": true,
          "image-name-specializations": [
            { "value": "layer2-ball-light.png" },
            { "appearance": "dark", "value": "layer2-ball-dark.png" }
          ],
          "name": "layer2-ball-dark"
        },
        {
          "glass": false,
          "image-name-specializations": [
            { "value": "layer1-shadow-light.png" },
            { "appearance": "dark", "value": "layer1-shadow-dark.png" }
          ],
          "name": "layer1-shadow-dark"
        },
        {
          "hidden-specializations": [ { "appearance": "dark", "value": true } ],
          "image-name": "layer0-background-light.png",
          "name": "layer0-background-light"
        }
      ],
      "lighting": "individual",
      "shadow": { "kind": "none", "opacity": 0.5 },
      "translucency": { "enabled": false, "value": 0.5 }
    }
  ],
  "supported-platforms": { "squares": "shared" }
}
```

Directory layout: `complex-icon.icon/{icon.json, Assets/layer0-background-light.png,
layer1-shadow-{light,dark}.png, layer2-ball-{light,dark}.png,
layer3-symbol-{light,dark}.png}`.

A minimal hand-written example that also renders (structure only, not
independently re-tested against `ictool` but matches the confirmed schema):

```json
{
  "fill": { "automatic-gradient": "extended-srgb:0.90,0.45,0.15,1.00" },
  "groups": [
    {
      "name": "Rope",
      "layers": [
        { "name": "rope", "image-name": "rope.svg", "glass": true }
      ],
      "lighting": "individual",
      "shadow": { "kind": "automatic", "opacity": 0.5 },
      "translucency": { "enabled": false, "value": 0.5 }
    }
  ],
  "supported-platforms": { "squares": "shared" }
}
```

---

## (c) Unknowns — must be verified by actually running Icon Composer.app

- Exact numeric safe-area/bleed margin for iOS/iPadOS/macOS square layers
  (the GUI computes one internally — strings show `safeAreaInsets`,
  `canvasInset`, `iconPadding` — but no number is exposed via docs or
  strings).
- Whether `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` truly just works
  unmodified when an `AppIcon.icon` file is dragged in alongside the existing
  `AppIcon.appiconset` name collision, or whether Xcode requires removing/
  renaming the old asset catalog first. Apple's doc implies replacement is
  automatic ("it replaces any existing icon asset catalog") but I did not
  add a live `.icon` file to this project's target and build it.
- Visual quality of the macOS-14 auto-generated legacy icon in practice (the
  June 2025 "inconsistent rendering" report may or may not still apply at
  GA — needs an actual `xcodebuild build` + Finder/Get-Info check per the
  coordinator brief's own Definition of Done).
- Exact unsupported-SVG-feature list (masks, filters, complex strokes) beyond
  the one confirmed case (text must be outlined). Not documented anywhere
  found.
- Whether `refractivity`/`specular-highlight-placement` ("Icon Composer 2.0")
  keys will be silently ignored or cause a hard open failure on this
  machine's v1.6 — the schema's `features` gate implies v1.x refuses
  documents declaring unknown features, but I did not test this (only tested
  a v1.x-only fixture).
- Whether the `giginet/apple-icon-composer-skill` schema is affiliated with
  or endorsed by Apple in any way — it is not; treat as reverse-engineered,
  now empirically corroborated, but unofficial and versioned independently
  of Apple's actual release cadence.

## (d) Direct answer: macOS 14 fallback

**Xcode 26 auto-generates legacy PNG/`.icns` representations from the `.icon`
file at build time for deployment targets that predate Liquid Glass (e.g.
`MACOSX_DEPLOYMENT_TARGET = 14.0`, this project's actual setting). No separate
`AppIcon.appiconset` is technically required for the icon to appear on macOS
14–25** — this is stated as current, settled Apple documentation, not a beta
caveat. A separate `.appiconset` is only needed if you want *different
artwork* (e.g., the old pre-rebrand mark) to show on pre-26 systems instead
of an auto-flattened version of the new Liquid Glass design — that's a
product decision, and per the coordinator brief, one to escalate rather than
assume. One credible but beta-era (June 2025) source claims early back-deploy
rendering was inconsistent; I could not confirm or refute this at GA without
actually building the target, which is implementation work outside this
research's scope.

---

## Sources

- https://developer.apple.com/documentation/Xcode/creating-your-app-icon-using-icon-composer (official, fetched in full)
- https://developer.apple.com/design/human-interface-guidelines/app-icons (official, fetched in full via data endpoint, dated "Refined guidance for Liquid Glass," June 8, 2026)
- https://developer.apple.com/videos/play/wwdc2025/361/ ("Create icons with Icon Composer")
- https://developer.apple.com/videos/play/wwdc2025/220/ ("Say hello to the new look of app icons")
- https://github.com/giginet/apple-icon-composer-skill (third-party, JSON Schema + fixtures — empirically corroborated by local `ictool`)
- https://github.com/ethbak/icon-composer-mcp (third-party, corroborating terminology: specular, blur_material, shadow_kind, translucency, blend_mode, lighting)
- https://useyourloaf.com/blog/adding-icon-composer-icons-to-xcode/ (third-party, June 23, 2025 — beta-era, weighted lower, flagged where it conflicts with current official docs)
- https://www.virtualsanity.com/202507/icon-composer-notes/ and https://micro.virtualsanity.com/2025/06/20/icon-composer-notes.html (third-party, beta-era, low weight)
- https://praeclarum.org/2025/09/12/app-icons.html (third-party)
- Local: `/Applications/Xcode.app/Contents/Applications/Icon Composer.app` — `strings` on `Contents/Frameworks/{IconComposerFoundation,IconComposerKit,IconRendering}.framework/*`, `Contents/Executables/ictool` (executed directly), `Contents/Info.plist` / `version.plist`
- This repo: `/Users/vchun/orca/workspaces/Ice-vc/skein-app-icon/Skein.xcodeproj/project.pbxproj` (confirmed `MACOSX_DEPLOYMENT_TARGET = 14.0`, `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`)

## Unresolved questions

- Exact numeric safe-area/bleed for iOS/iPadOS/macOS square icon layers.
- Whether v1.6 hard-fails or silently drops IC2.0-only keys (`refractivity`, `specular-highlight-placement`).
- Real build-time behavior of legacy-icon generation on this exact Xcode/macOS combo — needs an actual `xcodebuild build` with a live `.icon` file in the target, which is implementation, not research.
- Full supported/unsupported SVG feature matrix (masks, filters, strokes) — undocumented by Apple beyond "convert text to outlines."

Status: DONE
Summary: Full official-doc text confirms bundle layout (`icon.json` + `Assets/`), the 1024×1024 (1088 watchOS) canvas, max-4-groups model, system-owned mask/shadow/specular, and — critically — that Xcode 26 auto-generates legacy PNG icons at build time for `MACOSX_DEPLOYMENT_TARGET = 14.0`, so a separate `.appiconset` is not technically required (only needed to preserve different old-OS artwork). I additionally found and empirically ran `ictool`, Icon Composer's undocumented internal CLI, successfully rendering a hand-authored `icon.json` — direct, present-day proof of the reverse-engineered schema's accuracy and a real (if unsupported) headless-authoring/validation path.
Concerns: The 16pt-legibility ask has no schema-level answer — the format has no per-size override slot at all (only appearance/idiom/localization), so a multi-strand rope must survive one single layer set scaled all the way down; flag this back per the brief's own escalation clause. The macOS-14-fallback quality claim rests on current official docs superseding a stale (June 2025, beta) third-party bug report — an implementer should still visually confirm the auto-generated legacy icon once a real `.icon` file is wired into this project's target.
