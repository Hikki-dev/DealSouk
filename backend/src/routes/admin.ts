import { Router } from 'express';
import { Prisma } from '@prisma/client';
import { prisma } from '../index';
import { requireAuth, requireAdmin, AuthRequest } from '../middleware/auth';
import { authenticatedRateLimit } from '../middleware/rateLimits';
import { recalculateAccuracyRating, runApprovalEffects, createTokenLedgerEntry } from '../services/tokenEngine';
import { deleteSubmissionProofs } from '../services/storageHelpers';
import { decrypt, encrypt } from '../services/encryption';
import {
  notifyAccountBanned,
  notifyAccountSuspended,
  notifyAdminWarning,
  notifySubmissionHidden,
} from '../services/fcmNotifier';
import * as adminFirebase from 'firebase-admin';
import { sendWarningEmail, sendSuspensionEmail, sendBanEmail } from '../services/emailService';
import { generateAnalyticsReport } from '../services/pdfService';
import { recordAdminAction } from '../services/adminAudit';

const router = Router();
const adminWriteLimiter = authenticatedRateLimit({
  envName: 'ADMIN_RATE_LIMIT_PER_MINUTE',
  fallback: 60,
  message: 'Too many admin actions. Please try again in a minute.',
});

router.use(requireAuth);
router.use(requireAdmin);

const MAX_ADMIN_REASON_LENGTH = 500;
const MIN_PRICE_AED = 0.01;
const MAX_PRICE_AED = 10000;
const MAX_TEXT_LENGTH = 120;
const MAX_URL_LENGTH = 2048;
const MAX_BARCODE_LENGTH = 64;

function cleanNullableText(value: unknown, maxLength = MAX_TEXT_LENGTH): string | null | undefined {
  if (value === undefined) return undefined;
  if (value === null) return null;
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, maxLength);
}

function cleanRequiredText(value: unknown, maxLength = MAX_TEXT_LENGTH): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, maxLength);
}

function cleanOptionalUrl(value: unknown): string | null | undefined {
  const cleaned = cleanNullableText(value, MAX_URL_LENGTH);
  if (cleaned == null) return cleaned;
  try {
    const url = new URL(cleaned);
    return url.protocol === 'https:' ? cleaned : undefined;
  } catch {
    return undefined;
  }
}

function isValidPrice(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value) && value >= MIN_PRICE_AED && value <= MAX_PRICE_AED;
}

function isNonNegativeInteger(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0;
}

function decryptedPhoneNumber(value: string | null): string | null {
  if (!value) return null;
  if (!value.includes(':')) return value;
  try {
    return decrypt(value);
  } catch {
    return null;
  }
}

function serializeAdminUser<T extends { phoneNumber: string | null }>(user: T): Omit<T, 'phoneNumber'> & { phoneNumber: string | null } {
  return { ...user, phoneNumber: decryptedPhoneNumber(user.phoneNumber) };
}

function clampNumber(value: unknown, min: number, max: number, integer = true): number | undefined {
  if (value === undefined || value === null) return undefined;
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return undefined;
  const clamped = Math.min(max, Math.max(min, numeric));
  return integer ? Math.round(clamped) : clamped;
}

function hasOversizedString(values: Array<[unknown, number]>): boolean {
  return values.some(([value, maxLength]) => typeof value === 'string' && value.trim().length > maxLength);
}

function cleanReason(value: unknown, fallback: string): string {
  if (typeof value !== 'string') return fallback;
  const reason = value.trim();
  if (!reason) return fallback;
  return reason.slice(0, MAX_ADMIN_REASON_LENGTH);
}

// GET /admin/queue — flagged and pending submissions
router.get('/queue', async (_req, res) => {
  const flagged = await prisma.priceSubmission.findMany({
    where: { status: { in: ['hidden', 'pending'] } },
    include: { product: true, store: true, sourcer: true, flags: true },
    orderBy: { flagCount: 'desc' },
  });

  res.json(
    flagged.map((s) => ({
      id: s.id,
      priceAed: Number(s.priceAed),
      status: s.status,
      flagCount: s.flagCount,
      hasReceipt: s.hasReceipt,
      receiptUrl: s.receiptUrl,
      priceLabelUrl: s.priceLabelUrl,
      submittedAt: s.submittedAt,
      product: { id: s.product.id, name: s.product.name },
      store: { id: s.store.id, chain: s.store.chain, branchName: s.store.branchName },
      sourcer: { id: s.sourcer.id, displayName: s.sourcer.displayName, accuracyRating: s.sourcer.accuracyRating },
      flagReasons: s.flags.map((f) => f.reason),
    }))
  );
});

