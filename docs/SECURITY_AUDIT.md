# DealSouk Security Audit

Date: 2026-06-12
Branch audited: `feature/flutter-api-integration`
Scope: Flutter app, platform manifests, backend auth/admin routes, local config hygiene.

## Summary

| Severity | Count | Notes |
|---|---:|---|
| Critical | 0 | No current client-side admin bypass or plaintext release API default found. |
| High | 4 | Local secrets exist outside git, Firebase config history risk, PII/privacy gaps, mock/admin affordances. |
| Medium | 9 | Permission wording, analytics/crash setup, mock fallbacks, export/monitoring gaps, dependency advisory follow-up. |
| Low | 2 | Cleanup/readme/documentation polish. |
| Passed | 6 | Auth token attachment, admin route guard, HTTPS client guard, background location avoidance, `.env` gitignore, backend admin middleware. |

## Security Matrix

| # | Check | Rating | Evidence | Finding | Action |
|---|---|---|---|---|---|
| 1 | API keys committed in repo | High | `.gitignore`, `git ls-files` | No secret config files are currently tracked, but local ignored files exist: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`, `backend/.env`, `backend/firebase-service-account.json`. Firebase config files were previously tracked in branch history. | Keep ignored; rotate any exposed keys; purge history before public release. |
| 2 | Firebase config exposure | High | `lib/firebase_options.dart` ignored but present locally; `docs/FIREBASE_PRODUCTION_SETUP.md` | Flutter analysis in a clean clone requires Firebase options from CI secret or local generation. Firebase web/mobile API keys are identifiers, not service-account secrets, but they still need project restriction and history cleanup. | Use GitHub Secrets for CI, run `flutterfire configure` locally, restrict Firebase/Google keys by app bundle/package/referrer, and purge/rotate history before public release. |
| 3 | Google Maps API key exposure | Medium | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `web/index.html` | No Google Maps key is committed in platform manifests. Current implementation mostly uses `flutter_map`/OSM; `google_maps_flutter` is now added for MVP readiness. | Inject Maps keys through CI/build settings when native Google Maps is wired. |
| 4 | `.env` files committed | Passed | `.gitignore`, `git ls-files` | `.env` files are ignored and not tracked. | Continue using `.env.example` only. |
| 5 | Hardcoded bearer tokens | Passed | `lib/core/network/api_client.dart` | Firebase ID tokens are fetched dynamically and added as `Authorization: Bearer ...`. | No action. |
| 6 | Hardcoded user IDs | Medium | `backend/prisma/seed.ts`, `lib/features/stores/data/dubai_stores_seed.dart` | Seed data and static Dubai store fallback are dev/demo fixtures. No production user ID is used for auth, but fallback data can appear in production if API fails. | Keep fixtures in dev/mock repositories or feature flags. |
| 7 | Hardcoded admin access | Passed | `backend/src/middleware/auth.ts`, `backend/src/routes/auth.ts`, `lib/features/auth/domain/auth_role.dart` | Admin access is role/claim based. No production admin email is hardcoded. | Migrate fully from legacy `isAdmin` boolean to Firebase custom claims or backend roles when ready. |
| 8 | Hardcoded profile/user/token/cart data | Medium | `lib/features/*/presentation/*_providers.dart` | Central mock state has been split, but some UI counters and admin metrics remain seeded/mock-like. | Keep mock-only values under dev fixtures and make production screens read backend data only. |
| 9 | Admin route without auth guard | Passed | `lib/app/route_guard.dart`, `lib/app/router.dart`, `test/app/route_guard_test.dart` | `/admin` now redirects guests/unauthenticated users to `/welcome`, authenticated non-admins to `/unauthorized`, and admins through. Backend `/admin/*` uses `requireAdmin`. | Keep guard tests in CI. |
| 10 | Insecure HTTP URLs | Passed | `lib/core/network/api_client.dart` | Default API URL is `https://dealsouk.onrender.com`; release builds reject non-HTTPS `API_BASE_URL`. | No action for client. Ensure deployed backend terminates TLS. |
| 11 | Missing HTTPS enforcement | Medium | `backend/src/index.ts`, `docs/BACKEND_DEPLOYMENT.md` | Client enforces HTTPS in release. Backend uses Helmet and production CORS fails closed unless `ALLOWED_ORIGINS` is configured, but HTTPS/HSTS still need hosting-layer verification. | Configure HSTS and HTTPS redirect in deployment platform. |
| 12 | Debug logs leaking data | Medium | `backend/src/services/tokenEngine.ts`, `backend/src/routes/admin.ts` | Backend logs user IDs/token balances for voucher and suspension events. Not full PII, but user IDs are sensitive operational data. | Replace raw user IDs with structured redacted logs. |
| 13 | Android permissions | Passed | `android/app/src/main/AndroidManifest.xml` | Uses `INTERNET`, `CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`; no background location. | No background location should be added for MVP. |
| 14 | iOS permissions | Passed | `ios/Runner/Info.plist` | Uses camera and when-in-use location copy; no always-location key present. | No action. |
| 15 | Location permission wording | Medium | `ios/Runner/Info.plist`, `lib/features/stores/presentation/store_screen.dart` | Wording is understandable, but the app should show a pre-permission explainer before the OS dialog. | Add a simple in-app explanation: "We use your location only to show nearby supermarket prices." |
| 16 | Camera/photo permission wording | Passed | `ios/Runner/Info.plist` | Camera copy explains price labels and receipts. | No action. |
| 17 | Secure storage requirement | Medium | `pubspec.yaml` | `flutter_secure_storage` is now added, but no app-specific secure-storage wrapper exists yet. Firebase Auth handles its own session persistence. | Use secure storage for any future non-Firebase secrets or opaque app session metadata. |
| 18 | Token/session handling | Passed | `lib/core/network/api_client.dart`, Firebase Auth SDK | ID token refresh is handled on 401 retry. | Add integration tests around expired-token retry later. |
| 19 | Guest mode restrictions | Medium | `lib/app/route_guard.dart`, `lib/features/cart/presentation/cart_providers.dart` | Guest profile/submission routes are guarded and cart API sync is skipped for guests. Guest UI can still save local cart items. | Decide whether guest local cart is intentional; otherwise prompt sign-in on add-to-cart. |
| 20 | Privacy/PDPL risks | Medium | `backend/prisma/schema.prisma`, `backend/src/routes/auth.ts`, `lib/features/auth/presentation/welcome_screen.dart`, `lib/features/legal/presentation/privacy_policy_screen.dart`, `docs/PRIVACY_POLICY.md` | Privacy consent and policy screen exist, and precise GPS is not stored persistently in schema. Phone number encryption is being introduced, but display name/home area remain plain and legal review is still required. | Finish PII classification, verify encryption migration, and get Arabic/English policy reviewed before public launch. |
| 21 | Dependency advisories | Medium | `backend/package-lock.json`, `npm audit --omit=dev` | Firebase Admin currently pulls a transitive `uuid` advisory through Google Cloud libraries. npm's automatic fix proposes a breaking downgrade, so it was not applied. | Track upstream Firebase Admin/Google Cloud dependency updates and retest before production. |

## Current Release Blockers

No direct admin-route or plaintext-client release blocker remains in the current working tree.

The highest-risk items before production are:

1. Rotate/purge previously tracked Firebase config and service-account material from git history.
2. Ensure a fresh clone can generate `lib/firebase_options.dart` through documented setup.
3. Finish PII encryption/migration and legal review of privacy-policy copy.
4. Move remaining mock/demo metrics behind dev-only fixtures.
5. Keep production env values in secret managers only; do not commit Firebase files, `.env`, private keys, signing keys, or service-account JSON.
6. Add server-side malware scanning for uploaded receipt/price-label images.
7. Re-check backend dependency advisories before production deployment.
