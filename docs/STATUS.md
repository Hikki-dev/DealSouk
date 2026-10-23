# DealSouk Project Status

**Date**: June 18, 2026
**Active Workspace Branch**: `stabilize/mvp-audit` (Unified Base Branch)

This document serves as the single source of truth for the current development and production readiness status of the DealSouk platform.

---

## 🚀 Deployed Infrastructure & Live Systems

| Component | Provider | Live Status | Evidence / Verification |
|---|---|---|---|
| **Backend API** | Render | Deployed Live | `https://dealsouk.onrender.com/health` returns `200 OK`. |
| **Admin Web Portal** | Vercel | Deployed Live | `https://deal-souk.vercel.app` returns `200 OK`. |
| **Database** | Neon Serverless (**Frankfurt `eu-central-1`**, since 2026-06-18) | Connected & Seeded | Postgres on Neon project `dealsouk-eu` (`dark-art-33891694`). Seeded: 187 price submissions, 18 stores, 20 products, 13 badges. Old `us-east-1` project retained as rollback. See [NEON_FRANKFURT_CUTOVER.md](NEON_FRANKFURT_CUTOVER.md). |
| **Firebase Storage** | Firebase Storage | Live & Rules Deployed | Bucket storage initialized. Rules limiting uploads by user, type, and size are deployed. |
| **Upload Processing** | Firebase Functions + Cloud Run | Deployed Live | Cloud Run ClamAV scanner service is deployed to `me-central1` and wired to the Firebase Storage triggers. EXIF stripping and malware scanning are active. |

---

## 🧪 Testing & Code Health

* **Static Analysis**: `flutter analyze` runs with 0 errors, warnings, or lints.
* **Test Suite**: 31 Flutter tests + 41 backend Jest tests pass; verify critical business logic:
  * Cart pricing optimization (cheapest complete basket select)
  * Price expiry filtration (72-hour window boundary rules)
  * Token engine operations (initial welcome bonus, deduction, refund upon request expiration, rewards on approval)
  * Daily price submission limits (daily submission cap enforcement)
  * Auto-hide moderation (hidden after 3 unique flags)
  * Admin moderation queue operations (approve, reject, edit)
  * Monthly leaderboard rankings (sorting totals descending)
  * Arabic localization keys smoke test
  * Authentication and role-based client routing guards
* **Audit Checks**: `scripts/secret_scan.py` passes with zero committed secrets detected.

---

## 🔒 Hardened Security Controls

1. **Client URL Release Guard**: `api_client.dart` throws a `StateError` if `API_BASE_URL` is omitted or configured over non-HTTPS in release builds, preventing plaintext/development default leaks.
2. **Robust Route Guards**: Frontend `router.dart` uses a centralized `route_guard.dart` blocking guests and non-admin users from accessing `/admin` pages (redirecting them to `/unauthorized`).
3. **Backend Middleware Enforcement**: All backend `/admin/*` routes strictly verify authorization and administrative role permissions using the Neon/Postgres `User.isAdmin` field.
4. **Secure Token Transactions**: Token modifications are transactional and backed by a relational ledger (`TokenTransaction`). ✅ **S1 resolved (2026-06-16):** admin balance edits now route through the ledger.
5. **PII Encryption**: User phone numbers are encrypted at rest (AES-256-CBC) on **both** the shopper (`auth.ts`) and **admin** (`admin/` routes) paths. ✅ **S2 resolved (2026-06-16):** admin writes encrypt; reads decrypt.
6. **Hardened Email Console Log**: SMTP-unconfigured fallbacks suppress printing email body and mask recipient addresses in production (`NODE_ENV === 'production'`) to prevent PII leakage to system output logs.

---

## ⚠️ Public Production Blockers

These items must be resolved before releasing DealSouk to the public Apple App Store or Google Play Store:

