# Firebase Production Setup

Date: 2026-06-12

## Required Firebase Services

| Service | Required For |
|---|---|
| Firebase Authentication | Phone OTP, Google Sign-In, Apple Sign-In, Firebase ID tokens. |
| Firebase Cloud Messaging | Request fulfilled, reward, badge, and moderation notifications. |
| Firebase Storage | Receipt photos, price-label photos, optional profile photos. |
| Firebase Crashlytics | Production crash visibility. |
| Firebase Analytics | Basic anonymised product analytics. |

## Required Setup

1. Create separate Firebase projects for staging and production.
2. Register Android and iOS apps with final package/bundle IDs.
3. Enable Phone, Google, and Apple auth providers.
4. Configure APNs for iOS notifications.
5. Configure OAuth client restrictions for Google Sign-In.
6. Deploy Storage rules from `firebase/storage.rules`.
7. Restrict Google/Firebase API keys by package name, bundle ID, SHA fingerprints, and web referrer.
8. Generate Flutter config locally:

```bash
flutterfire configure
```

## Files That Must Not Be Committed

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Firebase Admin service-account JSON

Use GitHub Secrets for CI:

- `FIREBASE_OPTIONS_DART_B64`
- `GOOGLE_SERVICES_JSON_B64`
- `GOOGLE_SERVICE_INFO_PLIST_B64`

## Admin Role Model

Production admin access must come from backend/Firebase role claims or a backend user role field. Do not hardcode admin emails in the app. Backend admin endpoints must remain protected by `requireAuth` and `requireAdmin`.

## Storage Rules

Current Storage rules:

- Users can upload only to their own receipt/price-label/avatar folder.
- Receipt and price-label uploads are image-only and capped at 8 MB.
- Avatar uploads are image-only and capped at 4 MB.
- All other paths are denied.

Server-side malware scanning is still required before public production release.
