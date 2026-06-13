# DealSouk Production Readiness Plan

Date: 2026-06-12
Branch: `feature/flutter-api-integration`

Latest operational status: see `docs/CURRENT_STATUS_AND_NEXT_STEPS.md`.

## Reality Check

DealSouk can be made ready for colleague feedback quickly, but public production release is not the same as "all tests pass." Production requires store signing, deployed backend infrastructure, Firebase configuration, secret rotation, privacy/compliance review, app-store review, voucher operations, monitoring, and admin access controls.

Current practical readiness:

| Target | Readiness | Meaning |
|---|---:|---|
| Colleague feedback build | 80-90% | Good enough to review core shopper flow, trust, Arabic/English copy, admin moderation, and savings story. |
| Internal beta | 60-70% | Needs CI, deployment config, seed/demo data boundaries, signing, and Firebase setup. |
| Public production | 55-65% | Backend, admin web build path, Firebase Storage rules, and secret guardrails are now live; legal, store signing, app-store review, monitoring, and remaining PRD gaps still need completion. |

## Definition Of 100%

### Mobile App: Android + iOS

- Firebase phone, Google, and Apple auth are fully configured.
- Guest mode is read-only where required.
- User screens do not silently rely on mock data in production.
- Google Maps keys are injected through build secrets, not committed.
- Camera/photo and location permissions are explained clearly.
- Precise GPS is not stored persistently.
- Tokens are framed as rewards with no cash value.
- Arabic and English flows are checked on real devices.
- Android release signing and iOS signing are configured through CI secrets.
- TestFlight / Play Console internal testing are configured before public rollout.

### Admin

- Admin is web-based only.
- Admin is deployed separately from the mobile app.
- Mobile builds do not expose admin navigation to normal users.
- Admin access is based on backend/Firebase role claims, not email hardcoding.
- Backend `requireAdmin` remains the real enforcement point.
- Admin can moderate submissions, edit bad data, configure token settings, and review voucher queues.

### Backend

- Production requires `ALLOWED_ORIGINS`; no wildcard CORS in production.
- Body size and rate limits are configured through environment variables.
- Firebase service account credentials are supplied through secrets only.
- PII encryption and privacy policy obligations are complete.
- HTTPS/HSTS are configured at the hosting layer.
- Monitoring, logs, error reporting, and backup/restore are configured.

## Environment And Secret Rules

- Never commit `.env`, Firebase service-account files, Google service files, signing keys, keystores, private keys, provisioning profiles, or API secrets.
- Keep only `.env.example` in git.
- Use GitHub Actions secrets or the hosting provider's secret manager for production values.
- Rotate and purge any Firebase/service-account material that appeared in git history before public release.
- A fresh clone must document how to regenerate `lib/firebase_options.dart`.

Current ignored local secret files:

- `backend/.env`
- `backend/firebase-service-account.json`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

## Data And Abuse Limits

Current backend limits:

| Limit | Default | Config |
|---|---:|---|
| Global API rate limit | 120 requests/minute | `GLOBAL_RATE_LIMIT_PER_MINUTE` |
| Submission rate limit | 5 submissions/minute/account | `SUBMISSION_RATE_LIMIT_PER_MINUTE` |
| Request creation rate limit | 10 requests/minute/account | `REQUEST_RATE_LIMIT_PER_MINUTE` |
| JSON request body size | 1 MB | `JSON_BODY_LIMIT` |
| Daily submissions | 30/day by default | Admin setting |
| Price request bounty | 1-100 tokens | Backend validation |
| Product/store request text | 120 characters | Backend validation |
| Receipt URL | HTTPS only, max 2048 characters | Backend validation |
| Product price result limit | Max 50 | Backend validation |

## Today's Best Finish Line

The realistic target for today is an internal feedback build:

1. Keep current tests passing.
2. Add CI that runs format, analyze, backend build, and tests.
3. Build Android APK for testers.
4. Build unsigned iOS artifact for engineering validation.
5. Build Flutter Web admin separately.
6. Document required GitHub/Firebase/App Store/Play Store secrets.
7. Mark public-release blockers clearly.

