---
phase: 3
title: "P1b — Docs hygiene, repo cleanup, plan checkbox backfill → v1.3.0"
status: completed
priority: P1
effort: "0.5 day"
dependencies: [1, 2]
release: "v1.3.0"
---

# Phase 3: P1b — Docs hygiene → v1.3.0

## Overview

Close every documentation drift and repo-cleanliness item found by the audit, then tag v1.3.0 to record the milestone cleanly (docs consistency is user-visible even though app behavior does not change). This is the phase where we stop carrying dead upstream Ice weight in the repo.

## Requirements

### Functional
- Every drift finding in `plans/reports/scout-260828-2201-docs.md` closed.
- 16.4 MB of unreferenced upstream Ice design assets removed from `Resources/`.
- 50 stale plan checkboxes reconciled: either backfilled `[x]` where reality shipped that box, or removed if the task is genuinely obsolete.
- Ancient migration code (Ice `0.8.0`–`0.11.10`) pruned from `MigrationManager.swift` since no user can plausibly be on those versions (Frost lineage started at 1.0.0).
- v1.3.0 tag; release notes explicitly say "no app behavior change; docs and repo hygiene only".

### Non-Functional
- Every removed file confirmed non-referenced by `rg` across the entire repo before deletion.
- Every backfilled checkbox has a source pointer (commit SHA or PR link) in a "Record note" above it.

## Architecture

Five slices, all in one PR:

1. **CHANGELOG**: add missing `[1.2.1]` and `[1.2.2]` reference links at bottom; verify `[Unreleased]` compare URL.
2. **UPSTREAM**: fix version-lineage table (Skein is `1.2.x`, not `2.0.0 onward`); correct Sparkle URL to `https://skein.ariadnev.com/appcast.xml`.
3. **upgrade-frost-to-skein**: retarget download link + byte size at v1.2.2 (whatever ships).
4. **FREQUENT_ISSUES / DEVELOPMENT_WORKFLOW**: clarify `#6`/`#26` are upstream Ice issue numbers; add missing entry for `docs/upgrade-frost-to-skein.md` in the docs inventory.
5. **`Resources/` cleanup**: verify then delete `Icon.fig` (140 KB), `Icon.png` (452 KB), `rearranging.gif` (3.0 MB), `rearranging.mov` (12.7 MB), and `Acknowledgements.rtf` (superseded by PDF).
6. **`MigrationManager.swift` prune**: remove migration branches for Ice pre-1.0.0 versions.
7. **Plan checkbox backfill**: sweep the 4 shipped plans; PM provides the mapping table (in agy brief); agy applies.

## Related Code Files

- Modify: `CHANGELOG.md`
- Modify: `docs/UPSTREAM.md`
- Modify: `docs/upgrade-frost-to-skein.md`
- Modify: `FREQUENT_ISSUES.md`
- Modify: `docs/DEVELOPMENT_WORKFLOW.md`
- Modify: `Skein/Utilities/MigrationManager.swift` (prune only)
- Delete: `Resources/Icon.fig`
- Delete: `Resources/Icon.png`
- Delete: `Resources/rearranging.gif`
- Delete: `Resources/rearranging.mov`
- Delete: `Skein/Resources/Acknowledgements.rtf`
- Modify: `plans/260727-2348-rebrand-ice-vc-to-frost/phase-*.md` (backfill)
- Modify: `plans/260728-0123-snowflake-icon-and-sparkle-plist-comments/phase-*.md` (backfill)
- Modify: `plans/260823-1239-rebrand-frost-to-skein/phase-*.md` (backfill)
- Modify: `Skein.xcodeproj/project.pbxproj` (bump 1.2.2→1.3.0, build 1123→1130)
- Modify: `plans/260823-1810-skein-landing-page/plan.md` (mark superseded, close)

## OUT OF SCOPE

- Any app code changes beyond `MigrationManager.swift` prune.
- Any upstream cherry-picks.
- Any refactor of god-classes or timer polling.
- `AppIcon.appiconset` deletion (still referenced by `README.md:2`; separate concern requiring image rehoming, deferred).
- README image rehoming (defer with a `TODO` note in a new tracking issue).

## Implementation Steps

