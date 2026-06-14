CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE "User"
  ADD COLUMN "lastActiveAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN "sessionStartedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "TokenTransaction"
  ADD COLUMN "previousHash" TEXT,
  ADD COLUMN "hash" TEXT;

WITH RECURSIVE ordered AS (
  SELECT
    id,
    "userId",
    amount,
    reason,
    "createdAt",
    row_number() OVER (ORDER BY "createdAt" ASC, id ASC) AS rn
  FROM "TokenTransaction"
),
chain AS (
  SELECT
    id,
    rn,
    NULL::TEXT AS previous_hash,
    encode(
      digest(
        concat_ws(
          '|',
          "userId",
          amount::text,
          reason,
          to_char("createdAt" AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
          'GENESIS'
        ),
        'sha256'
      ),
      'hex'
    ) AS current_hash
  FROM ordered
  WHERE rn = 1

  UNION ALL

  SELECT
    ordered.id,
    ordered.rn,
    chain.current_hash AS previous_hash,
    encode(
      digest(
        concat_ws(
          '|',
          ordered."userId",
          ordered.amount::text,
          ordered.reason,
          to_char(ordered."createdAt" AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
          chain.current_hash
        ),
        'sha256'
      ),
      'hex'
    ) AS current_hash
  FROM ordered
  JOIN chain ON ordered.rn = chain.rn + 1
)
UPDATE "TokenTransaction" t
SET
  "hash" = chain.current_hash,
  "previousHash" = chain.previous_hash
FROM chain
WHERE t.id = chain.id;

ALTER TABLE "TokenTransaction"
  ALTER COLUMN "hash" SET NOT NULL;

CREATE UNIQUE INDEX "TokenTransaction_hash_key" ON "TokenTransaction"("hash");
