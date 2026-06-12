# Admin Security Review

Date: 2026-06-12

## Scope

Reviewed admin access paths in the Flutter app and backend auth response.

Admin routes and entry points found:

- `/admin` in `lib/app/router.dart`
- Standalone `AdminApp` launched with `--dart-define=ADMIN_MODE=true`
- Profile screen shortcut to `/admin`
- Submit-price success dialog shortcut to `/admin`
- Backend admin API routes under `/admin/*`, already protected by `requireAuth` and `requireAdmin`

## Changes Made

- Added a centralized route guard in `lib/app/route_guard.dart`.
- Added `/unauthorized` and `UnauthorizedScreen`.
- Changed `/admin` behavior:
  - Unknown auth state: no redirect until resolved.
  - Unauthenticated users: redirect to `/welcome`.
  - Guest users: redirect to `/welcome`.
  - Authenticated non-admin users: redirect to `/unauthorized`.
  - Admin users: allowed through.
- Updated `AuthState` to use a role set instead of production email checks.
- Added `AuthRole` parsing from `roles`, `role`, and legacy `isAdmin`.
- Added a debug-only `DEV_MOCK_ADMIN` dart define for prototype/dev admin testing.
- Updated `/auth/verify` to return `role` and `roles` while retaining `isAdmin` compatibility.
- Hid admin shortcuts from non-admin users in:
  - Profile screen
  - Submit-price success dialog

## Production Role Model

Production admin access must be based on backend-issued role data, such as Firebase custom claims or backend profile claims. The client now expects a claims-style model:

- `roles: ["user", "admin"]`
- `role: "admin"`

The old `isAdmin` field is still accepted only as a compatibility bridge while the backend/database model is migrated.

No production admin email is hardcoded in the client.

## Dev Mock Admin

Prototype admin access can be enabled only in debug mode with:

```sh
flutter run --dart-define=DEV_MOCK_ADMIN=true
```

This mock path is ignored in release builds by the `kDebugMode` check.

## Tests Added

Added `test/app/route_guard_test.dart` covering:

- Guest cannot access admin.
- Normal authenticated user cannot access admin.
- Admin user can access admin.

## Notes

Frontend route guards are a usability and defense-in-depth layer. The backend `requireAdmin` middleware remains the authority for protecting admin data and mutations.
