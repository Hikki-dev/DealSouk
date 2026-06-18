// Moderation queue: submission approve/reject/edit + user warn/suspend/ban (R2 split of the former admin.ts).
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
      product: {
        id: s.product.id,
        name: s.product.name,
        brand: s.product.brand,
        imageUrl: s.product.imageUrl,
      },
      store: { id: s.store.id, chain: s.store.chain, branchName: s.store.branchName },
      sourcer: { id: s.sourcer.id, displayName: s.sourcer.displayName, accuracyRating: s.sourcer.accuracyRating },
      flagReasons: s.flags.map((f) => f.reason),
    }))
  );
});

// POST /admin/submissions/:id/approve
router.post('/submissions/:id/approve', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { productImageUrl } = req.body as { productImageUrl?: string | null };
  if (
    productImageUrl &&
    (productImageUrl.length > MAX_URL_LENGTH || !isHttpsUrl(productImageUrl))
  ) {
    res.status(400).json({ error: 'productImageUrl must be a valid HTTPS URL' });
    return;
  }

  const submission = await prisma.priceSubmission.findUnique({
    where: { id: req.params.id },
    include: { product: true },
  });
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

  const approvedProductImageUrl = productImageUrl?.trim() || submission.priceLabelUrl;
  if (!submission.product.imageUrl && approvedProductImageUrl) {
    await prisma.product.update({
      where: { id: submission.productId },
      data: { imageUrl: approvedProductImageUrl },
    });
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
  const { priceAed, productId, storeId, productImageUrl } = req.body as {
    priceAed?: number;
    productId?: string;
    storeId?: string;
    productImageUrl?: string | null;
  };
  if (
    productImageUrl &&
    (productImageUrl.length > MAX_URL_LENGTH || !isHttpsUrl(productImageUrl))
  ) {
    res.status(400).json({ error: 'productImageUrl must be a valid HTTPS URL' });
    return;
  }

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

  if (productImageUrl !== undefined) {
    await prisma.product.update({
      where: { id: updated.productId },
      data: { imageUrl: productImageUrl?.trim() || null },
    });
  }

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

export default router;
