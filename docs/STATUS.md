# DealSouk Project Status

**Date**: June 13, 2026
**Active Workspace Branch**: `stabilize/mvp-audit` (Unified Base Branch)

This document serves as the single source of truth for the current development and production readiness status of the DealSouk platform.

---

## 🚀 Deployed Infrastructure & Live Systems

| Component | Provider | Live Status | Evidence / Verification |
|---|---|---|---|
| **Backend API** | Render | Deployed Live | `https://dealsouk.onrender.com/health` returns `200 OK`. |
| **Admin Web Portal** | Vercel | Deployed Live | `https://deal-souk.vercel.app` returns `200 OK`. |
| **Database** | Neon Serverless | Connected & Seeded | Postgres database connected. Seeded with 186 price submissions, 18 stores, 20 products, and 13 achievements. |
| **Firebase Storage** | Firebase Storage | Live & Rules Deployed | Bucket storage initialized. Rules limiting uploads by user, type, and size are deployed. |
| **Upload Processing** | Firebase Functions + Cloud Run | Repo Ready | EXIF stripping/quarantine function is implemented in `firebase/functions`; ClamAV scanner template is in `services/malware-scanner`. Deploy both before public launch. |

---

## 🧪 Testing & Code Health

* **Static Analysis**: `flutter analyze` runs with 0 errors, warnings, or lints.
* **Test Suite**: 21 unit tests fully verify critical business logic:
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
4. **Secure Token Transactions**: Token modifications are transactional and backed by a relational database schema recording every transaction in a ledger (`TokenTransaction`).
5. **PII Encryption**: User phone numbers are encrypted at rest using AES-256-CBC at application level.
6. **Hardened Email Console Log**: SMTP-unconfigured fallbacks suppress printing email body and mask recipient addresses in production (`NODE_ENV === 'production'`) to prevent PII leakage to system output logs.

---

## ⚠️ Public Production Blockers

These items must be resolved before releasing DealSouk to the public Apple App Store or Google Play Store:

| Priority | Area | Required Resolution |
|---|---|---|
| **Critical** | Google/Firebase Key Restrictions | Configure Android package + SHA-1 fingerprints, iOS bundle ID, and web referrer restrictions in the Google Cloud Console / Firebase Console. |
| **Critical** | Firebase Auth Admin IAM | Current `audit-claims` check reports `auth/insufficient-permission`; grant backend service account `roles/firebaseauth.admin` before production admin ops. |
| **Critical** | Legal/PDPL Audit | UAE Personal Data Protection Law (PDPL) review of the draft Arabic and English privacy policy copy. |
| **High** | Upload Malware Scanning | Repo implementation exists. Deploy `services/malware-scanner`, set `MALWARE_SCAN_URL`, and deploy Firebase Functions before public launch. |
| **High** | APNs & FCM Production Credentials | Map APNs certificates and FCM profiles for real-world device notification delivery. |
| **High** | App Store / Play Store Signing | Deferred by owner. Configure store certificates, provisioning profiles, and signing configs before public store release. |
| **Medium** | Offline Local Caching | Implement a local synchronization queue (e.g., Hive) to support offline cart operations in areas of poor supermarket connectivity. |
| **Medium** | Data Residency Confirmation | PRD prefers Google Cloud `me-central1`; current Neon deployment must be legally approved or migrated to an approved region/provider. |

---

## 📂 Related Documentation Directories

For further architectural and operational details, refer to:
* **[README.md](file:///Users/hikki/Desktop/DealSouk/README.md)**: Setup, build configurations, and map framework mismatch notes.
* **[AGENTS.md](file:///Users/hikki/Desktop/DealSouk/AGENTS.md)**: Automated coding agents reference guide.
* **[docs/HANDOFF.md](file:///Users/hikki/Desktop/DealSouk/docs/HANDOFF.md)**: Complete developer handoff documentation.
* **[docs/SECURITY_AUDIT.md](file:///Users/hikki/Desktop/DealSouk/docs/SECURITY_AUDIT.md)**: Overall security compliance, CORS, and rate limits.
* **[docs/DB_SECURITY_REVIEW.md](file:///Users/hikki/Desktop/DealSouk/docs/DB_SECURITY_REVIEW.md)**: Database access safety, parameterization, atomicity, and indexing.
* **[docs/FIREBASE_STORAGE_SECURITY.md](file:///Users/hikki/Desktop/DealSouk/docs/FIREBASE_STORAGE_SECURITY.md)**: Firebase Storage security rules, size limits, and EXIF/malware blockers.
* **[docs/PRIVACY_COMPLIANCE.md](file:///Users/hikki/Desktop/DealSouk/docs/PRIVACY_COMPLIANCE.md)**: UAE PDPL compliance details and consent grids.
* **[docs/OWNER_PRODUCTION_ACTIONS.md](file:///Users/hikki/Desktop/DealSouk/docs/OWNER_PRODUCTION_ACTIONS.md)**: Exact external console/deployment steps for scanner, key restrictions, APNs, and legal review.
