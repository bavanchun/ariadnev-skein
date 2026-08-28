---
type: handoff
task: "Coordinate Skein app icon artwork end-to-end"
priority: P1 (longest lead time — external designer)
created: 2026-08-23 18:37 +07
run_order: 1 of 4
---

# Handoff — Skein app icon artwork coordination

## Mission and current status

**Outcome desired:** Skein ships with its own app icon and template mark
(`SkeinMarkStroke`), replacing the last two Ice-branded assets in the repo
(`AppIcon.appiconset` = blue cube; `SkeinMarkStroke.imageset` = wireframe
cube).

**Done:**
- Rebrand + release `v1.2.0` shipped with Ice's artwork still in place.
- Parent plan exists: `plans/260728-0156-frost-app-icon-artwork/` (Overview,
  Goals, Constraints, Non-goals, 3 phases).
- **Designer brief written** and ready to hand off:
  `plans/260728-0156-frost-app-icon-artwork/design-brief.md`.
- Decision B locked: classic `.appiconset` PNG set (not Icon Composer).
- Decision A **reopened** under the Skein name (was written for "Frost";
  snowflake/crystal options are stale — re-evaluate as thread/coil).

**Remaining:**
- Send brief to a designer (external — this session's biggest single wait).
- Get 1024×1024 master + 16pt preview approved before the 10-slot export.
- Receive 10 PNGs + 1 template mark PNG + layered source file.
- Install into `Skein/Assets.xcassets/AppIcon.appiconset/` and
  `Skein/Assets.xcassets/SkeinMarkStroke.imageset/` (this is parent
  plan phases 2 and 3 — mechanical, ~1 hour once artwork exists).
- Ship a single PR `feat/skein-app-icon-artwork` into `main`.

**Urgency:** critical path for the landing page hero. Every day here = day
of slip on session 4.

## Scope and guardrails

- **Repo:** `bavanchun/ariadnev-skein` (worktree
  `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Ice-vc`, will be
  `.../Skein` after session 3 rename).
- **Allowed:** update the brief with clarifications; open the PR that
  installs final artwork; edit the parent plan status; open follow-up
  issues for anything discovered mid-design.
- **Prohibited:** touching the menu bar control-item icons (Snowflake,
  Door, etc. — settled by a previous plan and user-facing); changing
  `AccentColor.colorset` (separate decision); shipping `.icon` (Icon
  Composer) files (Decision B rejected them for the first landing);
  putting the letter "S" or the word "Skein" as text in the mark.
- **Hard filename contract:** the 10 PNGs must match the exact names in
  `Skein/Assets.xcassets/AppIcon.appiconset/Contents.json` — the catalog
  references them literally. Wrong names = silent build failure.

## Current state

- **Branch:** `main` @ `1f523236bcdba4bdb40438989c40e6f25aad5ca9` (clean
  except three untracked items from this planning session).
- **Untracked (intentional, awaiting commit):**
  - `plans/260728-0156-frost-app-icon-artwork/design-brief.md`
  - `docs/upgrade-frost-to-skein.md` (owned by session 2, ignore here)
  - `plans/260823-1810-skein-landing-page/` (owned by session 4, ignore here)
- **Parent plan:** `plans/260728-0156-frost-app-icon-artwork/plan.md` — 3
  phases, all `pending`.
- **Current assets that will be replaced:**
  - `Skein/Assets.xcassets/AppIcon.appiconset/` — 10 PNGs, blue cube (Ice's)
  - `Skein/Assets.xcassets/SkeinMarkStroke.imageset/` — 1 PNG @2x, template
    rendered, 1.4 KB, wireframe cube

## Decisions and rationale

- **`.appiconset` over Icon Composer** (locked): supported floor is macOS
  14; keep format migration and redesign as independent risks.
- **Filename `AppIcon` preserved** (`ASSETCATALOG_COMPILER_APPICON_NAME`):
  avoids project.pbxproj edits.
- **Concept direction (recommended, not locked):** stylised skein/coil of
  thread, matching the "Ariadne's thread through the labyrinth" naming.
  Alternatives ranked in the brief.
- **`README.md:2` links `icon_256x256.png` by name** — filename set must not
  change or the README image breaks silently on GitHub.

## Work performed

- Wrote 161-line designer brief with concept context, hard macOS style
  rules, exact deliverable list, filename contract, handoff checklist, and
  a 16pt-preview approval gate.
- No git changes yet — brief is untracked.

## Verification

- **Not yet applicable.** Verification happens after artwork arrives:
  1. Xcode build succeeds and shows the new icon in Debug Navigator.
  2. `Assets.xcassets` validator has no warnings.
  3. Dock/Finder/Sparkle dialog all render correctly at their native sizes.
  4. Settings → About renders `SkeinMarkStroke` as a clean silhouette.
- Nothing verified this session.

## Open risks and blockers

- **No designer identified yet.** Bottleneck. Either the user paints it,
  hires from Dribbble/99designs, or delegates to a friend. Without a
  designer on the clock, nothing else here moves.
- **Concept sign-off (Decision A).** The brief recommends thread/coil but
  does not lock it. User must decide, or explicitly delegate the call to
  the designer with the recommendation as a floor.
- **Trap — 16pt legibility.** Most icon concepts die at 16pt. The brief
  hard-gates on a 16pt preview before export; do not skip this.

## Exact next actions

1. **First safe step** — commit the brief so downstream sessions have a
   stable reference:
   ```
   git checkout -b docs/skein-icon-design-brief
   git add plans/260728-0156-frost-app-icon-artwork/design-brief.md
   git commit -m "docs(icon): add designer brief for Skein app icon artwork"
   gh pr create --base main --title "docs(icon): designer brief for Skein artwork" \
     --body "Ships the handoff document referenced by the icon coordination session."
   ```
2. Send the merged brief to a designer (user action; agent can draft the
   email/DM if asked).
3. When 1024 master + 16pt preview arrives, review in this session; if
   green, approve to export the 10 slots + template mark.
4. When final artwork arrives, run parent plan phases 2 and 3 in one PR:
   `feat/skein-app-icon-artwork` → replace files → build in Xcode →
   verify Sparkle dialog → merge.
5. Update parent plan `plan.md` phases from `pending` → `complete`.
6. Update this handoff status.

## Source pointers

- Designer brief: `plans/260728-0156-frost-app-icon-artwork/design-brief.md`
- Parent plan: `plans/260728-0156-frost-app-icon-artwork/plan.md`
- Phase docs: `plans/260728-0156-frost-app-icon-artwork/phase-0{1,2,3}-*.md`
- Assets to replace:
  - `Skein/Assets.xcassets/AppIcon.appiconset/Contents.json`
  - `Skein/Assets.xcassets/SkeinMarkStroke.imageset/Contents.json`
- README icon link: `README.md:2`
- Dev workflow (branch/PR rules): `docs/DEVELOPMENT_WORKFLOW.md`
- Repo: <https://github.com/bavanchun/ariadnev-skein>
