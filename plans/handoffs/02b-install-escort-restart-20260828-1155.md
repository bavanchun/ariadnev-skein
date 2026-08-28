---
type: coordinator-brief
supersedes: 02-install-skein-remove-frost-20260823-1837.md (current state only)
created: 2026-08-28 11:55 +07
agent: Claude Code
worktree: /Users/vchun/orca/workspaces/Ice-vc/skein-install-escort
branch: bavanchun/skein-install-escort
---

# Coordinator brief — install Skein, remove Frost (restart)

Read this file, then `plans/handoffs/02-install-skein-remove-frost-20260823-1837.md`,
then `docs/upgrade-frost-to-skein.md` (the 8 steps the user follows). Where this
file disagrees on current state, it wins; the older handoff stays authoritative
on rationale and safety.

## Your role — read this before anything else

**You are an escort, not an operator.** The user performs every step on their
own machine. You explain, you verify, you troubleshoot, you gate. You do not
run the destructive commands for them.

The previous run of this stream died when the repo folder was renamed
`Ice-vc` → `Skein`. It never got past reading its brief — **nothing has been
done on the machine.**

## Current machine state — verified by the coordinator just now

- `/Applications/Frost.app` **exists**. `/Applications/Skein.app` **does not**.
- `defaults domains` lists `com.vchun.Frost`. There is **no `com.ariadnev.Skein`
  domain**, which proves Skein has never launched on this Mac.
- `com.ariadnev.SkeinMigrationTest` exists — that is the leftover scratch
  harness from migration verification, **not** live state. Ignore it; do not
  treat its contents as evidence the migration works.
- Release `v1.2.0` is published on `bavanchun/ariadnev-skein`:
  `Skein-1.2.0.zip` (4,368,316 bytes) + `appcast.xml` (982 bytes).
- `https://skein.ariadnev.com/appcast.xml` returns **HTTP 200** right now.

## The gate that must not bend

`MigrationManager.migrate2_0_0` does a **one-shot** copy of the
`com.vchun.Frost` UserDefaults domain into `com.ariadnev.Skein` on first
launch. It runs once. If it silently drops a setting, Frost's on-disk prefs
are the **last remaining copy** of that data.

Therefore: **do not let the user run steps 6–8** (quit Frost,
`sudo rm -rf /Applications/Frost.app`, `defaults delete com.vchun.Frost`,
`tccutil reset`) until step 5 has passed **all four** checks:

1. Menu Bar Layout — items in the same sections, same order
2. Hotkeys — every binding present, including "Enable Skein Bar" keeping its
   old key combo
3. Appearance — tint, shadow, split, colour all carried over
4. General — launch at login, icon choice, and the rest

If **any** check comes up short: **stop, tell the user, do not remove Frost.**
A partial migration with Frost still installed is a recoverable situation. The
same partial migration after `defaults delete` is permanent data loss.

Once the user runs `defaults delete com.vchun.Frost`, that source is gone. Say
this to them plainly before they run it, not after.

## Other hard constraints

- **Never `pkill` broadly.** Quit Frost through its own menu or the exact
  `osascript` quit command in the guide.
- **Do not touch `com.ariadnev.Skein` defaults.** That is Skein's live state.
- macOS ties Accessibility and Screen Recording to the bundle ID. Frost's
  grants **do not** transfer. The user must re-grant both by hand — there is no
  programmatic workaround, and you should not look for one.
- **Local machine only. No repo changes**, with the one exception below.

## Second deliverable — screenshots for the landing page

This is new, and it is why this stream is running now.

The Skein landing page (running in parallel, worktree
`/Users/vchun/orca/workspaces/Ice-vc/skein-landing-page`, PR #2 in
`bavanchun/ariadnev-skein-web`) is **blocked** on real product screenshots. It
currently ships honest placeholders reading "Appearance capture pending".

Once Skein is installed, running, and configured, capture clean screenshots:

- The menu bar in its cluttered state vs. tidied by Skein
- Settings → Appearance
- Settings → General
- The search panel

Save them under `plans/reports/screenshots-260828/` in this worktree and tell
the coordinator the path. **Do not** commit them into the app repo yourself and
**do not** push them to the web repo — the landing stream owns that.

Shoot on a clean desktop, no personal information in the bar, Light and Dark
if cheap to do both.

## Escalate rather than decide

- Any step-5 check that does not fully pass.
- Migration behaving differently from the 9/9 scratch-harness result.
- The user wanting to skip ahead to removal. Repeat the gate; do not relent.

Report progress to the coordinator; leave findings in `plans/reports/`.
