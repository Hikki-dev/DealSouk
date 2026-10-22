# Changes

## Docs, demo mode and a test fix

1. New README with a hero picture, a tour of the shopper app and the moderator console, two diagrams, an honest list of known issues and the real test counts.
2. New guides: Demo mode, Using the app, How it works, Fixing problems and Questions and answers, plus CONTRIBUTING, SECURITY, issue and pull request templates.
3. **Demo mode:** run the shopper app, the moderator portal and the API on your computer with a local Postgres and the Firebase Auth emulator, with no Firebase project or Neon account. It adds `demo/`, `backend/prisma/demo.ts` (`npm run seed:demo`), `backend/scripts/demo-token.ts`, an emulator section in `firebase.json` and an off-by-default `USE_FIREBASE_EMULATORS` flag in `lib/main.dart`.
4. A `demo.yml` workflow builds the demo on every pull request.
5. **Fixed:** the Jest test for `POST /auth/verify` expected `verifyIdToken(token, true)`, but the route deliberately uses `false` since June 2026. The test now matches, and the backend suite passes (41 of 41).

## Admin login, stabilisation and monitoring (June 2026)

1. Fixed admin sign-in failures and the dead end on the unauthorised screen.
2. The admin API was split into one router per area, and the admin panel widgets were pulled out of one big file.
3. Sentry crash reporting for the backend and the app, and a real saved-items list, distinct from the cart.
4. Disk-cached, slot-sized images for product cards, store logos and avatars, a shared `formatAed()` and named constants for time windows.
5. Better error handling (load error versus empty results, with a retry), price input checks and fixes to the price request flow.

## Rewards, hardening and releases (June 2026)

1. A rewards release: tokens, challenges, streaks, badges, the leaderboard and vouchers.
2. A full security hardening pass: authentication, validation and abuse prevention, then storage hardening with upload limits and expiry clean-up, and admin security.
3. The deployed commit shows on `/health`. Google and Apple profile photos are saved as the avatar.
4. Continuous builds of the Android APK and an AltStore IPA, attached to GitHub Releases on version tags.
5. Admin CRUD, evidence previews, confirmation screens, store and home filters, saved language and real distances.
