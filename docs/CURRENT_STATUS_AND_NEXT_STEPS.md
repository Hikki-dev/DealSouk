# DealSouk Current Status And Next Steps

Date: 2026-06-13
Branch: `feature/flutter-api-integration`

## Live Now

| Area | Status | Evidence |
|---|---|---|
| Backend API | Live on Render | `https://dealsouk.onrender.com/health` returns `200`. |
| Admin web | Live on Vercel | `https://deal-souk.vercel.app` returns `200`. |
| Database | Connected | Render logs show `Database connected`; Prisma migrations are up to date. |
| Firebase Storage | Enabled and rules deployed | `firebase deploy --only storage --project dealsouk-6e140` completed. |
| Secrets in current tree | Clean | `python3 scripts/secret_scan.py` passes. |
| Admin access model | Role/claim based | Backend admin routes use auth/admin middleware; app route guard blocks guests and non-admin users. |
| Admin records | Verified in Neon | Neon currently has 2 users and 1 admin user. Firebase Auth listing needs IAM permission before it can be audited from CLI. |
| Demo/mobile data fallback | Present | Dubai store/price fallbacks support colleague feedback when API data is sparse. |

## Good For Colleague Feedback

DealSouk is suitable for controlled internal feedback on:

- shopper home flow
- store map and store price experience
- cart savings story
- submit price flow
- request price flow
- tokens, leaderboard, and profile basics
- web admin moderation
- Arabic/English copy direction

Use this as an internal feedback build, not a public production launch.

## Not Public Production Yet

These items still need closure before a public app-store launch:

| Priority | Area | What remains |
|---|---|---|
| Critical | Firebase/Google key restrictions | Confirm Android package + SHA fingerprints, iOS bundle ID, and web referrer restrictions in Google Cloud/Firebase. |
| Critical | Git history | Firebase config appeared in old commits. Keep repo private until keys are rotated/restricted and history is purged or accepted as private-only. |
| Critical | Legal/PDPL | Have the English/Arabic privacy copy reviewed by a UAE-aware legal/privacy reviewer. |
| High | Upload safety | Add server-side malware/image scanning before public user uploads are trusted. |
| High | Monitoring/backups | Confirm Neon backups, Render logs/alerts, and production incident contacts. |
| High | Push notifications | Complete APNs and FCM production testing for iOS and Android. Admin warning/suspension/ban FCM hooks exist when users have FCM tokens. |
| High | Store release | Android/iOS signing and app-store review are intentionally skipped for now, but required for public release. |
| Medium | Offline behavior | Add clearer offline/cache handling for in-store use. |
| Medium | Remaining PRD gaps | Finish or explicitly defer price-drop notifications, profile photo upload, production Maps wiring, and voucher operations details. |

## Immediate Next Fix Order

1. Verify current branch checks: secret scan, Flutter analyze, Flutter tests, backend build.
2. Let Render redeploy the latest backend fix and re-check `/system/status`.
3. In Firebase/Google Cloud, restrict client keys for Android, iOS, and web.
4. In Render, remove `MAINTENANCE_MESSAGE` or leave it only for planned maintenance; the backend ignores it while `MAINTENANCE_MODE=false`.
5. Maintain admins with `cd backend && npm run admin:set -- --email admin@example.com --admin`; the script upserts the Neon user and sets Firebase custom claims.
6. Run one real-device iOS smoke test and one Android build smoke test with `API_BASE_URL=https://dealsouk.onrender.com`.

## Current Safety Rules

- Do not commit `.env`, `backend/render.env`, Firebase service-account JSON, Firebase client config files, keystores, provisioning profiles, or private keys.
- Keep Render, Vercel, Firebase, and GitHub secrets in each provider's encrypted environment settings.
- Do not run `npm audit fix --force` on the backend without testing; the current advisory path proposes a breaking Firebase Admin dependency change.
- Keep the repository private until key restrictions/history cleanup decisions are complete.
