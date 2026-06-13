# DealSouk Developer Handoff Documentation

This document provides a comprehensive handoff guide for human engineers taking over development, testing, and production operations of the DealSouk codebase.

---

## 🗺️ Project Overview

DealSouk is a crowd-sourced grocery price comparison and discount discovery application tailored for shoppers in Dubai, UAE.

It consists of:
1. **Shopper Mobile App (Flutter)**: Multi-platform mobile app targeting Android and iOS, built using Riverpod for state management and GoRouter.
2. **Admin Web Console (Flutter Web)**: Embedded administrative mode within the primary Flutter codebase toggled by build configuration flag.
3. **Backend API Server (Node.js/Express)**: TypeScript REST service connecting to Neon Serverless PostgreSQL database with Prisma.
4. **Cloud Infrastructure**: Firebase Auth (Phone OTP, Google/Apple Sign-In), Firebase Storage (Receipt and avatar image hosting), and Firebase Cloud Messaging (Push notifications).

---

## 🟢 Current Deployed State & Live Operations

The development sandbox environments are actively running and validated:
* **Prisma schema & migrations** are up-to-date and deployed to **Neon Postgres**.
* **Neon DB has been seeded** with 186 price submissions, 18 supermarket chains/stores, 20 catalog products, and 13 achievements.
* **Express backend** is hosted on Render at `https://dealsouk.onrender.com`.
* **Admin web** is hosted on Vercel at `https://deal-souk.vercel.app`.
* **Firebase Storage** has rules deployed to enforce file constraints.
* **Continuous Integration (CI)**: GitHub workflows are configured to run analyze, formatting verification, unit tests, and generate signed release APKs.

---

## 🚀 Quick Start & How to Run

### 1. Configure the Environment Safely
To run locally, you need config files. **Never commit these files to Git.**

* **Backend Environment File**:
  Create `backend/.env` containing:
  ```ini
  PORT=3000
  NODE_ENV=development
  DATABASE_URL="REPLACE_WITH_NEON_POSTGRES_CONNECTION_STRING"
  DATABASE_ENCRYPTION_KEY="your-32-byte-aes-encryption-key"
  FIREBASE_PROJECT_ID="dealsouk-6e140"
  FIREBASE_CLIENT_EMAIL="REPLACE_WITH_FIREBASE_SERVICE_ACCOUNT_EMAIL"
  FIREBASE_PRIVATE_KEY="REPLACE_WITH_FIREBASE_PRIVATE_KEY_ESCAPED_WITH_NEWLINES"
  ```
* **Firebase Config Files**:
  Fetch and place platform files in:
  * `android/app/google-services.json`
  * `ios/Runner/GoogleService-Info.plist`
  * `lib/firebase_options.dart` (generate via `flutterfire configure`)

---

### 2. Run the Backend API
```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev
npm run dev
```

---

### 3. Run the Mobile Shopper App
Ensure you pass the required target API url via `--dart-define`:
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL="http://localhost:3000"
```

---

### 4. Run the Web Admin Console
To boot the Flutter Web portal locally:
```bash
flutter run --dart-define=API_BASE_URL="http://localhost:3000" --dart-define=ADMIN_MODE=true
```

---

### 5. Running the Test Suites
To run the automated linting checks and the 21 mobile unit tests:
```bash
flutter analyze
flutter test
```
To build/compile the TypeScript backend:
```bash
cd backend
npm run build
```

---

## 👑 Administrative Role Management

Admin access is role-based and validated cryptographically. **Do not hardcode admin email addresses.**

To promote a registered user to the Admin role (this updates the PostgreSQL database field and assigns Firebase custom claims):
```bash
cd backend
npm run admin:set -- --email admin@example.com --admin
```
*(You may also identify users by Firebase UID: `npm run admin:set -- --uid your_uid --admin`)*

To revoke administrative privileges:
```bash
cd backend && npm run admin:set -- --email admin@example.com --no-admin
```

---

## 🚧 Remaining PRD Gaps & Launch Roadblockers

Before deploying the DealSouk codebase to production stores:

1. **Google Maps SDK Integration**:
   * *Gap*: The PRD mandates Google Maps. The MVP uses OpenStreetMap (`flutter_map` with CartoDB Voyager tiles) to simplify offline local developer environments.
   * *Action*: Replace `FlutterMap` widget calls with `GoogleMap` views and configure native platform API key settings in Google Cloud.
2. **Media Malware Scan & EXIF Stripping**:
   * *Current*: Firebase Functions image processing is implemented under `firebase/functions`. It strips EXIF metadata, normalizes images, and quarantines invalid files. A Cloud Run ClamAV scanner template exists under `services/malware-scanner`.
   * *Remaining*: Deploy the scanner, set `MALWARE_SCAN_URL`, and deploy the Firebase Function before public launch.
3. **Database PII Encryption**:
   * *Gap*: Mobile phone numbers are encrypted at rest, but display names and email addresses are currently stored in plaintext.
   * *Action*: Apply application-level AES-256 encryption to additional User fields in the Prisma route handlers.
4. **Push Notifications APNs Certificates**:
   * *Gap*: iOS Push Notification configuration requires provisioning profile configuration and APNs certificate key mapping in Firebase.
5. **UAE PDPL Legal Privacy Policy**:
   * *Gap*: Draft privacy policies exist, but must be reviewed by UAE legal advisors.

---

## 📅 Recommended Next Work Order

1. **Google Maps Production Migration**: Replace the OSM widget defaults with native Google Maps views.
2. **Media Bucket Integrity**: Add the server-side Sharp/ClamAV image post-processing functions.
3. **Offline Caching**: Configure Hive or SQLite local caching for the Grocery Cart so shoppers can review lists while offline in store basements.
4. **App Store Publishing**: Implement signing workflows for Apple App Store Connect and Google Play Console.
