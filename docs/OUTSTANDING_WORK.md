# Outstanding Work — Backlog

> The live task list for DealSouk. Every known issue and improvement, each with a stable
> ID, file:line anchor, fix, and acceptance check. Work items in **phase order**.
> Compiled from the 2026-06-16 four-dimension audit (security / correctness / performance
> / readability) cross-referenced against `docs/PRD_TEXT.txt`.
>
> **Before editing:** grep the quoted symbol to confirm the current line — anchors drift,
> files don't. **After finishing:** flip the checkbox and add a one-line note (commit SHA).
> New finding? Add it here with the next free ID; don't start a parallel doc.

**Status legend:** `[ ]` open · `[~]` in progress · `[x]` done · `[!]` blocked / needs owner decision

**Severity:** 🔴 critical · 🟠 high · 🟡 medium · 🟢 low

---

## 📌 Status banner — updated 2026-06-18 (read this first)

All of this session's scoped work is **done, merged to `main` (`c9b87b7`), and live on
Render** (Frankfurt DB). Verified: backend build + **41 Jest**, flutter analyze + **31
tests**, secret scan clean.

**Closed this session:** Sec#3 (Neon→Frankfurt migration **+ live cutover**) ·
NFR-08 session expiry (was already implemented; verified) · **B1 B2 B3 B5 B9** ·
**P4** · **G1** (Sentry) · **G3** (saved-items list) · **R1 R2 R3 R4 R5** · **D1–D3**
documented. Plus Phase-1 security **S1–S8** (done 2026-06-16) and the 49-commit
`main` merge reconciliation.

