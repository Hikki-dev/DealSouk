// Shared admin helpers, constants, and the write rate-limiter (R2). Imported by
// every admin sub-router so the split files don't duplicate validation logic.
import { authenticatedRateLimit } from '../../middleware/rateLimits';
import { decrypt } from '../../services/encryption';

export const adminWriteLimiter = authenticatedRateLimit({
  envName: 'ADMIN_RATE_LIMIT_PER_MINUTE',
  fallback: 60,
  message: 'Too many admin actions. Please try again in a minute.',
});

export const MAX_ADMIN_REASON_LENGTH = 500;
export const MIN_PRICE_AED = 0.01;
export const MAX_PRICE_AED = 10000;
export const MAX_TEXT_LENGTH = 120;
export const MAX_URL_LENGTH = 2048;
export const MAX_BARCODE_LENGTH = 64;

export function cleanNullableText(value: unknown, maxLength = MAX_TEXT_LENGTH): string | null | undefined {
  if (value === undefined) return undefined;
  if (value === null) return null;
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, maxLength);
}

export function cleanRequiredText(value: unknown, maxLength = MAX_TEXT_LENGTH): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, maxLength);
}

export function cleanOptionalUrl(value: unknown): string | null | undefined {
  const cleaned = cleanNullableText(value, MAX_URL_LENGTH);
  if (cleaned == null) return cleaned;
  try {
    const url = new URL(cleaned);
    return url.protocol === 'https:' ? cleaned : undefined;
  } catch {
    return undefined;
  }
}

export function isValidPrice(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value) && value >= MIN_PRICE_AED && value <= MAX_PRICE_AED;
}

export function isNonNegativeInteger(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0;
}

export function decryptedPhoneNumber(value: string | null): string | null {
  if (!value) return null;
  if (!value.includes(':')) return value;
  try {
    return decrypt(value);
  } catch {
    return null;
  }
}

export function serializeAdminUser<T extends { phoneNumber: string | null }>(user: T): Omit<T, 'phoneNumber'> & { phoneNumber: string | null } {
  return { ...user, phoneNumber: decryptedPhoneNumber(user.phoneNumber) };
}

export function clampNumber(value: unknown, min: number, max: number, integer = true): number | undefined {
  if (value === undefined || value === null) return undefined;
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return undefined;
  const clamped = Math.min(max, Math.max(min, numeric));
  return integer ? Math.round(clamped) : clamped;
}

export function hasOversizedString(values: Array<[unknown, number]>): boolean {
  return values.some(([value, maxLength]) => typeof value === 'string' && value.trim().length > maxLength);
}

export function cleanReason(value: unknown, fallback: string): string {
  if (typeof value !== 'string') return fallback;
  const reason = value.trim();
  if (!reason) return fallback;
  return reason.slice(0, MAX_ADMIN_REASON_LENGTH);
}

export function isHttpsUrl(value: string): boolean {
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}
