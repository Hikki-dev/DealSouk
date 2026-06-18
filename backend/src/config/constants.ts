// Shared business-rule / time-window constants used across multiple backend
// files. Named here, following the `*_MS` convention in middleware/auth.ts, so
// the domain windows that drive freshness, expiry, decay, and moderation can't
// silently drift between routes. Prefer adding new time magic numbers here.

// FR-48: Levels 1–20 based on cumulative lifetime tokens earned, one level per
// this many tokens. Single source of truth — the Flutter client reads this via
// the API (see /config) rather than re-hardcoding it (R4: prevents drift).
export const TOKENS_PER_LEVEL = 500;
export const MAX_LEVEL = 20;

export const SECOND_MS = 1000;
export const MINUTE_MS = 60 * SECOND_MS;
export const HOUR_MS = 60 * MINUTE_MS;
export const DAY_MS = 24 * HOUR_MS;
// Back-compat alias for code that imports MS_PER_HOUR.
export const MS_PER_HOUR = HOUR_MS;

// FR-17 / FR-18 / FR-20: crowd-sourced prices are "fresh" for 72h, after which
// they are dimmed and excluded from active results / best-price resolution.
export const PRICE_FRESHNESS_MS = 72 * HOUR_MS;

// FR-12: a store pin is shown as "stale" when it has had no submission in 48h.
export const STORE_STALE_MS = 48 * HOUR_MS;

// FR-29: an unfulfilled price request is refunded and expired after 48h.
export const REQUEST_EXPIRY_MS = 48 * HOUR_MS;

// FR-33: duplicate-submission decay considers other submissions for the same
// product+store within the past 24h.
export const DUPLICATE_DECAY_WINDOW_MS = 24 * HOUR_MS;

// FR-54: 7-day automatic suspension after 3 removals in a rolling 30-day window.
export const SUSPENSION_DURATION_MS = 7 * DAY_MS;
export const REMOVAL_LOOKBACK_MS = 30 * DAY_MS;

// FR-41: a voucher is linked to the store the sourcer submitted the most data
// for over the trailing 30-day qualifying period.
export const VOUCHER_QUALIFYING_PERIOD_MS = 30 * DAY_MS;

/** Returns midnight (00:00:00.000) of the current day in local time. */
export function startOfToday(): Date {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}
