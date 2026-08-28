---
type: handoff
task: "Rename local worktree folder from Ice-vc to Skein"
priority: P3 (cosmetic; small blast radius but grows over time)
created: 2026-08-23 18:37 +07
run_order: 3 of 4
---

# Handoff — Rename local worktree folder

## Mission and current status

**Outcome desired:** the local git worktree lives at
`/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein` instead of the
legacy `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Ice-vc`. Every
bookmark, shell alias, VS Code workspace, and shell shortcut is updated to
match.

**Done:** nothing. The folder still carries its Frost-era name.

**Remaining:** the actual `mv` and the follow-up shortcut updates. This
CANNOT be done from within a Claude Code session whose CWD is inside the
folder being moved — the harness holds an open file descriptor on the
CWD, and every absolute-path tool call would break the instant `mv`
completes.

**Urgency:** low. Nothing breaks by leaving `Ice-vc`. But every new
bookmark that references `Ice-vc` from today onward is another thing to
update later.

## Scope and guardrails

- **User-executed in a plain terminal**, not inside a Claude Code session
  whose CWD is the folder.
- **Close Xcode, VS Code, and any editor that has the project open**
  first. Open file handles will hold on to the old path.
- **Do NOT touch `.git/`.** It uses relative paths internally; the folder
  rename leaves it working.
- **Do NOT change the git remote.** `origin` = `git@github.com:bavanchun/ariadnev-skein.git`
  is unaffected by local folder name.
- **DO NOT rename to a path with a space** — some tooling still chokes on
  it. `Skein` is safe.

## Current state

- **Absolute path today:** `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Ice-vc`
- **Target absolute path:** `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein`
- **Branch:** `main` @ `1f523236bcdba4bdb40438989c40e6f25aad5ca9`
- **Git remote (unaffected):** `origin` → `bavanchun/ariadnev-skein`
- **Untracked (do not block; will still be present after rename):**
  `docs/upgrade-frost-to-skein.md`,
  `plans/260728-0156-frost-app-icon-artwork/design-brief.md`,
  `plans/260823-1810-skein-landing-page/`

## Decisions and rationale

- **`Skein`, not `skein-app` / `Skein-vc` / `ariadnev-skein`.** Keep it
  short; the folder is under `Menubar-Manager/` which already namespaces
  it. The old `-vc` suffix was a VChun-fork disambiguator from the fork
  era — no longer needed now that the app is standalone.
- **Do it in a separate terminal, not in-session.** Prevents CWD
  invalidation mid-command.

## Work performed

- None yet. This session captured the rename plan; the user runs it.

## Verification

After rename, verify from the new folder:

1. `pwd` prints `.../Menubar-Manager/Skein`.
2. `git status` runs, shows the expected untracked files, no `.git`
   corruption.
3. `git remote -v` still shows `bavanchun/ariadnev-skein`.
4. `git log --oneline -3` returns the same three commits (`1f52323`,
   `44a85c4`, `cef98f4`).
5. `xcodebuild -list -project Skein.xcodeproj` still works.

## Open risks and blockers

- **Xcode DerivedData** — Xcode may hold a stale reference to the old
  path in `~/Library/Developer/Xcode/DerivedData/`. Cleaning that
  directory (or letting Xcode re-index) after rename is optional but
  removes noise. Command:
  `rm -rf ~/Library/Developer/Xcode/DerivedData/Skein-*`
- **VS Code / Cursor workspaces** — any `*.code-workspace` file with the
  old path in it needs manual update.
- **Shell aliases** — check `~/.zshrc`, `~/.zprofile`, `~/.zsh_aliases`
  for any hardcoded `Ice-vc`.
- **`launchctl` LaunchAgents / cron / GitKrakenCLI hooks** — if any
  pointed at `Ice-vc`, they will silently fail after rename. Search:
  `grep -rn Ice-vc ~/Library/LaunchAgents/ 2>/dev/null`

## Exact next actions

1. **First safe step** — exit any active Claude Code session that has
   its CWD inside `Ice-vc` (this session included). Also quit Xcode /
   VS Code / any file browser sitting inside that folder.
2. In a plain Terminal.app or iTerm2 window:
   ```
   cd ~/Codes/My-projects/tools/Menubar-Manager
   mv Ice-vc Skein
   cd Skein
   git status
   git remote -v
   git log --oneline -3
   ```
   Confirm outputs match the Verification checklist.
3. Update any hardcoded references — recommended sweep:
   ```
   grep -rn "Ice-vc" ~/.zshrc ~/.zprofile ~/.zsh_aliases 2>/dev/null
   grep -rn "Ice-vc" ~/Library/LaunchAgents 2>/dev/null
   ls ~/*.code-workspace 2>/dev/null | xargs grep -l "Ice-vc" 2>/dev/null
   ```
   Edit each file that reports a hit.
4. (Optional) `rm -rf ~/Library/Developer/Xcode/DerivedData/Skein-*` to
   force a clean Xcode re-index.
5. Open a fresh Claude Code session at the new path:
   `cd ~/Codes/My-projects/tools/Menubar-Manager/Skein && claude`.
6. This handoff can be closed after step 5 succeeds.

## Source pointers

- Current worktree: `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Ice-vc`
- Git repo: <https://github.com/bavanchun/ariadnev-skein>
- Nothing in the repo hardcodes the local folder name — verified by
  `git grep -n "Ice-vc"` returning zero hits (safe rename).
