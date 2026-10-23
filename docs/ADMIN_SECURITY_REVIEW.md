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

## Creating Or Removing Admins

Do not hardcode admin emails in Flutter or backend route guards.

After the user has signed in once and `/auth/verify` has created their backend profile, promote them from the backend with:

```bash
cd backend
npm run admin:set -- --email admin@example.com --admin
```

Or by Firebase UID:

```bash
cd backend
npm run admin:set -- --uid firebase_uid_here --admin
```

To remove admin access:

```bash
cd backend
npm run admin:set -- --email admin@example.com --no-admin
```

This upserts the Neon/Postgres `User` row, updates the backend `User.isAdmin` field, and sets Firebase custom claims. The backend `requireAdmin` middleware remains the source of truth for admin APIs.

Current production candidate check on 2026-06-13:

- Neon/Postgres contains 2 users.
- Neon/Postgres contains 1 admin user.
- The current admin user is `Yusuf Inam` with Firebase UID `HDdqHwjrlsYAium2FlK21yTdHSv1`.
- Firebase Auth user listing from CLI failed with insufficient service-account permission. Grant the service account Firebase Authentication admin/list permissions before using CLI audits to compare Firebase custom claims at scale.

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

Admin moderation now supports warning, suspension, and permanent ban actions. These actions are recorded in `AdminUserAction`, and affected users receive FCM notifications when an FCM token exists.
