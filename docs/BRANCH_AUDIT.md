# DealSouk Branch Audit & Stabilization Report

**Branch Target**: `stabilize/mvp-audit`
**Base Source**: `feature/flutter-api-integration`

---

## 1. Branch Assessments

### 🔴 `production`
* **Status**: Outdated/Legacy Prototype
* **Details**: Points directly to the original default Flutter application skeleton. It contains heavy mock-only screens, zero database connectivity, and relies on a flat, unstructured codebase.
* **MVP Role**: **Do NOT use as the source of truth.** It does not represent the actual features, APIs, or data models of the app. It must be reset and merged from `stabilize/mvp-audit` once auditing and stabilization are complete.

### 🟡 `feature/firebase-auth`
* **Status**: Incomplete Auth Scaffold (Superseded)
* **Details**: Adds dependencies for Firebase Auth and initial sign-in layouts, but lacks complete initialization logic, proper error boundaries, and integration with the backend API.
* **MVP Role**: Archived. Superseded by `feature/flutter-api-integration`.

### 🟡 `feature/backend-foundation`
* **Status**: Incomplete Backend Scaffold (Superseded)
* **Details**: Contains a backend skeleton and initial database tables, but lacks the core API routes, gamification services, and moderation dashboard endpoints.
* **MVP Role**: Archived. Superseded by `feature/flutter-api-integration`.

### 🟢 `feature/flutter-api-integration`
* **Status**: Active Production Candidate (Base Branch)
* **Details**: The most complete, robust branch containing the full feature-folder refactored client structure, fully integrated Node.js Express REST API, Neon PostgreSQL database schemas, FCM push notifications, Firebase Storage, and standard automated tests.
* **MVP Role**: Selected as the correct, MVP-ready base branch.

---

## 2. Technical Gaps & Blockers

### A. Missing Firebase Configuration Wording
* **Description**: Since `lib/firebase_options.dart` and mobile configuration files (`google-services.json`/`GoogleService-Info.plist`) are git-ignored, a fresh clone of the codebase will fail to compile.
* **Blocker Severity**: High (Developer onboarding)
* **Resolution**: Documented clear base64 environment injection for CI/CD and added a try-catch initialization safe boundary in `lib/main.dart` to allow local app boots in mock mode without crash loops.

### B. Insecure HTTP Release Fallbacks
* **Description**: The default API endpoint had a hardcoded Render HTTPS URL fallback. In release mode, the app should never rely on hardcoded production fallbacks without explicit verification.
* **Blocker Severity**: High (Production deployment security)
* **Resolution**: Reconfigured `api_client.dart` to throw a strict `StateError` if `API_BASE_URL` is omitted via `--dart-define` in release mode.

### C. Gaps in PRD Feature Compliance
* **Description**: The PRD outlines Google Maps SDK integration, but the current UI uses OpenStreetMap (CartoDB Voyager). Additionally, TimescaleDB and Redis implementations are not yet wired into the Neon database.
* **Blocker Severity**: Medium (Product parity)
* **Resolution**: Documented the Google Maps vs. OSM mismatch in the README and added explicit `TODO` markers in the backend database code.

---

## 3. Recommended Migration Path
1. Keep `stabilize/mvp-audit` as the active QA and stabilization staging branch.
2. Verify all CI builds succeed.
3. Reset the `production` branch to point directly to `stabilize/mvp-audit` prior to final MVP release.
