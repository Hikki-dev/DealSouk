// Shared business-rule constants used across multiple backend files.
// Centralising them here prevents magic-number drift when values change.

export const MS_PER_HOUR = 3_600_000;

// Price submissions are "fresh" for 72 hours after submission (FR-18).
export const PRICE_FRESHNESS_MS = 72 * MS_PER_HOUR;

// Price requests expire after 48 hours (FR-29).
export const REQUEST_EXPIRY_MS = 48 * MS_PER_HOUR;

// Submissions are "stale" (show warning badge) after 48 hours without update.
export const STORE_STALE_MS = 48 * MS_PER_HOUR;

/** Returns midnight (00:00:00.000) of the current day in local time. */
export function startOfToday(): Date {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}
