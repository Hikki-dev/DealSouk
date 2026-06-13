# Developer Agent Guidelines (AGENTS.md)

Welcome, coding agent! This document describes the structure of DealSouk, current branch status, key commands, and important development boundaries you must respect.

---

## 📋 Project Summary & Branch State

* **Active Candidate Branch**: `stabilize/mvp-audit` (All development, stabilization, and hardening must happen here).
* **PRD Document**: `/Users/hikki/Downloads/DealSouk_PRD_v1.0.pdf` (or plain text reference: `docs/PRD_TEXT.txt`).
* **Source of Truth Status**: **[STATUS.md](file:///Users/hikki/Desktop/DealSouk/docs/STATUS.md)** (Refer here for live operational readiness, test status, and blockers).

---

## 🛠️ System Architecture

1. **Shopper Mobile App (Flutter)**:
   * Features located in: `lib/features/`
   * Routing & Guards: `lib/app/router.dart` and `lib/app/route_guard.dart`
   * Localized Strings: `lib/l10n/app_en.arb` and `app_ar.arb`
   * Map Engine: Custom OpenStreetMap (`flutter_map`) with CartoDB Voyager tiles (chosen for MVP to avoid key constraints).
2. **Admin Web Console (Flutter Web)**:
   * Shared Flutter code with Shopper app, toggled using `--dart-define=ADMIN_MODE=true`.
3. **Backend REST API (Express & TypeScript)**:
   * Main server entrypoint: `backend/src/index.ts`
   * Schema and Migrations: `backend/prisma/`
   * Database: PostgreSQL hosted on Neon.

---

## 🔑 Secret Safety Rules

* **DO NOT** commit `.env` or `render.env` files.
* **DO NOT** commit Firebase config files (`google-services.json`, `GoogleService-Info.plist`, or `lib/firebase_options.dart`).
* **DO NOT** print, log, or leak sensitive PII or credentials.
* **SMTP Warning**: If `process.env.NODE_ENV === 'production'` and SMTP is not configured, email console logging is suppressed and recipients are masked to prevent leakage.

---

## ⚡ Important Commands

### 📱 Flutter Client
* **Fetch Dependencies**: `flutter pub get`
* **Run Shopper Client**: `flutter run --dart-define=API_BASE_URL="http://localhost:3000"`
* **Run Admin Client**: `flutter run --dart-define=API_BASE_URL="http://localhost:3000" --dart-define=ADMIN_MODE=true`
* **Run Static Code Check**: `flutter analyze`
* **Run Test Suite**: `flutter test`

### 💻 Backend Server
* **Install Packages**: `cd backend && npm install`
* **Compile TypeScript**: `cd backend && npm run build`
* **Apply Migrations**: `cd backend && npx prisma migrate dev`
* **Run Server (Dev)**: `cd backend && npm run dev`
* **Promote User to Admin**:
  ```bash
  cd backend && npm run admin:set -- --email admin@example.com --admin
  ```
  *(Or use `--uid firebase_uid` instead of `--email`)*
* **Remove Admin Role**:
  ```bash
  cd backend && npm run admin:set -- --email admin@example.com --no-admin
  ```

---

## 🚫 What NOT to Touch / Modify

1. **Google Maps SDK Integration**: Deferred for post-MVP release. Do not replace the current `flutter_map` (OpenStreetMap) wrapper.
2. **Framework Choice**: Keep Riverpod, go_router, Express, and Prisma. Do not refactor the architecture to clean architecture/DDD unless explicitly instructed.
3. **NPM Audit Force**: Do not run `npm audit fix --force` blindly on the backend. Upgrading `firebase-admin` introduces breaking version bumps.

---

## 🚀 Pre-Commit Verification Checklist

Before committing or pushing any code changes, you **MUST** run:
1. `python3 scripts/secret_scan.py`
2. `dart format --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test`
5. `cd backend && npm run build`
6. `cd backend && npx prisma migrate status`
