// Catalog CRUD: products and users (R2 split of the former admin.ts).
import { Router } from 'express';
import { Prisma } from '@prisma/client';
import { prisma } from '../../index';
import { AuthRequest } from '../../middleware/auth';
import { recalculateAccuracyRating, runApprovalEffects, createTokenLedgerEntry } from '../../services/tokenEngine';
import { deleteSubmissionProofs } from '../../services/storageHelpers';
import { decrypt, encrypt } from '../../services/encryption';
import {
  notifyAccountBanned,
  notifyAccountSuspended,
  notifyAdminWarning,
  notifySubmissionHidden,
} from '../../services/fcmNotifier';
import * as adminFirebase from 'firebase-admin';
import { sendWarningEmail, sendSuspensionEmail, sendBanEmail } from '../../services/emailService';
import { generateAnalyticsReport } from '../../services/pdfService';
import { recordAdminAction } from '../../services/adminAudit';
import {
  adminWriteLimiter, MAX_ADMIN_REASON_LENGTH, MIN_PRICE_AED, MAX_PRICE_AED,
  MAX_TEXT_LENGTH, MAX_URL_LENGTH, MAX_BARCODE_LENGTH, cleanNullableText,
  cleanRequiredText, cleanOptionalUrl, isValidPrice, isNonNegativeInteger,
  decryptedPhoneNumber, serializeAdminUser, clampNumber, hasOversizedString,
  cleanReason, isHttpsUrl,
} from './shared';

const router = Router();

router.get('/products', async (req, res) => {
  const q = String(req.query.q ?? '').trim();
  const category = req.query.category ? String(req.query.category).trim() : undefined;
  const page = Math.max(0, Number(req.query.page ?? 0));
  const limit = Math.min(50, Number(req.query.limit ?? 20));

  const whereClause = {
    ...(q && {
      OR: [
        { name: { contains: q, mode: 'insensitive' as const } },
        { brand: { contains: q, mode: 'insensitive' as const } },
        { barcode: q },
      ],
    }),
    ...(category && category !== 'All' && { category }),
  };

  const products = await prisma.product.findMany({
    where: whereClause,
    orderBy: { name: 'asc' },
    skip: page * limit,
    take: limit,
  });

  const total = await prisma.product.count({
    where: whereClause,
  });

  res.json({ products, total });
});

// GET /admin/products/:id — Fetch product details
router.get('/products/:id', async (req, res) => {
  const product = await prisma.product.findUnique({
    where: { id: req.params.id },
  });
  if (!product) {
    res.status(404).json({ error: 'Product not found' });
    return;
  }
  res.json(product);
});

// POST /admin/products — Create new product
router.post('/products', adminWriteLimiter, async (req, res) => {
  const { name, brand, packSize, category, imageUrl, barcode } = req.body as {
    name: string;
    brand?: string;
    packSize?: string;
    category: string;
    imageUrl?: string;
    barcode?: string;
  };

  const cleanName = cleanRequiredText(name);
  const cleanCategory = cleanRequiredText(category);
  const cleanBrand = cleanNullableText(brand);
  const cleanPackSize = cleanNullableText(packSize);
  const cleanImageUrl = cleanOptionalUrl(imageUrl);
  const cleanBarcode = cleanNullableText(barcode, MAX_BARCODE_LENGTH);

  if (hasOversizedString([[name, MAX_TEXT_LENGTH], [brand, MAX_TEXT_LENGTH], [packSize, MAX_TEXT_LENGTH], [category, MAX_TEXT_LENGTH], [imageUrl, MAX_URL_LENGTH], [barcode, MAX_BARCODE_LENGTH]])) {
    res.status(400).json({ error: 'Product fields exceed allowed length' });
    return;
  }
  if (!cleanName || !cleanCategory) {
    res.status(400).json({ error: 'Name and category are required' });
    return;
  }
  if (imageUrl !== undefined && cleanImageUrl === undefined) {
    res.status(400).json({ error: 'imageUrl must be a valid HTTPS URL' });
    return;
  }

  try {
    const product = await prisma.product.create({
      data: {
        name: cleanName,
        brand: cleanBrand ?? null,
        packSize: cleanPackSize ?? null,
        category: cleanCategory,
        imageUrl: cleanImageUrl ?? null,
        barcode: cleanBarcode ?? null,
      },
    });
    res.status(201).json(product);
  } catch (err: any) {
    if (err.code === 'P2002') {
      res.status(400).json({ error: 'Product with this barcode already exists' });
    } else {
      res.status(500).json({ error: 'Failed to create product' });
    }
  }
});

