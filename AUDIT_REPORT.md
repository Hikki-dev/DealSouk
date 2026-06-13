# DealSouk Audit Report

> [!NOTE]
> **Historical Document Notice**: This document represents the initial codebase audit performed on June 12, 2026. Many of the critical issues, missing tests, and router safety gaps identified below have been resolved on the current `stabilize/mvp-audit` branch.
> For the live operational status and remaining deployment blockers, see the single source of truth: **[STATUS.md](file:///Users/hikki/Desktop/DealSouk/docs/STATUS.md)**.

Date: 2026-06-12
Workspace branch at audit time: `feature/flutter-api-integration`

## Executive Summary

- Branches: the three feature branches are `feature/backend-foundation`, `feature/firebase-auth`, and `feature/flutter-api-integration`. `main` and `production` also exist and point to the same commit.
- Prototype branch: `main`/`production` are effectively the prototype/demo branch because they are mock-data driven and contain prototype/demo UI copy.
- Production candidate: `feature/flutter-api-integration` is the production candidate because it adds backend API services, Firebase Auth, Prisma schema, routes, FCM, storage, cart persistence, admin queue APIs, and token-engine logic.
- Production vs main: `production` and `main` are identical at commit `be2b2de7f6d0052522141ab90312e9e9c1c7bf0b`; no diff.
- Copied code cleanup: the current production candidate had an orphaned `lib/core/mock_data/mock_data.dart`; it was removed. The named `production` branch still actively depends on that file, so deleting it there would break the app.
- PRD source: no PRD file exists in the repo. FR/NFR statuses below are based on code evidence and inline requirement references, not authoritative PRD wording.
- Production verdict: not production-ready yet. It is a credible MVP production candidate after a focused cleanup pass, security/config hardening, and a minimum test suite.
- Maintainability verdict: understandable by another Flutter developer, but only after orientation. The app is not hopelessly over-engineered; it is under-separated in places, with several large screen files and centralized state that now behave like spaghetti pressure points.

## Priority Findings

### Critical Issues

| Issue | Files | Why it blocks production | Recommended fix |
|---|---|---|---|
| HTTP backend default is hardcoded | `lib/core/services/api_client.dart` | Production API traffic can use plaintext HTTP and a private/local IP by default. | Require `API_BASE_URL`; fail fast in release if missing or non-HTTPS. |
| Maps keys are placeholders | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/AppDelegate.swift`, `web/index.html` | Maps cannot be considered production-integrated. Placeholder values also hide release config gaps. | Inject keys per platform through CI/build config; document setup. |
| No test suite exists | `test/`, `integration_test/` | `flutter test` fails because there are no tests. Token, cart, auth, requests, moderation, RTL, and accessibility behavior are unprotected. | Add focused unit/widget/integration tests before feature refactors. |
| Admin access has a legacy unguarded router path | `lib/core/router/router.dart` | `routerProvider` guards `/admin`, but legacy `appRouter` still exposes routes without equivalent redirect logic. | Remove `appRouter` or make it impossible to import/use in production. |
| Ignored local Firebase config and env files are present | `backend/.env`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart` | They are ignored, but any accidental commit or screen share can leak project identifiers/config. | Keep ignored, verify never tracked, rotate if previously exposed, document secret handling. |

### High Priority Issues

| Issue | Files | Impact | Recommended fix |
|---|---|---|---|
| Mock/prototype UI remains in production candidate | `lib/features/cart/cart_screen.dart`, `lib/features/stores/store_screen.dart`, `lib/features/admin/admin_screen.dart`, `lib/core/widgets/tutorial_overlay.dart`, `lib/features/leaderboard/leaderboard_screen.dart` | Users/admins can see demo/prototype language and mock-only panels. | Remove demo copy, gate mock-only panels behind dev flags, or replace with real backend data. |
| Giant screen files mix UI and workflow logic | `lib/features/admin/admin_screen.dart`, `lib/features/home/home_screen.dart`, `lib/features/leaderboard/leaderboard_screen.dart`, `lib/features/profile/profile_screen.dart`, `lib/features/cart/cart_screen.dart`, `lib/features/products/product_detail_screen.dart`, `lib/features/auth/welcome_screen.dart` | Increases regression risk and slows onboarding. | Extract feature widgets and small controllers incrementally. |
| Centralized app state is too broad | `lib/core/state/state.dart` | Products, stores, cart, submissions, requests, badges, challenges, locale, and profile are coupled in one file. | Move providers beside their features while keeping Riverpod simple. |
| API service layer lacks environment and error strategy | `lib/core/services/*.dart`, `lib/core/services/api_client.dart` | Screens get silent failures and empty states; release behavior is unclear. | Add small `AppConfig`, typed API errors, and visible retry/error state where needed. |
| Admin dashboard is only partially real | `lib/features/admin/admin_screen.dart`, `lib/features/admin/admin_app.dart`, `backend/src/routes/admin.ts` | Some admin panels are mock-only; admin strategy is not fully production-operable. | Keep moderation/settings for MVP; remove or hide unfinished panels. |
| Dependency vulnerabilities/outdated packages | `backend/package-lock.json`, `backend/package.json`, `pubspec.yaml`, `pubspec.lock` | `npm audit` reports 8 moderate vulnerabilities; many Flutter packages lag major versions. | Upgrade deliberately in small PRs; avoid blind force upgrades without testing. |

### Medium Priority Issues

| Issue | Files | Impact | Recommended fix |
|---|---|---|---|
| Localization is present but incomplete | `lib/l10n/*.arb`, `lib/features/**/*.dart` | Many UI strings appear hardcoded in English; Arabic/RTL coverage cannot be claimed. | Move user-facing strings into ARB files screen by screen. |
| RTL is unverified | `lib/app.dart`, `lib/features/profile/profile_screen.dart`, `lib/l10n/*` | Flutter supports RTL, but screenshots/tests are absent. | Add Arabic golden/smoke screenshots for home, product, cart, submit, leaderboard, profile. |
| Accessibility is mostly implicit | `lib/features/**/*.dart`, `lib/core/widgets/*.dart` | No explicit semantic labels, focus audits, contrast checks, or text-scale checks. | Add semantics for icon-only/custom controls and widget tests for key flows. |
| Typed models use string statuses | `lib/core/models/models.dart`, `backend/prisma/schema.prisma`, backend routes | Stringly typed states can drift across client/server. | Add Dart enums and backend validation when touching those flows. |
| Token economy lacks tests | `backend/src/services/tokenEngine.ts`, `backend/src/routes/admin.ts`, `backend/src/routes/requests.ts` | Ledger and reward regressions are high-impact. | Add backend unit tests around earn/spend/decay/streak/refund. |
| Release configs are incomplete | `android/app/build.gradle.kts`, platform config files | Android signing TODO and platform key placeholders remain. | Add release checklist/config templates. |

### Low Priority Issues

| Issue | Files | Impact | Recommended fix |
|---|---|---|---|
| README is still starter-level | `README.md` | Onboarding friction. | Replace with setup, env, Firebase, Maps, backend, and release instructions. |
| Generated Flutter platform files add noise | `windows/`, `linux/`, `macos/` | Not harmful, but broadens maintenance surface if unsupported. | Keep only if desktop/web builds are intentionally supported; otherwise document as generated/unofficial. |
| Some comments reference mock UI elements | `lib/core/widgets/tutorial_overlay.dart`, `lib/features/leaderboard/leaderboard_screen.dart` | Mostly cosmetic, but weakens production confidence. | Rename comments when replacing demo visuals. |

## What Is Good

- The app has a sensible initial shape: `lib/core` plus `lib/features`.
- Riverpod is already adopted, and providers are simple enough to refactor without a framework migration.
- Firebase Auth is integrated with phone OTP, Google, Apple, and guest browsing.
- Backend integration exists through service classes rather than direct HTTP calls in most widgets.
- Prisma schema covers users, products, stores, submissions, flags, token transactions, requests, badges, cart items, and daily challenges.
- Backend admin routes, moderation queue, token engine, request expiry/refund, and FCM notification paths exist.
- `.gitignore` blocks common env, Firebase config, service account, node, and build artifacts.
- `flutter analyze` is clean after small lint fixes.
- Backend TypeScript build passes.

## What Should Not Be Changed Yet

- Do not replace Riverpod. The problem is organization and provider boundaries, not the state-management tool.
- Do not introduce a heavy enterprise clean-architecture framework across the whole app. Use `data/domain/presentation` only where it clarifies real feature boundaries.
- Do not rewrite every screen before adding tests. The large files are risky; tests should precede deeper extraction.
- Do not replace Firebase Auth or Prisma as part of the cleanup. They are adequate for the MVP.
- Do not build a complex offline-first sync system unless offline mode is confirmed as MVP-critical. For MVP, explicit online-only behavior plus graceful failures may be acceptable if PRD allows.

## What Must Be Refactored Before Production

| Refactor | Files | Target outcome |
|---|---|---|
| API/environment config | `lib/core/services/api_client.dart`, build docs, platform release config | No hardcoded HTTP/IP defaults in release. |
| Router cleanup | `lib/core/router/router.dart`, `lib/app.dart` | One router source of truth with auth/admin/guest guards. |
| Mock/demo cleanup | `lib/features/cart/cart_screen.dart`, `lib/features/stores/store_screen.dart`, `lib/features/admin/admin_screen.dart` | No prototype/demo language or mock-only admin panels in production builds. |
| State separation | `lib/core/state/state.dart` | Move feature state to feature folders while preserving current behavior. |
| Large screen decomposition | `admin_screen.dart`, `home_screen.dart`, `leaderboard_screen.dart`, `profile_screen.dart`, `cart_screen.dart`, `product_detail_screen.dart`, `welcome_screen.dart` | Smaller widgets/controllers that a new developer can understand. |
| Test baseline | `test/`, `integration_test/`, backend test setup | Guard token engine, cart logic, auth routing, submission, request, leaderboard, RTL smoke checks. |

## What Can Stay For MVP

- Current visual design and most UI composition can stay if demo copy is removed.
- Current Riverpod Notifier approach can stay.
- Service classes in `lib/core/services` can stay temporarily while moving feature by feature.
- Backend route structure can stay for MVP; add validation/tests before a larger backend reorganization.
- Guest browsing can stay, with submit/profile restrictions.
- Admin dashboard can stay if unfinished tabs are hidden and moderation/settings are real.

## Branch Audit

| Branch | Role | Evidence | Audit result |
|---|---|---|---|
| `feature/backend-foundation` | Backend foundation | Adds backend scaffold and Firebase cleanup lineage. | Intermediate, not app-complete. |
| `feature/firebase-auth` | Auth integration | Adds real Firebase Auth, phone OTP, Google, Apple, guest mode. | Intermediate, closer to production. |
| `feature/flutter-api-integration` | Production candidate | Adds backend services, API client, Prisma schema, route layer, FCM, admin APIs. | Best production candidate, but not production-ready. |
| `main` | Prototype/demo baseline | Same commit as `production`; mock-data driven UI. | Prototype baseline. |
| `production` | Named production branch | Same commit as `main`; depends on `MockData`. | Not a true production implementation yet. |

## PRD Coverage: FR-01 to FR-62

| ID | Area inferred from code | Status | Evidence / gap |
|---|---|---|---|
| FR-01 | Product catalog/search | Done | `ProductsService.search`, `/products/search`, typed `Product`. |
| FR-02 | Product categories/filtering | Partial | Category params and UI filters exist; no taxonomy/admin governance. |
| FR-03 | Product detail price list | Done | `getPrices`, `/products/:id/prices`, product detail screen. |
| FR-04 | Store discovery | Done | `StoresService.getNearby`, `/stores/nearby`, store screen. |
| FR-05 | Location-aware store distance | Partial | Geolocator and lat/lng exist; local fallback/demo copy remains. |
| FR-06 | User onboarding/auth | Done | Firebase phone, Google, Apple, guest mode. |
| FR-07 | First approved submission bonus | Done | `checkFirstSubmissionBonus` and admin approval route. |
| FR-08 | Profile basics | Done | `/profile/me`, profile state sync. |
| FR-09 | Preferred home area | Done | Profile model and UI update flow. |
| FR-10 | Language preference | Partial | Locale provider and l10n exist; backend persistence appears limited. |
| FR-11 | Product price submission | Done | Submit screen, `SubmissionsService.submit`, `/submissions`. |
| FR-12 | Price validation | Partial | Backend requires fields; stronger range/anomaly validation not evident. |
| FR-13 | Receipt/photo upload | Partial | Firebase Storage service exists; backend receipt URL stored. End-to-end proof missing. |
| FR-14 | Submission pending queue | Done | `PriceSubmission.status`, `/admin/queue`. |
| FR-15 | Admin approve/reject | Done | `/admin/submissions/:id/approve`, reject route and UI. |
| FR-16 | Admin edit submission | Done | `/admin/submissions/:id` PATCH. |
| FR-17 | Submission flagging | Done | `SubmissionFlag`, flag count, admin handling. |
| FR-18 | Hide/reject bad data | Partial | Status supports rejected/hidden; automated moderation is limited. |
| FR-19 | Freshness labels | Done | Model computes freshness and updated labels. |
| FR-20 | Stale price handling | Partial | Expiry exists; stale filtering is basic. |
| FR-21 | Cart add/remove/update | Done | `CartNotifier`, cart screen. |
| FR-22 | Best-price cart comparison | Partial | UI optimization exists; no unit test and algorithm is not isolated. |
| FR-23 | Cart persistence | Done | `/profile/me/cart` GET/PUT and `CartItem` table. |
| FR-24 | Cart checkout/order | Mock Only | Cart confirmation still says prototype flow complete. |
| FR-25 | Token balance | Done | `User.tokenBalance`, profile sync, token transactions. |
| FR-26 | Token transaction history | Done | `/profile/me/transactions`, typed `TokenTransaction`. |
| FR-27 | Price request creation | Done | `/requests`, request board flow. |
| FR-28 | Request fulfillment notification | Done | Request fulfill route calls FCM notifier. |
| FR-29 | Request expiry/refund | Done | Lazy expiry refund logic in requests route. |
| FR-30 | User request history | Done | `/profile/me/requests`, `/requests/mine`. |
| FR-31 | Leaderboard | Done | `/leaderboard/monthly`, leaderboard service/screen. |
| FR-32 | Current user leaderboard position | Done | API returns current user outside top 10. |
| FR-33 | Reward decay formula | Done | `computeReward` duplicate-submission decay. |
| FR-34 | Daily submission cap | Done | Profile cap and backend settings reference. |
| FR-35 | Receipt bonus | Done | Token engine receipt multiplier. |
| FR-36 | Store/product seed data | Partial | Prisma seed exists, but includes dummy Firebase UID. |
| FR-37 | Nearby map view | Partial | Google Maps exists; placeholder API keys remain. |
| FR-38 | Push notification registration | Done | `FcmService` registers token. |
| FR-39 | Foreground notification UI | Done | `showFcmBanner`. |
| FR-40 | Backend auth verification | Done | `/auth/verify` and Firebase Admin middleware. |
| FR-41 | Guest browsing | Done | Guest mode and route guards. |
| FR-42 | Guest submit restrictions | Done | Router blocks guest submit/profile. |
| FR-43 | Account deletion/profile deletion | Partial | Profile route has deletion markers; full UX/compliance not verified. |
| FR-44 | Accuracy rating | Partial | Model field exists; update algorithm not clearly complete. |
| FR-45 | Badges | Done | Badge/UserBadge schema and token-engine unlocks. |
| FR-46 | Streak milestones | Done | Streak logic and FCM in token engine. |
| FR-47 | Daily challenges | Done | Schema, route, service, progress update. |
| FR-48 | User levels | Done | Level multiplier and badge unlocks. |
| FR-49 | Voucher threshold | Partial | Token engine checks threshold; voucher redemption UX not verified. |
| FR-50 | Admin settings | Done | `/admin/settings`, settings UI/service. |
| FR-51 | Admin dashboard | Partial | UI exists, but some tabs explicitly mock-only. |
| FR-52 | Admin route protection | Partial | Client guard and backend admin middleware exist; static `appRouter` remains unguarded legacy. |
| FR-53 | Multi-platform Flutter app | Partial | iOS/Android/Web present; release configs incomplete. |
| FR-54 | Arabic localization | Partial | ARB/localizations exist; full screen translation incomplete. |
| FR-55 | RTL layout | Partial | Flutter locale support exists; RTL screenshots/tests absent. |
| FR-56 | Admin edit price/product/store | Done | Admin PATCH route and service. |
| FR-57 | Moderation queue | Done | Pending queue and actions exist. |
| FR-58 | Suspension/abuse controls | Partial | User schema has suspension fields; enforcement not evident. |
| FR-59 | Real backend integration | Partial | API services exist; hardcoded HTTP default and no integration tests. |
| FR-60 | Offline mode | Missing | No local cache/sync queue/offline storage strategy. |
| FR-61 | Accessibility | Partial | Flutter widgets have some semantics by default; no explicit a11y tests/audit. |
| FR-62 | Release readiness | Partial | Builds/analyze pass; secrets, Maps keys, tests, release signing still incomplete. |

## NFR Coverage: NFR-01 to NFR-25

| ID | Area inferred from audit request | Status | Evidence / gap |
|---|---|---|---|
| NFR-01 | Performance | Partial | Indexed DB fields and API pagination signs exist; no profiling/budgets. |
| NFR-02 | Availability/reliability | Partial | Backend exists; no health checks, retries beyond token refresh. |
| NFR-03 | Security | Partial | Firebase Admin auth and Helmet exist; HTTP default URL and local config risks remain. |
| NFR-04 | Privacy | Partial | No committed service account, but local Firebase config exists and deletion/compliance unclear. |
| NFR-05 | Accessibility | Partial | No dedicated accessibility tests. |
| NFR-06 | Localization | Partial | English/Arabic files exist; not all UI strings appear localized. |
| NFR-07 | RTL | Partial | Locale support exists; no screenshot verification. |
| NFR-08 | Offline support | Missing | No offline persistence or sync queue. |
| NFR-09 | Rate limiting | Done | Submission route has express rate limit comment/implementation. |
| NFR-10 | Input validation | Partial | Basic validation exists; schema validator layer absent. |
| NFR-11 | AuthN/AuthZ | Partial | Firebase + admin checks; static unguarded legacy router should be removed. |
| NFR-12 | Secret management | Partial | `.gitignore` is good; ignored local secrets exist and need rotation hygiene. |
| NFR-13 | HTTPS-only | Missing | Flutter default backend URL is `http://100.69.54.28:3000`. |
| NFR-14 | Observability | Missing | No structured logging, tracing, or error reporting evident. |
| NFR-15 | Testability | Partial | Logic exists but few/no tests. |
| NFR-16 | Maintainability | Partial | Services exist, but giant widgets/state file need splitting. |
| NFR-17 | Scalability | Partial | Prisma indexes exist; no load testing or caching. |
| NFR-18 | Data integrity | Partial | Token ledger is transactional; moderation and idempotency gaps remain. |
| NFR-19 | Backup/recovery | Missing | No backup or restore docs/config. |
| NFR-20 | CI/CD | Missing | No CI workflow found. |
| NFR-21 | Dependency hygiene | Partial | `flutter pub outdated` and npm audit show upgrades/vulnerabilities. |
| NFR-22 | Platform release config | Partial | Platform folders exist; signing configs placeholders remain. |
| NFR-23 | Maps reliability | Partial | Maps package/config present; placeholder API keys remain. |
| NFR-24 | Admin auditability | Missing | No admin action audit log model found. |
| NFR-25 | Documentation | Partial | README is Flutter starter text; no PRD/setup/runbook coverage. |

## Flutter Architecture Audit

- Folder structure: `lib/core` plus `lib/features/*` exists and is a good start.
- Feature separation: screens are separated by feature, but feature-local models/state/repositories are not. Most state remains centralized in `lib/core/state/state.dart`.
- State separation per feature: partial. Riverpod notifiers exist, but central file is 755 lines.
- Business logic outside widgets: partial. API calls are in services, but large screens still contain non-trivial flow logic and mock/demo presentation branches.
- Repositories/data sources: partial. Service classes exist, but repository interfaces and testable data-source boundaries do not.
- Mock data isolation: improved on current branch by deleting orphaned `lib/core/mock_data/mock_data.dart`; production branch still depends on mock data.
- Typed models: partial. Dart models and Prisma schema are typed, but status values are strings instead of enums in several places.
- Navigation/auth guards: partial. `routerProvider` has guards for auth/admin/guest. Legacy static `appRouter` is still present and unguarded.
- Huge files needing split: `admin_screen.dart` 2386 lines, `home_screen.dart` 1383, `leaderboard_screen.dart` 1272, `profile_screen.dart` 1009, `cart_screen.dart` 830, `product_detail_screen.dart` 818, `welcome_screen.dart` 802.

## Security Audit

- API keys/secrets: no committed service-account private key was found, but local ignored files exist: `backend/.env`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`.
- Firebase config files: ignored by `.gitignore`, but present locally. Do not commit; rotate if they were ever exposed.
- Google Maps: placeholders remain in `android/app/src/main/AndroidManifest.xml`, `ios/Runner/AppDelegate.swift`, and `web/index.html`.
- Bearer tokens/passwords: no hardcoded bearer token found. `.env.example` contains expected placeholders.
- Hardcoded users/URLs: `backend/prisma/seed.ts` contains `dummy_seed_sourcer_uid`; `api_client.dart` defaults to `http://100.69.54.28:3000`; admin allowlist defaults to sample emails.
- HTTPS-only backend access: not confirmed. Current default is HTTP.
- Admin route protection: backend routes use auth/admin middleware, and `routerProvider` guards `/admin`; legacy `appRouter` should be removed or guarded.

## Code Quality Audit

Commands run:

- `dart format .`: completed; 22 files changed plus ignored local `lib/firebase_options.dart`.
- `flutter analyze`: initially 2 lint issues; fixed. Final result: no issues.
- `flutter test`: failed because `test/` has no `*_test.dart` files.
- `flutter pub outdated`: 27 dependencies constrained below resolvable/latest versions.
- `npm audit --audit-level=moderate`: failed with 8 moderate vulnerabilities through `firebase-admin` dependency chain; force fix would install `firebase-admin@14.0.0` with breaking-change risk.
- `npm run build`: passed.

Unused/prototype cleanup:

- Removed unused `lib/core/mock_data/mock_data.dart` from `feature/flutter-api-integration`.
- Remaining prototype/demo strings exist in cart, stores, and admin screens.

## Production Readiness Audit

| Area | Status | Notes |
|---|---|---|
| Firebase Auth | Partial | Integrated, but local config files are ignored and setup depends on generated config. |
| Maps | Partial | Package and screens exist; API keys are placeholders. |
| Backend API | Partial | Services and routes exist; default URL is hardcoded HTTP. |
| Submission flow | Partial | Flutter service and backend route exist; real backend integration test missing. |
| Cart persistence | Done | Backend cart endpoints and Flutter sync exist. |
| Token ledger integrity | Partial | Earn/spend uses Prisma transactions; lacks tests/idempotency checks. |
| Moderation queue | Done | Pending queue, approve/reject/edit exist. |
| Admin dashboard strategy | Partial | Separate admin mode exists; some panels are mock-only. |
| iOS/Android release configs | Partial | Platform projects exist; Android signing TODO and Maps placeholders remain. |

## Testing Audit

- Unit tests: missing for token engine, cart best-price logic, decay formula.
- Widget tests: missing for important screens.
- Integration tests: missing for auth, cart, submit price, request, leaderboard.
- RTL Arabic screenshots: missing.
- Accessibility checks: missing.

## Recommended Next Actions

1. Decide branch naming: promote `feature/flutter-api-integration` to production candidate or rename `production` after merge.
2. Remove or guard legacy `appRouter`.
3. Replace HTTP default backend URL with required `API_BASE_URL` and enforce HTTPS for release builds.
4. Replace Maps placeholders with environment/CI injected values.
5. Split large feature screens and move business logic into feature controllers/repositories.
6. Add unit tests for token engine, cart optimization, request expiry/refunds, and reward decay.
7. Add integration tests for auth, cart persistence, submit price, request fulfillment, leaderboard, RTL, and accessibility.
8. Add CI for Flutter analyze/test, backend build/test, dependency audit, and secret scan.

## Recommended Flutter Folder Structure

Keep the MVP simple. Do not force every feature to have all layers if it only needs a screen and one provider.

```text
lib/
  main.dart
  app.dart
  core/
    config/
      app_config.dart
    api/
      api_client.dart
      api_error.dart
    auth/
      auth_service.dart
      auth_provider.dart
    l10n/
    router/
      router.dart
    theme/
    widgets/
  features/
    products/
      data/
        products_repository.dart
      domain/
        product.dart
        store_product_price.dart
      presentation/
        product_detail_screen.dart
        search_screen.dart
        product_card.dart
        product_providers.dart
    stores/
      data/
      domain/
      presentation/
    cart/
      data/
        cart_repository.dart
      domain/
        cart_item.dart
        cart_optimizer.dart
      presentation/
        cart_screen.dart
        cart_providers.dart
    submissions/
      data/
      domain/
      presentation/
    requests/
      data/
      domain/
      presentation/
    leaderboard/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
    admin/
      data/
      domain/
      presentation/
    challenges/
      data/
      domain/
      presentation/
```

Rules for applying this structure:

- Use `domain/` only for models or pure business logic that is shared or tested.
- Use `data/` for API/repository code that talks to `ApiClient`.
- Use `presentation/` for screens, widgets, and Riverpod providers/controllers used by UI.
- Keep `core/` for cross-cutting infrastructure only: config, API client, auth primitives, router, theme, shared widgets.
- Do not create empty folders just to satisfy architecture purity.

## Safest Refactor Plan In Small Commits

### Commit 1: Document Audit Baseline

- Add this audit report.
- Keep behavior unchanged.
- Include command results: `flutter analyze`, `flutter test`, `flutter pub outdated`, `npm audit`, `npm run build`.

### Commit 2: Production Config Guardrails

- Update `lib/core/services/api_client.dart` or move it to `lib/core/api/api_client.dart`.
- Require `API_BASE_URL` for release builds.
- Reject non-HTTPS release URLs.
- Keep local HTTP allowed only in debug/profile.
- Add README setup notes.

### Commit 3: Router Single Source Of Truth

- Remove or deprecate legacy `appRouter` in `lib/core/router/router.dart`.
- Ensure only `routerProvider` is used.
- Add tests for unauthenticated, guest, authenticated, and non-admin `/admin` redirects.

### Commit 4: Hide Prototype/Demo Surfaces

- Remove user-facing prototype copy in `lib/features/cart/cart_screen.dart`.
- Replace `GPS demo active` in `lib/features/stores/store_screen.dart`.
- Hide or remove mock-only admin panels in `lib/features/admin/admin_screen.dart`.
- Keep any dev-only preview behind a `bool.fromEnvironment('DEMO_MODE')` flag if truly needed.

### Commit 5: Establish Test Baseline

- Add unit tests for cart optimizer, token reward decay, request spend/refund, and auth route guards.
- Add one widget smoke test each for welcome, home, search, product detail, cart, submit price, leaderboard, profile.
- Add Arabic/RTL smoke test for home/cart/profile.

### Commit 6: Split Cart Feature First

- Extract pure cart best-price logic into `features/cart/domain/cart_optimizer.dart`.
- Move cart provider into `features/cart/presentation/cart_providers.dart`.
- Keep `CartScreen` behavior unchanged.

### Commit 7: Split Products And Stores

- Move product/store models and service/repository code into feature folders.
- Keep public provider APIs stable while screens migrate.
- Add tests around product parsing and stale/fresh labels.

### Commit 8: Split Admin Carefully

- Break `admin_screen.dart` into queue, settings, metrics, and shell widgets.
- Keep moderation queue and settings real.
- Remove unfinished mock panels from production.
- Add backend tests for approve/reject/edit authorization.

### Commit 9: Localization And RTL Completion

- Move hardcoded user-facing strings into ARB files feature by feature.
- Verify Arabic text, layout direction, overflow, and text scaling.
- Add screenshot or golden smoke checks for key Arabic screens.

### Commit 10: Release Readiness

- Add platform release config docs.
- Add CI checks for Flutter analyze/test, backend build/test, npm audit, secret scan.
- Add dependency upgrade PRs separately, starting with backend audit fix.

## Developer Continuation Assessment

- Can another developer continue this project? Yes, but they will need a short technical onboarding document and should start with router/config/tests before touching UI decomposition.
- Is the app overcomplicated? Not globally. It uses common Flutter/Firebase/Riverpod/Dio patterns. The risk is that the architecture is uneven: some production infrastructure exists while UI/state still has prototype-era density.
- Is the app under-engineered? In testing, configuration, localization verification, accessibility, and release discipline, yes.
- Is any part spaghetti code? The highest-risk spaghetti areas are `lib/features/admin/admin_screen.dart`, `lib/core/state/state.dart`, and the larger feature screens where widget layout, API state, local workflow logic, and demo affordances live together.
- Can it be made production-readable without a rewrite? Yes. The safest path is small extractions backed by tests, not a framework migration.