## GitHub Actions

Current workflows:

| Workflow | Purpose | Output |
|---|---|---|
| `.github/workflows/ci.yml` | Runs Flutter format/analyze/test and backend TypeScript build. | Pass/fail validation. |
| `.github/workflows/android-internal.yml` | Manual Android internal APK build. | `app-release.apk` artifact. |
| `.github/workflows/ios-internal.yml` | Manual unsigned iOS release build. | `build/ios/iphoneos` artifact for engineering validation. |
| `.github/workflows/admin-web.yml` | Manual Flutter Web admin build. | `build/web` artifact. |

Required GitHub Secrets:

| Secret | Use |
|---|---|
| `FIREBASE_OPTIONS_DART_B64` | Base64-encoded `lib/firebase_options.dart` for all Flutter builds. |
| `GOOGLE_SERVICES_JSON_B64` | Base64-encoded `android/app/google-services.json` for Android builds. |
| `GOOGLE_SERVICE_INFO_PLIST_B64` | Base64-encoded `ios/Runner/GoogleService-Info.plist` for iOS builds. |

Future release secrets:

- Android upload keystore and passwords.
- Apple signing certificate, provisioning profile, App Store Connect API key, issuer ID, and key ID.
- Backend deployment credentials.
- Admin web hosting credentials.
- Sentry/Crashlytics/analytics keys.

## Vercel Admin Web

Vercel should host the web admin console, not replace the mobile app release path. The admin build is configured through `vercel.json` and `vercel_build.sh`.

Required Vercel env vars:

- `FIREBASE_OPTIONS_DART_B64`
- `API_BASE_URL`

See `docs/VERCEL_ADMIN_DEPLOYMENT.md`.

## Render Backend API

Render should host the backend API that mobile and admin web clients call. The repository now includes `render.yaml`, and the backend has a `render:build` script that runs Prisma generation, production migrations, and TypeScript compilation.

Use the Render project to create a Web Service from branch `feature/flutter-api-integration`, with root directory `backend`, build command `npm ci && npm run render:build`, start command `npm start`, and health check path `/health`.

Required Render secrets:

- `DATABASE_URL`
- `DATABASE_ENCRYPTION_KEY`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `ALLOWED_ORIGINS`

See `docs/RENDER_BACKEND_DEPLOYMENT.md`.

## Public Production Blockers

These cannot be skipped for a real user launch:

- Rotate/purge previously exposed Firebase/service-account files from git history.
- Configure production Firebase projects, OAuth clients, APNs, FCM, Storage rules, and Maps key restrictions.
- Backend deployment is live on Render with HTTPS. Database backups and monitoring still need confirmation.
- Complete legal review of the in-app privacy policy draft in English and Arabic.
- Finish or explicitly defer PRD gaps: barcode scan, Google Maps production wiring, price history, voucher inventory imports, exports, offline cache, admin analytics, and server-side media scanning.
- Configure Android signing, iOS signing, TestFlight, Play Console, and app-store metadata.

## Completed Since This Plan Was Created

- Backend production startup now fails when required env vars are missing.
- Production CORS fails closed unless `ALLOWED_ORIGINS` is configured.
- Backend body size and abuse limits are environment-configurable.
- Firebase Storage rules now restrict uploads by user, content type, and file size.
- Firebase Storage has been enabled and rules deployed for `dealsouk-6e140`.
- Render backend is live at `https://dealsouk.onrender.com`.
- Vercel admin web is live at `https://deal-souk.vercel.app`.
- Voucher threshold now creates real backend `VoucherRequest` records.
- Admin can approve/reject vouchers from the web admin queue.
- Approved vouchers are visible from the user profile.
- Privacy/terms screen is available from onboarding and profile settings.
- Barcode scanning is wired through `mobile_scanner` and backend product barcode search.
- Product detail now has an API-backed 90-day price history chart.
- Admin analytics now uses backend operational data instead of mock-only panels.
- Admin CSV export endpoint is available for submissions.
- Maintenance status endpoint and app-level banner are wired.
- Deployment, Firebase, secret rotation, voucher ops, and privacy drafts are documented.
