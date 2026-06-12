# DealSouk Client & Backend Security Audit

**Date**: June 12, 2026  
**Auditor**: Antigravity AI  
**Repository Branch**: `feature/flutter-api-integration`

This document details the security posture of the DealSouk crowd-sourced price comparison application. It covers 20 specific security checkpoints across the Flutter client and the Node.js/TypeScript backend, mapping vulnerabilities to risk ratings, codebase evidence, and recommended remediation.

---

## Executive Summary Statistics

| Severity | Count | Status Description |
|---|---|---|
| 🔴 **Critical** | 4 | Immediate release blockers; routes auth bypasses or leaks data over plaintext. |
| 🟡 **High** | 2 | Significant functional or compliance risk (PDPL, unhandled UI exceptions). |
| 🔵 **Medium** | 3 | Privacy configurations or trace artifacts needing cleanup before App Store review. |
| 🟢 **Low** | 1 | Minor testing or local configuration adjustments. |
| 🟢 **Passed** | 10 | Fully compliant with security and PRD rules. |

---

## Detailed Security Matrix

### 1. Credentials & Configuration Management

| Checkpoint | Target Description | Severity | Code Evidence | Gaps & Risk Analysis | Recommended Fix |
|---|---|---|---|---|---|
| **01** | API keys committed in repo | 🟢 **Passed** | `backend/.env.example` | No production Firebase service account keys, Postgres credentials, or FCM tokens are committed. | Maintain credential loading via `.env` files in local runs and environment variables in CI/CD. |
| **02** | Firebase config exposure | 🔵 **Medium** | `.gitignore:L70-L74` | Local Firebase configurations (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are ignored, but git history reveals they were previously tracked before commit `bd5f642`. | Run `git-filter-repo` to purge config files from history. Rotate Firebase project identifiers. |
| **03** | Google Maps API key exposure | 🔴 **Critical** | `AndroidManifest.xml:L36`<br>`AppDelegate.swift`<br>`index.html` | Google Maps API keys are hardcoded as placeholders (`YOUR_GOOGLE_MAPS_API_KEY`), which will break maps on devices. If developers replace them locally, they risk committing them. | Inject API keys via Gradle/Xcode build variables at compile time. Do not check keys into git. |
| **04** | `.env` files committed | 🟢 **Passed** | `.gitignore:L55-L61` | `.env` and `.env.local` files are properly ignored. Only `.env.example` is tracked. | Keep ignoring local env files; configure CI/CD injection. |

---

### 2. Authentication & Authorization Controls

| Checkpoint | Target Description | Severity | Code Evidence | Gaps & Risk Analysis | Recommended Fix |
|---|---|---|---|---|---|
| **05** | Hardcoded bearer tokens | 🟢 **Passed** | `api_client.dart:L24-L49` | Authentication tokens are dynamically requested from Firebase Auth and attached to requests. | No action required. |
| **06** | Hardcoded user IDs | 🟢 **Passed** | `prisma/seed.ts:L111-L125` | Mock seed user (`dummy_seed_sourcer_uid`) is used for local database population only. Production API users are resolved dynamically via Firebase tokens. | Keep seed user ids segregated from production environments. |
| **07** | Hardcoded admin access | 🟢 **Passed** | `schema.prisma:L21`<br>`auth.ts:L49` | Admin rights are resolved dynamically using the `isAdmin` boolean field in the database. | No action required. |
| **08** | Hardcoded profile data | 🟢 **Passed** | `state.dart` | Hardcoded mock data maps have been deleted. Profile, cart, and submissions states are loaded dynamically from the API. | No action required. |
| **09** | Admin route without auth guard | 🔴 **Critical** | [router.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/router/router.dart#L194) | The legacy static `appRouter` is still exported and contains **no route redirection logic or admin check guards**. If imported, it allows users to bypass authorization check blocks. | Remove the legacy `appRouter` entirely from the codebase. |

---

### 3. Transport & Network Security

| Checkpoint | Target Description | Severity | Code Evidence | Gaps & Risk Analysis | Recommended Fix |
|---|---|---|---|---|---|
| **10** | Insecure HTTP URLs | 🔴 **Critical** | [api_client.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/services/api_client.dart#L11) | The default URL is hardcoded as plaintext HTTP (`http://100.69.54.28:3000`). Profile credentials and coordinates are sent unencrypted. | Require HTTPS. Throw an assertion error in release mode if the API URL does not begin with `https://`. |
| **11** | Missing HTTPS enforcement | 🔴 **Critical** | `api_client.dart` | The client permits connecting to unencrypted endpoints. The backend has no middleware to force redirection to HTTPS. | Configure backend middleware to force HTTPS redirection and set HTTP Strict Transport Security (HSTS) headers. |
| **12** | Debug logs leaking data | 🟢 **Passed** | `backend/src/` | Console logging only outputs lifecycle and connection indicators; no sensitive PII or location tokens are printed. | Maintain print filters; replace standard prints with `debugPrint` in the client. |

---

### 4. Device Permissions & Privacy Controls

| Checkpoint | Target Description | Severity | Code Evidence | Gaps & Risk Analysis | Recommended Fix |
|---|---|---|---|---|---|
| **13** | AndroidManifest permissions | 🟢 **Passed** | `AndroidManifest.xml:L2-L5` | Requests `INTERNET`, `CAMERA`, and location permissions. Background location is NOT requested, satisfying PRD rules. | No action required. |
| **14** | iOS Info.plist permissions | 🔵 **Medium** | `Info.plist:L63-L64` | Plist declares `NSLocationAlwaysAndWhenInUseUsageDescription` (Always Allow Location). This is unnecessary since background location is out of scope. | Remove `NSLocationAlwaysAndWhenInUseUsageDescription` to prevent App Store rejection. |
| **15** | Location permission wording | 🔵 **Medium** | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart#L60) | The app directly launches the OS location permission dialog without a plain-language explainer overlay, violating `FR-04`. | Implement a simple pre-prompt dialog explaining that location is needed to display nearby supermarket pricing. |
| **16** | Camera/photo permission wording | 🟢 **Passed** | `Info.plist:L59-L60` | Camera description string is clear: *"We need camera access to capture price labels and receipts."* | No action required. |

---

### 5. Session, Storage & Compliance

| Checkpoint | Target Description | Severity | Code Evidence | Gaps & Risk Analysis | Recommended Fix |
|---|---|---|---|---|---|
| **17** | Secure storage requirement | 🟢 **Passed** | Firebase SDK | Session caching is managed natively by the Firebase Auth SDK (using Keychain on iOS and Keystore on Android). | No action required. |
| **18** | Token/session handling | 🟢 **Passed** | Firebase SDK | Tokens expire and refresh automatically. Session tokens expire after 30 days of inactivity, satisfying `NFR-08`. | No action required. |
| **19** | Guest mode restrictions | 🟡 **High** | [router.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/router/router.dart#L42-L46) | Guest users can access the Grocery Cart screen and click "Add to Cart". These actions trigger API syncs to `/profile/me/cart` without tokens, resulting in unhandled 401 errors. | Disable the "Add to Cart" button for guest users and show a prompt asking them to sign in. |
| **20** | Privacy & PDPL compliance | 🟡 **High** | `welcome_screen.dart`<br>`schema.prisma` | 1. The Welcome/Login screen lacks privacy policy consent checkboxes.<br>2. User PII (phone numbers, display names) is stored in plaintext in PostgreSQL instead of being encrypted at rest. | 1. Add privacy policy checkboxes to the registration screen.<br>2. Encrypt phone numbers at rest in the database. |

---

## Key Security Recommendations (Priority Actions)

1. **Purge Git History (Medium)**: Use `git-filter-repo` to delete `google-services.json` and `GoogleService-Info.plist` from previous commits, then rotate project credentials.
2. **Remove Legacy Router (Critical)**: Delete the legacy static `appRouter` from [router.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/router/router.dart#L194) to eliminate the auth bypass vector.
3. **Enforce HTTPS (Critical)**: Change the default endpoint in [api_client.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/services/api_client.dart#L11) to a secure HTTPS URL, and add compile-time checks to prevent HTTP traffic in release builds.
4. **Fix Guest Cart Sync (High)**: Add guest checks in [cart_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/cart/cart_screen.dart) to prevent unauthenticated API requests to the cart endpoints.
