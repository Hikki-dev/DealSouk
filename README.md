# DealSouk

DealSouk is a collaborative supermarket price comparison and crowd-sourced discount tracking application designed for shoppers in Dubai. It empowers consumers to find the cheapest groceries, share real-time shelf prices, request price updates, and earn rewards for contributing data.

The project consists of three main components:
1. **DealSouk Shopper (Mobile Client)**: The customer-facing companion app for browsing discounts, comparing shopping baskets, submitting/requesting price lookups, and climbing the leaderboard.
2. **DealSouk Admin (Web Portal)**: A moderator dashboard to review submitted receipt photos, flag fraudulent submissions, approve supermarket voucher requests, manage configurations, and analyze platform stats.
3. **DealSouk Backend (API Server)**: A Node.js & TypeScript REST API powered by Express, Prisma ORM, Neon Serverless PostgreSQL, and Firebase Admin.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Node](https://img.shields.io/badge/Node.js-20-339933?logo=nodedotjs&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-Express-3178C6?logo=typescript&logoColor=white)
![Postgres](https://img.shields.io/badge/Postgres-Neon%20%2B%20Prisma-4169E1?logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20FCM%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)

**Live services**: backend API on Render (`/health` for a status check), admin portal at [deal-souk.vercel.app](https://deal-souk.vercel.app).

---

## ✨ Features

### Shoppers
- **Search and compare** prices across Dubai supermarkets. Each product shows its cheapest fresh price, and prices expire after **72 hours**.
- **Smart cart**: compare a basket across stores and find the cheapest complete basket.
- **Barcode scanner** to look up a product instantly.
- **Nearby stores** on a map, with per-store price lists and price history charts.
- **Submit prices** with a shelf or receipt photo and earn tokens.
- **Price requests board**: ask for a price check, or fulfil someone else's request.
- **Rewards**: tokens, daily challenges, streaks, badges, a monthly **leaderboard**, and supermarket **voucher** redemptions.
- **Saved items**, push notifications, **English and Arabic** (with RTL), and an offline queue that syncs when the connection returns.

### Moderators (admin portal)
- **Moderation queue**: approve, reject or edit submissions, and review flagged ones (a submission is auto-hidden after 3 unique flags).
- **User actions**: warn, suspend or ban, all written to an audit log.
- **Catalog and user management**, voucher approval and **voucher inventory import**.
- **Analytics**, a store map view, and **CSV / PDF exports**.
- Platform **settings** (for example voucher thresholds) and a maintenance mode switch.

---

## 🎨 Design and screens

- [Design system](docs/DESIGN_SYSTEM.md): tokens, breakpoints, components, accessibility
- [Screens](docs/SCREENS.md): every screen with its mockup and implementing file
- [Redesign notes](docs/REDESIGN.md): what changed, how it was verified, known gaps
- [Admin access and showcase](docs/ACCESS_AND_SHOWCASE.md)

## 🏗️ Architecture

```
 Shopper app (Flutter)      Admin portal (Flutter web, ADMIN_MODE=true)
          \                         /
           \   HTTPS + Firebase ID token
            v                     v
        Express API (TypeScript) ── Prisma ──> Neon PostgreSQL
            |        \
            |         +── Firebase Admin (verify tokens, FCM push)
            |         +── Redis (optional, rate limiting)
            v
   Firebase Storage  ──> Cloud Functions (EXIF strip) ──> malware-scanner (ClamAV on Cloud Run)
```

- **One Flutter codebase, two apps.** `ADMIN_MODE` chooses the shopper or moderator UI at build time.
- **Auth**: Firebase Authentication signs users in (Google, Apple, phone OTP). The API verifies the Firebase ID token and keeps a matching user row. The admin role is stored in the database and as a Firebase custom claim.
- **Token ledger**: every token change is written as a hash-chained transaction, so the history can be verified.
- **Uploads**: the client asks the API for a signed URL, uploads straight to Firebase Storage, and a Cloud Function and a malware scanner process the file.

### Project structure

```
lib/                     Flutter client
├── app/                 App, router, route guard
├── core/                Network, offline queue, theme, l10n helpers, shared widgets
├── features/            One folder per feature: admin, auth, cart, home, leaderboard,
│                        legal, products, profile, requests, saved, stores,
│                        submissions, tokens  (data / domain / presentation)
└── l10n/                English and Arabic strings
backend/                 Express + TypeScript + Prisma API
├── src/routes/          One router per module (admin is split into 3 routers)
├── src/services/        Token engine, notifications, encryption, PDF, Redis, storage
├── prisma/              Schema, migrations, seed
├── scripts/             Admin promotion and claim audit
└── test/                Jest tests
firebase/                Storage rules and Cloud Functions
services/malware-scanner Cloud Run ClamAV service
scripts/                 secret_scan.py, history purge helper
.github/workflows/       CI, Android and iOS builds, admin web build, keep-warm
```

---

## 🔌 API overview

All routes are served by the Express app in `backend/src/index.ts`. Write endpoints are rate limited. Routes marked "auth" need a Firebase ID token, and `/admin/*` additionally needs the admin role.

| Module | Base path | Highlights |
|---|---|---|
| Auth | `/auth` | `POST /verify` exchanges a Firebase token for a DealSouk user |
| Products | `/products` | `GET /search`, `/:id`, `/:id/prices`, `/:id/history` |
| Stores | `/stores` | `GET /nearby`, `/:id`, `/:id/prices` |
| Submissions | `/submissions` | `GET /feed`, `GET /estimate`, `POST /` (auth), `POST /:id/flag` (auth) |
| Requests | `/requests` | `GET /board`, `GET /mine`, `POST /`, `POST /:id/fulfill`, `DELETE /:id` |
| Profile | `/profile` | `/me`, `/me/transactions`, `/me/vouchers`, `/me/submissions`, `/me/cart`, `/me/requests`, `/me/fcm-token`, `DELETE /me` |
| Leaderboard | `/leaderboard` | `GET /monthly` |
| Challenges | `/challenges` | `GET /today` |
| Uploads | `/uploads` | `POST /signed-url` |
| Translate, Logos, Config | `/translate`, `/logos/:slug`, `/config` | Helpers and client configuration |
| Admin | `/admin` | `/queue`, `/submissions/:id/{approve,reject}`, `/users/:id/{warn,suspend,ban}`, `/products`, `/users`, `/vouchers`, `/analytics`, `/settings`, `/exports/*` |

The server also exposes `/health`.

---

## 🧪 Testing

```bash
# Flutter client
flutter analyze
flutter test

# Backend
cd backend
npm install
npm test          # Jest, runs in band

# Secret scan (also runs in CI)
python3 scripts/secret_scan.py
```

CI (`.github/workflows/ci.yml`) checks formatting, `flutter analyze`, `flutter test`, the secret scan, the Prisma client generation, the backend build and the backend tests on every pull request. Manual test plans are in [docs/TEST_PLAN.md](docs/TEST_PLAN.md) and [docs/AUTOMATED_TEST_PLAN.md](docs/AUTOMATED_TEST_PLAN.md).

---

## 🔐 Security

- Helmet, CORS allow-list, request body size limit and per-route **rate limiting** (Redis-backed in production).
- Phone numbers are **encrypted at rest** (`DATABASE_ENCRYPTION_KEY`).
- Admin actions are written to an **audit log**, and admin MFA can be required (`ADMIN_MFA_REQUIRED`).
- Uploads are limited by user, type and size, have EXIF stripped and are malware scanned.
- Never commit `.env`, service-account files, `google-services.json`, `GoogleService-Info.plist` or `firebase_options.dart`.

See [SECURITY_AUDIT.md](SECURITY_AUDIT.md) and the pre-launch [SECURITY_CHECKLIST.md](SECURITY_CHECKLIST.md).

---

## ⚙️ Backend environment variables

Copy `backend/.env.example` to `backend/.env`. Main keys:

| Key | Purpose |
|---|---|
| `DATABASE_URL` | Postgres connection string (Neon) |
| `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` | Firebase Admin credentials |
| `DATABASE_ENCRYPTION_KEY` | Encrypts phone numbers at rest |
| `ALLOWED_ORIGINS` | CORS allow-list |
| `REDIS_URL`, `RATE_LIMIT_REDIS` | Optional Redis-backed rate limiting |
| `*_RATE_LIMIT_PER_MINUTE` | Per-route rate limits |
| `ADMIN_MFA_REQUIRED` | Require MFA for admin API access |
| `GOOGLE_TRANSLATE_API_KEY` | `/translate` endpoint |
| `SMTP_*`, `FROM_EMAIL` | Optional email |
| `MAINTENANCE_MODE`, `MAINTENANCE_MESSAGE` | Maintenance switch |

---

## 🛠️ Technology Stack

* **Frontend**: Flutter (Mobile & Web), Riverpod (State Management), GoRouter (Navigation), OpenStreetMap / `flutter_map` (with CartoDB Voyager tile wrapper)
* **Backend**: Node.js & Express (TypeScript), Prisma (ORM), Postgres (Neon), Helmet & CORS, Express Rate Limiter
* **Authentication**: Firebase Authentication (OAuth Google/Apple, Phone OTP, Custom Claims Role Model)
* **Services**: Firebase Cloud Messaging (Push Notifications), Firebase Cloud Storage (Receipts/Avatars Upload)

---

## ⚙️ Flutter Environment Configurations (`--dart-define`)

All build-time environment values must be passed when compiling or running the Flutter client:

| Key | Expected Format | Purpose | Release Requirement |
|---|---|---|---|
| `API_BASE_URL` | `https://your-domain.com` | Base endpoint of the backend Express API. | **Required**. Release builds will crash with a `StateError` if left blank or configured as non-HTTPS. |
| `GOOGLE_WEB_CLIENT_ID` | `548247...apps.googleusercontent.com` | OAuth client ID required for Google Sign-In on Web. | **Required** for web client authentication. |
| `MAPBOX_ACCESS_TOKEN` | `pk.eyJ1...` | Mapbox public token used for the base-map tiles on the shopper and admin maps. Restrict it by URL/bundle ID in the Mapbox dashboard. Never commit it. | **Required**. Without it, maps show blank/failed tiles. |
| `ADMIN_MODE` | `true` or `false` | Sets the application target view. Toggles between the Moderator Portal (`true`) and Shopper Companion (`false`). | Defaults to `false` (Shopper). |

---

## 🗺️ Maps Implementation & Mismatch

### PRD Mismatch Notice
* **PRD Requirement**: The DealSouk PRD mandates the usage of the **Google Maps SDK** for rendering supermarket pin markers.
* **MVP Implementation**: The MVP uses **OpenStreetMap (`flutter_map`)** with **Mapbox Streets** raster tiles (CARTO's free Voyager endpoint now returns an "API KEY REQUIRED" placeholder). This wrapper was chosen for local development to prevent billing, credential setup, and API key restrictions from blocking engineers.
* **Release Path**: Maps run on `flutter_map` with Mapbox tiles. If you later want native Google Maps, add `google_maps_flutter` back (it was removed because nothing used it) and restrict its API keys per platform.

### Dependencies
`google_maps_flutter`, `cloud_firestore`, `firebase_analytics`, `firebase_crashlytics` and `google_fonts` were removed because nothing in `lib/` imported them (crash reporting is `sentry_flutter`). Fonts are bundled, see below.

---

## 🚀 Getting Started

### 1. Backend Setup

Prerequisites: Node.js (v20.x), PostgreSQL database connection.

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up your environment variables:
   * Copy `backend/.env.example` to `backend/.env` and fill in the required keys (`DATABASE_URL`, `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, etc.).
4. Generate the Prisma database client:
   ```bash
   npx prisma generate
   ```
5. Apply database migrations:
   ```bash
   npx prisma migrate dev
   ```
6. Start the API in development mode:
   ```bash
   npm run dev
   ```

To promote a registered user to an Admin Moderator, run:
```bash
npm run admin:set -- --email admin@example.com --admin
```

---

### 2. Flutter Client Setup

Prerequisites: Flutter SDK (Stable), CocoaPods (for iOS).

1. Fetch packages:
   ```bash
   flutter pub get
   ```
2. Generate your local Firebase configuration:
   ```bash
   flutterfire configure
   ```
3. Run the standard **DealSouk Shopper** application:
   ```bash
   flutter run --dart-define=API_BASE_URL="http://localhost:3000"
   ```
4. Run the **DealSouk Admin** application locally:
   ```bash
   flutter run --dart-define=API_BASE_URL="http://localhost:3000" --dart-define=ADMIN_MODE=true
   ```

---

## 🤖 GitHub Automation & Releases

The repository is configured with automated GitHub Actions under `.github/workflows/` to validate code and package releases.

### Automated Builds
We build two targeted flavors of the app:
* **DealSouk Shopper (User Companion)**: Packaged with `ADMIN_MODE=false`.
* **DealSouk Admin (Moderator Portal)**: Packaged with `ADMIN_MODE=true`.

### How to Publish a Release
1. Push all verified changes to your target branch.
2. Create a new **Release** in your GitHub repository sidebar.
3. Give it a version tag (e.g., `v1.0.0-rc1`).
4. Once published, a GitHub runner will build both **DealSouk-Shopper.apk** and **DealSouk-Admin.apk** in parallel and automatically attach them as download assets on the release page.

---

## 🎨 Design assets and credits

- **Font**: Readex Pro (SIL Open Font License) is bundled in `assets/fonts/`. One family covers Latin and Arabic, so nothing loads from the network and Arabic no longer falls back to a system font.
- **Images**: `assets/images/` holds the optimised photos used on the welcome screen and home carousel. `assets/logos/` holds 256px chain logos.
- **Photo credits**: Dubai Marina by Norlando Pobre (CC BY 2.0), vegetable market by Ithra Dubai (CC BY-SA 4.0), Carrefour UAE (CC BY-SA 4.0, Wikimedia Commons "Dates at Carrefour, UAE"), Dubai Creek (public domain). The same credits appear in the app under Privacy & Terms. The market photo shows a real person and has no confirmed model release, so replace it before launch.
- **Maps**: © Mapbox, © OpenStreetMap contributors.
