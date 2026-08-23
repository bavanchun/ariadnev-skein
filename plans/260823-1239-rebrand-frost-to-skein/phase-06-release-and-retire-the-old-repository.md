---
phase: 6
title: "Release 2.0.0 and retire bavanchun/Frost"
status: complete
priority: P2
effort: "2h"
dependencies: [5]
---

# Phase 6: Release 2.0.0 and retire bavanchun/Frost

## Overview

Ship Skein, point the Cloudflare feed route at it, then archive the old
repository — in that order, because the old feed is load-bearing until the new
release exists.

## Version — requires explicit sign-off

The bundle identifier moves, macOS sees a new application, and permissions must
be re-granted. `docs/release-guide.md` § "Versioning Policy" makes that a major
bump.

**Approved 2026-08-23: `1.2.0`.** The maintainer chose the minor bump over the proposed `2.0.0`, on the recorded counter-argument that a personal app with one known install has no compatibility surface to break. Build counter 1120 -> 1121.

~~Proposed: `2.0.0`.~~ Per repository policy the version is proposed and cut only
after the maintainer signs off. **Do not tag without it.**

The counter-argument, recorded so the decision is informed: with one known
install there is arguably no compatibility surface to break, which would make
`1.2.0` defensible.

## Implementation Steps

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`; write the `2.0.0`
   changelog entry. Release notes must state plainly that settings migrate
   automatically but **Accessibility and Screen Recording must be re-granted**.
2. Build, codesign inside-out, zip, and sign the zip per
   `docs/release-guide.md` steps 3-4. `SUPublicEDKey` is unchanged, so the
   existing Keychain private key still signs.
3. Publish the GitHub release on `ariadnev-skein` with an SSH-signed tag.
4. Add the Cloudflare route in `ariadnev-web`, resolving
   `https://ariadnev.com/skein/appcast.xml` to the new release's appcast. That
   repository has contract tests over its public edge — follow its own workflow
   and extend the contract test rather than bypassing it.
5. Verify Sparkle end to end: install `2.0.0`, confirm it polls the Worker route
   and reports no update.
6. Retire `bavanchun/Frost`, only now:
   ```bash
   gh api -X PATCH repos/bavanchun/Frost \
     -f description="Moved to bavanchun/ariadnev-skein — Frost is now Skein."
   gh api -X PATCH repos/bavanchun/Frost -F archived=true
   ```
   Keep its releases and `appcast.xml` intact so installed Frost builds do not
   404.

## Success Criteria

- [ ] `2.0.0` approved before the tag is cut
- [ ] Release published with an SSH-signed tag
- [ ] `https://ariadnev.com/skein/appcast.xml` returns the appcast
- [ ] A clean `2.0.0` install polls the Worker route successfully
- [ ] `bavanchun/Frost` archived, description points at the new repository
- [ ] The old `appcast.xml` still resolves

## Risk Assessment

**Archiving before `2.0.0` publishes** leaves installed builds polling a feed
whose newest release is still Frost. Step 6 is deliberately last.

**A wrong Ed25519 signature yields a silent update failure** — Sparkle simply
finds nothing. Verify the signature before publishing, not after.

**`ariadnev-web` is production infrastructure** serving `ariadnev.com` with
contract-tested routes. The appcast route goes through that repository's own
review and test process; it is not a side edit.