// PUT /admin/products/:id — Update product
router.put('/products/:id', adminWriteLimiter, async (req, res) => {
  const { name, brand, packSize, category, imageUrl, barcode } = req.body as {
    name?: string;
    brand?: string;
    packSize?: string;
    category?: string;
    imageUrl?: string;
    barcode?: string;
  };

  const cleanName = name !== undefined ? cleanRequiredText(name) : undefined;
  const cleanCategory = category !== undefined ? cleanRequiredText(category) : undefined;
  const cleanBrand = cleanNullableText(brand);
  const cleanPackSize = cleanNullableText(packSize);
  const cleanImageUrl = cleanOptionalUrl(imageUrl);
  const cleanBarcode = cleanNullableText(barcode, MAX_BARCODE_LENGTH);

  if (hasOversizedString([[name, MAX_TEXT_LENGTH], [brand, MAX_TEXT_LENGTH], [packSize, MAX_TEXT_LENGTH], [category, MAX_TEXT_LENGTH], [imageUrl, MAX_URL_LENGTH], [barcode, MAX_BARCODE_LENGTH]])) {
    res.status(400).json({ error: 'Product fields exceed allowed length' });
    return;
  }
  if ((name !== undefined && !cleanName) || (category !== undefined && !cleanCategory)) {
    res.status(400).json({ error: 'Name and category cannot be blank' });
    return;
  }
  if (imageUrl !== undefined && cleanImageUrl === undefined) {
    res.status(400).json({ error: 'imageUrl must be a valid HTTPS URL' });
    return;
  }

  try {
    const data: Prisma.ProductUpdateInput = {};
    if (cleanName) data.name = cleanName;
    if (cleanBrand !== undefined) data.brand = cleanBrand;
    if (cleanPackSize !== undefined) data.packSize = cleanPackSize;
    if (cleanCategory) data.category = cleanCategory;
    if (cleanImageUrl !== undefined) data.imageUrl = cleanImageUrl;
    if (cleanBarcode !== undefined) data.barcode = cleanBarcode;

    const product = await prisma.product.update({
      where: { id: req.params.id },
      data,
    });
    res.json(product);
  } catch (err: any) {
    if (err.code === 'P2002') {
      res.status(400).json({ error: 'Product with this barcode already exists' });
    } else if (err.code === 'P2025') {
      res.status(404).json({ error: 'Product not found' });
    } else {
      res.status(500).json({ error: 'Failed to update product' });
    }
  }
});

// DELETE /admin/products/:id — Safe delete product with cascades
router.delete('/products/:id', adminWriteLimiter, async (req, res) => {
  const productId = req.params.id;

  try {
    await prisma.$transaction(async (tx) => {
      // Delete cart items
      await tx.cartItem.deleteMany({ where: { productId } });

      // Find price submissions of this product
      const subs = await tx.priceSubmission.findMany({
        where: { productId },
        select: { id: true },
      });
      const subIds = subs.map((s) => s.id);

      if (subIds.length > 0) {
        // Delete submission flags
        await tx.submissionFlag.deleteMany({
          where: { submissionId: { in: subIds } },
        });
        // Delete price submissions
        await tx.priceSubmission.deleteMany({
          where: { id: { in: subIds } },
        });
      }

      // Delete product
      await tx.product.delete({ where: { id: productId } });
    });

    res.json({ message: 'Product deleted successfully' });
  } catch (err) {
    console.error('[Admin Product Delete] Failed:', err);
    res.status(500).json({ error: 'Failed to delete product' });
  }
});

// GET /admin/users — List all users with search
router.get('/users', async (req, res) => {
  const q = String(req.query.q ?? '').trim();
  const page = Math.max(0, Number(req.query.page ?? 0));
  const limit = Math.min(50, Number(req.query.limit ?? 20));

  const whereClause = {
    ...(q && {
      OR: [
        { displayName: { contains: q, mode: 'insensitive' as const } },
        { firebaseUid: q },
      ],
    }),
  };

  const users = await prisma.user.findMany({
    where: whereClause,
    orderBy: { displayName: 'asc' },
    skip: page * limit,
    take: limit,
  });

  const total = await prisma.user.count({
    where: whereClause,
  });

  res.json({ users: users.map(serializeAdminUser), total });
});

