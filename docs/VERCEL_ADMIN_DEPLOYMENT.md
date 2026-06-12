# Vercel Admin Web Deployment

Date: 2026-06-12

## What Vercel Should Host

Use Vercel for the DealSouk web admin console only.

Do not use this Vercel deployment as the public mobile app distribution path. Android and iOS should be distributed through internal APK/TestFlight first, then Play Store/App Store later.

## Required Vercel Environment Variables

Set these in Vercel Project Settings, not in git:

| Variable | Example | Notes |
|---|---|---|
| `FIREBASE_OPTIONS_DART_B64` | base64 text | Base64-encoded contents of `lib/firebase_options.dart`. |
| `API_BASE_URL` | `https://api.dealsouk.ae` | Must be HTTPS for release builds. |

Optional:

| Variable | Example |
|---|---|
| `VERCEL_PROJECT_PRODUCTION_URL` | `admin.dealsouk.ae` |

## How To Create `FIREBASE_OPTIONS_DART_B64`

Run locally after `flutterfire configure`:

```bash
base64 -i lib/firebase_options.dart | pbcopy
```

Paste the value into Vercel as `FIREBASE_OPTIONS_DART_B64`.

## Build Settings

Vercel uses:

- Build command: `bash ./vercel_build.sh`
- Output directory: `build/web`

The build script restores Firebase options from env and runs:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=ADMIN_MODE=true
```

## Security Rules

- Do not commit `lib/firebase_options.dart`.
- Do not commit `.env`, service accounts, signing keys, or Google service files.
- Restrict Firebase web API keys by Vercel/admin domain referrer.
- Restrict admin access in backend roles. The web route guard is not the source of truth.
- Set backend `ALLOWED_ORIGINS` to the final Vercel/admin URL.

## Backend Hosting

The backend should not be treated as solved by this Vercel Flutter web deployment. The current backend is an Express + Prisma API and is better deployed to a backend host such as Cloud Run, Fly.io, Render, Railway, or another Node/Postgres-capable platform with managed secrets, HTTPS, logs, and migrations.
