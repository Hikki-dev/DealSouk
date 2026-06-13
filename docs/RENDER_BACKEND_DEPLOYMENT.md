# Render Backend Deployment

Date: 2026-06-12
Branch: `feature/flutter-api-integration`

## What To Create

Create one Render Web Service for the DealSouk API. Vercel should keep hosting the web admin console. Render should host only the backend API that the iOS app, Android app, and admin web console call.

## Dashboard Steps

From the empty Render project:

1. Click **Create new service**.
2. Choose **Web Service**.
3. Connect GitHub repo `Hikki-dev/DealSouk`.
4. Use branch `feature/flutter-api-integration` until it is promoted to production.
5. Set **Root Directory** to `backend`.
6. Set **Runtime** to `Node`.
7. Set **Build Command** to:

```bash
npm ci && npm run render:build
```

8. Set **Start Command** to:

```bash
npm start
```

9. Set **Health Check Path** to:

```text
/health
```

Render can also read the checked-in `render.yaml` blueprint for these non-secret settings.

## Local Render Env Helper

There is no committed `render.env` because it contains production secrets.

Local helper files:

| File | Purpose | Commit? |
|---|---|---|
| `backend/render.env` | Real local paste/import file for Render environment variables. | No |
| `backend/render.env.example` | Safe template showing required keys. | Yes |

To copy the real local Render env values:

```bash
pbcopy < backend/render.env
```

Then paste into Render's environment variable import/paste UI if available, or copy each key/value manually.

## Required Secrets

Set these in Render environment variables, not in git:

| Key | Notes |
|---|---|
| `DATABASE_URL` | Neon Postgres connection string. Use the direct Neon URL for now because Prisma migrations run during deploy. |
| `DATABASE_ENCRYPTION_KEY` | 32-byte base64 secret for backend field encryption. Generate once and keep private. |
| `FIREBASE_PROJECT_ID` | `dealsouk-6e140` unless you create a separate production Firebase project. |
| `FIREBASE_CLIENT_EMAIL` | Firebase Admin service account client email. |
| `FIREBASE_PRIVATE_KEY` | Firebase Admin private key, including escaped newlines if Render stores it on one line. |
| `ALLOWED_ORIGINS` | Comma-separated admin web origins, for example `https://deal-souk.vercel.app`. |

Set these non-secret defaults if they are not already imported from `render.yaml`:

```text
NODE_ENV=production
JSON_BODY_LIMIT=1mb
GLOBAL_RATE_LIMIT_PER_MINUTE=120
SUBMISSION_RATE_LIMIT_PER_MINUTE=5
REQUEST_RATE_LIMIT_PER_MINUTE=10
ADMIN_RATE_LIMIT_PER_MINUTE=60
MAINTENANCE_MODE=false
```

## Neon Connection Guidance

Use a direct Neon connection string for the first Render deploy because `npm run render:build` runs `prisma migrate deploy`. Pooled Neon URLs include `-pooler`; direct URLs do not. Later, when traffic grows, update Prisma to use pooled `DATABASE_URL` plus a separate `DIRECT_URL` for migrations.

Reference: https://neon.com/docs/connect/choose-connection

## After First Deploy

1. Open the Render service URL and verify `/health`.
2. Copy the API base URL, for example `https://dealsouk.onrender.com`.
3. Set Vercel `API_BASE_URL` to that URL.
4. Build mobile apps with:

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://dealsouk.onrender.com
flutter build apk --release --dart-define=API_BASE_URL=https://dealsouk.onrender.com
```

5. Run an authenticated smoke test from the app.
6. Run an admin smoke test from the Vercel admin web build.

## Free-Tier Limits

Render free services can sleep when idle, so the first request after inactivity may feel slow. This is acceptable for demos and internal feedback, but not ideal for public production. For a real launch, use a paid Render instance or a platform with minimum instances enabled.

Neon free/serverless can also have a short cold start. If shoppers are testing with colleagues, this is fine. If public users are relying on it in-store, upgrade before launch.

## Security Notes

- Do not put `.env` values in Render build logs.
- Do not commit Firebase Admin service account JSON.
- Keep CORS strict with `ALLOWED_ORIGINS`.
- Keep `NODE_ENV=production` so the backend fails startup if required secrets are missing.
- Rotate Firebase client API keys and restrict them in the Firebase/Google Cloud console before public release.
- If a Firebase Admin private key ever entered git history, rotate it immediately and purge history before the repo is public.
