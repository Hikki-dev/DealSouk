# Neon Data-Residency Cutover — us-east-1 → Frankfurt (eu-central-1)

**Why:** PRD §11.2 / NFR-11 (UAE PDPL) prefer an in-region datastore. Neon has no
UAE region, so we moved to the closest compliant region — **AWS `eu-central-1`
(Frankfurt)**, the EU region named as the acceptable DR fallback in the PRD.
This closes backlog item **Sec#3 / D4**.

## What was done (automated)

- Created Neon project **`dealsouk-eu`** (`dark-art-33891694`) in `aws-eu-central-1`,
  Postgres 18 (matches source).
- Applied all 11 Prisma migrations (`prisma migrate deploy`).
- Seeded the dataset and refreshed the `price_history_daily` materialized view.
  Verified: **18 stores · 20 products · 187 submissions · 13 badges · 187 history rows.**
- Phone PII is encrypted with the **same `DATABASE_ENCRYPTION_KEY`** as before (the
  seed inherited it), so that env var must **not** change.
- Local `backend/.env` and `backend/render.env` were repointed at the Frankfurt
  **pooled** endpoint and connectivity was verified.

## Remaining manual step (owner) — the production cutover

I can't reach your Render dashboard, so the live swap is yours:

1. In **Render → dealsouk service → Environment**, set `DATABASE_URL` to the
   Frankfurt **pooled** connection string. The value is already in your local
   `backend/render.env` (`DATABASE_URL=…-pooler.c-4.eu-central-1.aws.neon.tech…`),
   or copy it from the Neon console for project `dealsouk-eu`.
   - **Keep `DATABASE_ENCRYPTION_KEY` exactly as-is** (do not regenerate).
2. **Manual Deploy** (or let the next push trigger build). `render:build` runs
   `prisma migrate deploy` — already a no-op since migrations are applied.
3. Smoke-test `https://dealsouk.onrender.com/health` and the `/stores/nearby` map.

## Rollback

The original `us-east-1` project (`dealsouk` / `nameless-math-88401654`) is left
**intact as a backup**. To roll back, set `DATABASE_URL` back to its connection
string and redeploy. Once Frankfurt is confirmed healthy in production for a few
days, the old project can be deleted.

## Caveat — data fidelity

Frankfurt was provisioned by re-running the seed (the documented dataset), because
`pg_dump` wasn't available in the migration environment. If real, post-seed
user-generated rows in `us-east-1` must be preserved exactly, run a
`pg_dump --data-only | psql` copy from a machine with the Postgres client tools
**before** deleting the old project. For the current pre-launch/demo state the
seed-equivalent dataset is sufficient.

## Legal (still required)

Frankfurt is EU, not UAE. Document this region choice in
`docs/PRIVACY_COMPLIANCE.md` and obtain PDPL sign-off for EU hosting (or plan a
future move to a true `me-central1` provider — GCP Cloud SQL / AWS Bahrain — if
strict in-country residency is mandated).