// POST /admin/submissions/:id/approve
router.post('/submissions/:id/approve', adminWriteLimiter, async (req: AuthRequest, res) => {
  const submission = await prisma.priceSubmission.findUnique({ where: { id: req.params.id } });
  if (!submission) {
    res.status(404).json({ error: 'Submission not found' });
    return;
  }
  const updated = await prisma.priceSubmission.updateMany({
    where: { id: req.params.id, status: { not: 'approved' } },
    data: { status: 'approved' },
  });
  if (updated.count === 0) {
    res.status(400).json({ error: 'Already approved' });
    return;
  }

  // Award tokens, welcome bonus (FR-07), streak (FR-46), challenge progress
  // (FR-47), accuracy (FR-55), and rank-change push (FR-50).
  const accuracyRating = await runApprovalEffects({
    sourcerId: submission.sourcerId,
    tokensAwarded: submission.tokensAwarded,
    submissionId: req.params.id,
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: submission.sourcerId,
    action: 'approve_submission',
    reason: `Approved submission ${req.params.id}`,
  });

  res.json({ message: 'Approved', tokensAwarded: submission.tokensAwarded, accuracyRating });
});

// POST /admin/submissions/:id/reject
router.post('/submissions/:id/reject', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { reason: rawReason } = req.body as { reason?: string };
  const reason = cleanReason(rawReason, 'Submission did not meet DealSouk quality rules.');
  const submission = await prisma.priceSubmission.findUnique({
    where: { id: req.params.id },
    include: { sourcer: true },
  });
  if (!submission) {
    res.status(404).json({ error: 'Submission not found' });
    return;
  }

  await prisma.priceSubmission.update({
    where: { id: req.params.id },
    data: { status: 'rejected' },
  });

  // Delete proof photos from Firebase Storage — no point keeping rejected evidence
  void deleteSubmissionProofs(submission.receiptUrl, submission.priceLabelUrl);

  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: submission.sourcerId,
    action: 'reject_submission',
    reason,
  });
  await recalculateAccuracyRating(submission.sourcerId);

  // Check auto-suspension: 3+ rejections in rolling 30 days
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const recentRejections = await prisma.priceSubmission.count({
    where: {
      sourcerId: submission.sourcerId,
      status: 'rejected',
      submittedAt: { gte: thirtyDaysAgo },
    },
  });

  if (recentRejections >= 3) {
    const suspendedUntil = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const suspendedUser = await prisma.user.update({
      where: { id: submission.sourcerId },
      data: {
        isSuspended: true,
        suspendedUntil,
        suspensionCount: { increment: 1 },
      },
    });
    await recordAdminAction({
      adminUserId: req.userId!,
      targetUserId: submission.sourcerId,
      action: 'suspend',
      reason: 'Automatic suspension after 3 rejected submissions in 30 days.',
      expiresAt: suspendedUntil,
    });
    await notifyAccountSuspended(submission.sourcer.fcmToken, suspendedUntil, reason);
    try {
      const firebaseUser = await adminFirebase.auth().getUser(submission.sourcer.firebaseUid);
      if (firebaseUser.email) {
        await sendSuspensionEmail(firebaseUser.email, suspendedUntil, reason);
      }
    } catch (err) {
      console.warn('[Email] Failed to send auto-suspension email:', err);
    }

    if (suspendedUser.suspensionCount >= 3) {
      await prisma.user.update({
        where: { id: submission.sourcerId },
        data: {
          bannedAt: new Date(),
          banReason: 'Permanent ban after repeated suspensions.',
        },
      });
      await recordAdminAction({
        adminUserId: req.userId!,
        targetUserId: submission.sourcerId,
        action: 'ban',
        reason: 'Permanent ban after repeated suspensions.',
      });
      await notifyAccountBanned(submission.sourcer.fcmToken, 'Permanent ban after repeated suspensions.');
      try {
        const firebaseUser = await adminFirebase.auth().getUser(submission.sourcer.firebaseUid);
        if (firebaseUser.email) {
          await sendBanEmail(firebaseUser.email, 'Permanent ban after repeated suspensions.');
        }
      } catch (err) {
        console.warn('[Email] Failed to send auto-ban email:', err);
      }
    }
  }

  res.json({ message: 'Rejected' });
});

