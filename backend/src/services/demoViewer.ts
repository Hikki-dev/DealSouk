// Demo viewers: anyone signed in may look around the moderator console, but only
// real admins (users.isAdmin, set with `npm run admin:set`) can change anything.
// Off unless ADMIN_DEMO_VIEWERS=true, so a plain deploy stays admin-only.

export function isDemoViewerEnabled(): boolean {
  const v = process.env.ADMIN_DEMO_VIEWERS;
  return v === 'true' || v === '1';
}

// Receipt and price-label photos are other shoppers' pictures. Hidden from viewers
// unless ADMIN_DEMO_SHOW_PHOTOS=true.
function showPhotos(): boolean {
  const v = process.env.ADMIN_DEMO_SHOW_PHOTOS;
  return v === 'true' || v === '1';
}

const HIDDEN_KEYS = new Set(['email', 'phoneNumber', 'firebaseUid', 'voucherCode', 'fcmToken', 'banReason']);
const PHOTO_KEYS = new Set(['receiptUrl', 'priceLabelUrl', 'avatarUrl']);
const NAME_KEYS = new Set(['displayName', 'sourcerName']);

function maskName(name: string): string {
  const first = name.trim().slice(0, 1);
  return first ? `${first}•••` : '•••';
}

// Returns a copy of a JSON-like value with personal data removed.
export function maskForDemo(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(maskForDemo);
  if (value && typeof value === 'object' && !(value instanceof Date)) {
    const out: Record<string, unknown> = {};
    for (const [key, v] of Object.entries(value as Record<string, unknown>)) {
      if (HIDDEN_KEYS.has(key)) out[key] = null;
      else if (PHOTO_KEYS.has(key)) out[key] = showPhotos() ? v : null;
      else if (NAME_KEYS.has(key) && typeof v === 'string') out[key] = maskName(v);
      else out[key] = maskForDemo(v);
    }
    return out;
  }
  return value;
}
