# Backend Deployment Runbook

Date: 2026-06-12

## Production Environment Variables

Required:

- `NODE_ENV=production`
- `DATABASE_URL`
- `DATABASE_ENCRYPTION_KEY`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `ALLOWED_ORIGINS`

Recommended:

- `PORT`
- `JSON_BODY_LIMIT=1mb`
- `GLOBAL_RATE_LIMIT_PER_MINUTE=120`
- `SUBMISSION_RATE_LIMIT_PER_MINUTE=5`
- `REQUEST_RATE_LIMIT_PER_MINUTE=10`
- `ADMIN_RATE_LIMIT_PER_MINUTE=60`

The backend now fails startup in production if required env vars are missing.
Local development loads `backend/.env` through `dotenv`; production values must still come from the hosting provider secret manager.

## Deployment Steps

1. Provision PostgreSQL in the required region.
2. Store all env vars in the hosting provider secret manager.
3. Run Prisma migrations:

```bash
cd backend
npm ci
npx prisma migrate deploy
npm run build
npm start
```

4. Configure HTTPS and HSTS at the edge/proxy.
5. Set `ALLOWED_ORIGINS` to the mobile/admin web origins only.
6. Verify `/health`.
7. Verify authenticated routes reject missing tokens.
8. Verify `/admin/*` rejects non-admin users.

## Required Production Checks

- No `.env` files on build artifacts.
- No Firebase service-account files in repo or artifacts.
- Database backups enabled.
- Error monitoring enabled.
- Logs do not contain phone numbers, precise GPS, Firebase tokens, voucher codes, or service credentials.
- Deployments are rollback-capable.
