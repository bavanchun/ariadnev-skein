---
phase: 6
title: "P2 — Re-plan dropped-click and item-movement handling"
status: pending
priority: P2
effort: "1.0 day (scout + plan only; implementation is a separate plan)"
dependencies: [5]
release: "none — this phase ships no code"
created: 2026-09-05
---

# Phase 6: P2 — Re-plan dropped-click and item-movement handling

> **Why this phase exists.** The original Phase 4 contract bundled two unrelated
> things: porting upstream's mouse-moved event tap, and fixing dropped clicks
> when moving menu bar items. Only the first is a small, self-contained port.
> The second lives almost entirely in `MenuBarItemManager.swift`, which every
> phase in this plan lists as OUT OF SCOPE, and upstream reworked it across
> three large commits rather than one cherry-pickable fix. Evidence:
> [`plans/reports/scout-260905-phase-04-contract-check.md`](../reports/scout-260905-phase-04-contract-check.md),
> Finding 2.
>
> Rather than write a contract for work nobody has sized, this phase produces
> the sizing. **It ships no Swift.**

## Overview

Moving a menu bar item in Skein is a synthesized-event dance: the manager posts
mouse-down / mouse-drag / mouse-up events to the target item's window and waits
for the system to acknowledge each one. When an acknowledgement never arrives —
the event tap was disabled by timeout, the item did not accept the click, the
window moved mid-gesture — the move silently fails and the click is dropped.

Upstream reworked this three times in one month:

| Commit | Date | Title | MenuBarItemManager | EventTap | Other |
|---|---|---|---|---|---|
| `8d4b6a5` | 2025-08-07 | Improve menu bar item movement | +619/− | 114 | new `ConcurrencyHelpers.swift` (+218), deletes `TaskHelpers.swift` (−87) |
| `e3c63f2` | 2025-08-17 | Improve menu bar item event handling | 567 | 252 | `Bridging.swift`, `Shims.swift` |
| `b0a1942` | 2025-08-22 | Improve menu bar item handling | 618 | 88 | `Extensions.swift`, `MouseHelpers.swift` |

Together: roughly 1,800 lines of churn in `MenuBarItemManager.swift` alone, on
top of a file Skein has already diverged from. That is not a cherry-pick. It is
either a rewrite of Skein's manager against upstream's, or a targeted fix
informed by upstream's reasoning — and which of those is correct is exactly the
question this phase answers.

## Requirements

### Functional

The deliverable is a written decision, backed by evidence, that answers:

1. **Is the bug reproducible in Skein today?** On the maintainer's macOS 26.6.2
   machine, at the version on `main`, with a named reproduction procedure —
   or a statement that it could not be reproduced, which is equally a result.
2. **Does Skein's `MenuBarItemManager` share upstream's cause?** Skein forked
   before all three commits. The three upstream commits describe what upstream
   was fixing; this phase establishes whether Skein's code has the same defect,
   a different one, or none.
3. **Which of the three strategies applies**, with the cost of each:
   - port upstream's rework wholesale (largest diff, closest to upstream, hardest to review);
   - extract the specific ordering/acknowledgement fix and apply it to Skein's manager;
   - do nothing, and record why.
4. **What the follow-on plan looks like** if a fix is warranted: phases, effort,
   files, and gates — written as a new plan directory, not as more phases here.

### Non-Functional

- No Swift file in `Skein/` is modified by this phase. `git diff --stat` at the
  end of it touches only `plans/`.
- Every claim about upstream cites a commit SHA and a path. Every claim about
  Skein cites `file:line`.

## Sequencing

`dependencies: [5]` is deliberate. Phase 5 moves `Bridging.swift` and the CGS
shims into `Shared/`, and `e3c63f2` touches both (`Shared/Bridging/Bridging.swift`,
`Shared/Bridging/Shims.swift` in upstream's tree). Scouting this before Phase 5
lands would produce a file map that Phase 5 immediately invalidates.

Phase 4 is unrelated and may land at any time.

## Related Code Files

Read-only, for the scout:

- `Skein/MenuBar/MenuBarItems/MenuBarItemManager.swift` — the subject
- `Skein/Events/EventTap.swift`, `Skein/Events/EventManager.swift`
- `Skein/Utilities/MouseCursor.swift` — Skein's counterpart to upstream's
  `Ice/Utilities/MouseHelpers.swift`, which `8d4b6a5` and `b0a1942` both touch
- Upstream: `git show 8d4b6a5`, `git show e3c63f2`, `git show b0a1942`

Written by this phase:

- `plans/reports/scout-2609XX-menu-bar-item-movement.md` — the evidence
- A new plan directory under `plans/`, if the decision is to fix

## OUT OF SCOPE

- Writing any Swift.
- Opening a PR against `Skein/`.
- The `MenuBarItemManager` god-class refactor as a refactor. If the fix requires
  restructuring, that is a finding to record, not a licence to start.
- Phase 4's hover tap and Phase 5's XPC service.

## Implementation Steps

1. Wait for Phase 5 to merge, so the file map is stable.
2. Reproduce. Move items in the Skein Bar and in Settings → Menu Bar Layout,
   with and without a slow/unresponsive third-party item present. Record the
   exact procedure and whether it fails.
3. Read the three upstream commits in date order. For each, write down what
   changed and what defect it was fixing — from the diff, not the commit title.
4. Map each upstream change onto Skein's `MenuBarItemManager` and record whether
   the corresponding code exists, differs, or is absent.
5. Cost each of the three strategies in files, lines, and review burden.
6. Write the scout report.
7. Put the recommendation to the maintainer with the trade-off, and let them
   choose. Do not choose on their behalf.
8. If the answer is "fix it", write the new plan. If it is "not now", update the
   audit report's finding with the reason and close this phase.

## Success Criteria

- [ ] Reproduction attempt documented, with the result either way.
- [ ] All three upstream commits read and summarized by defect, not by title.
- [ ] Skein-side mapping written with `file:line` citations.
- [ ] Three strategies costed.
- [ ] Maintainer has chosen, and the choice is recorded in the plan.
- [ ] `git diff --stat` for this phase touches only `plans/`.

## Risk Assessment

- **The bug is not reproducible.** Signal: step 2 finds nothing. Response: that
  is a valid outcome and closes the phase — record it and stop. Do not port
  1,800 lines to fix a defect nobody has observed in this fork.
- **Scope creep into the god-class refactor.** Signal: the report starts
  proposing a `MenuBarItemManager` restructure. Response: restructuring is a
  finding, and belongs in its own plan with its own approval.
- **Phase 5 shifts the file map mid-scout.** Signal: paths in the report no
  longer exist. Response: this is why the phase depends on 5; if it is started
  early anyway, re-verify every path before publishing.

## Rollback

Nothing to roll back — this phase produces documents only.