// PATCH /admin/submissions/:id — edit price, product, or store (FR-56)
router.patch('/submissions/:id', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { priceAed, productId, storeId } = req.body as {
    priceAed?: number;
    productId?: string;
    storeId?: string;
  };

  const submission = await prisma.priceSubmission.findUnique({ where: { id: req.params.id } });
  if (!submission) {
    res.status(404).json({ error: 'Submission not found' });
    return;
  }

  if (priceAed !== undefined && !isValidPrice(priceAed)) {
    res.status(400).json({ error: `priceAed must be a number between ${MIN_PRICE_AED} and ${MAX_PRICE_AED}` });
    return;
  }

  if (productId) {
    const product = await prisma.product.findUnique({ where: { id: productId }, select: { id: true } });
    if (!product) {
      res.status(400).json({ error: 'Invalid productId' });
      return;
    }
  }

  if (storeId) {
    const store = await prisma.store.findUnique({ where: { id: storeId }, select: { id: true } });
    if (!store) {
      res.status(400).json({ error: 'Invalid storeId' });
      return;
    }
  }

  const updated = await prisma.priceSubmission.update({
    where: { id: req.params.id },
    data: {
      ...(priceAed !== undefined && { priceAed }),
      ...(productId && { productId }),
      ...(storeId && { storeId }),
    },
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: submission.sourcerId,
    action: 'edit_submission',
    reason: `Edited submission ${req.params.id}`,
  });

  res.json({ id: updated.id, priceAed: Number(updated.priceAed), productId: updated.productId, storeId: updated.storeId });
});

// POST /admin/users/:id/warn — warn a sourcer without blocking access (FR-53)
router.post('/users/:id/warn', adminWriteLimiter, async (req: AuthRequest, res) => {
  const reason = cleanReason((req.body as { reason?: string }).reason, 'Please follow DealSouk price submission rules.');
  const user = await prisma.user.update({
    where: { id: req.params.id },
    data: { warningCount: { increment: 1 } },
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: user.id,
    action: 'warn',
    reason,
  });
  await notifyAdminWarning(user.fcmToken, reason);
  try {
    const firebaseUser = await adminFirebase.auth().getUser(user.firebaseUid);
    if (firebaseUser.email) {
      await sendWarningEmail(firebaseUser.email, reason);
    }
  } catch (err) {
    console.warn('[Email] Failed to send warning email:', err);
  }

  res.json({ id: user.id, warningCount: user.warningCount, message: 'Warning sent' });
});

// POST /admin/users/:id/suspend — manually suspend a sourcer (FR-53/FR-54)
router.post('/users/:id/suspend', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { days } = req.body as { days?: number };
  const durationDays = Math.min(30, Math.max(1, Number.isFinite(Number(days)) ? Number(days) : 7));
  const suspendedUntil = new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000);
  const reason = cleanReason((req.body as { reason?: string }).reason, 'Account suspended for repeated incorrect submissions.');
  const user = await prisma.user.update({
    where: { id: req.params.id },
    data: {
      isSuspended: true,
      suspendedUntil,
      suspensionCount: { increment: 1 },
    },
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: user.id,
    action: 'suspend',
    reason,
    expiresAt: suspendedUntil,
  });
  await notifyAccountSuspended(user.fcmToken, suspendedUntil, reason);
  try {
    const firebaseUser = await adminFirebase.auth().getUser(user.firebaseUid);
    if (firebaseUser.email) {
      await sendSuspensionEmail(firebaseUser.email, suspendedUntil, reason);
    }
  } catch (err) {
    console.warn('[Email] Failed to send suspension email:', err);
  }

  res.json({
    id: user.id,
    isSuspended: user.isSuspended,
    suspendedUntil,
    suspensionCount: user.suspensionCount,
    message: 'User suspended',
  });
});

