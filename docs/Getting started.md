# Getting started

This page takes you from nothing to the API and both apps running on your own computer.

## What you need

1. Node.js 20 and npm, for the API.
2. A Postgres database. A free Neon database works well.
3. A Firebase project, for sign-in, photos and notifications.
4. The Flutter SDK (stable channel), for the apps. iOS also needs CocoaPods.

## 1. The API

```bash
cd backend
npm install
```

Copy `backend/.env.example` to `backend/.env` and fill in the keys. The main ones:

| Key | What it is for |
|---|---|
| `DATABASE_URL` | The Postgres connection string |
| `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` | Lets the API check Firebase sign-in tokens |
| `DATABASE_ENCRYPTION_KEY` | Encrypts phone numbers in the database |
| `ALLOWED_ORIGINS` | The websites allowed to call the API |
| `REDIS_URL`, `RATE_LIMIT_REDIS` | Optional. Makes rate limits shared between servers |
| `*_RATE_LIMIT_PER_MINUTE` | How many requests each kind of route allows |
| `ADMIN_MFA_REQUIRED` | Make moderators use a second sign-in step |
| `GOOGLE_TRANSLATE_API_KEY` | The `/translate` route |
| `SMTP_*`, `FROM_EMAIL` | Optional email |
| `MAINTENANCE_MODE`, `MAINTENANCE_MESSAGE` | Switch the app to a maintenance message |

Then:

```bash
npx prisma generate       # builds the database client
npx prisma migrate dev    # creates the tables
npm run dev               # starts the API on port 3000
```

Open `http://localhost:3000/health`. If it answers, the API is running.

## 2. The shopper app

```bash
flutter pub get
flutterfire configure     # writes lib/firebase_options.dart (never commit it)
flutter run --dart-define=API_BASE_URL="http://localhost:3000"
```

For the web, add `-d chrome`.

## 3. The moderator console

It is the same code. One setting turns it on.

```bash
flutter run --dart-define=API_BASE_URL="http://localhost:3000" --dart-define=ADMIN_MODE=true
```

A new account is a shopper, so you land on the Unauthorized screen. Make yourself a moderator:

```bash
cd backend
npm run admin:set -- --email you@example.com --admin
```

Then sign out of the console and sign in again. The full story, including how to show both apps, is in [Moderator access](Moderator%20access.md).

## Build settings (`--dart-define`)

These are given when you run or build the app.

| Key | Example | What it does |
|---|---|---|
| `API_BASE_URL` | `https://api.example.com` | The API address. Required. Release builds stop if it is empty or not HTTPS. |
| `GOOGLE_WEB_CLIENT_ID` | `548247….apps.googleusercontent.com` | Needed for Google sign-in on the web |
| `MAPBOX_ACCESS_TOKEN` | `pk.eyJ1…` | Draws the map. Use a restricted public token. Without it the map is blank. |
| `ADMIN_MODE` | `true` or `false` | `true` builds the moderator console. Default is the shopper app. |

## About the map

The product plan asked for Google Maps. The app uses `flutter_map` with Mapbox tiles instead, so nobody needs a billing account just to start. If you want Google Maps later, add `google_maps_flutter` back and restrict its keys for each platform.

## Check that everything works

```bash
flutter analyze
flutter test
cd backend && npm test
python3 scripts/secret_scan.py
```

The same checks run on every pull request. The tests also draw every screen to a picture, so a layout that overflows fails the build. They are written to `build/screenshots/`.

## When something goes wrong

Read [Fixing problems](Fixing%20problems.md).
