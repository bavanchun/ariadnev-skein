---
phase: 2
title: "P1a — Landing ship + escort install"
status: pending
priority: P1
effort: "1.0 day"
dependencies: [1]
release: "no version bump — content only, Cloudflare Pages deploy"
---

# Phase 2: P1a — Landing ship & escort install

## Overview

Complete the public landing rollout: guide the maintainer through installing Skein v1.2.2 (verifying Frost→Skein settings migration works end-to-end), capture real product screenshots of the running app, replace all placeholder mockups on the landing page, and merge the resulting landing PR. This phase produces no app release; it produces trust — the first thing a stranger sees at the landing URL.

## Requirements

### Functional
- Maintainer's own Mac installs v1.2.2 clean, migration from Frost preserves all 37 pref keys, no crash on first launch.
- ≥6 real product screenshots (menu bar in use, Skein Bar open, hotkey editor, appearance pane, search pane, settings general) captured at 2560×1600 (Retina), lossless PNG or JPEG-90.
- Screenshots stored in `plans/reports/screenshots-260828/` (owned by this plan) and copied into `ariadnev-skein-web/public/images/` under stable names.
- Landing PR replaces every placeholder (`.placeholder` divs, `overflow` menu bar illustration) with the real captures where a real capture makes sense; keeps hand-drawn illustration only where it improves narrative.
- Frost.app finally removed from `/Applications/` — but only after all 4 migration checks pass, per install-escort protocol.

### Non-Functional
- Screenshots use Skein's real rope-orange AccentColor from Phase 1, not the old Ice blue.
- Every screenshot: no Dock badges, no personal notification, no other visible username/email, no timestamps that read as embarrassing (2am debugging session), no other menu bar apps that could mislead.
- Landing build passes: `pnpm format`, `pnpm check`, `pnpm build` all green.

## Architecture

Two workstreams run inside this phase, coordinated by PM:

**Workstream A — Escort (PM + Maintainer, agy prepares tooling only):**
- agy prepares a fresh escort brief that supersedes `plans/handoffs/02b-install-escort-restart-20260828-1155.md` for v1.2.2 (not 1.2.0). It updates the byte-size expectation, the release URL, and the 8-step sequence.
- Maintainer runs the escort steps themselves in their normal terminal. Backup at `~/frost-prefs-backup-260828.plist` remains the safety net.
- After migration verified, maintainer captures the 6+ screenshots. agy does NOT open Skein.app itself.

**Workstream B — Landing PR (agy):**
- agy checks out the `ariadnev-skein-web` repo (separate repo, cwd `/tmp/skein-web-phase-02`).
- Replaces placeholders in `src/pages/index.astro` with real screenshots; adjusts CSS for actual image aspect ratios; verifies alt text describes what the reader sees.
- Runs build gates and opens a follow-up PR.
- Waits for PM merge signal — does not merge itself.

## Related Code Files

**In this repo (`ariadnev-skein`):**
- Create: `plans/handoffs/02c-install-escort-v1.2.2-20260828.md` (fresh escort brief tailored to 1.2.2 byte size + URL)
- Create: `plans/reports/screenshots-260828/README.md` (index of captured screenshots with when/how)
- Create (data): `plans/reports/screenshots-260828/*.png` (the actual captures)

**In `ariadnev-skein-web` repo:**
- Modify: `src/pages/index.astro` — replace placeholder mockups with real screenshot references
- Modify: `src/styles/global.css` — image sizing rules if needed
- Create: `public/images/screenshots/*.png` — copies of the plans/reports/screenshots-260828/ files, versioned in the web repo

## OUT OF SCOPE

