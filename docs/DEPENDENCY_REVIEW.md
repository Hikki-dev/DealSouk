# DealSouk Dependency Review

Date: 2026-06-12
Branch: `feature/flutter-api-integration`

## Summary

`pubspec.yaml` already had the core MVP stack for Riverpod, routing, Firebase Auth, social sign-in, FCM, Firebase Storage, Dio, localization, geolocation, and image picking.

The missing MVP-required packages were added:

- `google_maps_flutter`
- `firebase_analytics`
- `firebase_crashlytics`
- `flutter_secure_storage`
- `mobile_scanner`

## MVP Dependency Matrix

| Dependency | Needed? | PRD Support | Why It Is Needed | Timing | Security / Privacy Notes |
|---|---|---|---|---|---|
| `flutter_riverpod` | Yes, already present | App architecture | Existing state-management pattern. | Now | Keep providers scoped by feature to avoid global state sprawl. |
| `go_router` | Yes, already present | Auth/admin routing | Declarative navigation and route guards. | Now | Admin access must remain guarded in `lib/app/route_guard.dart`. |
| `flutter_localizations`, `intl` | Yes, already present | Arabic/English UI, RTL | Localization and formatted numbers/dates/currency. | Now | Avoid hardcoded English in production screens. |
| `firebase_core` | Yes, already present | Firebase initialization | Required foundation for Firebase services. | Now | `lib/firebase_options.dart` should be generated locally/CI, not committed. |
| `firebase_auth` | Yes, already present | FR-01, FR-02, NFR-08 | Phone OTP and identity session handling. | Now | Use Firebase token verification server-side. |
| `google_sign_in` | Yes, already present | FR-02 | Google login. | Now | Restrict OAuth clients by package/bundle/domain. |
| `sign_in_with_apple` | Yes, already present | FR-02 | Apple login on iOS. | Now | Keep nonce hashing for Apple auth. |
| `firebase_messaging` | Yes, already present | Notifications, rank/badge updates | Push notifications for rewards and moderation events. | Now | Avoid PII in notification payloads. |
| `firebase_storage` | Yes, already present | Receipt/shelf photo upload | Stores price evidence images. | Now | Storage rules must require authenticated users and per-user paths. |
| `image_picker` | Yes, already present | Photo upload | Captures/selects receipt and price label images. | Now | Request only camera/photo permissions that are actually used. |
| `dio` | Yes, already present | Backend API client | HTTP client with auth token interceptor. | Now | Release builds reject non-HTTPS API URLs. |
| `geolocator` | Yes, already present | Nearby stores/prices | Foreground location for supermarket distance and radius search. | Now | Do not store precise GPS persistently. |
| `google_maps_flutter` | Yes, added | FR-08, NFR-04 | PRD calls for production map integration. Current UI still uses `flutter_map`; this package enables native Google Maps implementation. | Now | Inject restricted Maps API keys through build/CI settings. |
| `flutter_map`, `latlong2` | Keep for now | Map fallback/prototype | Existing store screen uses OSM tiles and lat/lng helpers. | Now, reassess later | OSM tile policy should be reviewed before production scale. |
| `mobile_scanner` | Yes, added | FR-13 | Barcode scanning for product lookup. | Now | Camera frames should not be uploaded unless user submits evidence. |
| `flutter_secure_storage` | Yes, added | Secure storage requirement | Provides Keychain/Keystore-backed storage for future app secrets/session metadata beyond Firebase Auth. | Now | Do not duplicate Firebase tokens unless strictly needed. |
| `firebase_crashlytics` | Yes, added | Reliability/observability | Crash reporting for production mobile builds. | Now | Scrub PII from custom keys/logs. |
| `firebase_analytics` | Yes, added | Analytics/usage measurement | Product analytics for funnels, search, submission conversion, and retention. | Now | Avoid precise location, phone, names, receipt contents, or raw search text if sensitive. |
| `cloud_firestore` | Review | Existing dependency | Not clearly used by current API-first implementation. | Later cleanup | Remove if unused after confirming no Firebase direct data path remains. |
| `crypto` | Yes, already present | Apple Sign-In nonce | Hashes Apple auth nonce. | Now | Low risk. |

## Packages Not Added

| Package | Reason |
|---|---|
| `permission_handler` | Not required yet; `geolocator` and platform permission prompts cover current location flow. Add only if opening settings or managing broader permissions. |
| Local database/cache packages | Offline mode is a PRD gap, but no cache design has been chosen. Add after deciding Hive/Drift/shared preferences scope. |
| Charting packages | Price history/trends are still missing; add a chart package when implementing those screens. |
| PDF/CSV export packages | Admin export is missing; choose backend export first before adding Flutter-side PDF dependencies. |

## Pubspec Changes Made

Added to `pubspec.yaml`:

```yaml
google_maps_flutter: ^2.17.1
firebase_analytics: ^11.6.0
firebase_crashlytics: ^4.3.10
flutter_secure_storage: ^10.3.1
mobile_scanner: ^7.2.0
```

`pubspec.lock` was updated by `flutter pub add`.
