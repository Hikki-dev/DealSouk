# Codebase Map

> Token-saving reference. Answer "where does X live?" from here instead of grepping
> the repo. One line per file. Last verified: **2026-06-18**.
> Read [AGENT_HANDOFF.md](AGENT_HANDOFF.md) first; task list is in
> [OUTSTANDING_WORK.md](OUTSTANDING_WORK.md).

## Top-level layout

```
backend/            Express + TypeScript + Prisma API (entry: src/index.ts)
lib/                Flutter client (shopper app + admin web console)
firebase/           Firebase Storage security rules
services/           malware-scanner/ — ClamAV Cloud Run service (NFR-10)
docs/               Documentation (this folder)
.github/workflows/  CI: android-internal.yml, ios-internal.yml
scripts/            secret_scan.py and tooling
```

Build/run/test commands and dev boundaries: **[AGENTS.md](../AGENTS.md)**.

---

## Backend (`backend/src/`, ~4.5k LOC)

**Entry & config**
- `index.ts` — Express app: helmet, compression, CORS (`isCorsOriginAllowed`),
  route mounting, global error handler, exports the shared `prisma` client.
- `config/constants.ts` — shared time windows (`PRICE_FRESHNESS_MS`, `REQUEST_EXPIRY_MS`,
  `STORE_STALE_MS`, `startOfToday()`). **Prefer adding new magic numbers here.**
- `config/env.ts` — environment variable access.

**Middleware (`middleware/`)**
- `auth.ts` — `requireAuth` (verifies Firebase token w/ revocation check + loads User,
  updates `lastActiveAt`), `requireAdmin`, `requireEmailVerified`, `AuthRequest` type.
- `rateLimits.ts` — `authenticatedRateLimit`, submission/request/admin limiters (Redis-backed).

**Routes (`routes/`)** — handler counts in parens
- `admin/` (dir) — **R2 done (2026-06-18):** the former 1431-line `admin.ts` is now
  `admin/index.ts` (auth-gated mount: `requireAuth`+`requireAdmin`, composes the
  sub-routers), `admin/shared.ts` (validation helpers, constants, write limiter),
  `admin/moderation.ts` (queue, submission approve/reject/edit, user warn/suspend/ban),
  `admin/operations.ts` (settings, vouchers, analytics, exports, map-data),
  `admin/catalog.ts` (products + users CRUD). Mounted at `/admin` via `routes/admin`.
- `config.ts` (1) — public `GET /config`: exposes `tokensPerLevel`, `maxLevel`,
  `priceFreshnessHours` so the Flutter client doesn't re-hardcode them (R4).
- `profile.ts` (10) — current user, profile edit, cart sync, FCM token, account deletion.
- `requests.ts` (5) — price request board, create/cancel, lazy expiry + refund.
- `submissions.ts` (4) — create price submission, feed, flag, validation (FR-32/34).
- `products.ts` (4) — search, detail, 90-day price history (reads `price_history_daily`).
- `stores.ts` (3) — list, nearby (bounding-box + batched queries), store prices.
- `auth.ts` (1) — `/auth/verify`: verify token + upsert User; **encrypts phoneNumber**.
- `leaderboard.ts` (1) — monthly/all-time board + per-user rank (cached 60s).
- `challenges.ts` (1) — daily challenge (upsert by date).
- `uploads.ts` (1) — signed-URL/proxy upload to Firebase Storage; per-type size caps.
- `translate.ts` (1) — Google Translate proxy.
- `logos.ts` (1) — store-logo/favicon proxy.

**Services (`services/`)**
- `tokenEngine.ts` — reward/decay math, `awardTokens`, `spendTokens` (atomic),
  `createTokenLedgerEntry` (per-user hash chain), `verifyTokenLedgerChain`,
  `recalculateAccuracyRating`, `runApprovalEffects`, monthly rank.
- `storageHelpers.ts` — `deleteSubmissionProofs` / `deleteStorageFileByUrl`
  (Firebase-hostname gated), `validateProofImage` (Anthropic Vision content check —
  fail-open, background, NOT malware scanning).
- `maintenance.ts` — cron jobs: `expireStaleSubmissions`, request expiry+refund,
  `clearElapsedSuspensions`, refresh of `price_history_daily` materialized view.
- `encryption.ts` — AES-256 `encrypt`/`decrypt`; throws at startup if
  `DATABASE_ENCRYPTION_KEY` is missing.
- `emailService.ts` — SMTP w/ masked-recipient console fallback in production.
- `fcmNotifier.ts` — Firebase Cloud Messaging push send.
- `redis.ts` — Redis client (rate limiters + caches).
- `adminAudit.ts` — records admin actions (`AdminUserAction`).
- `pdfService.ts` — PDF export generation.