// POST /admin/users/:id/ban — permanently ban a sourcer (FR-53/FR-54)
router.post('/users/:id/ban', adminWriteLimiter, async (req: AuthRequest, res) => {
  const reason = cleanReason((req.body as { reason?: string }).reason, 'Account permanently banned for repeated policy violations.');
  const user = await prisma.user.update({
    where: { id: req.params.id },
    data: {
      isSuspended: true,
      suspendedUntil: null,
      bannedAt: new Date(),
      banReason: reason,
    },
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: user.id,
    action: 'ban',
    reason,
  });
  await notifyAccountBanned(user.fcmToken, reason);
  try {
    const firebaseUser = await adminFirebase.auth().getUser(user.firebaseUid);
    if (firebaseUser.email) {
      await sendBanEmail(firebaseUser.email, reason);
    }
  } catch (err) {
    console.warn('[Email] Failed to send ban email:', err);
  }

  res.json({ id: user.id, bannedAt: user.bannedAt, message: 'User banned' });
});

// GET /admin/settings
router.get('/settings', async (_req, res) => {
  const settings = await prisma.adminSettings.upsert({
    where: { id: 1 },
    update: {},
    create: { id: 1 },
  });
  res.json(settings);
});

// PATCH /admin/settings
router.patch('/settings', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { tokenEarnRate, voucherThreshold, dailySubmissionCap, requestCostTokens, decayFactor } = req.body as {
    tokenEarnRate?: number;
    voucherThreshold?: number;
    dailySubmissionCap?: number;
    requestCostTokens?: number;
    decayFactor?: number;
  };

  const update = {
    ...(tokenEarnRate != null && { tokenEarnRate: clampNumber(tokenEarnRate, 1, 500) }),
    ...(voucherThreshold != null && { voucherThreshold: clampNumber(voucherThreshold, 1, 100000) }),
    ...(dailySubmissionCap != null && { dailySubmissionCap: clampNumber(dailySubmissionCap, 1, 500) }),
    ...(requestCostTokens != null && { requestCostTokens: clampNumber(requestCostTokens, 0, 10000) }),
    ...(decayFactor != null && { decayFactor: clampNumber(decayFactor, 0, 1, false) }),
  };

  const updated = await prisma.adminSettings.upsert({
    where: { id: 1 },
    update,
    create: { id: 1 },
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: req.userId!,
    action: 'update_settings',
    reason: 'Updated admin settings',
  });

  res.json(updated);
});

// GET /admin/vouchers — real voucher approval queue (FR-40/FR-41)
router.get('/vouchers', async (req, res) => {
  const status = typeof req.query.status === 'string' ? req.query.status : 'pending';
  const vouchers = await prisma.voucherRequest.findMany({
    where: status === 'all' ? undefined : { status },
    include: {
      user: {
        select: {
          id: true,
          displayName: true,
          homeArea: true,
          tokenBalance: true,
        },
      },
    },
    orderBy: { requestedAt: 'asc' },
    take: 100,
  });

  res.json(
    vouchers.map((voucher) => ({
      id: voucher.id,
      status: voucher.status,
      thresholdTokens: voucher.thresholdTokens,
      tokenCost: voucher.tokenCost,
      denominationAed: voucher.denominationAed,
      supermarket: voucher.supermarket,
      voucherCode: voucher.status === 'approved' ? voucher.voucherCode : null,
      adminNote: voucher.adminNote,
      requestedAt: voucher.requestedAt,
      reviewedAt: voucher.reviewedAt,
      deliveredAt: voucher.deliveredAt,
      user: voucher.user,
    })),
  );
});

