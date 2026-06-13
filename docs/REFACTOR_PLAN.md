# DealSouk Refactor Plan

> [!NOTE]
> **Active Staging Branch**: `stabilize/mvp-audit`
> For the current status of refactored files and testing validation, see **[STATUS.md](file:///Users/hikki/Desktop/DealSouk/docs/STATUS.md)**.

Date: 2026-06-13
Status: Applied on `stabilize/mvp-audit`

## Refactor Goal

Move from a prototype structure with shared global state and models into a readable feature-first Flutter architecture while keeping Riverpod, go_router, and the existing UI.

## Completed File Movement

| Legacy Location | Current Location | Status |
|---|---|---|
| `lib/app.dart` | `lib/app/app.dart` | Done |
| `lib/core/router/router.dart` | `lib/app/router.dart` | Done |
| new route guard | `lib/app/route_guard.dart` | Done |
| `lib/core/services/api_client.dart` | `lib/core/network/api_client.dart` | Done |
| `lib/core/services/storage_service.dart` | `lib/core/network/storage_service.dart` | Done |
| `lib/core/services/fcm_service.dart` | `lib/core/network/fcm_service.dart` | Done |
| `lib/core/services/auth_service.dart` | `lib/features/auth/data/auth_service.dart` | Done |
| `lib/core/state/auth_provider.dart` | `lib/features/auth/presentation/auth_providers.dart` | Done |
| `lib/core/state/state.dart` | feature-level providers | Done |
| `lib/core/models/models.dart` | feature-level domain files | Done |
| flat feature screens | `features/*/presentation/` | Done |
| feature API services | `features/*/data/` | Done |

## Remaining Safe Commit Sequence

1. **Document Firebase setup**
   - Add README setup for `flutterfire configure`.
   - Explain why `lib/firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist` are ignored.
   - Validation: fresh clone setup instructions are enough to run `flutter analyze`.

2. **Move mock store fallback behind dev-only provider**
   - Keep `dubai_stores_seed.dart`, but expose it through a mock repository/provider override.
   - Production provider should show an error/empty state when API fails instead of silently displaying seed data.
   - Validation: `flutter analyze`, widget smoke check on stores screen.

3. **Create profile domain model**
   - Move `ProfileData` out of `lib/features/profile/data/profile_service.dart` into `lib/features/profile/domain/profile_data.dart`.
   - Validation: `flutter analyze`, profile provider tests if available.

4. **Extract submission wizard controller**
   - Keep current UI, but move token-estimate and submit orchestration out of `submit_price_screen.dart`.
   - Validation: focused controller unit tests.

5. **Split admin dashboard widgets**
   - Extract moderation queue, submission detail panel, analytics mock panel, and settings panel.
   - Keep `AdminScreen` as a coordinator.
   - Validation: `flutter analyze`, admin web build.

6. **Add repository/provider seams only where useful**
   - Wrap service singletons in Riverpod providers.
   - Do not add abstract classes everywhere; add them when replacing mock/backend data or writing tests.

## Validation Gates

After each commit:

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- Backend-touched changes: `npm run build` from `backend/`

## Do Not Reintroduce

- A global `lib/core/state/state.dart`
- A global `lib/core/models/models.dart`
- Production screens directly reading mock data
- Hardcoded admin email checks
