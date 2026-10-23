# Agent Handoff — Start Here

> **You are a coding agent picking up DealSouk.** Read this file first. It tells you
> where to look, what is already true, what is still broken, and how to work here
> without re-scanning the whole codebase. Last verified: **2026-06-18**.

DealSouk is a crowd-sourced grocery price-comparison app for Dubai: a Flutter
client (shopper app + admin web console via `--dart-define=ADMIN_MODE=true`) and an
Express/TypeScript + Prisma + PostgreSQL (Neon) backend. Data sourcers submit prices
for tokens; shoppers build best-price carts. Full product spec: `docs/PRD_TEXT.txt`.

---

## ⏩ Where we left off — session 2026-06-18

**The MVP-audit backlog is fully cleared and shipped to production.** PR #19
(`stabilize/mvp-audit` → `main`) is **MERGED** (`c9b87b7`) and **live on Render**
(`/health` → `c9b87b7`).

**To resume:** `git checkout main && git pull` (main now has everything; the
`stabilize/mvp-audit` branch is merged). Then pick from "Remaining work" below.

What shipped this session (all on `main`, verified: backend build + 41 Jest, flutter
analyze + 31 tests, secret scan clean):
- **Data residency (Sec#3 / D4):** prod DB migrated Neon `us-east-1` → **`eu-central-1`
  Frankfurt** (project `dealsouk-eu` / `dark-art-33891694`) and **cut over live** —
  Render env-group `DATABASE_URL` points at the Frankfurt pooled host;
  `DATABASE_ENCRYPTION_KEY` unchanged; old us-east-1 project kept as rollback.
- **G1 Sentry** (backend + Flutter, DSN-gated, no-op without `SENTRY_DSN`).
- **B3** load error/retry states (home + search) — fixes the cold-start "looks empty" UX.
- **B5/B6** numeric freshness sort + localized home/barcode strings.
- **P4** disk-cached, slot-sized images (`cached_network_image`).
- **R2** split `admin.ts` (1431 lines) → `backend/src/routes/admin/{shared,moderation,operations,catalog,index}.ts`.
- **R1** extracted shared admin widgets + the Analytics panel (`admin_screen.dart` 4612→4315).
- **R3** shared `formatAed()`; **R4/R5** named constants + `GET /config` endpoint.
- **G3** real saved-items list (`/saved` route + persisted `savedProductsProvider` +
  product-detail heart) — distinct from the cart.
- Reconciled a 49-commit merge of `main` into the branch (B9 community-price flow ⊕
  main's ABUSE-1..7 / SSRF / email-verify hardening — both preserved).

**🔴 The ONE blocker (owner-only):** **GitHub Actions billing.** Every CI run fails
with *"recent account payments have failed or your spending limit needs to be
increased."* The job never executes — so the "Format, analyze, test, backend build"
check is red on PR #19 **and all ~18 open Dependabot PRs**. This is NOT a code failure
(everything passes locally). Fix at GitHub → Settings → Billing & plans. Until then CI
cannot gate anything; we admin-merged PR #19 past it.

**Other owner actions (no code):**
- **Rotate the Render API key** (it was pasted in chat on 2026-06-18) at
  `dashboard.render.com/u/settings`.
- **PDPL legal sign-off** for EU (Frankfurt) hosting + **PM sign-off** on deviations
  D1–D4 — see `docs/PRD_DEVIATIONS.md`.
- After Frankfurt is proven healthy for a few days, the old us-east-1 Neon project can
  be deleted.

**Render infra quick facts** (full detail: memory + `docs/NEON_FRANKFURT_CUTOVER.md`):
service `srv-d8mcdau7r5hc739khhlg`, auto-deploys `main`. Secrets (`DATABASE_URL`,
`DATABASE_ENCRYPTION_KEY`, Firebase) live in env-group **`evg-d8mc824vikkc73bmgf00`**,
not as direct service env vars. **Build command must be `npm install …` not `npm ci`**
(macOS lockfile omits Linux-only `@emnapi/*`; `npm ci` fails — corrected 2026-06-18).
The `render` MCP is configured in `.mcp.json` (set `RENDER_API_KEY` + restart to use).

---

## Read order (save tokens — read docs before grepping code)

1. **This file** — orientation, ground rules, what's stale.
2. **[CODEBASE_MAP.md](CODEBASE_MAP.md)** — where every route/service/feature lives.
3. **[OUTSTANDING_WORK.md](OUTSTANDING_WORK.md)** — the live, prioritized backlog
   (Phase 1–6 now all closed; remaining = owner actions + low-priority follow-ups).
4. **[AGENTS.md](../AGENTS.md)** — hard development boundaries + mandatory pre-commit checklist.

Reference docs: `docs/API_SPEC.md`, `docs/PRD_TRACEABILITY_MATRIX.md`,
`docs/STATUS.md`, `docs/OWNER_PRODUCTION_ACTIONS.md`, `docs/NEON_FRANKFURT_CUTOVER.md`.

---

## Ground rules (from AGENTS.md — do not violate)

- **Do not** replace `flutter_map` (OpenStreetMap) with Google Maps SDK — deferred (D1).
- **Do not** refactor to clean architecture / DDD. Keep Riverpod, go_router, Express, Prisma.
- **Do not** run `npm audit fix --force` on the backend (breaks `firebase-admin`).
- **Do not** commit `.env` / `render.env`, Firebase config files, or service-account JSON.
  Run `python3 scripts/secret_scan.py` before every commit. (`docs/` is gitignored too —
  these handoff docs are local-only working files.)
- **Pre-commit checklist (all must pass):** `python3 scripts/secret_scan.py` ·
  `dart format --set-exit-if-changed .` · `flutter analyze` · `flutter test` ·
  `cd backend && npm run build` · `cd backend && npx prisma migrate status`.

---

## What is actually true right now (verified 2026-06-18)

**Working / done** — don't redo these:
- Token economy with per-user, hash-chained, tamper-evident ledger; `spendTokens` atomic.
  **S1 done** — admin balance edits now go through the ledger.
- PII: phone numbers encrypted at rest on **both** shopper and admin paths. **S2 done.**
- Auth: Firebase phone OTP + Google + Apple Sign-In; session expiry (30d/90d) enforced.
- Trust & moderation: accuracy ratings, flag auto-hide at 3, admin queue, ABUSE-1..7 guards.
- 72h freshness + auto-expiry cron; offline submission queue (NFR-22).
- NFR-10 malware scanning via deployed ClamAV Cloud Run + EXIF stripping. (The Anthropic
  Vision call in `storageHelpers.ts` is a *separate* content check, not the malware control.)
- DB is **Frankfurt (`eu-central-1`)**; `/config` endpoint live; Sentry wired (DSN-gated).
- `flutter analyze` clean; **41 backend Jest + 31 Flutter tests pass.**

**No more stale S1/S2 claims** — both are resolved. `STATUS.md` is refreshed to match.

---

## Remaining work (all low-priority or owner-gated)

- **Owner:** GitHub Actions billing · rotate Render key · PDPL + PM sign-off (above).
- **Code follow-ups (small, optional):** B6 tail (welcome-OTP / product-detail hardcoded
  strings); P4 tail (leaderboard + admin `Image.network` not yet cached); §10 UI-02/03 +
  NFR-17/18/19 polish (`docs/UI_CONFORMANCE_S10.md`); R1 tail (map/settings/vouchers/CRUD
  panels still in the admin State by design — entangled with controllers/dialogs); wire the
  Flutter leaderboard to consume `/config` instead of a hardcoded 500.
- New findings → add to `OUTSTANDING_WORK.md` with the next ID; don't start a parallel doc.

---

## How to work a task

1. `git checkout main && git pull`. Pick from "Remaining work" or `OUTSTANDING_WORK.md`.
2. Confirm file:line by grepping the quoted symbol (anchors drift).
3. Surgical change, match style, add/extend a test where an acceptance check is listed.
4. Run the full pre-commit checklist.
5. Update `OUTSTANDING_WORK.md` / this file's "Remaining work" with a one-line note + SHA.
6. Commit on a branch (CI is billing-blocked, so coordinate merges); end with the
   `Co-Authored-By` trailer.
