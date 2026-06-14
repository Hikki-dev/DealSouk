# DealSouk — Full Manual Test Plan (A–Z)

**Purpose:** Hand this to a developer/QA to verify every feature works end-to-end against the real backend (no hardcoded data). Each step lists the **action** and the **expected result**. Check the box when it passes; note failures inline.

**Branch under test:** `stabilize/mvp-audit`
**Live backend:** `https://dealsouk.onrender.com`
**Live admin web:** `https://deal-souk.vercel.app`

---

## 0. Prerequisites (do these first)

| # | Action | Expected |
|---|--------|----------|
| 0.1 | Hit `https://dealsouk.onrender.com/health` in a browser | Returns `200 OK`. (Free-tier Render sleeps after ~15 min; first hit may take ~50s. The `keep-warm` GitHub Action pings it every 10 min.) |
| 0.2 | Confirm `keep-warm` workflow is enabled in GitHub → Actions | Runs every ~10 min; backend stays awake |
| 0.3 | Build the **consumer** app: `flutter run --dart-define=API_BASE_URL=https://dealsouk.onrender.com` | App launches to the Welcome screen (shopper mode) |
| 0.4 | For **admin web**: open `https://deal-souk.vercel.app` | Loads the admin Welcome screen ("Review supermarket prices shared by shoppers") |
| 0.5 | Grant an admin account: sign in once on the admin web, then run `cd backend && npm run admin:set -- --email YOUR_EMAIL --admin` against the prod DB | Prints `... admin=true` |
| 0.6 | **Firebase Console → Authentication → Settings → Authorized domains** includes `deal-souk.vercel.app` | Present (required for web Google login) |

---

## 1. Authentication (FR-01, FR-02)

| # | Action | Expected |
|---|--------|----------|
| 1.1 | Welcome → **Sign in with Phone** → enter a valid UAE number | OTP SMS arrives; code field is **dark text on white** (readable) |
| 1.2 | Enter the OTP | Lands on Home feed; a welcome token bonus is granted (check Profile balance) |
| 1.3 | Sign out → **Continue with Google** (mobile) | Google account picker → returns signed in |
| 1.4 | Sign out → **Continue with Google** (web admin) | Google popup → **no `invalid_client` error** → returns signed in |
| 1.5 | **Sign in with Apple** (iOS only) | Apple sheet → returns signed in |
| 1.6 | As a **non-admin** user, open the admin web | Shows **Unauthorized** screen (not the console) |
| 1.7 | As an **admin** user, open the admin web | Shows the **Admin console** (Audit Queue / Fraud Filter / Issue Tokens) |
| 1.8 | Privacy consent: on first shopper sign-in, the privacy checkbox is required | Cannot proceed without agreeing (shopper mode only; admin mode skips it) |

---

## 2. Home feed & discovery (UI-01)

| # | Action | Expected |
|---|--------|----------|
| 2.1 | Open Home | Real price submissions load from the backend (not hardcoded) |
| 2.2 | Tap freshness chips: **All / Under 6h / Under 24h / Under 72h** | List filters by submission age |
| 2.3 | Pull to refresh | Feed reloads from backend |
| 2.4 | Search a product (e.g. "milk") | Results from `/products/search` |
| 2.5 | Turn off network, reopen Home | Graceful empty/error state — **no fake data** |

---

## 3. Store map (flutter_map / OpenStreetMap)

| # | Action | Expected |
|---|--------|----------|
| 3.1 | Open the **Map** tab | Map centers on Dubai; loads **real backend stores** (~14), each pin showing the **chain logo** (Carrefour, Lulu, Spinneys, etc.) |
| 3.2 | Logos render | Real brand logos (bundled assets) — not blank squares, not letter circles |
| 3.3 | Grant location while in Dubai | Map pans to your location; stores refetch around you |
| 3.4 | Deny location | Stores still load (Dubai-center fetch) — map is **not empty** |
| 3.5 | Tap a store pin / list row → **View Prices** | Bottom sheet opens with that store's **real fresh (<72h) approved** prices |
| 3.6 | Tap a store with no fresh prices | Shows localized **"No prices yet"** empty state — **no fake "Updated 2h ago" items** |
| 3.7 | Filter by chain chip (Carrefour, Lulu, …) | List narrows to that chain |

---

## 4. Product detail & price history (PRD §13.3 TimescaleDB)

| # | Action | Expected |
|---|--------|----------|
| 4.1 | Tap a product | Detail screen with current best price + store |
| 4.2 | View **price history** chart | Trend from `/products/:id/history` (TimescaleDB `time_bucket` rollup) |
| 4.3 | "Also at" / next-cheapest options shown | Lists other stores' prices for the same product |

---

## 5. Submit a price (FR token economy, UI-04, UI-05)