// GET /admin/users/:id — Fetch user details
router.get('/users/:id', async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.params.id },
  });
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  res.json(serializeAdminUser(user));
});

// POST /admin/users — Create new user
// Note: isAdmin is intentionally excluded — use `npm run admin:set` CLI to grant admin privileges.
router.post('/users', adminWriteLimiter, async (req, res) => {
  const { displayName, phoneNumber, homeArea, preferredLocale, tokenBalance, firebaseUid } = req.body as {
    displayName: string;
    phoneNumber?: string;
    homeArea?: string;
    preferredLocale?: string;
    tokenBalance?: number;
    firebaseUid: string;
  };

  if (!displayName || !firebaseUid) {
    res.status(400).json({ error: 'DisplayName and FirebaseUid are required' });
    return;
  }
  if (tokenBalance !== undefined && !isNonNegativeInteger(tokenBalance)) {
    res.status(400).json({ error: 'tokenBalance must be a non-negative integer' });
    return;
  }
  if (hasOversizedString([[displayName, MAX_TEXT_LENGTH], [phoneNumber, 32], [homeArea, MAX_TEXT_LENGTH], [preferredLocale, 8], [firebaseUid, 128]])) {
    res.status(400).json({ error: 'User fields exceed allowed length' });
    return;
  }

  const cleanDisplayName = cleanRequiredText(displayName);
  const cleanPhoneNumber = cleanNullableText(phoneNumber, 32);
  const cleanHomeArea = cleanNullableText(homeArea);
  const cleanPreferredLocale = cleanRequiredText(preferredLocale ?? 'en', 8);
  const cleanFirebaseUid = cleanRequiredText(firebaseUid, 128);

  if (!cleanDisplayName || !cleanFirebaseUid || !cleanPreferredLocale) {
    res.status(400).json({ error: 'DisplayName, FirebaseUid, and locale are required' });
    return;
  }

  try {
    const user = await prisma.$transaction(async (tx) => {
      const created = await tx.user.create({
        data: {
          displayName: cleanDisplayName,
          firebaseUid: cleanFirebaseUid,
          phoneNumber: cleanPhoneNumber ? encrypt(cleanPhoneNumber) : null,
          homeArea: cleanHomeArea ?? null,
          preferredLocale: cleanPreferredLocale,
          isAdmin: false,
        },
      });
      if (tokenBalance && tokenBalance > 0) {
        await createTokenLedgerEntry(tx, {
          userId: created.id,
          amount: tokenBalance,
          reason: 'Admin balance adjustment',
        });
        return tx.user.update({
          where: { id: created.id },
          data: {
            tokenBalance: { increment: tokenBalance },
            lifetimeTokensEarned: { increment: tokenBalance },
          },
        });
      }
      return created;
    });
    res.status(201).json(serializeAdminUser(user));
  } catch (err: any) {
    if (err.code === 'P2002') {
      res.status(400).json({ error: 'A user with this Firebase UID or phone number already exists' });
    } else {
      res.status(500).json({ error: 'Failed to create user' });
    }
  }
});

