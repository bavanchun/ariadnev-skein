---
phase: 1
title: "Stand up ariadnev-skein as a standalone repository"
status: pending
priority: P1
effort: "30m"
dependencies: []
---

# Phase 1: Stand up ariadnev-skein as a standalone repository

## Overview

Leave GitHub's fork network without losing a commit. Everything else in this plan
lands as pull requests in the repository this phase creates, so nothing else can
start first.

## Context

`gh api repos/bavanchun/Frost` reports `"fork": true`, `"parent":
"jordanbaird/Ice"`. That flag is GitHub metadata, not a Git property — the local
history already holds every Ice commit plus 18 fork-side commits. Pushing that
history into a repository made with `gh repo create` yields `fork: false` with
the history intact.

## Requirements

- New repository `bavanchun/ariadnev-skein`, public, GPL-3.0, `fork: false`
- Full commit history and all three tags present
- Repository settings matching `docs/DEVELOPMENT_WORKFLOW.md`: squash merge only,
  auto-delete head branches, protected `main`
- `bavanchun/Frost` untouched in this phase — it stays the live repository until
  phase 6

## Implementation Steps

1. Create the repository without any template or fork relationship:
   ```bash
   gh repo create bavanchun/ariadnev-skein --public \
     --description "Skein — menu bar manager for macOS. Part of the Ariadnev ecosystem."
   ```
2. Add it as a remote and push everything:
   ```bash
   git remote add skein git@github.com:bavanchun/ariadnev-skein.git
   git push skein main
   git push skein --tags
   ```
3. Verify the fork flag and history depth before trusting the result:
   ```bash
   gh api repos/bavanchun/ariadnev-skein -q '.fork'          # must print false
   git rev-list --count main                                  # compare to old repo
   gh api repos/bavanchun/ariadnev-skein/tags -q '.[].name'   # v1.1.0 v1.0.1 v1.0.0
   ```
4. Apply repository settings:
   ```bash
   gh api -X PATCH repos/bavanchun/ariadnev-skein \
     -F allow_squash_merge=true -F allow_merge_commit=false \
     -F allow_rebase_merge=false -F delete_branch_on_merge=true
   ```
5. Leave branch protection **unset for now**. Phase 5 replaces the required check
   with the new CI aggregator; configuring protection twice is wasted work and
   risks blocking the phase 2-4 pull requests.
6. Repoint the local clone, keeping `upstream` for future Ice security fixes:
   ```bash
   git remote set-url origin git@github.com:bavanchun/ariadnev-skein.git
   git remote remove skein
   git remote -v   # origin -> ariadnev-skein, upstream -> jordanbaird/Ice
   ```

## Success Criteria

- [ ] `gh api repos/bavanchun/ariadnev-skein -q .fork` prints `false`
- [ ] No "forked from" banner on the repository page
- [ ] `git rev-list --count main` identical in both repositories
- [ ] Tags `v1.0.0`, `v1.0.1`, `v1.1.0` all present
- [ ] `origin` points at `ariadnev-skein`; `upstream` still points at Ice
- [ ] `bavanchun/Frost` still public and unmodified

## Risk Assessment

**Creating the repository through the Fork button, or `gh repo fork`, defeats the
entire phase.** It must be `gh repo create`.

**Pushing before verifying the remote URL** can send the history to the wrong
place. Step 3 verifies before step 6 rewrites `origin`.

**Branch protection applied too early blocks phases 2-4**, because the required
check named in the old repository does not exist yet here. Deliberately deferred
to phase 5.