**Still OPEN (out of this session's scope — pick these next):**
- 🟠 **B4** — duplicate/daily-cap TOCTOU (needs a migration / serializable txn).
- 🟠 **P1 P2 P3** — N+1 in product search, missing composite indexes, `/admin/map-data`
  full scan. 🟡 **P5 P6 P7** perf.
- 🟢 **B7 B8** — admin dialog controller disposal; FCM-token-before-auth.
- 🟢 **G2** (Amplitude) · 🟢 **G4** (Twilio OTP fallback) — deferrable.
- **Tails of closed items:** B6 (welcome-OTP / product-detail strings), P4 (leaderboard +
  admin `Image.network`), §10 UI-02/03 + NFR-17/18/19, R1 (map/settings/vouchers/CRUD
  panels still in admin State by design), R4 (wire Flutter leaderboard to `/config`).

**Owner-only (no code):** 🔴 **GitHub Actions billing** (fails ALL CI runs incl. ~18
Dependabot PRs) · rotate the Render API key (pasted in chat 2026-06-18) · PDPL + PM
sign-off (D1–D4). See [AGENT_HANDOFF.md](AGENT_HANDOFF.md) "Where we left off".

> Checkboxes below are from the 2026-06-16 audit; this banner is the authoritative
> current state. Trust the banner where they disagree.

---

## Phase 1 — Security & compliance (do first; all small, surgical)

- [x] **S1** 🔴 — Admin can write `tokenBalance` directly, bypassing the audit ledger.  
  _Done 2026-06-16: admin user create/update now records balance deltas through `TokenTransaction`; backend Jest/build pass._
  - **Where:** `backend/src/routes/admin.ts` — POST `/users` (~:1048), PUT `/users/:id` (~:1082).
  - **Problem:** Direct `tokenBalance` writes never create a `TokenTransaction`, so balance
    desyncs from the hash-chained ledger and is invisible to `verifyTokenLedgerChain`.
  - **PRD:** FR-42 (token history must be fully auditable).
  - **Fix:** Route all balance changes through `awardTokens`/`spendTokens` (ledger-backed);
    remove `tokenBalance` from the user create/update payloads.
  - **Accept:** Adjusting a balance via admin produces a matching `TokenTransaction`;
    `verifyTokenLedgerChain` still passes. Add a backend test.

- [x] **S2** 🟠 — Admin path stores `phoneNumber` in plaintext (PII at rest).  
  _Done 2026-06-16: admin writes encrypt phone numbers, reads serialize decrypted values, encrypted-column substring search removed._
  - **Where:** `backend/src/routes/admin.ts:1045` (create) & `:1079` (update); contrast the
    shopper path `backend/src/routes/auth.ts:32` which calls `encrypt()`.
  - **Problem:** Admin-created/updated users get unencrypted phone numbers; also the admin
    search `phoneNumber: { contains: q }` (~:991) can never match the encrypted column.
  - **PRD:** NFR-07 (all PII at rest AES-256), §15.1 PDPL. **Also fixes the false claim in
    `STATUS.md`.**
  - **Fix:** `encrypt()` on write in admin.ts; `decrypt()` on read in admin responses (or omit
    the field); drop substring search over the encrypted column.
  - **Accept:** Phone written via admin is ciphertext in DB; round-trips through decrypt on read.

- [x] **S3** 🟠 — SSRF gate uses substring hostname match.  
  _Done 2026-06-16: Firebase Storage parser now requires exact host and has look-alike-host coverage._
  - **Where:** `backend/src/services/storageHelpers.ts:16` —
    `parsed.hostname.includes('firebasestorage.googleapis.com')`.
  - **Problem:** `firebasestorage.googleapis.com.attacker.tld` passes; this gate decides which
    URLs get fetched by `validateProofImage` (→ Anthropic) and which files get deleted.
  - **Fix:** Exact equality: `parsed.hostname === 'firebasestorage.googleapis.com'`
    (submissions.ts already uses `===` — match it).
  - **Accept:** A look-alike host returns `null`/rejected; legit Firebase URL still parses.

- [x] **S4** 🟠 — Admin write routes accept unvalidated input.  
  _Done 2026-06-16: admin submission/product/user/settings writes validate bounds, shapes, and FK existence._
  - **Where:** `backend/src/routes/admin.ts` — PATCH submission (~:192–221), products CRUD
    (~:874–941), users create/update (~:1025–1094).
  - **Problem:** No bounds/format checks on `priceAed` (NaN/negative/huge), `productId`/`storeId`
    existence, `displayName`/`imageUrl`/`barcode` length & shape → stored-XSS into admin
    console/exports and unhandled P2003 → 500.
  - **Fix:** Mirror the validation already in `profile.ts`/`submissions.ts`; wrap FK writes in
    try/catch returning 400.
  - **Accept:** Invalid price/FK/oversized string returns 400, not 500 or a corrupt row.

- [x] **S5** 🟡 — `/auth/verify` skips token revocation check.  
  _Done 2026-06-16: `/auth/verify` calls `verifyIdToken(token, true)` with Jest coverage._
  - **Where:** `backend/src/routes/auth.ts:25` uses `verifyIdToken(token)`; `middleware/auth.ts`
    uses `verifyIdToken(token, true)`.
  - **Fix:** Pass `true` to check revocation (or document why verify is exempt).
  - **Accept:** A revoked token no longer returns a profile from `/auth/verify`.

- [x] **S6** 🟡 — Full stack traces logged in production.  
  _Done 2026-06-16: production error handler logs only error name/message; dev keeps stack traces._
  - **Where:** `backend/src/index.ts:169` `console.error(err.stack)`.
  - **Problem:** Prisma errors can carry field values (PII) into Render logs.
  - **Fix:** In production log `err.name`/`err.message` (redacted); keep full stack in dev only.

- [x] **S7** 🟡 — Outbound proxy fetches have no timeout.  
  _Done 2026-06-16: logo and translate proxy fetches now use `AbortSignal.timeout`._
  - **Where:** `backend/src/routes/logos.ts:51`, `backend/src/routes/translate.ts:47`.
  - **Fix:** Add `AbortSignal.timeout(...)` (the proof-validation path already has an 8s guard).

- [x] **S8** 🟢 — `AdminSettings` PATCH accepts unbounded numbers.  
  _Done 2026-06-16: settings writes clamp token, voucher, cap, request-cost, and decay ranges._
  - **Where:** `backend/src/routes/admin.ts` settings handler (~:331–359).
  - **Problem:** `decayFactor > 1` would *increase* duplicate rewards; negative `tokenEarnRate`
    breaks rewards.
  - **Fix:** Clamp settings to sane ranges.

---

## Phase 2 — Correctness / broken features

- [x] **B1** 🟠 — Foreground push banner never displays (orphaned navigator key).  
  _Done 2026-06-16: app now uses the exported GoRouter root navigator key for foreground FCM banners._
  - **Where:** `lib/app/app.dart:20,29` reads `_navigatorKey.currentContext`, but the router uses
    its own `_rootKey` (`lib/app/router.dart:22,37`), so the key is never attached.
  - **PRD:** FR-50 / US-17 (rank-change), FR-28 (request-fulfilled) in-app notifications.
  - **Fix:** Export `_rootKey` from router.dart and use it in the FCM callback (or wire
    `_navigatorKey` into the router config). ~2-line fix.
  - **Accept:** A foreground FCM message shows the in-app banner.

- [x] **B2** 🟠 — `setState` after `await` without `mounted` in the location flow.  
  _Done 2026-06-16: post-await location flow state/map updates now check `mounted`._
  - **Where:** `lib/features/stores/presentation/store_screen.dart` ~:129,134,143,148,154,164.
  - **Problem:** Leaving the Stores tab mid-locate throws "setState() called after dispose()".
  - **Fix:** Guard each post-await `setState` with `if (!mounted) return;`.

- [ ] **B3** 🟠 — Network failure is indistinguishable from "no results".
  - **Where:** `lib/features/products/presentation/products_providers.dart:10–18` (`catch (_) {}`
    → empty list); consumers `home_screen.dart:779`, `search_screen.dart:293`.
  - **Problem:** On Render cold-start the app looks empty with no retry; bad first-run UX.
  - **Fix:** Model products as `AsyncValue<List<Product>>` (or add an error flag) and render an
    error+retry state distinct from empty.

- [ ] **B4** 🟡 — Duplicate / daily submission cap is check-then-write (TOCTOU).
  - **Where:** `backend/src/routes/submissions.ts:191–220` (daily cap ~:191, dup check ~:205).
  - **Problem:** Concurrent requests can both pass the count/findFirst then both insert,
    defeating the anti-farming cap (FR-34, NFR-09).
  - **Fix:** Add a partial unique index / `@@unique(sourcerId, productId, storeId, day-bucket)`
    or do count+create in a serializable transaction. (Needs a migration.)
  - **Accept:** Two parallel identical submissions → one succeeds, one rejected.

- [ ] **B5** 🟡 — Freshness sort/filter parses an English display string back into minutes.
  - **Where:** `lib/features/products/domain/product.dart:42–52` discards numeric `hoursAgo`;
    `lib/features/home/presentation/home_screen.dart:~1180` regex-parses the label.
  - **Problem:** Breaks in Arabic and is fragile to copy changes.
  - **PRD:** NFR-20 (RTL), UI-01 (freshness filter).
  - **Fix:** Keep numeric `hoursAgo` (and/or a DateTime) on the model; sort/filter on the number;
    format the label at the widget layer via `AppLocalizations`.

- [ ] **B6** 🟡 — Hardcoded English user-facing strings bypass localization.
  - **Where:** `barcode_scan_screen.dart:39,71`; `welcome_screen.dart:216–219` (inline EN/AR OTP
    error); `product_detail_screen.dart:92–95`; freshness labels in
    `product.dart:45–51` & `store_price.dart:30–34`.
  - **PRD:** NFR-25 (single shared localization file), NFR-20.
  - **Fix:** Move to `lib/l10n/app_en.arb` + `app_ar.arb`; resolve via `AppLocalizations`.

- [ ] **B7** 🟢 — Admin dialog `TextEditingController`s never disposed.
  - **Where:** `lib/features/admin/presentation/admin_screen.dart` dialog helpers
    (~:1654,1814,2292,2847,3718,4204).
  - **Fix:** Dispose on dialog close (stateful dialog body or in the `.then`). Admin-web only, minor.

- [ ] **B8** 🟢 — FCM token registered before auth completes → silent 401.
  - **Where:** `lib/core/network/fcm_service.dart:15` (POSTs `/profile/me/fcm-token` on first frame).
  - **Fix:** Register/refresh the token after auth reaches `authenticated`.

- [x] **B9** 🟡 — Price request fulfillment could submit against a fuzzy catalog match.  
  _Done 2026-06-16: request-linked submissions now resolve the exact requested product name, create a community product when needed, and award the request bounty from the actual submission flow._
  - **Where:** `lib/features/submissions/presentation/submit_price_screen.dart`, `backend/src/routes/submissions.ts`.
  - **Problem:** A request for "Milk" could auto-select the catalog item "Whole Milk"; `/requests/:id/fulfill`
    also allowed a request to be marked fulfilled without being tied to the submitted price row.
  - **Fix:** Only auto-select exact product-name matches, expose an exact typed-product option, and pass
    `requestId` through `/submissions` so the backend creates/reuses the exact requested product before
    fulfilling the request.
  - **Accept:** Submitting a price for a "Milk" request records the submission against product "Milk", not
    "Whole Milk"; backend Jest covers this case.

---

## Phase 3 — Performance (NFR-02 < 1.5s search, NFR-05 scale)

- [ ] **P1** 🟠 — N+1 in product search (1 + up to 50 per-product price queries).
  - **Where:** `backend/src/routes/products.ts:41–58` (per-product `findFirst` inside `Promise.all`).
  - **Fix:** One `groupBy(['productId'], _min: priceAed, where productId in […])` + one batched
    store `findMany`; join in memory.
  - **Accept:** `/products/search` issues O(1) queries regardless of result count.

- [ ] **P2** 🟠 — Missing composite DB indexes on the hottest paths.
  - **Where:** `backend/prisma/schema.prisma` (model `PriceSubmission`).
  - **Fix (one migration):** add `@@index([status, expiresAt])`,
    `@@index([storeId, status, submittedAt])`, `@@index([productId, status, submittedAt])`.
  - **Accept:** `EXPLAIN` on the expiry sweep and per-store/product fresh-approved reads uses
    an index range scan, not a seq scan.

- [ ] **P3** 🟠 — `/admin/map-data` loads every approved submission row to count them.
  - **Where:** `backend/src/routes/admin.ts:717–734`.
  - **Fix:** `groupBy(['storeId'], _count)` over approved submissions + separate `store.findMany`.

- [ ] **P4** 🟠 — Images have no disk cache or resize.
  - **Where:** `lib/core/widgets/souk_widgets.dart:363`, `store_logo_avatar.dart:124`,
    `avatar_image.dart:15`, `leaderboard_screen.dart:285`; no `cached_network_image` in pubspec.
  - **Fix:** Add `cached_network_image` (disk cache) + `cacheWidth`/`memCacheWidth` sized to slot.
  - **PRD:** NFR-01 (cold start < 3s), Min storage runtime cache < 150 MB.

- [ ] **P5** 🟡 — Home feed re-filters/re-sorts the whole catalog every build (regex in comparator).
  - **Where:** `lib/features/home/presentation/home_screen.dart:247–267`.
  - **Fix:** Precompute freshness minutes once per product (ties into B5); memoize the
    filtered/sorted list keyed by query+filter.

- [ ] **P6** 🟡 — `/requests/board` does a per-row expiry update loop on a public GET;
  `/admin/queue` is unpaginated with full relations.
  - **Where:** `backend/src/routes/requests.ts:26–42`; `backend/src/routes/admin.ts:39–43`.
  - **Fix:** Move request expiry to the existing maintenance cron (keep the read pure / batch the
    flip); add `take`/`skip` + `select` to the admin queue.

- [ ] **P7** 🟢 — Misc: leaderboard per-user rank uses unbounded `groupBy`
  (`leaderboard.ts:34–38`, `tokenEngine.ts` rank); `adminSettings.findUnique({id:1})` refetched
  multiple times per submission flow (cacheable); `verifyTokenLedgerChain` loads the whole ledger
  into memory (paginate). Low impact at MVP scale.

---

## Phase 4 — Deviations & gaps needing an OWNER DECISION (`[!]`)

- [!] **D1** — Maps engine: PRD mandates **Google Maps SDK** (FR-08, §12, §13); app ships
  `flutter_map`/OpenStreetMap, and pubspec currently has **both** deps. AGENTS.md says OSM is the
  deliberate MVP choice. **Action:** confirm which engine actually renders and record the
  divergence (NFR-24 requires written PM sign-off). Do NOT switch engines without that sign-off.

- [!] **D2** — Time-series store: PRD mandates **TimescaleDB**; substituted with a
  `price_history_daily` **materialized view** (migration `20260613150000_price_history_rollup`)
  because TimescaleDB is unavailable on Neon. Works for FR-16/FR-59 at MVP scale, but
  `REFRESH MATERIALIZED VIEW` is a full recompute and won't scale to NFR-05. **Action:** accept as
  documented post-MVP debt, or plan a Timescale-capable host.

- [!] **D3** — Admin dashboard: PRD recommends **Metabase**; built as Flutter Web
  (`ADMIN_MODE=true`). Satisfies the "web tool, not in the mobile app" intent (FR-57). **Action:**
  verify FR-58/59/60 (price trends, demand heatmap, sourcer-activity map) are complete enough, or
  log gaps as new tasks.

- [!] **D4** — Data residency: PRD prefers Google Cloud `me-central1` (Doha); Neon is
  `aws-us-east-1`. **Action:** legal sign-off for PDPL or migrate. (Already tracked in `STATUS.md`.)

---

## Phase 5 — Feature gaps vs PRD

- [ ] **G1** 🟠 (launch-readiness) — No crash/error monitoring. **Sentry** (PRD §12) is absent.
  Launching with zero production observability hides the very Phase-1/2 bugs. **Fix:** wire Sentry
  in the Flutter app and the Node backend.

- [ ] **G2** 🟢 — No product analytics (**Amplitude**, PRD §12). Acceptable to defer.

- [ ] **G3** 🟡 — Saved-items / quick-access list (US-10, "Should Have") appears collapsed into the
  cart (`savedCount = cartItems.length` in home/search screens); not a distinct list. **Decide:**
  defer (Should-Have) or build a real saved list.

- [ ] **G4** 🟢 — No **Twilio Verify** OTP fallback (PRD §12). Low priority — Firebase phone auth
  is primary.

---

## Phase 6 — Readability / maintainability (mechanical; verify with analyzer + tests)

- [ ] **R1** — Split `lib/features/admin/presentation/admin_screen.dart` (**~4,612 lines**, one
  State class) into per-panel `ConsumerWidget`s under `admin/presentation/panels/`. One panel at a
  time; thread shared State fields explicitly. Low risk if lifted verbatim.

- [ ] **R2** — Split `backend/src/routes/admin.ts` (**~1,174 lines, 28 routes**) into per-domain
  Express routers (`admin/submissions.ts`, `admin/vouchers.ts`, `admin/crud.ts`,
  `admin/analytics.ts`) mounted under one `adminRouter`. Handlers are independent — low risk.

- [ ] **R3** — Extract duplicated `storeDistanceKm()` + `formatDistanceKm()` + `formatAed()`
  helpers into `lib/core/util/geo_utils.dart` / a formatter. Duplicated across `home_screen.dart`,
  `submit_price_screen.dart`, `store_screen.dart`, and ~11 `'AED ' + toStringAsFixed(2)` sites.

- [ ] **R4** — Name `TOKENS_PER_LEVEL = 500`; it's hardcoded in both the backend
  (`tokenEngine.ts:~21`) and Flutter (`leaderboard_screen.dart:463,476,485,491`) — silent-drift
  hazard. Expose via API/settings so the two can't diverge.

- [ ] **R5** — Name the backend time-window magic numbers (`48*60*60*1000`, `72*…`, decay windows)
  in `config/constants.ts` following the existing `auth.ts` `*_MS` convention.

---

## Recommended order

Phase 1 (security/compliance) → B1/B2/B3 (visible breakage) → P2 then P1/P3 (scale) → B4 (needs
migration) → owner decisions D1–D4 and G1/G3 → readability sweep (R1–R5). Every Phase 1–2 item is
independently shippable and covered by the existing test suite (add tests for S1, S2, B4).
