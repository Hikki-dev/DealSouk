# DealSouk — Automated Testing Plan

**Goal:** A test suite that runs on every push and answers, automatically, one question: *"Is the app ready?"* It exercises every PRD requirement (FR-01–62, NFR-01–25) that can be verified without a human, and clearly marks the few that still need a human.

This is the **automation** companion to [Test%20plan.md](Test%20plan.md) (the manual hand-off checklist).

---

## 1. Definition of "ready" (exit criteria)

The app is release-ready when CI is green on all of:

1. **Backend API suite** passes (every endpoint + business rule).
2. **Flutter unit + widget tests** pass with **≥ 70% line coverage** on `lib/features/**` logic.
3. **Flutter integration tests** pass on both an Android emulator and an iOS simulator.
4. **Static gates** pass: `dart format`, `flutter analyze` (0 issues), `npm run build`, `secret_scan.py`, `prisma migrate status`.
5. **Non-functional probes** pass: cold-start < 3s (NFR-01), search < 1.5s (NFR-02), a11y scan, RTL render, rate-limit returns 429 (NFR-09).
6. **Manual-only checklist** (Section 8) signed off — the handful of things no machine can do (real SMS OTP, real Google/Apple consent, real device push, store review).

---

## 2. The test pyramid (layers + tooling)

```
        ╱╲        E2E (few)         real app ⇄ staging backend ⇄ test DB
       ╱  ╲                          tool: integration_test + patrol
      ╱----╲      Integration        full flows on emulator/simulator
     ╱      ╲                         tool: flutter integration_test, patrol
    ╱--------╲    Widget (many)       screens/widgets in isolation
   ╱          ╲                       tool: flutter_test + mocktail + network_image_mock
  ╱------------╲  Unit (most)         pure logic, Dart + backend
 ╱______________╲                     tool: flutter_test  /  Jest + Supertest
```

| Layer | Runs against | Tooling | Speed |
|-------|-------------|---------|-------|
| Dart unit | pure functions, providers | `flutter test` + `mocktail` | ms |
| Backend unit/API | Express routes + Prisma | **Jest + Supertest** on a **disposable Neon branch** | seconds |
| Widget | single screen, mocked providers | `flutter_test`, `ProviderScope` overrides, `network_image_mock` | ms–s |
| Integration | whole app on a device | `integration_test` + **patrol** (for native dialogs: permissions, OTP autofill) | minutes |
| E2E (smoke) | real staging stack | `integration_test` pointed at `dealsouk-staging.onrender.com` | minutes |

---

## 3. What exists today vs. the gap

**Exists (✅):** 20 Dart logic tests — token engine, 72h expiry, cart best-price, moderation auto-hide, leaderboard sort, route guards, Arabic smoke.

**Missing (must build):**
- ❌ **No backend test suite at all** (no Jest/Supertest). This is the biggest gap — the DB/API rules are unverified by automation.
- ❌ **No widget tests** (no screen renders verified).
- ❌ **No integration/E2E tests** (no full-flow automation).
- ❌ **No coverage gate** in CI.

---

## 4. Requirement → test coverage matrix

Legend: **U**=Dart unit · **A**=backend API · **W**=widget · **I**=integration/E2E · **M**=manual-only

### Functional
| FR | Requirement | Layer |
|----|-------------|-------|
| FR-01/02 | Phone/Apple/Google signup < 60s | I (flow), **M** (real OTP/consent) |
| FR-03–08 | Search, scan barcode, browse, categories | A (search API), W (chips/list), I |
| FR-09–16 | Store map, pins, prices per store | A (`/stores/nearby`, `/:id/prices`), W (map renders), I |
| FR-17/18 | 72h dim + auto-expire | **U (done)** + A (cutoff query) |
| FR-19–24 | Cart, best price, total basket, persist, price-drop banner | U (pricing done), A (cart persist), W (banner), I |
| FR-25–30 | Item requests, token cost, board, refund 48h | A (create/refund), U (token flow done), I |
| FR-31–36 | Submit price, token estimate, daily cap, receipt 1.5×, feed < 60s | A (submit+estimate+cap), W (estimate updates), I |
| FR-37–43 | Token balance, earn/spend, voucher threshold, ledger | A (ledger atomicity), U (done), I |
| FR-44–50 | Leaderboard, Hall of Fame, streaks, levels, badges, rank push | U (sort done), A (monthly/hallOfFame), I, **M** (real push) |
| FR-51–56 | Flagging, auto-hide ≥3, suspension, accuracy, admin edit | U (auto-hide done), A (flag/suspend/edit), I (admin) |
| FR-57–62 | Admin dashboard, trends, sourcer map, config, CSV/PDF export | A (admin endpoints + export), I (web admin) |

