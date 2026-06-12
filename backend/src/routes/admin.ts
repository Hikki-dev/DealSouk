import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, requireAdmin, AuthRequest } from '../middleware/auth';
import { awardTokens } from '../services/tokenEngine';

const router = Router();

router.use(requireAuth);
router.use(requireAdmin);

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
      submittedAt: s.submittedAt,
      product: { id: s.product.id, name: s.product.name },
      store: { id: s.store.id, chain: s.store.chain, branchName: s.store.branchName },
      sourcer: { id: s.sourcer.id, displayName: s.sourcer.displayName, accuracyRating: s.sourcer.accuracyRating },
      flagReasons: s.flags.map((f) => f.reason),
    }))
  );
});

// POST /admin/submissions/:id/approve
router.post('/submissions/:id/approve', async (req: AuthRequest, res) => {
  const submission = await prisma.priceSubmission.findUnique({ where: { id: req.params.id } });
  if (!submission) {
    res.status(404).json({ error: 'Submission not found' });
    return;
  }
  if (submission.status === 'approved') {
    res.status(400).json({ error: 'Already approved' });
    return;
  }

  await prisma.priceSubmission.update({
    where: { id: req.params.id },
    data: { status: 'approved' },
  });

  if (submission.tokensAwarded > 0) {
    await awardTokens(
      submission.sourcerId,
      submission.tokensAwarded,
      `Approved submission: ${req.params.id}`
    );
  }

  res.json({ message: 'Approved', tokensAwarded: submission.tokensAwarded });
});

// POST /admin/submissions/:id/reject
router.post('/submissions/:id/reject', async (req: AuthRequest, res) => {
  const submission = await prisma.priceSubmission.findUnique({ where: { id: req.params.id } });
  if (!submission) {
    res.status(404).json({ error: 'Submission not found' });
    return;
  }

  await prisma.priceSubmission.update({
    where: { id: req.params.id },
    data: { status: 'rejected' },
  });

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
    await prisma.user.update({
      where: { id: submission.sourcerId },
      data: { isSuspended: true, suspendedUntil },
    });
    console.log(`[AUTO-SUSPEND] User ${submission.sourcerId} suspended until ${suspendedUntil.toISOString()}`);
  }

  res.json({ message: 'Rejected' });
});

// PATCH /admin/submissions/:id — edit price, product, or store (FR-56)
router.patch('/submissions/:id', async (req, res) => {
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

  const updated = await prisma.priceSubmission.update({
    where: { id: req.params.id },
    data: {
      ...(priceAed != null && { priceAed }),
      ...(productId && { productId }),
      ...(storeId && { storeId }),
    },
  });

  res.json({ id: updated.id, priceAed: Number(updated.priceAed), productId: updated.productId, storeId: updated.storeId });
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
router.patch('/settings', async (req, res) => {
  const { tokenEarnRate, voucherThreshold, dailySubmissionCap, requestCostTokens, decayFactor } = req.body as {
    tokenEarnRate?: number;
    voucherThreshold?: number;
    dailySubmissionCap?: number;
    requestCostTokens?: number;
    decayFactor?: number;
  };

  const updated = await prisma.adminSettings.upsert({
    where: { id: 1 },
    update: {
      ...(tokenEarnRate != null && { tokenEarnRate }),
      ...(voucherThreshold != null && { voucherThreshold }),
      ...(dailySubmissionCap != null && { dailySubmissionCap }),
      ...(requestCostTokens != null && { requestCostTokens }),
      ...(decayFactor != null && { decayFactor }),
    },
    create: { id: 1 },
  });

  res.json(updated);
});

export default router;