// GET /admin/analytics — operational dashboard summary (FR-58/FR-59/FR-60)
router.get('/analytics', async (_req, res) => {
  const now = new Date();
  const dayStart = new Date(now);
  dayStart.setHours(0, 0, 0, 0);
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

  const [
    submissionsToday,
    submissionsThisMonth,
    activeUsers,
    pendingVouchers,
    issuedVouchers,
    tokenAggregate,
    trendingProducts,
    coverageAreas,
  ] = await Promise.all([
    prisma.priceSubmission.count({ where: { submittedAt: { gte: dayStart } } }),
    prisma.priceSubmission.count({ where: { submittedAt: { gte: monthStart } } }),
    prisma.user.count({ where: { createdAt: { gte: monthStart } } }),
    prisma.voucherRequest.count({ where: { status: 'pending' } }),
    prisma.voucherRequest.count({ where: { status: 'approved' } }),
    prisma.tokenTransaction.aggregate({ _sum: { amount: true } }),
    prisma.priceSubmission.groupBy({
      by: ['productId'],
      where: { submittedAt: { gte: monthStart } },
      _count: { productId: true },
      orderBy: { _count: { productId: 'desc' } },
      take: 10,
    }),
    prisma.priceSubmission.groupBy({
      by: ['storeId'],
      where: { submittedAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
      _count: { storeId: true },
      orderBy: { _count: { storeId: 'desc' } },
      take: 10,
    }),
  ]);

  const productIds = trendingProducts.map((item) => item.productId);
  const storeIds = coverageAreas.map((item) => item.storeId);
  const products = await prisma.product.findMany({ where: { id: { in: productIds } } });
  const stores = await prisma.store.findMany({ where: { id: { in: storeIds } } });

  res.json({
    submissionsToday,
    submissionsThisMonth,
    activeUsers,
    tokensNet: tokenAggregate._sum.amount ?? 0,
    pendingVouchers,
    issuedVouchers,
    trendingProducts: trendingProducts.map((item) => {
      const product = products.find((p) => p.id === item.productId);
      return {
        productId: item.productId,
        name: product?.name ?? 'Unknown product',
        category: product?.category ?? 'Unknown',
        submissions: item._count.productId,
      };
    }),
    coverageAreas: coverageAreas.map((item) => {
      const store = stores.find((s) => s.id === item.storeId);
      return {
        storeId: item.storeId,
        chain: store?.chain ?? 'Unknown',
        branchName: store?.branchName ?? '',
        area: store?.area ?? 'Unknown',
        recentSubmissions: item._count.storeId,
      };
    }),
  });
});

// GET /admin/exports/submissions.csv — CSV export for admin reporting (FR-62)
router.get('/exports/submissions.csv', async (_req, res) => {
  const submissions = await prisma.priceSubmission.findMany({
    include: { product: true, store: true, sourcer: true },
    orderBy: { submittedAt: 'desc' },
    take: 5000,
  });

  const escapeCsv = (value: unknown) => {
    const text = String(value ?? '');
    return `"${text.replace(/"/g, '""')}"`;
  };
  const rows = [
    ['id', 'product', 'store', 'area', 'priceAed', 'status', 'flagCount', 'hasReceipt', 'sourcer', 'submittedAt'],
    ...submissions.map((submission) => [
      submission.id,
      submission.product.name,
      `${submission.store.chain} ${submission.store.branchName}`.trim(),
      submission.store.area,
      Number(submission.priceAed).toFixed(2),
      submission.status,
      submission.flagCount,
      submission.hasReceipt,
      submission.sourcer.displayName,
      submission.submittedAt.toISOString(),
    ]),
  ];

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="dealsouk-submissions.csv"');
  res.send(rows.map((row) => row.map(escapeCsv).join(',')).join('\n'));
});

// POST /admin/vouchers/:id/approve — approve voucher by auto-allocating from inventory
router.post('/vouchers/:id/approve', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { adminNote } = req.body as { adminNote?: string };

  try {
    const result = await prisma.$transaction(async (tx) => {
      // 1. Lock the voucher request and verify status
      const voucher = await tx.voucherRequest.findUnique({
        where: { id: req.params.id },
        include: { user: true },
      });
      if (!voucher) {
        throw new Error('NOT_FOUND');
      }
      if (voucher.status !== 'pending') {
        throw new Error('ALREADY_REVIEWED');
      }
      if (voucher.user.tokenBalance < voucher.tokenCost) {
        throw new Error('INSUFFICIENT_TOKENS');
      }

      // 2. Find and lock an unused voucher code in inventory
      const inventoryItem = await tx.voucherInventory.findFirst({
        where: {
          supermarket: { equals: voucher.supermarket, mode: 'insensitive' },
          denominationAed: voucher.denominationAed,
          isUsed: false,
        },
      });
      if (!inventoryItem) {
        throw new Error('NO_STOCK');
      }

      // 3. Mark the inventory item as used
      await tx.voucherInventory.update({
        where: { id: inventoryItem.id },
        data: {
          isUsed: true,
          usedAt: new Date(),
          voucherRequestId: voucher.id,
        },
      });

      // 4. Deduct tokens from user
      await createTokenLedgerEntry(tx, {
        userId: voucher.userId,
        amount: -voucher.tokenCost,
        reason: `Voucher approved: AED ${voucher.denominationAed} ${voucher.supermarket}`,
      });
      await tx.user.update({
        where: { id: voucher.userId },
        data: { tokenBalance: { decrement: voucher.tokenCost } },
      });

      // 5. Update voucher request
      return tx.voucherRequest.update({
        where: { id: voucher.id },
        data: {
          status: 'approved',
          voucherCode: inventoryItem.code,
          adminNote: adminNote?.trim() || null,
          reviewedAt: new Date(),
          deliveredAt: new Date(),
        },
      });
    });
    await recordAdminAction({
      adminUserId: req.userId!,
      targetUserId: result.userId,
      action: 'approve_voucher',
      reason: `Approved voucher request ${result.id}`,
    });

    res.json({
      id: result.id,
      status: result.status,
      denominationAed: result.denominationAed,
      supermarket: result.supermarket,
      voucherCode: result.voucherCode,
      deliveredAt: result.deliveredAt,
    });
  } catch (err: any) {
    if (err.message === 'NOT_FOUND') {
      res.status(404).json({ error: 'Voucher request not found' });
    } else if (err.message === 'ALREADY_REVIEWED') {
      res.status(400).json({ error: 'Voucher request is already reviewed' });
    } else if (err.message === 'INSUFFICIENT_TOKENS') {
      res.status(400).json({ error: 'User no longer has enough tokens for this voucher' });
    } else if (err.message === 'NO_STOCK') {
      res.status(400).json({
        error: 'No voucher inventory available. Please import more voucher stock.',
      });
    } else {
      console.error('[Voucher Approval] Transaction failed:', err);
      res.status(500).json({ error: 'Failed to approve voucher request' });
    }
  }
});

