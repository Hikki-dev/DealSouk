# DealSouk

DealSouk is a collaborative supermarket price comparison and crowd-sourced discount tracking application designed for shoppers in Dubai. It empowers consumers to find the cheapest groceries, share real-time shelf prices, request price updates, and earn rewards for contributing data.

The project consists of three main components:
1. **DealSouk Shopper (Mobile Client)**: The customer-facing companion app for browsing discounts, comparing shopping baskets, submitting/requesting price lookups, and climbing the leaderboard.
2. **DealSouk Admin (Web Portal)**: A moderator dashboard to review submitted receipt photos, flag fraudulent submissions, approve supermarket voucher requests, manage configurations, and analyze platform stats.
3. **DealSouk Backend (API Server)**: A Node.js & TypeScript REST API powered by Express, Prisma ORM, Neon Serverless PostgreSQL, and Firebase Admin.

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
| `ADMIN_MODE` | `true` or `false` | Sets the application target view. Toggles between the Moderator Portal (`true`) and Shopper Companion (`false`). | Defaults to `false` (Shopper). |

---

## 🗺️ Maps Implementation & Mismatch

### PRD Mismatch Notice
* **PRD Requirement**: The DealSouk PRD mandates the usage of the **Google Maps SDK** for rendering supermarket pin markers.
* **MVP Implementation**: The MVP uses **OpenStreetMap (`flutter_map`)** with **CartoDB Voyager** tiles. This wrapper was chosen for local development to prevent billing, credential setup, and API key restrictions from blocking engineers.
* **Release Path**: The app contains `google_maps_flutter` in `pubspec.yaml`. For the post-MVP production release launch, developers should replace the `FlutterMap` widget wrapper with native `GoogleMap` views and inject restricted Google Maps API keys via build config profiles.

### Unused Dependency Audits
* **`google_maps_flutter`**: Included in `pubspec.yaml` but not currently imported in Dart views. Kept as a placeholder to allow transition to Google Maps post-MVP.

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