**Schema (`prisma/schema.prisma`)** — models:
`User, Store, Product, PriceSubmission, SubmissionFlag, TokenTransaction,
VoucherRequest, VoucherInventory, PriceRequest, Badge, UserBadge, AdminSettings,
AdminUserAction, CartItem, DailyChallenge, UserDailyChallenge`.
Note: `price_history_daily` is a **materialized view** (migration
`20260613150000_price_history_rollup`), not a Prisma model — TimescaleDB substitute
(deviation D2).

---

## Flutter client (`lib/`, ~31k LOC)

**App shell (`app/`)**
- `app.dart` — `MaterialApp.router`, theme, FCM foreground banner wiring
  (⚠ orphaned navigator key — task B1).
- `router.dart` — `routerProvider` (GoRouter) + `_AuthChangeNotifier` (auth-driven
  redirect refresh). Owns the real root navigator key (`_rootKey`).
- `route_guard.dart` — `resolveRouteRedirect` (guest/auth/admin gating).

**Core (`core/`)**
- `network/` — `api_client.dart` (HTTPS-enforced base URL, 401 refresh-retry),
  `storage_service.dart` (photo capture/upload), `fcm_service.dart`.
- `offline/` — offline submission queue (SharedPreferences persistence + replay).
- `util/` — `geo_utils.dart` (`haversineKm`; **add shared distance/format helpers here** — R3).
- `widgets/` — `souk_widgets.dart` (`SoukPrice`, cards), `store_logo_avatar.dart`,
  `avatar_image.dart`.
- `theme/` — design tokens (forest green #0C3B2E + lime + cream, scallop trims).
- `localization/`, plus `lib/l10n/app_en.arb` & `app_ar.arb` — **all user-facing
  strings belong here** (NFR-25).

**Features (`features/<name>/presentation|domain|data`)**
- `auth/` — welcome/OTP/social sign-in; `auth_service.dart`, `auth_providers.dart`
  (`AuthNotifier` — subscription cancelled via `ref.onDispose`).
- `home/` — `home_screen.dart` (**~2,588 lines**): feed, freshness filter, carousel,
  home-area/location bootstrap. Split candidate.
- `products/` — search, detail, barcode scan; `product.dart` model + providers.
- `stores/` — `store_screen.dart` (**~1,799 lines**): store list + map; `store_price.dart`.
- `cart/` — best-price basket logic.
- `submissions/` — `submit_price_screen.dart` (**~1,404 lines**): live token estimate.
- `requests/` — price request board.
- `tokens/`, `leaderboard/` — token balance UI, ranking.
- `profile/` — profile/settings, account deletion.
- `admin/` — `admin_screen.dart` (**~4,315 lines**, one State class): admin panels.
  **R1 partial (2026-06-18):** shared builders extracted to
  `admin/presentation/widgets/admin_panel_widgets.dart` (`adminStatCard`,
  `adminAnalyticsSection`, `adminAnalyticsRow`); the Analytics panel lifted to
  `admin/presentation/panels/analytics_panel.dart` (`AnalyticsPanel`). Map/settings/
  vouchers/products-CRUD/users-CRUD panels remain in State (entangled — by design).
- `saved/` — `presentation/saved_providers.dart` (`savedProductsProvider`, persisted
  product-id set via SharedPreferences) + `saved_screen.dart` (`SavedScreen`, `/saved`
  route). G3 / US-10: quick-access list distinct from the cart; toggled by the
  product-detail heart; home/search bookmark icon links here.
- `legal/` — privacy policy / terms screens.

---

## Key cross-cutting flows (which files to touch)

- **Auth & redirect:** `auth_service.dart` → `auth_providers.dart` → `router.dart` +
  `route_guard.dart`; backend `middleware/auth.ts` + `routes/auth.ts`.
- **Price submission:** `submit_price_screen.dart` → `storage_service.dart` (photo) →
  `uploads.ts` → `submissions.ts` (validate, create) → `tokenEngine.ts` (reward) →
  `storageHelpers.ts` (`validateProofImage` background).
- **Token ledger:** all earn/spend must go through `tokenEngine.ts`
  (`awardTokens`/`spendTokens` + `createTokenLedgerEntry`). Direct `tokenBalance`
  writes bypass the audit chain — see task S1.
- **Moderation:** `admin.ts` (queue/approve/reject) → `tokenEngine.runApprovalEffects` +
  `adminAudit.ts`; flags via `submissions.ts` flag route → auto-hide at 3.
- **Best-price cart:** `products` + `stores` data → `cart/` logic; backend `stores.ts`
  `/nearby` + `products.ts` search.
- **Maintenance/expiry:** `services/maintenance.ts` cron + lazy paths in
  `requests.ts` / `submissions.ts`.