// POST /admin/vouchers/:id/reject — reject without deducting tokens
router.post('/vouchers/:id/reject', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { adminNote } = req.body as { adminNote?: string };
  const voucher = await prisma.voucherRequest.findUnique({ where: { id: req.params.id } });
  if (!voucher) {
    res.status(404).json({ error: 'Voucher request not found' });
    return;
  }
  if (voucher.status !== 'pending') {
    res.status(400).json({ error: 'Voucher request is already reviewed' });
    return;
  }

  const updated = await prisma.voucherRequest.update({
    where: { id: voucher.id },
    data: {
      status: 'rejected',
      adminNote: adminNote?.trim() || null,
      reviewedAt: new Date(),
    },
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: voucher.userId,
    action: 'reject_voucher',
    reason: adminNote?.trim() || `Rejected voucher request ${voucher.id}`,
  });

  res.json({ id: updated.id, status: updated.status });
});

// POST /admin/vouchers/inventory/import — bulk import voucher codes
router.post('/vouchers/inventory/import', adminWriteLimiter, async (req, res) => {
  const { supermarket, denominationAed, codes } = req.body as {
    supermarket: string;
    denominationAed: number;
    codes: string[];
  };

  if (!supermarket?.trim()) {
    res.status(400).json({ error: 'supermarket is required' });
    return;
  }
  const denom = Number(denominationAed);
  if (!denom || denom <= 0) {
    res.status(400).json({ error: 'denominationAed must be a positive number' });
    return;
  }
  if (!Array.isArray(codes) || codes.length === 0) {
    res.status(400).json({ error: 'codes must be a non-empty array' });
    return;
  }

  const validCodes = codes.map((c) => String(c).trim()).filter((c) => c.length >= 4);
  if (validCodes.length === 0) {
    res.status(400).json({ error: 'No valid codes provided (must be at least 4 characters)' });
    return;
  }

  try {
    let createdCount = 0;
    for (const code of validCodes) {
      try {
        await prisma.voucherInventory.create({
          data: {
            supermarket: supermarket.trim(),
            denominationAed: denom,
            code,
          },
        });
        createdCount++;
      } catch (err) {
        // Never log the raw voucher code (sensitive value, AGENTS.md log-safety).
        console.warn('[Inventory] Skipping import of a duplicate voucher code');
      }
    }

    res.json({
      message: `Successfully imported ${createdCount} of ${validCodes.length} voucher codes.`,
      importedCount: createdCount,
    });
  } catch (err) {
    console.error('[Inventory] Bulk import failed:', err);
    res.status(500).json({ error: 'Failed to import voucher inventory' });
  }
});