| Priority | Area | Required Resolution |
|---|---|---|
| ✅ Done | Google/Firebase Key Restrictions | Android key restricted (package + SHA-1, 2026-06-13). iOS bundle ID + web referrer restrictions added in Google Cloud Console (2026-06-14). |
| ✅ Done | Firebase Auth Admin IAM | Backend service account granted `roles/firebaseauth.admin` (verified in IAM, 2026-06-14). |
| ✅ Done | Offline Local Caching | `offline_submission_queue.dart` persists price submissions to SharedPreferences when offline and auto-flushes on reconnect (NFR-22). |
| **Critical** | Legal/PDPL Audit | UAE Personal Data Protection Law (PDPL) review of the draft Arabic and English privacy policy copy. Owner action — send `docs/PRIVACY_COMPLIANCE.md` to legal. |
| **High** | APNs & FCM Production Credentials | Blocked on Apple Developer Program enrollment ($99/yr). APNs key cannot be uploaded to Firebase until enrolled. FCM (Android) already wired. |
| **High** | App Store / Play Store Signing | Deferred by owner. Configure store certificates, provisioning profiles, and signing configs before public store release. |
| ✅ Done | Redis Activation | Redis connection string format corrected on Render (to `rediss://`). Verified in logs: `[redis] client initialised — rate limiters and cache are Redis-backed` (NFR-05). |
| ✅ Done (PDPL sign-off pending) | Data Residency | DB migrated to Neon **`eu-central1` (Frankfurt)** and **cut over in production** (2026-06-18): Render env-group `DATABASE_URL` → Frankfurt pooled, deploy `dep-d8q0pnnavr4c73fuc3sg` live, `/health` 200, `/stores/nearby` serving 18 seeded stores from Frankfurt. `DATABASE_ENCRYPTION_KEY` unchanged. Old `us-east-1` project retained as rollback. **Remaining:** PDPL legal sign-off for EU hosting. See [NEON_FRANKFURT_CUTOVER.md](NEON_FRANKFURT_CUTOVER.md). |
| 🔴 Owner | GitHub Actions Billing | All CI runs fail with *"recent account payments have failed / spending limit"* — the job never starts. Affects PR checks + ~18 open Dependabot PRs. **Not a code issue.** Fix at GitHub → Settings → Billing & plans. (PR #19 was admin-merged past it.) |
| 🟠 Owner | Rotate Render API Key | A Render API key was pasted in chat 2026-06-18 (used for the DB cutover). Rotate it at `dashboard.render.com/u/settings`. |

### ⚡ Demo / cold-start note (Render free tier)
The backend sleeps after ~15 min idle and takes ~50s to wake. While asleep, the app's `/stores/nearby` call times out and the map falls back to **client-side static demo stores** (whose IDs the backend doesn't recognize, so tapping shows the empty state). **Before any live demo, warm the backend** by hitting `https://dealsouk.onrender.com/health` ~1 minute beforehand — then the map loads the real ~14 Dubai stores with live crowd-sourced prices. For a fully reliable demo, upgrade the Render service off the free tier.

---

## 📂 Related Documentation Directories

For further architectural and operational details, refer to:
* **[docs/AGENT_HANDOFF.md](file:///Users/hikki/Desktop/DealSouk/docs/AGENT_HANDOFF.md)**: 🤖 Start-here front door for coding agents.
* **[docs/CODEBASE_MAP.md](file:///Users/hikki/Desktop/DealSouk/docs/CODEBASE_MAP.md)**: Where every route/service/feature lives (token-saver).
* **[docs/OUTSTANDING_WORK.md](file:///Users/hikki/Desktop/DealSouk/docs/OUTSTANDING_WORK.md)**: Live prioritized backlog — bugs, security, perf, PRD gaps, cleanups.
* **[README.md](file:///Users/hikki/Desktop/DealSouk/README.md)**: Setup, build configurations, and map framework mismatch notes.
* **[AGENTS.md](file:///Users/hikki/Desktop/DealSouk/AGENTS.md)**: Automated coding agents reference guide.
* **[docs/SECURITY_AUDIT.md](file:///Users/hikki/Desktop/DealSouk/docs/SECURITY_AUDIT.md)**: Overall security compliance, CORS, and rate limits.
* **[docs/DB_SECURITY_REVIEW.md](file:///Users/hikki/Desktop/DealSouk/docs/DB_SECURITY_REVIEW.md)**: Database access safety, parameterization, atomicity, and indexing.
* **[docs/FIREBASE_STORAGE_SECURITY.md](file:///Users/hikki/Desktop/DealSouk/docs/FIREBASE_STORAGE_SECURITY.md)**: Firebase Storage security rules, size limits, and EXIF/malware blockers.
* **[docs/PRIVACY_COMPLIANCE.md](file:///Users/hikki/Desktop/DealSouk/docs/PRIVACY_COMPLIANCE.md)**: UAE PDPL compliance details and consent grids.
* **[docs/OWNER_PRODUCTION_ACTIONS.md](file:///Users/hikki/Desktop/DealSouk/docs/OWNER_PRODUCTION_ACTIONS.md)**: Exact external console/deployment steps for scanner, key restrictions, APNs, and legal review.
