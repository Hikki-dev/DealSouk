# Contributing

Thank you for helping. This page explains how to make a change that is easy to accept.

## What we ask of every change

1. Never put a password, an API key, a service account, a phone number or a real person's details in the code, the docs, a test or a screenshot. Run `python3 scripts/secret_scan.py` before you push.
2. Keep the moderator in charge. A price must not earn tokens before a moderator approves it, and every admin action must be written to the audit log.
3. Anything a shopper reads goes in `lib/l10n` in English **and** Arabic.
4. Use the named constants in `backend/src/config/constants.ts` for time windows and limits. Do not add new magic numbers.
5. Add or update a test when you change behaviour.

## Where things are

1. `backend/` is the API. Read [How it works](docs/How%20it%20works.md) first.
2. `lib/` is the Flutter app, with one folder per feature in `lib/features`.
3. `firebase/` has the storage rules and the Cloud Functions, and `services/malware-scanner` the virus scanner.
4. `demo/` is [demo mode](docs/Demo%20mode.md), and `docs/` is the written help.

## Running the checks

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
cd backend && npm install && npx prisma generate && npm run build && npm test
python3 scripts/secret_scan.py
```

These are the checks in `.github/workflows/ci.yml`. The `demo.yml` workflow also builds the demo on every pull request.

## Trying a change safely

Use [demo mode](docs/Demo%20mode.md): a local Postgres and the Auth emulator. Never point a test at the production database or the live Firebase project.

## Taking screenshots

Take them from demo mode so no real person's data is ever in a picture.

## Sending a change

1. Make a branch.
2. Keep the change small and about one thing.
3. Run the checks.
4. Open a pull request. Say what changed, why, and how you tested it.

## Reporting a problem

Open an issue and choose the right form. Say what you expected and what happened. Never paste your `.env`, passwords or keys.
