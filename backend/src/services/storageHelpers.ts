import * as admin from 'firebase-admin';
import Anthropic from '@anthropic-ai/sdk';

function storageBucketName(): string {
  return (
    process.env.FIREBASE_STORAGE_BUCKET ??
    `${process.env.FIREBASE_PROJECT_ID}.firebasestorage.app`
  );
}

// Firebase download URL format:
// https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded_path}?alt=media&token=...
export function objectPathFromFirebaseUrl(url: string): string | null {
  try {
    const parsed = new URL(url);
    if (parsed.hostname !== 'firebasestorage.googleapis.com') return null;
    const match = parsed.pathname.match(/\/v0\/b\/[^/]+\/o\/(.+)/);
    if (!match) return null;
    return decodeURIComponent(match[1]);
  } catch {
    return null;
  }
}

export async function deleteStorageFileByUrl(url: string): Promise<void> {
  const path = objectPathFromFirebaseUrl(url);
  if (!path) return;
  try {
    await admin.storage().bucket(storageBucketName()).file(path).delete();
  } catch {
    // File already deleted or never existed — ignore
  }
}

export async function deleteSubmissionProofs(
  receiptUrl: string | null | undefined,
  priceLabelUrl: string | null | undefined,
): Promise<void> {
  await Promise.allSettled([
    receiptUrl ? deleteStorageFileByUrl(receiptUrl) : Promise.resolve(),
    priceLabelUrl ? deleteStorageFileByUrl(priceLabelUrl) : Promise.resolve(),
  ]);
}

// ---------------------------------------------------------------------------
// Photo validation via Claude Haiku vision
// ---------------------------------------------------------------------------

const VALIDATION_TIMEOUT_MS = 8_000;

const PROOF_PROMPTS: Record<string, string> = {
  receipt:
    'Does this image show a grocery store receipt, till slip, or purchase receipt listing items and prices? Reply with only YES or NO, then a brief reason.',
  price_label:
    'Does this image show a grocery store price label, shelf tag, or price sticker on or near a product? Reply with only YES or NO, then a brief reason.',
};

export interface ProofValidationResult {
  valid: boolean;
  reason: string;
}

function makeClient(): Anthropic | null {
  const key = process.env.ANTHROPIC_API_KEY;
  if (!key) return null;
  return new Anthropic({ apiKey: key });
}

// Fail-open: if vision is unavailable (no key, timeout, API error) we return
// valid=true so a network blip never silently blocks legitimate submissions.
export async function validateProofImage(
  imageUrl: string,
  kind: 'receipt' | 'price_label',
): Promise<ProofValidationResult> {
  // SSRF guard: only forward Firebase Storage URLs to the Anthropic Vision API.
  // objectPathFromFirebaseUrl already checks the hostname — if it returns null
  // the URL is not a Firebase Storage URL and we skip validation rather than
  // forwarding an arbitrary URL to a third-party API.
  if (!objectPathFromFirebaseUrl(imageUrl)) {
    return { valid: true, reason: 'Validation skipped — not a Firebase Storage URL' };
  }

  const client = makeClient();
  if (!client) {
    return { valid: true, reason: 'Validation skipped — ANTHROPIC_API_KEY not set' };
  }

  const prompt = PROOF_PROMPTS[kind];

  try {
    const raceResult = await Promise.race([
      client.messages.create({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 80,
        messages: [
          {
            role: 'user',
            content: [
              { type: 'image', source: { type: 'url', url: imageUrl } },
              { type: 'text', text: prompt },
            ],
          },
        ],
      }),
      new Promise<null>((resolve) => setTimeout(() => resolve(null), VALIDATION_TIMEOUT_MS)),
    ]);

    if (!raceResult) {
      return { valid: true, reason: 'Validation timed out' };
    }

    const text =
      raceResult.content[0].type === 'text' ? raceResult.content[0].text.trim() : '';
    const valid = text.toUpperCase().startsWith('YES');
    const reason = text.replace(/^(YES|NO)[.,]?\s*/i, '').trim() || text;
    return { valid, reason };
  } catch (err) {
    console.warn('[ProofValidation] Vision check error — failing open:', err);
    return { valid: true, reason: 'Validation unavailable' };
  }
}