- Any Skein app code changes (Phase 1 is the only app change window in this release train until Phase 4).
- DNS cutover of `skein.ariadnev.com` — already live per prior work, not touched here.
- Cloudflare Worker code — untouchable per plan guardrail #4.
- Landing content copy rewrite — copy is fine as-is, only replace image placeholders.
- Screenshot editing/retouching that fakes UI state (e.g. compositing icons that aren't real).

## Implementation Steps

1. **agy — escort brief authoring:**
   - Read the existing `plans/handoffs/02b-install-escort-restart-20260828-1155.md` and `docs/upgrade-frost-to-skein.md`.
   - Write `plans/handoffs/02c-install-escort-v1.2.2-20260828.md` covering: pre-checks, download v1.2.2 ZIP (exact bytes from GitHub release), unzip, drag to /Applications, first-launch Gatekeeper walkthrough, migration verification (4 checks: Menu Bar Layout, Hotkeys, Appearance, General), Frost removal (only after all 4 pass), screenshot capture checklist.
   - PR the escort brief as a standalone commit in `feat/phase-02-escort-brief`.

2. **Maintainer — install escort (guided by PM using the fresh brief):**
   - PM reads the brief aloud to maintainer step by step; maintainer executes.
   - Captures screenshots as the last step; saves to `~/Desktop/skein-shots-260828/` then moves into repo `plans/reports/screenshots-260828/`.

3. **agy — landing PR:**
   - `git clone bavanchun/ariadnev-skein-web` into `/tmp/skein-web-phase-02`.
   - Branch `feat/phase-02-real-screenshots` from `main`.
   - Copy screenshots from `../ariadnev-skein/plans/reports/screenshots-260828/` into `public/images/screenshots/`.
   - Edit `src/pages/index.astro`: replace each placeholder with `<img src="/images/screenshots/…" alt="…" width="…" height="…" loading="lazy">` — set correct intrinsic dimensions.
   - Adjust CSS if needed for the real aspect ratios (avoid layout shift).
   - `pnpm format && pnpm check && pnpm build` — all green.
   - Open PR titled `feat(web): replace landing placeholders with real Skein screenshots`.
   - Wait for PM merge signal, do not merge.

## PM VERIFICATION CHECKLIST

- [ ] `plans/handoffs/02c-install-escort-v1.2.2-20260828.md` exists, byte size matches the actual v1.2.2 ZIP on GitHub.
- [ ] All 4 migration checks passed on maintainer's Mac (PM asks maintainer directly, does not assume).
- [ ] `~/frost-prefs-backup-260828.plist` still exists (safety net not deleted).
- [ ] Screenshots in `plans/reports/screenshots-260828/`: ≥6 files, each ≥1920×1200, no PII visible on visual inspection.
- [ ] Landing PR diff replaces every `<div class="placeholder">` and every `<div class="menu-bar overflow">…</div>` block (except where a hand-drawn illustration is intentionally kept — PM decides case-by-case).
- [ ] `pnpm build` output in PR CI shows 0 errors.
- [ ] No commit in the landing PR touches the FAQ block from PR #2 (already merged, do not regress).

## Success Criteria

- [ ] v1.2.2 running cleanly on maintainer's Mac with migrated Frost prefs intact.
- [ ] Landing PR merged; Cloudflare Pages deploy live within 2 minutes; https://skein.ariadnev.com shows real screenshots.
- [ ] Prior plan `260823-1810-skein-landing-page` closed with a record note pointing at this phase's PR.

## Risk Assessment

- **Migration silently drops a key.** MigrationManager is one-shot; if a mapping is missing, that key is lost forever without the backup. Signal: maintainer says "my hotkey for X is gone" after migration. Response: restore from `~/frost-prefs-backup-260828.plist`, file bug against MigrationManager, do NOT close escort until root-caused.
- **Screenshots leak PII.** Signal: PM's visual inspection catches personal email/name/other-app-notification. Response: reject, ask maintainer to recapture with a clean scratch macOS user or after quieting notifications.
- **Cloudflare Pages deploy fails.** Signal: PR merged but https://skein.ariadnev.com still shows old build after 3 minutes. Response: PM checks Cloudflare Pages dashboard, does not attempt to reconfigure — asks maintainer.

---

## AGY BRIEF (feed this verbatim to agy)

Bạn là developer thực thi Phase 2 của plan `plans/260828-2226-audit-fixes-p0-p3/plan.md`. Đọc kỹ `phase-02-p1a-landing-ship.md`.

Phase này có 2 workstream. Bạn ONLY làm phần agy:
- **A**: viết escort brief mới (file MD trong repo này).
- **B**: sửa landing PR trong repo web (repo khác).

Bạn KHÔNG được:
- Mở Skein.app hoặc Frost.app.
- Chạy `open /Applications/Skein.app`.
- Chụp screenshot (maintainer tự làm).
- `sudo rm`, `defaults delete`, `tccutil reset`.
- Merge PR nào.
- Sửa Cloudflare Worker.

### Workstream A: Escort brief mới

CWD: `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein`
Branch: `feat/phase-02-escort-brief`

1. `/ak:scout` đọc:
   - `plans/handoffs/02b-install-escort-restart-20260828-1155.md`
   - `docs/upgrade-frost-to-skein.md`
2. Lấy byte size v1.2.2 ZIP thật: `gh release view v1.2.2 --repo bavanchun/ariadnev-skein --json assets` → tìm asset `Skein-1.2.2.zip` → size.
3. Viết `plans/handoffs/02c-install-escort-v1.2.2-20260828.md` copy structure của 02b nhưng cập nhật:
   - version 1.2.0 → 1.2.2 mọi chỗ.
   - byte size mới.
   - URL release mới.
   - 4 checks giữ nguyên (Menu Bar Layout, Hotkeys, Appearance, General).
   - Gatekeeper walkthrough: giữ nguyên cả 2 option (Settings và xattr).
4. `/ak:code-review` self-review file.
5. `gh pr create` với title `docs(handoffs): install escort brief for v1.2.2 migration`.
6. In: `PHASE_2A_DONE: <PR URL>`

### Workstream B: Landing PR (làm SAU khi maintainer báo đã chụp xong screenshots)

Bạn phải đợi PM báo tín hiệu `START_2B` trước khi bắt đầu. Không tự đoán.

Khi có `START_2B`:

CWD làm việc: `/tmp/skein-web-phase-02`

1. `git clone git@github.com:bavanchun/ariadnev-skein-web.git /tmp/skein-web-phase-02 && cd /tmp/skein-web-phase-02`.
2. Branch `feat/phase-02-real-screenshots` từ `main`.
3. Copy screenshots từ `/Users/vchun/Codes/My-projects/tools/Menubar-Manager/Skein/plans/reports/screenshots-260828/*.png` vào `public/images/screenshots/`.
4. `/ak:scout` mở `src/pages/index.astro`, list mọi `<div class="placeholder">` và `<div class="menu-bar overflow">…</div>`.
5. Với mỗi placeholder, quyết định: replace bằng `<img>` real screenshot, hay giữ nguyên (nếu là hand-drawn illustration có mục đích narrative). Nếu không chắc → hỏi PM chứ không tự quyết.
6. Sửa CSS nếu cần cho aspect ratio đúng, tránh layout shift.
7. Alt text mô tả nội dung thật, không copy-paste generic.
8. `pnpm install && pnpm format && pnpm check && pnpm build` — tất cả xanh.
9. `gh pr create` với title `feat(web): replace landing placeholders with real Skein screenshots`, KHÔNG mark ready-for-review, để DRAFT.
10. In: `PHASE_2B_DONE: <PR URL>`

Nếu stuck: `/ak:advise` gọi kongming, báo counsel lại cho PM.

## Kongming checkpoint (PM run)

**After 2A escort brief drafted, before maintainer runs the escort:** PM asks kongming to review the escort brief for gaps that could brick the maintainer's setup. Pass: brief content, existing migration code paths (`MigrationManager.swift`), the specific question: "What migration failure modes are not covered by the 4 verification checks, and what should the escort brief add?"
