# Mobile Device Build Checklist

Date: 2026-06-12
Branch: `feature/flutter-api-integration`

## Why The iPhone Build Looked Empty

The app shell can run on device, but live data depends on the backend API and Firebase setup.

Issues found from the device screenshots:

- Home category/promo artwork referenced `assets/...` files that did not exist in the repository.
- Store map uses static Dubai store fallback data when the backend is unavailable.
- Static store fallback IDs do not always match backend database IDs, so store price sheets could show "Could not load prices".
- A device build without `--dart-define=API_BASE_URL=...` used the default API URL.
- The current Render API URL is not live yet; `/health` returns Render `404 no-server`.

## Fixed In Code

- Removed missing home asset references and replaced them with built-in Flutter icon artwork.
- Added fallback store prices for static Dubai store IDs.
- Store price sheets now use fallback prices when backend prices are empty or unreachable.
- Default API URL now points to the planned HTTPS Render backend:

```text
https://dealsouk.onrender.com
```

## Required Before Real Device Testing

### Backend

Render must have a live Web Service for the backend.

Expected health check:

```bash
curl https://dealsouk.onrender.com/health
```

Expected response:

```json
{"status":"ok"}
```

If this returns `404 no-server`, the backend is not deployed yet and the app cannot load live products, prices, profile, requests, tokens, admin data, or submissions.

### iOS

Required local files:

- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Build command for local testing:

```bash
flutter build ios --debug --no-codesign --dart-define=API_BASE_URL=https://dealsouk.onrender.com
```

For physical device deployment through Xcode, pass the same Dart define in the Flutter build settings or use Flutter CLI to run:

```bash
flutter run -d <device-id> --dart-define=API_BASE_URL=https://dealsouk.onrender.com
```

### Android

Required local files:

- `android/app/google-services.json`
- `lib/firebase_options.dart`

Build command for local testing:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=https://dealsouk.onrender.com
```

### Firebase Storage

Firebase Storage must be enabled in the Firebase console before photo uploads can work.

After enabling Storage, deploy rules:

```bash
firebase deploy --only storage:rules --project dealsouk-6e140
```

## What Works Without Backend

- App shell
- Home layout
- Static Dubai store map
- Static fallback store price sheet for demo stores
- Cart local state
- Basic navigation

## What Needs Backend

- Auth-backed profile
- Real product search
- Real approved store prices
- Submit price
- Request price
- Tokens and voucher requests
- Leaderboard
- Admin moderation
- Push notifications

## Safe Secret Handling

Do not commit:

- `.env`
- `backend/firebase-service-account.json`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`
- signing keys, keystores, provisioning profiles, or `.p8` files

Use GitHub/Vercel/Render secrets for CI and deployment.
