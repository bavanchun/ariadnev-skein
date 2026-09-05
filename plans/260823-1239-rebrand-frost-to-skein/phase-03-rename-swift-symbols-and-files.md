---
phase: 3
title: "Rename Swift symbols and filenames"
status: complete
priority: P1
effort: "1h"
dependencies: [2]
---

# Phase 3: Rename Swift symbols and filenames

## Overview

Mechanical, large, and low-risk: the compiler catches every miss. Must land
immediately after phase 2.

## Context

Measured on `main` at 2026-08-23: **383 `Frost` occurrences across the Swift
sources**, 134 in file-header comments and 249 in code. Twenty-two distinct
`Frost*` symbols.

## Files to rename

```text
Skein/Main/FrostApp.swift
Skein/UI/FrostBar/            -> SkeinBar/
Skein/UI/FrostBar/FrostBar.swift
Skein/UI/FrostBar/FrostBarColorManager.swift
Skein/UI/FrostBar/FrostBarLocation.swift
Skein/UI/FrostUI/             -> SkeinUI/
Skein/UI/FrostUI/FrostForm.swift
Skein/UI/FrostUI/FrostGroupBox.swift
Skein/UI/FrostUI/FrostLabeledContent.swift
Skein/UI/FrostUI/FrostMenu.swift
Skein/UI/FrostUI/FrostPicker.swift
Skein/UI/FrostUI/FrostSection.swift
Skein/UI/FrostUI/FrostSlider.swift
Skein/Assets.xcassets/FrostMarkStroke.imageset/  (+ its PNG)
```

## Symbols

`FrostApp`, `FrostBar`, `FrostBarPanel`, `FrostBarLocation`,
`FrostBarPinnedLocation`, `FrostBarColorManager`, `FrostBarItemView`,
`FrostBarItemClickView`, `FrostBarHostingView`, `FrostBarContentView`,
`FrostForm`, `FrostFormToggleStyle`, `FrostGroupBox`, `FrostLabeledContent`,
`FrostMenu`, `FrostPicker`, `FrostSection`, `FrostSectionOptions`,
`FrostSectionLayout`, `FrostSlider`, `FrostIcon` — each `Frost` prefix becomes
`Skein`.

## Implementation Steps

1. `git mv` the files and directories above.
2. Rename symbols. Prefer Xcode's rename refactor over `sed` so references in the
   project file and asset catalog move too.
3. Update file-header comments (`//  SkeinApp.swift` / `//  Skein`).
4. Rename the asset: `FrostMarkStroke.imageset` → `SkeinMarkStroke.imageset`,
   including the PNG inside it and its `Contents.json` filename entry.
5. Update `project.pbxproj` file references for every renamed path.
6. Leave user-facing strings and defaults keys alone — phase 4 owns both.
7. Build clean, then run SwiftLint: `swiftlint --strict`.

## Success Criteria

> **Record note.** Backfilled 2026-09-05. These verification steps were performed
> during the rebrand and shipped in `v1.2.0` (`44a85c4`) but were never recorded.
> See the plan-level record note for the source-level proof.

- [x] No `Frost` identifier, filename, or header comment remains; the 45 surviving hits are all string literals, which phase 4 owns
- [x] No file or directory named `*Frost*` under `Skein/`
- [x] Clean Release build succeeds, producing Skein.app
- [x] `swiftlint --strict` passes in CI; the `file_header` rule moved to `//  Skein` in the same commit
- [x] Settings → About and the search panel button still render their mark

## Risk Assessment

**Renaming the imageset without updating `Contents.json` or the call site yields a
blank image and no build error.** Established hazard — see the snowflake plan.
Verify visually, not just by building.

**A `sed`-driven rename can corrupt `project.pbxproj`.** Use the refactor tool, or
edit the project file deliberately and separately.