### Non-functional
| NFR | Requirement | Layer |
|-----|-------------|-------|
| NFR-01 | Cold start < 3s | I (timed boot probe) |
| NFR-02 | Search < 1.5s (≤500 results) | A (timed query) |
| NFR-03 | New price in feed < 60s | A (submit→feed timing) |
| NFR-04 | Map pins < 2s | I (timed) |
| NFR-05 | 50k concurrent, scale to 500k | **Load test** (k6/Artillery) — separate job |
| NFR-06 | TLS 1.3 | A (reject non-HTTPS in release — already guarded) |
| NFR-07 | PII AES-256 at rest | A (assert phone stored encrypted) |
| NFR-08 | Session expiry 30d/90d | A (token TTL) |
| NFR-09 | Rate limit 5/min submissions | A (6th call → 429) |
| NFR-10 | Photo malware/EXIF scan | A (scanner trigger) , **M** (Cloud Run verify) |
| NFR-11–15 | PDPL, no GPS stored, privacy policy, account deletion, min location | A (deletion clears PII), **M** (legal/PDPL) |
| NFR-16–20 | WCAG AA, 44px targets, Dynamic Type, a11y labels, RTL | W (a11y + semantics), I (RTL render) |
| NFR-21 | 99.9% uptime | Monitoring (keep-warm + uptime check), not unit-testable |
| NFR-22 | Offline degrade + queue | U/W (queue), I (airplane→reconnect) |
| NFR-24/25 | iOS/Android parity, single l10n file | I (run same suite on both), W (no hardcoded strings lint) |

---

## 5. Auth testing strategy (the hard part)

Auth can't fully self-test because real SMS/Google/Apple need humans. Solution: the **Firebase Auth Emulator**.

- **CI / integration:** run the Firebase Auth Emulator. Use **test phone numbers** (Firebase lets you register `+971...` → fixed OTP `123456`) so phone login is fully automated. Mint **custom tokens** via Firebase Admin to simulate Google/Apple/admin users without real consent screens.
- **Backend:** mock `admin.auth().verifyIdToken` to return a fixed decoded token, so API tests don't need live Firebase.
- **Manual-only (Section 8):** the *real* Google popup, the *real* Apple sheet, and a *real* SMS to a physical SIM. One-time human verification per release.

---

## 6. Backend API suite (highest priority — build first)

Add to `backend/`:
```
backend/
  jest.config.js
  test/
    helpers/db.ts        # spins a Neon test branch, runs prisma migrate, seeds, tears down
    helpers/auth.ts      # mocks verifyIdToken → {uid, name, ...}
    auth.test.ts         # /auth/verify: new user, admin claim, suspended
    submissions.test.ts  # create, estimate, daily cap (FR-34), receipt 1.5x (FR-35), 72h (FR-17/18)
    stores.test.ts       # nearby radius, prices freshness window
    requests.test.ts     # create costs tokens (FR-26), refund after 48h (FR-29)
    tokens.test.ts       # ledger atomicity (FR-42), voucher threshold (FR-40)
    leaderboard.test.ts  # monthly top10 + hallOfFame (FR-44/45)
    admin.test.ts        # approve/reject/edit, auto-hide ≥3 (FR-52), suspend (FR-54), config (FR-61), CSV/PDF (FR-62)
    security.test.ts     # rate limit 429 (NFR-09), non-admin blocked, phone encrypted (NFR-07)
```
- **DB:** create a throwaway Neon branch per CI run (`neonctl branches create`), point `DATABASE_URL` at it, `prisma migrate deploy`, seed, run, then `neonctl branches delete`. Isolated, real Postgres, no mocking of the DB.
- **`npm test`** = `jest --runInBand --coverage`.

