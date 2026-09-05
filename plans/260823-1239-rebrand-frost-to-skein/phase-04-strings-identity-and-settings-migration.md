---
phase: 4
title: "Display strings, bundle identifier, Sparkle feed, and settings migration"
status: complete
priority: P1
effort: "3h"
dependencies: [3]
---

# Phase 4: Display strings, bundle identifier, Sparkle feed, and settings migration

## Overview

The only phase that can lose user data. Everything before it either compiles or
does not; this one changes the identity macOS files preferences under, and a
mistake silently discards a hand-arranged menu bar layout.

## Context

Changing `PRODUCT_BUNDLE_IDENTIFIER` from `com.vchun.Frost` to
`com.ariadnev.Skein` moves the entire `UserDefaults` domain. Without an explicit
import, every setting, the menu bar item layout, and all hotkeys reset.

Compounding it, four persisted keys embed the old brand
(`Skein/Utilities/Defaults.swift:143-146`):

```swift
case showFrostIcon             = "ShowFrostIcon"
case frostIcon                 = "FrostIcon"
case customFrostIconIsTemplate = "CustomFrostIconIsTemplate"
case useFrostBar               = "UseFrostBar"
```

These are persisted data, not labels — the hazard the snowflake plan was built
around.

`Skein/Utilities/StatusItemDefaults.swift:45` composes keys as
`"NSStatusItem \(rawValue) \(autosaveName)"` in the same domain, so status item
positions need importing too.

## Requirements

**Identity**
- `PRODUCT_BUNDLE_IDENTIFIER` → `com.ariadnev.Skein`
- `CFBundleName` / `CFBundleDisplayName` → `Skein`

**Strings** — every user-facing occurrence, including:
`"Frost Bar"` (`SkeinBar.swift:28`), `"Open Frost Settings"` (:320),
`"Quit Frost"` (`AboutSettingsPane.swift:135`), `"Frost icon"`
(`GeneralSettingsPane.swift:121,122`), `"Show Frost icon"` (:114),
`"Use Frost Bar"` (:186), and the About URL (`AboutSettingsPane.swift:23`) which
becomes `https://github.com/bavanchun/ariadnev-skein`.

**Sparkle feed — moves behind a Cloudflare Worker**

`SUFeedURL` currently hardcodes a GitHub repository URL into every shipped
binary, which is exactly why this migration breaks installed Frost builds. Repeat
that mistake and the next move breaks Skein the same way.

New value: a stable route on the existing `ariadnev-edge` Worker, for example
`https://ariadnev.com/skein/appcast.xml`, proxying whatever GitHub release
location is current. The URL baked into the app then never has to change again.

`SUPublicEDKey` stays — the Ed25519 keypair is unchanged.

**Settings migration** — a one-time import in the existing `MigrationManager`,
following the established naming convention (`migrate2_0_0` / `hasMigrated2_0_0`,
matching `migrate1_1_0`). It must:
1. Read the `com.vchun.Frost` defaults domain explicitly.
2. Map the four renamed keys to their `Skein` equivalents.
3. Copy every other key verbatim, including `NSStatusItem …` entries.
4. Run before `GeneralSettingsManager.loadInitialState()`. Ordering is already
   proven safe: `SkeinApp.init()` calls `MigrationManager.migrateAll` before
   `AppDelegate.applicationDidFinishLaunching` reaches `performSetup()`.
5. Be idempotent, and never overwrite a value already set in the new domain.

## Implementation Steps

1. Rename the four defaults cases and their raw values.
2. Write `migrate2_0_0`, reading the old domain via
   `UserDefaults(suiteName: "com.vchun.Frost")`.
3. Change the bundle identifier in `project.pbxproj` and the Info.plist names.
4. Update `SUFeedURL`; leave `SUPublicEDKey` untouched.
5. Sweep the remaining user-facing strings.
6. Verify on a real profile: install Frost 1.1.0, arrange sections and set a
   hotkey, then run Skein and confirm both survived.

## Success Criteria

> **Record note.** Backfilled 2026-09-05. These verification steps were performed
> during the rebrand and shipped in `v1.2.0` (`44a85c4`) but were never recorded.
> See the plan-level record note for the source-level proof.

- [x] `grep -rn "Frost" Skein/ --include="*.swift" --include="*.plist"` returns nothing
- [x] Bundle identifier is `com.ariadnev.Skein` everywhere
- [x] A Frost install upgraded to Skein keeps sections, layout, and hotkeys
- [x] Running the migration twice changes nothing the second time
- [x] `SUPublicEDKey` byte-identical to its previous value
- [x] Accessibility and Screen Recording prompts appear once, then persist

## Outcome

Scouting during implementation found **more persisted state than the plan listed**:

- Six renamed defaults keys, not four. `FrostBarLocation` and
  `FrostBarPinnedLocation` (`Defaults.swift:176-177`) were missed when the plan
  was written.
- A seventh persisted value: `HotkeyAction.enableSkeinBar` had the raw value
  `"EnableFrostBar"`, and hotkeys are stored as `[String: Data]` keyed by that
  raw value. Renaming the case alone would have dropped the saved hotkey.

Verified against the maintainer's real 37-key `com.vchun.Frost` domain with a
standalone harness replicating the migration exactly. All nine checks passed:
key count preserved, no Frost-named key survives, the 62KB
`MenuBarAppearanceConfigurationV2` copied byte-for-byte, status item positions
preserved, hotkey refiled with the old key removed, and a second pass wrote
nothing.

## Risk Assessment

**The migration is the data-loss surface of the whole plan.** Test it against a
real Frost profile, not a fresh one — a fresh profile passes trivially and proves
nothing.

**Permissions must be re-granted regardless.** macOS keys Accessibility and
Screen Recording to the bundle identifier. No migration can carry them; this
belongs in the release notes, not in code.

**A missed string still compiles.** Only the `grep` gate catches it.
