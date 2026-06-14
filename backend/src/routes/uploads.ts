import crypto from 'crypto';
import { Router } from 'express';
import * as admin from 'firebase-admin';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { authenticatedRateLimit } from '../middleware/rateLimits';

const router = Router();

const uploadLimiter = authenticatedRateLimit({
  envName: 'UPLOAD_SIGN_RATE_LIMIT_PER_MINUTE',
  fallback: 20,
  message: 'Too many upload requests. Please try again in a minute.',
});

const UPLOAD_CONFIG = {
  receipt: { folder: 'receipts', maxBytes: 8 * 1024 * 1024 },
  price_label: { folder: 'price-labels', maxBytes: 8 * 1024 * 1024 },
  avatar: { folder: 'avatars', maxBytes: 4 * 1024 * 1024 },
} as const;

const CONTENT_TYPES: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/jpg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/heic': 'heic',
  'image/heif': 'heif',
};

function storageBucketName(): string {
  return process.env.FIREBASE_STORAGE_BUCKET ?? `${process.env.FIREBASE_PROJECT_ID}.firebasestorage.app`;
}

function encodeStorageObjectPath(path: string): string {
  return encodeURIComponent(path);
}

// POST /uploads/signed-url
router.post('/signed-url', requireAuth, uploadLimiter, async (req: AuthRequest, res) => {
  const { kind, contentType, sizeBytes } = req.body as {
    kind?: keyof typeof UPLOAD_CONFIG;
    contentType?: string;
    sizeBytes?: number;
  };

  if (!kind || !(kind in UPLOAD_CONFIG)) {
    res.status(400).json({ error: 'kind must be one of: receipt, price_label, avatar' });
    return;
  }
  if (!contentType || !CONTENT_TYPES[contentType.toLowerCase()]) {
    res.status(400).json({ error: 'contentType must be a supported image type' });
    return;
  }

  const numericSize = Number(sizeBytes);
  const config = UPLOAD_CONFIG[kind];
  if (!Number.isFinite(numericSize) || numericSize <= 0 || numericSize > config.maxBytes) {
    res.status(400).json({ error: `sizeBytes must be between 1 and ${config.maxBytes}` });
    return;
  }

  const normalizedContentType = contentType.toLowerCase();
  const extension = CONTENT_TYPES[normalizedContentType];
  const uploadId = crypto.randomUUID();
  const downloadToken = crypto.randomUUID();
  const objectPath = `${config.folder}/${req.firebaseUid}/${Date.now()}-${uploadId}.${extension}`;
  const bucketName = storageBucketName();
  const bucket = admin.storage().bucket(bucketName);
  const file = bucket.file(objectPath);
  const requiredHeaders = {
    'Content-Type': normalizedContentType,
    'x-goog-meta-firebasestoragedownloadtokens': downloadToken,
  };

  const [uploadUrl] = await file.getSignedUrl({
    version: 'v4',
    action: 'write',
    expires: Date.now() + 10 * 60 * 1000,
    contentType: normalizedContentType,
    extensionHeaders: requiredHeaders,
  });

  const downloadUrl =
    `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
    `${encodeStorageObjectPath(objectPath)}?alt=media&token=${downloadToken}`;

  res.status(201).json({
    uploadUrl,
    objectPath,
    downloadUrl,
    expiresInSeconds: 600,
    requiredHeaders,
  });
});

export default router;