---

## 7. Flutter integration/E2E suite

Add `integration_test/` driven by **patrol** (handles native permission + OTP dialogs):
```
integration_test/
  app_boot_test.dart        # NFR-01 cold start timing; lands on Welcome
  auth_flow_test.dart       # phone OTP (emulator test number) → Home
  submit_flow_test.dart     # submit price → token estimate → appears in feed (FR-31/36)
  cart_flow_test.dart       # add items → best price → total basket (FR-19/21)
  map_flow_test.dart        # map loads real stores < 2s, tap → prices (NFR-04)
  offline_flow_test.dart    # airplane → submit queued → reconnect → flushed (NFR-22)
  rtl_flow_test.dart        # switch to Arabic → assert RTL + Arabic strings (NFR-20)
  admin_web_test.dart       # (web target) admin login → approve a submission
```
Run on a matrix: Android emulator (API 33) + iOS simulator (iOS 16) → satisfies parity (NFR-24).

---

## 8. What stays MANUAL (cannot be automated)

These go in [Test%20plan.md](Test%20plan.md) for a human, once per release:
- Real **Google popup** + **Apple sheet** consent (only emulator/custom-token in CI).
- Real **SMS OTP** to a physical SIM.
- Real **device push notification** delivery (APNs/FCM) — needs Apple Developer Program.
- **Cloud Run** malware/EXIF scanner end-to-end with a real malicious sample (NFR-10).
- **Legal/PDPL** review (NFR-11).
- **App Store / Play Store** review + signing.
- Visual polish / "does it feel right" on real devices.

---

## 9. CI wiring (`.github/workflows/`)

Extend the existing `ci.yml` into parallel jobs:
```yaml
jobs:
  static:        # format, analyze, secret_scan, migrate status   (exists)
  dart-unit:     # flutter test --coverage  → upload coverage, fail < 70%
  backend-api:   # spin Neon test branch → jest --coverage → delete branch
  flutter-it:    # matrix [android-emulator, ios-simulator] → integration_test
  nfr-probes:    # timed cold-start + search + rate-limit 429 assertions
  # load test (NFR-05) runs nightly, not per-PR (k6 against staging)
```
PR is mergeable only when `static`, `dart-unit`, `backend-api` are green; `flutter-it` required before tagging a release.

---

## 10. Phased rollout (recommended order)

| Phase | Build | Why first |
|-------|-------|-----------|
| **1** | Backend API suite (Jest + Supertest + Neon test branch) | Biggest gap; verifies the DB/business rules your devs care about most. ~2–3 days. |
| **2** | Dart widget tests for the 6 core screens + coverage gate | Catches UI regressions cheaply. ~2 days. |
| **3** | Integration suite (patrol) for the 8 golden flows + Firebase Auth Emulator | Proves real end-to-end behaviour. ~3–4 days. |
| **4** | NFR probes (timing, a11y, RTL, rate-limit) + Android/iOS matrix | Closes non-functional coverage. ~2 days. |
| **5** | Nightly load test (k6) for NFR-05 | Scale validation before public launch. ~1 day. |

After Phase 1–3, a single `git push` tells you—automatically—whether the app still works end to end.

---

## 11. One-command local run (target)

```bash
# Backend
cd backend && npm test                     # Jest + Supertest on a Neon test branch

# Flutter
flutter test --coverage                    # unit + widget
patrol test                                # integration on attached device/emulator

# Full gate (what CI runs)
./scripts/ci_full.sh                        # to be added: runs all of the above + static gates
```
