# Fixing problems

| What you see | What to do |
|---|---|
| `Missing required environment variable` when the API starts | `backend/.env` is missing a key. Run `bash demo/prepare.sh` for a demo, or copy `backend/.env.example` and fill it in |
| `Environment variable not found: DATABASE_URL` from `npm run seed` | The seed scripts do not read `.env` by themselves. Load it first: `set -a; . ./.env; set +a`. `demo/seed.sh` does this for you |
| `Can't reach database server` | The Postgres is not running, or `DATABASE_URL` is wrong. For the demo, start the Docker command in [Demo mode](Demo%20mode.md) |
| `Invalid or expired token` from the API | The token was made for another Firebase project. In demo mode the API needs `FIREBASE_AUTH_EMULATOR_HOST` in `backend/.env`, and the apps need `USE_FIREBASE_EMULATORS=true` |
| The app says it cannot sign in, or the Google button does nothing | In demo mode, allow pop-ups for the page, and check that the Auth emulator is running on port 9099 |
| `auth/email-already-exists` from `demo-token.ts` | An account with that email exists with another id. Clear the emulator's accounts: `curl -X DELETE http://127.0.0.1:9099/emulator/v1/projects/demo-dealsouk/accounts`, then run `bash demo/seed.sh` again |
| `API_BASE_URL must be defined via --dart-define in release mode` | Release and profile-style builds need the API address, and release builds need `https://`. For a local demo use `flutter run` (a debug build) or a profile build |
| An admin cannot sign in to the portal | The account is not a moderator. Run `npm run admin:set -- --email you@example.com --admin` in `backend` |
| The shopping list shows `AED 0.00` | A known issue. See the [README](../README.md#known-issues) |
| Product pictures show a basket icon | The pictures come from Unsplash. They need the internet |
| The map has no tiles | The tiles come from CartoDB and OpenStreetMap. They need the internet |
| `flutter test` or `flutter analyze` fails after `flutter pub get` changed files | `pubspec.lock` and `analysis_options.yaml` may be rewritten by your Flutter version. Do not commit that by accident |
| `dart format --set-exit-if-changed .` fails in CI | Run `dart format .` and commit the result |
| The Render API is slow on the first request | The free plan sleeps after 15 minutes. `keep-warm.yml` pings it every 10 minutes, and the first call after a sleep can still take about a minute |

## Still stuck?

Open an issue and use the **Problem** template. Say what you ran, what you expected and what happened, and paste the error text. Never paste your `.env`.