// GET /admin/vouchers/inventory/status — view stock levels
router.get('/vouchers/inventory/status', async (_req, res) => {
  try {
    const summary = await prisma.voucherInventory.groupBy({
      by: ['supermarket', 'denominationAed', 'isUsed'],
      _count: {
        id: true,
      },
    });

    res.json(
      summary.map((item) => ({
        supermarket: item.supermarket,
        denominationAed: item.denominationAed,
        isUsed: item.isUsed,
        count: item._count.id,
      }))
    );
  } catch (err) {
    console.error('[Inventory] Failed to get status:', err);
    res.status(500).json({ error: 'Failed to get inventory status' });
  }
});

// GET /admin/map-data — return coordinates and active submission counts for heatmap
router.get('/map-data', async (_req, res) => {
  try {
    const storesWithSubmissions = await prisma.store.findMany({
      include: {
        submissions: {
          where: { status: 'approved' },
          select: { id: true },
        },
      },
    });

    res.json(
      storesWithSubmissions.map((store) => ({
        id: store.id,
        chain: store.chain,
        branchName: store.branchName,
        lat: store.lat,
        lng: store.lng,
        area: store.area,
        activeSubmissionsCount: store.submissions.length,
      }))
    );
  } catch (err) {
    console.error('[MapData] Failed to get map data:', err);
    res.status(500).json({ error: 'Failed to get map data' });
  }
});

// GET /admin/exports/analytics.pdf — operational analytics report in PDF format
router.get('/exports/analytics.pdf', async (_req, res) => {
  try {
    const now = new Date();
    const dayStart = new Date(now);
    dayStart.setHours(0, 0, 0, 0);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      submissionsToday,
      submissionsThisMonth,
      activeUsers,
      pendingVouchers,
      issuedVouchers,
      tokenAggregate,
      trendingProducts,
      coverageAreas,
    ] = await Promise.all([
      prisma.priceSubmission.count({ where: { submittedAt: { gte: dayStart } } }),
      prisma.priceSubmission.count({ where: { submittedAt: { gte: monthStart } } }),
      prisma.user.count({ where: { createdAt: { gte: monthStart } } }),
      prisma.voucherRequest.count({ where: { status: 'pending' } }),
      prisma.voucherRequest.count({ where: { status: 'approved' } }),
      prisma.tokenTransaction.aggregate({ _sum: { amount: true } }),
      prisma.priceSubmission.groupBy({
        by: ['productId'],
        where: { submittedAt: { gte: monthStart } },
        _count: { productId: true },
        orderBy: { _count: { productId: 'desc' } },
        take: 10,
      }),
      prisma.priceSubmission.groupBy({
        by: ['storeId'],
        where: { submittedAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
        _count: { storeId: true },
        orderBy: { _count: { storeId: 'desc' } },
        take: 10,
      }),
    ]);

    const productIds = trendingProducts.map((item) => item.productId);
    const storeIds = coverageAreas.map((item) => item.storeId);
    const [products, stores] = await Promise.all([
      prisma.product.findMany({ where: { id: { in: productIds } } }),
      prisma.store.findMany({ where: { id: { in: storeIds } } }),
    ]);

    const analyticsData = {
      submissionsToday,
      submissionsThisMonth,
      activeUsers,
      tokensNet: tokenAggregate._sum.amount ?? 0,
      pendingVouchers,
      issuedVouchers,
      trendingProducts: trendingProducts.map((item) => {
        const product = products.find((p) => p.id === item.productId);
        return {
          productId: item.productId,
          name: product?.name ?? 'Unknown product',
          category: product?.category ?? 'Unknown',
          submissions: item._count.productId,
        };
      }),
      coverageAreas: coverageAreas.map((item) => {
        const store = stores.find((s) => s.id === item.storeId);
        return {
          storeId: item.storeId,
          chain: store?.chain ?? 'Unknown',
          branchName: store?.branchName ?? '',
          area: store?.area ?? 'Unknown',
          recentSubmissions: item._count.storeId,
        };
      }),
    };

    const pdfBuffer = await generateAnalyticsReport(analyticsData);

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename="dealsouk-analytics.pdf"');
    res.send(pdfBuffer);
  } catch (err) {
    console.error('[PDF Export] Failed to generate PDF:', err);
    res.status(500).json({ error: 'Failed to generate PDF report' });
  }
});

// GET /admin/products — List all products with search & category filters
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