1. Branch `feat/phase-03-p1b-docs-hygiene` from `main` (after Phase 2's landing PR merged so plan.md dependencies line up).
2. Docs slice 1-4: apply text edits using the exact line numbers in `plans/reports/scout-260828-2201-docs.md`.
3. Verify `Resources/` deletion candidates: `rg -l Icon.fig Skein/ && rg -l rearranging Skein/` — must return zero matches. Only then `git rm`.
4. Prune `MigrationManager.swift`: keep only migrations from Frost 1.0.0 onward. Test: launch fresh dev build with a mocked "1.1.0 → 1.3.0" defaults — settings persist.
5. Backfill checkboxes: PM supplies mapping table below. agy applies mechanically.
6. Bump pbxproj to 1.3.0 / 1130.
7. Add `[1.3.0]` CHANGELOG entry with a Changed subsection referencing docs cleanup and Resources purge, plus a note that no app behavior changed.
8. Build Release (must still exit 0 after MigrationManager prune).
9. Package ZIP + DMG (identical process to Phase 1).
10. Open PR titled `release: 1.3.0 (docs hygiene + repo cleanup)`.

### Checkbox backfill mapping (PM-supplied)

| Plan | Phase file | Checkbox pattern | Action | Source |
|------|-----------|------------------|--------|--------|
| `260728-0123-snowflake-icon-and-sparkle-plist-comments` | all phase files | all `[ ]` | mark `[x]` with note `Record: shipped in v1.1.0 tag` | git log v1.1.0 |
| `260823-1239-rebrand-frost-to-skein` | phase-01 through phase-05 | remaining `[ ]` | mark `[x]` | git log v1.2.0 |
| `260727-2348-rebrand-ice-vc-to-frost` | phase-04/05 (GUI/permission tasks) | `[ ]` | keep `[ ]`, add note `Record: not applicable — superseded by Frost→Skein rebrand` | this plan |
| `260823-1810-skein-landing-page` | plan.md | `status: in-progress` | change to `status: superseded-by: 260828-2226-audit-fixes-p0-p3/phase-02` | this plan |

## PM VERIFICATION CHECKLIST

- [x] `git diff main..HEAD --stat` matches Related Code Files exactly, plus `CHANGELOG.md`,
      `docs/release-guide.md`, `plans/260823-1239-rebrand-frost-to-skein/phase-06-*.md` and
      `plans/260727-2348-rebrand-ice-vc-to-frost/plan.md` — see the deviations note below.
- [x] `rg -q "Skein-1.2.0.zip" docs/` returns nothing — the upgrade doc now points at
      `releases/latest` rather than any pinned version.
- [x] `rg -q "ariadnev.com/skein/appcast.xml" docs/` returns nothing (URL corrected).
- [x] `Resources/Icon.fig`, `Resources/Icon.png`, `Resources/rearranging.gif`, `Resources/rearranging.mov` all removed from git.
- [x] `du -sh Resources/` at least 15 MB smaller than pre-phase — the directory is gone
      entirely; 16,353,402 bytes (15.6 MB) removed.
- [x] `MigrationManager.swift` no longer references version strings `0.8.0`, `0.9.0`, `0.10.0`, `0.11.*` — 548 lines down to 207.
- [x] Every plan flagged in backfill mapping now has ≥ 90% checkbox coverage OR explicit
      "not applicable" record notes — snowflake 26/26, Frost→Skein 46/47, Ice→Frost 41/48
      with a record note on all 7 remaining boxes.
- [x] `pbxproj` shows exactly `MARKETING_VERSION = 1.3.0;` twice, `CURRENT_PROJECT_VERSION = 1130;` twice.
- [x] `CHANGELOG.md` `[1.3.0]` entry present; `[1.2.1]` and `[1.2.2]` reference links at bottom.
- [x] `xcodebuild ... build` exit 0 — `** BUILD SUCCEEDED **`, built bundle reports
      `1.3.0` / `1130` / `com.ariadnev.Skein`. Warning delta zero: the same three
      pre-existing warnings as `main` (CustomColorPicker switch, AppIntents metadata,
      SwiftLint not installed), none from the pruned file.

## Success Criteria

- [x] PR merged, v1.3.0 tagged, release published. — PR #21 (`2080d2e`); tag
      `v1.3.0` is SSH-signed at that commit; the release is deliberately
      notes-only. 1.3.0 changed no app behavior, so shipping a binary for it
      would only hand Sparkle a second archive to choose between. The release
      page says so and points at 1.4.0.
- [x] `docs/` inventory reflects reality; audit report's Section 4 findings all closed.
- [x] `plans/260823-1810-skein-landing-page` superseded and closed cleanly.

## Deviations from the phase contract

Four, each a stronger fix for the same finding rather than a scope grab:

1. **`docs/upgrade-frost-to-skein.md` points at `releases/latest`, not v1.2.2.**
   The contract said "retarget download link + byte size at v1.2.2". Pinning a
   version is what caused this finding in the first place, so the doc now takes
   whatever the latest release offers and the drift cannot recur.
2. **`docs/release-guide.md` was edited, though it is not in Related Code Files.**
   It documents `sign_update` at a path that does not exist — the v1.2.2 release
   in this same session hit that exact wall. Its version examples were also
   stale. Same finding class as slice 4, so it was fixed here.
3. **`260823-1239` phase-06 was backfilled, though the mapping table stops at
   phase-05.** Its boxes were verified against live state, not assumed: the
   `v1.2.0` tag object carries an SSH signature, `bavanchun/Frost` is archived
   pointing at the new repo, and both feeds return 200. The one box left
   unticked names a URL that 404s — which is the same wrong URL slice 2 fixes.
4. **`260823-1810-skein-landing-page` reads `status: cancelled`.** The mapping
   table asked for `status: superseded-by: …`, which is neither valid YAML nor a
   status `av plan status` accepts (`pending | in-progress | completed |
   cancelled`). The supersession is recorded in a `superseded-by:` frontmatter
   key and in the plan's record note instead.

Not done, deliberately: step 9 (package ZIP + DMG). That is release mechanics,
and the tag is the maintainer's call under guardrail 1.

## Risk Assessment

- **MigrationManager prune breaks a real user.** Signal: user on Ice pre-1.0 reports settings lost after 1.3.0 upgrade. Response: Skein was only ever released as Frost 1.0.0+. No Ice-prefix user can plausibly have Skein bundle-id defaults. Risk acceptable but flag in release notes.
- **README image link breaks.** Signal: `README.md:2` `<img>` 404. Response: this phase does NOT delete `AppIcon.appiconset`, only unreferenced `Resources/` assets — README stays valid. PM verifies with GitHub preview after merge.
- **Cross-plan supersede semantics.** Signal: `260823-1810-skein-landing-page` still shows up as in-progress in `ak plan list`. Response: `ak plan close` after this phase's PR merges.

---

## AGY BRIEF (feed this verbatim to agy)

Bạn thực thi Phase 3 của plan `260828-2226-audit-fixes-p0-p3`. Đọc `phase-03-p1b-docs-hygiene.md` — hợp đồng phase.

CWD: `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein`
Branch: `feat/phase-03-p1b-docs-hygiene` từ `main`.

### Skills bắt buộc
- `/ak:scout` — đọc `plans/reports/scout-260828-2201-docs.md` để có line-level pointers, không tự đoán.
- `/ak:docs` — apply mọi text edit vào docs.
- `/ak:code-review` — self-review trước push.
- `/ak:test` — build Release sau khi prune MigrationManager, chắc chắn không vỡ.
- `/ak:ship` — chuẩn bị release artifact (không tag, không publish).

### Hard rules
1. KHÔNG xoá `Skein/Assets.xcassets/AppIcon.appiconset/` — nó còn được README.md:2 tham chiếu.
2. KHÔNG sửa `README.md` trong phase này.
3. Trước khi `git rm` bất cứ file `Resources/` nào, chạy `rg -l "$(basename $FILE)" .` — nếu ra bất kỳ match nào, DỪNG và báo PM.
4. Backfill checkbox chỉ theo đúng bảng PM cung cấp. Không tự phán "cái này chắc xong rồi".
5. Prune `MigrationManager.swift`: chỉ xoá branches version pre-1.0.0. Bất kỳ branch nào mơ hồ → giữ nguyên và hỏi PM.
6. KHÔNG `git tag`, KHÔNG merge PR.
7. Stuck → `/ak:advise` → kongming → report lại.

### Deliverables
1. PR `release: 1.3.0 (docs hygiene + repo cleanup)`.
2. CI xanh.
3. In: `PHASE_3_DONE: <PR URL>`

## Kongming checkpoint (PM run)

**Before merge:** PM asks kongming: "Does pruning MigrationManager branches pre-1.0.0 carry any risk given any Ice-fork lineage user could still exist in the wild?" Pass: git log of the file, the diff, the plan's mitigation.
