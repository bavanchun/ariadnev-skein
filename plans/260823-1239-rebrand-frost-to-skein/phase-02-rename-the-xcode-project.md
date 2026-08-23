---
phase: 2
title: "Rename the Xcode project, target, scheme, and source folder"
status: pending
priority: P1
effort: "1h"
dependencies: [1]
---

# Phase 2: Rename the Xcode project, target, scheme, and source folder

## Overview

The structural rename. After this phase the project builds as Skein while its
Swift symbols still read `Frost` — coherent but half-done, which is why phase 3
follows immediately.

## Context

Mirrors `plans/260727-2348-rebrand-ice-vc-to-frost/phase-02-swift-symbol-and-file-rename.md`,
which ran this successfully for Ice → Frost.

## Files

| From | To |
|---|---|
| `Frost.xcodeproj` | `Skein.xcodeproj` |
| `Frost.xcodeproj/xcshareddata/xcschemes/Frost.xcscheme` | `Skein.xcscheme` |
| `Frost/` | `Skein/` |
| `Frost/Frost.entitlements` | `Skein/Skein.entitlements` |

`.github/workflows/build.yml:29,37,38` hardcode `-scheme Frost -project
Frost.xcodeproj` and must move in the same commit or CI breaks.

## Implementation Steps

1. `git mv` each path above so Git records the renames.
2. Rewrite `Skein.xcodeproj/project.pbxproj`: target name, product name, scheme
   references, `INFOPLIST_FILE`, `CODE_SIGN_ENTITLEMENTS`, and the source folder
   path. Leave `PRODUCT_BUNDLE_IDENTIFIER` alone — phase 4 owns identity.
3. Update `.github/workflows/build.yml` scheme and project arguments.
4. Confirm the asset catalog still resolves: `ASSETCATALOG_COMPILER_APPICON_NAME`
   stays `AppIcon`, which is name-stable and needs no change.
5. Build clean:
   ```bash
   xcodebuild build -scheme Skein -project Skein.xcodeproj \
     -configuration Release -derivedDataPath .ci-output \
     CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
   ```

## Success Criteria

- [ ] `grep -rn "Frost" Skein.xcodeproj/project.pbxproj` returns nothing
- [ ] No path named `*Frost*` remains outside `.ci-output` and `plans/`
- [ ] Clean Release build succeeds
- [ ] `git status` shows renames, not delete-plus-add
- [ ] CI green on the pull request

## Risk Assessment

**`project.pbxproj` has no shared ancestor once renamed.** Hand-editing it is
error-prone and a mistake surfaces as an opaque build failure. Change one
category of key at a time and rebuild between categories.

**Renaming the folder without updating `INFOPLIST_FILE` or
`CODE_SIGN_ENTITLEMENTS`** yields a build that fails late, at packaging rather
than compilation.
