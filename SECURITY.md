# Security

## Reporting a problem

Please do not open a public issue for a security problem. Use the **Report a vulnerability** button on the Security tab of this project on GitHub. Say what you found and how to repeat it.

## What this project does to protect people

1. Sign-in is Firebase Authentication. The API checks the Firebase ID token on every protected call, refuses banned and suspended accounts, and ends a session after 30 days of no use or 90 days in all.
2. Phone numbers are encrypted at rest with `DATABASE_ENCRYPTION_KEY`.
3. The API uses Helmet, a CORS allow-list, a request size limit and per-route rate limits (Redis-backed when `REDIS_URL` is set).
4. Admin routes need the admin role, can require multi-factor sign-in (`ADMIN_MFA_REQUIRED`), and every warning, suspension and ban is written to an audit log.
5. Uploads are limited by user, type and size, have their location data (EXIF) removed and are scanned for malware.
6. Token changes are written to a hash-chained ledger, so a changed row can be found.
7. A secret scan (`scripts/secret_scan.py`) runs in CI.

## For people running a copy

1. Never commit `.env`, service-account files, `google-services.json`, `GoogleService-Info.plist` or `firebase_options.dart`.
2. Set `ALLOWED_ORIGINS`, `DATABASE_ENCRYPTION_KEY` and the `FIREBASE_*` values in production. In production the API stops at start-up if they are missing.
3. Turn on `ADMIN_MFA_REQUIRED` for the moderator portal.
4. Demo mode (`demo/`) uses fake credentials and a throwaway key. Never use it, or its accounts, with a real project or database.
5. Read [SECURITY_AUDIT.md](SECURITY_AUDIT.md) and the pre-launch [SECURITY_CHECKLIST.md](SECURITY_CHECKLIST.md).
