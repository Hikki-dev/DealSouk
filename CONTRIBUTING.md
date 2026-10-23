# Contributing

Thank you for helping. This page explains how to make a change that is easy to accept.

## What we ask of every change

1. Use plain English in anything a person reads. Short sentences. If a technical word is needed, explain it in the same place.
2. Never put a password, key or personal detail in the code, the docs or a test. The secret scan will stop it.
3. Every screen must work on a phone and on a desktop, in English and in Arabic, and at large text.
4. Use the parts in `lib/core/design/` before making a new one.
5. Every button must be at least 48 pixels tall. Never show a status with colour alone.
6. Test on a throwaway database, never on the real one.

## Where things are

1. `lib/` is the apps. Read [How it works](docs/How%20it%20works.md) first.
2. `lib/core/design/` is the design system. Read [Design system](docs/Design%20system.md).
3. `backend/` is the API. `docs/` is the written help.

## Running the checks

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
cd backend && npm test
python3 scripts/secret_scan.py
```

The same checks run on every pull request. The Flutter tests also draw each screen to `build/screenshots/`, so open the pictures of any screen you changed.

## Sending a change

1. Make a branch.
2. Keep the change small and about one thing.
3. Run the checks, and look at the screenshots of what you changed.
4. Open a pull request. Say what changed, why and how you tested it. Add a line to [CHANGELOG.md](CHANGELOG.md).

## Reporting a problem

Open an issue and choose the right form. Say what you expected and what happened. Never paste keys, passwords or links that contain a token.