| # | Action | Expected |
|---|--------|----------|
| 5.1 | Tap **Submit** | Form: product, store, price (AED, 2 decimals), receipt toggle |
| 5.2 | Fill fields | **Live token estimate** updates as you type |
| 5.3 | Toggle **receipt attached** | Estimate increases (1.5× multiplier → 15 vs 10 base tokens) |
| 5.4 | Submit without receipt | Success; tokens awarded; appears in feed (auto-approved if you're a trusted sourcer, else pending) |
| 5.5 | Submit with a receipt photo | Photo uploads to Firebase Storage; passes EXIF strip + malware scan (Cloud Run) |
| 5.6 | Hit the **daily submission cap** | Further submissions blocked with a clear message |
| 5.7 | Verify the submission landed in the DB | Appears in admin **Audit Queue** (if pending) or in the store's price list (if approved) |

---

## 6. Offline mode (NFR-22)

| # | Action | Expected |
|---|--------|----------|
| 6.1 | Enable airplane mode | App still usable for cached views |
| 6.2 | Submit a price while offline | UI confirms it's **queued** (not lost) |
| 6.3 | Re-enable network | Queue **auto-flushes**; submission reaches the backend |
| 6.4 | Force-quit offline with a queued item, relaunch online | Pending item flushes on next connection |

---

## 7. Cart & best-price (UI-02)

| # | Action | Expected |
|---|--------|----------|
| 7.1 | Add several products to cart | Cart shows each item's **best price** |
| 7.2 | Each item shows **"Also at"** next-cheapest store | Present |
| 7.3 | Cart computes the **cheapest complete basket** | Total reflects optimal store split |
| 7.4 | A cart item's live price drops below price-at-add (FR-24) | In-app **price-drop banner** appears |

---

## 8. Tokens, requests & gamification (FR-44–FR-50)

| # | Action | Expected |
|---|--------|----------|
| 8.1 | Open **Leaderboard & Tokens** | Monthly top 10; **your rank always visible** |
| 8.2 | **Hall of Fame** | Previous month's top 3 shown |
| 8.3 | Token balance | Matches your earned/spent ledger |
| 8.4 | Create a **price request** (Request Board) | Costs 10 tokens; balance decreases |
| 8.5 | Let a request expire (or simulate) | Bounty tokens **refunded** (FR-29) |
| 8.6 | Get a submission approved that changes your rank | Rank-change **push notification** (FR-50, Android/FCM) |

---

## 9. Profile, localization & accessibility (NFR-25, NFR-17)

| # | Action | Expected |
|---|--------|----------|
| 9.1 | Open **Profile** | Name, balance, transactions, settings |
| 9.2 | Edit display name | Persists to backend |
| 9.3 | Toggle language **EN → عربى** | **All app text** switches to Arabic (not just layout); layout flips **RTL**; back/chevron icons mirror |
| 9.4 | Tab through with a screen reader (TalkBack/VoiceOver) | Bottom-nav items and icon buttons have labels |
| 9.5 | Touch targets | Min 44px (buttons are comfortably tappable) |
| 9.6 | **Delete account** (NFR-14) | Firebase user deleted + PII cleared; signed out |

---

## 10. Admin console — web only (FR-36)

| # | Action | Expected |
|---|--------|----------|
| 10.1 | **Audit Queue** | Lists pending submissions |
| 10.2 | **Approve** a submission | Status → approved; tokens awarded; appears in shopper feed/store prices |
| 10.3 | **Reject** a submission | Status → rejected; no tokens; hidden from feed |
| 10.4 | **Edit** a submission's price | Saved value reflected |
| 10.5 | **Fraud Filter** | A submission with ≥3 unique flags is **auto-hidden** |
| 10.6 | **Issue Tokens** | Manual token grant updates the user's balance + ledger |
| 10.7 | All `/admin/*` calls require admin role | A non-admin token is rejected by backend middleware |

---

## 11. Security & infra spot-checks

| # | Action | Expected |
|---|--------|----------|
| 11.1 | Inspect network calls | All over **HTTPS**; release build refuses non-HTTPS `API_BASE_URL` |
| 11.2 | Phone numbers in DB | **Encrypted at rest** (AES-256-CBC) |
| 11.3 | Render logs after deploy | `[redis] client initialised …` (rate limiters/cache Redis-backed) |
| 11.4 | Hammer an endpoint past the rate limit | `429 Too Many Requests` |
| 11.5 | No secrets in repo | `python3 scripts/secret_scan.py` passes |

---

## 12. Build verification (CI artifacts)

| # | Action | Expected |
|---|--------|----------|
| 12.1 | GitHub Actions → **Android Internal APK** | Produces **DealSouk-Shopper.apk** (consumer) + **DealSouk-Admin.apk** |
| 12.2 | GitHub Actions → **iOS Internal Build** | Produces unsigned consumer iOS build |
| 12.3 | GitHub Actions → **Admin Web Build** | Produces admin web bundle (`ADMIN_MODE=true`) |
| 12.4 | Install **Shopper APK** | Opens in consumer mode (shopper tabs, no admin) |
| 12.5 | Open **deal-souk.vercel.app** | Admin-only console |

---

## Known limitations (not bugs)

- **Cold start:** if the `keep-warm` action is paused, the first request after ~15 min idle takes ~50s. Warm with `/health` before demos.
- **APNs (iOS push):** requires Apple Developer Program enrollment — not yet configured. FCM (Android push) works.
- **Data residency:** backend DB is on Neon `aws-us-east-1`; PRD prefers UAE/GCP `me-central1` — pending legal sign-off or migration.
- **Arabic copy:** machine-translated (Modern Standard Arabic), not yet reviewed by a native speaker.

---

## Sign-off

| Tester | Date | Sections passed | Failures / notes |
|--------|------|-----------------|------------------|
|        |      |                 |                  |
