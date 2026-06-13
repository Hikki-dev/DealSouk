-- Native-Postgres time-series rollup for product price history (NFR-05 / §13.3).
-- TimescaleDB is unavailable on Neon, so we approximate a continuous aggregate
-- with a materialized view: one row per (product, store, day) holding the day's
-- min/avg price and sample count. The /products/:id/history endpoint reads this
-- instead of scanning raw PriceSubmission rows, and the maintenance scheduler
-- periodically REFRESHes it (CONCURRENTLY, enabled by the unique index below).

CREATE MATERIALIZED VIEW IF NOT EXISTS price_history_daily AS
SELECT
  "productId"                          AS product_id,
  "storeId"                            AS store_id,
  date_trunc('day', "submittedAt")     AS bucket_day,
  MIN("priceAed")                      AS min_price,
  AVG("priceAed")                      AS avg_price,
  COUNT(*)                             AS sample_count
FROM "PriceSubmission"
WHERE status = 'approved'
GROUP BY "productId", "storeId", date_trunc('day', "submittedAt");

-- Unique index is required for REFRESH MATERIALIZED VIEW CONCURRENTLY, and it
-- also makes the per-product range scan in the history endpoint fast.
CREATE UNIQUE INDEX IF NOT EXISTS price_history_daily_pk
  ON price_history_daily (product_id, store_id, bucket_day);

CREATE INDEX IF NOT EXISTS price_history_daily_product_day
  ON price_history_daily (product_id, bucket_day);