// PUT /admin/users/:id — Update user
// Note: isAdmin is intentionally excluded — use `npm run admin:set` CLI to grant admin privileges.
router.put('/users/:id', adminWriteLimiter, async (req, res) => {
  const { displayName, phoneNumber, homeArea, preferredLocale, tokenBalance, isSuspended } = req.body as {
    displayName?: string;
    phoneNumber?: string | null;
    homeArea?: string | null;
    preferredLocale?: string;
    tokenBalance?: number;
    isSuspended?: boolean;
  };

  if (tokenBalance !== undefined && !isNonNegativeInteger(tokenBalance)) {
    res.status(400).json({ error: 'tokenBalance must be a non-negative integer' });
    return;
  }
  if (hasOversizedString([[displayName, MAX_TEXT_LENGTH], [phoneNumber, 32], [homeArea, MAX_TEXT_LENGTH], [preferredLocale, 8]])) {
    res.status(400).json({ error: 'User fields exceed allowed length' });
    return;
  }

  const cleanDisplayName = displayName !== undefined ? cleanRequiredText(displayName) : undefined;
  const cleanPhoneNumber = cleanNullableText(phoneNumber, 32);
  const cleanHomeArea = cleanNullableText(homeArea);
  const cleanPreferredLocale = preferredLocale !== undefined ? cleanRequiredText(preferredLocale, 8) : undefined;

  if ((displayName !== undefined && !cleanDisplayName) || (preferredLocale !== undefined && !cleanPreferredLocale)) {
    res.status(400).json({ error: 'DisplayName and locale cannot be blank' });
    return;
  }

  try {
    const user = await prisma.$transaction(async (tx) => {
      const existing = await tx.user.findUnique({ where: { id: req.params.id } });
      if (!existing) {
        throw new Error('NOT_FOUND');
      }

      const data: Prisma.UserUpdateInput = {};
      if (cleanDisplayName) data.displayName = cleanDisplayName;
      if (cleanPhoneNumber !== undefined) data.phoneNumber = cleanPhoneNumber ? encrypt(cleanPhoneNumber) : null;
      if (cleanHomeArea !== undefined) data.homeArea = cleanHomeArea;
      if (cleanPreferredLocale) data.preferredLocale = cleanPreferredLocale;
      if (isSuspended != null) data.isSuspended = isSuspended;

      let updated = await tx.user.update({
        where: { id: req.params.id },
        data,
      });

      if (tokenBalance !== undefined && tokenBalance !== existing.tokenBalance) {
        const delta = tokenBalance - existing.tokenBalance;
        await createTokenLedgerEntry(tx, {
          userId: existing.id,
          amount: delta,
          reason: 'Admin balance adjustment',
        });
        updated = await tx.user.update({
          where: { id: req.params.id },
          data: {
            tokenBalance: delta > 0 ? { increment: delta } : { decrement: Math.abs(delta) },
            ...(delta > 0 && { lifetimeTokensEarned: { increment: delta } }),
          },
        });
      }

      return updated;
    });
    res.json(serializeAdminUser(user));
  } catch (err: any) {
    if (err.code === 'P2002') {
      res.status(400).json({ error: 'Phone number already in use' });
    } else if (err.message === 'NOT_FOUND') {
      res.status(404).json({ error: 'User not found' });
    } else {
      res.status(500).json({ error: 'Failed to update user' });
    }
  }
});

// DELETE /admin/users/:id — Safe delete user with cascades & Firebase Auth clean up
router.delete('/users/:id', adminWriteLimiter, async (req, res) => {
  const userId = req.params.id;

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { firebaseUid: true },
    });

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    await prisma.$transaction(async (tx) => {
      // Delete Submission flags flaggerId
      await tx.submissionFlag.deleteMany({ where: { flaggerId: userId } });

      // Find user's submissions
      const subs = await tx.priceSubmission.findMany({
        where: { sourcerId: userId },
        select: { id: true },
      });
      const subIds = subs.map((s) => s.id);
      if (subIds.length > 0) {
        await tx.submissionFlag.deleteMany({
          where: { submissionId: { in: subIds } },
        });
        await tx.priceSubmission.deleteMany({
          where: { id: { in: subIds } },
        });
      }

      // Delete other relations
      await tx.tokenTransaction.deleteMany({ where: { userId } });
      await tx.userBadge.deleteMany({ where: { userId } });
      await tx.cartItem.deleteMany({ where: { userId } });
      await tx.userDailyChallenge.deleteMany({ where: { userId } });
      await tx.adminUserAction.deleteMany({
        where: { OR: [{ targetUserId: userId }, { adminUserId: userId }] },
      });
      await tx.priceRequest.deleteMany({ where: { requesterId: userId } });

      // Clear vouchers
      const vouchers = await tx.voucherRequest.findMany({
        where: { userId },
        select: { id: true },
      });
      const voucherIds = vouchers.map((v) => v.id);
      if (voucherIds.length > 0) {
        await tx.voucherInventory.updateMany({
          where: { voucherRequestId: { in: voucherIds } },
          data: { voucherRequestId: null, isUsed: false, usedAt: null },
        });
        await tx.voucherRequest.deleteMany({ where: { userId } });
      }

      // Delete User
      await tx.user.delete({ where: { id: userId } });
    });

    // Also delete from Firebase Auth to keep synced
    try {
      if (user.firebaseUid && !user.firebaseUid.startsWith('deleted_')) {
        await adminFirebase.auth().deleteUser(user.firebaseUid);
      }
    } catch (err) {
      console.warn('[Admin User Delete] Failed to delete Firebase Auth user:', err);
    }

    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    console.error('[Admin User Delete] Failed:', err);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

export default router;
