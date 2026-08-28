---
type: handoff
task: "Escort user through installing Skein 1.2.0, verifying migration, and removing Frost"
priority: P1 (only user can execute; unblocks screenshots for session 4)
created: 2026-08-23 18:37 +07
run_order: 2 of 4
---

# Handoff — Install Skein, verify migration, remove Frost

## Mission and current status

**Outcome desired:** the user is running `Skein.app` 1.2.0 on their Mac
with all Frost settings migrated (menu bar layout, hotkeys, appearance,
"show icon" preferences), Frost is fully uninstalled, and Skein autostarts
cleanly across reboots.

**Done (from a previous session):**
- Release `v1.2.0` published: <https://github.com/bavanchun/ariadnev-skein/releases/tag/v1.2.0>
  Assets: `Skein-1.2.0.zip` (4,368,316 bytes) + `appcast.xml`.
- Sparkle feed live: `https://skein.ariadnev.com/appcast.xml` (returns 200,
  advertised length byte-for-byte equal to the zip).
- Migration `migrate2_0_0` implemented in
  `Skein/Utilities/MigrationManager.swift` — one-shot copy of the
  `com.vchun.Frost` UserDefaults domain into `com.ariadnev.Skein` on first
  launch. Verified 9/9 against the user's real 37-key Frost domain in a
  scratch harness.
- Upgrade guide written: `docs/upgrade-frost-to-skein.md` (108 lines, 8
  steps).

**Remaining:** the user physically performs the 8 steps. This session's job
is to escort, troubleshoot, and confirm.

**Urgency:** blocks session 4 (landing page needs real Skein screenshots).

## Scope and guardrails

- **Local machine actions only.** No repo changes. No release changes.
- **DO NOT skip step 5 (verify migration) before step 7 (`rm -rf` Frost).**
  Migration is one-shot; if it silently drops a setting, Frost's on-disk
  prefs are the last remaining source of truth. Once `defaults delete
  com.vchun.Frost` runs, that source is gone.
- **DO NOT touch `com.ariadnev.Skein` defaults** — that's Skein's live
  state, unaffected by Frost cleanup.
- **DO NOT `pkill` broadly.** Use the app's own Quit menu or the
  osascript quit command in the guide.
- macOS ties Accessibility + Screen Recording to bundle ID; Frost's grants
  do **not** transfer to Skein. Must be re-granted manually.

## Current state

- **Branch:** `main` @ `1f523236bcdba4bdb40438989c40e6f25aad5ca9` (clean
  except three untracked items from this planning session, none owned here).
- **Untracked and relevant here:** `docs/upgrade-frost-to-skein.md` — the
  step-by-step guide the user follows.
- **Machine state (user-observed, not probed):** presumed Frost.app is
  installed at `/Applications/Frost.app` and running; Skein not yet
  installed.

## Decisions and rationale

- **Coexist first, remove Frost last.** Two menu bar managers can run
  simultaneously without corrupting either; safer than a hard cutover.
- **Migration reads `com.vchun.Frost` via `persistentDomain(forName:)`.**
  App-sandbox is off — required for cross-domain reads. Do not toggle
  sandbox on until migration is retired.
- **New user permissions are unavoidable.** macOS TCC bundle-ID model —
  no programmatic workaround exists that would satisfy Apple's threat
  model.

## Work performed

- Wrote `docs/upgrade-frost-to-skein.md`. No commits.
- No commands executed on the user's machine this session.

## Verification

Verification is what the user performs in step 5 of the guide. Checklist:

- Menu Bar Layout tab shows the previous hidden/always-hidden/pinned layout.
- Hotkeys tab shows the previous hotkeys; the label `Enable Frost Bar`
  is now `Enable Skein Bar` with the same key combo.
- Appearance tab retains tint / shadow / split / colour choices.
- General tab retains "Show Skein Icon", bar location, pinned location.

If any of the above is empty, the migration did not run or partially failed
— **STOP, do not remove Frost, escalate.**

Post-cleanup verification:
- `defaults read com.vchun.Frost` returns "Domain … does not exist".
- Skein still launches at login after a reboot.
- No `Frost.app` in `/Applications` or Dock; no orphan LaunchAgent.

## Open risks and blockers

- **Gatekeeper prompt** — the release ZIP is signed + notarised, but first
  launch may still need right-click → Open. Documented in step 3.
- **Screen Recording quit-and-relaunch loop** — after granting Screen
  Recording, macOS forces a quit + relaunch. Expected, not a bug.
- **Login item ghost** — if Frost had "Launch at Login" enabled, its entry
  points at a soon-to-be-missing path. Step 8 in the guide toggles Skein's
  launch-at-login off/on to force macOS to register the new bundle ID.
- **Nothing to escalate to yet** — the user has not started.

## Exact next actions

1. **First safe step** — user opens `docs/upgrade-frost-to-skein.md` and
   reads it fully before starting. Ask any question that comes up before
   running any command.
2. Follow steps 1–4 (download, move, first launch, grant permissions).
3. **Gate: perform step 5 verification.** Report back what's present and
   what's missing before proceeding.
4. Only on 5 = fully green: run steps 6–8 (quit Frost, `rm -rf`, optional
   `defaults delete` + `tccutil reset`, then confirm autostart).
5. When done, report back so session 4 (landing page) can start
   collecting screenshots.

## Source pointers

- Guide: `docs/upgrade-frost-to-skein.md`
- Release download: <https://github.com/bavanchun/ariadnev-skein/releases/latest>
- Migration source: `Skein/Utilities/MigrationManager.swift`
  (`migrateDefaultsDomain2_0_0`, `migrateHotkeyAction2_0_0`)
- Persisted key rename map: `frostRenamedKeys` in the file above
- Hotkey rename: `Skein/Hotkeys/HotkeyAction.swift:15`
- Renamed defaults keys: `Skein/Utilities/Defaults.swift`
- Sparkle feed URL: `Skein/Info.plist` (`SUFeedURL`)
- Provenance / lineage: `docs/UPSTREAM.md`
