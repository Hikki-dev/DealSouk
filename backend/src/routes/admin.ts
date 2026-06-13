import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, requireAdmin, AuthRequest } from '../middleware/auth';
import { authenticatedRateLimit } from '../middleware/rateLimits';
import { awardTokens, checkFirstSubmissionBonus, updateStreakOnApproval, updateChallengeProgress, spendTokens } from '../services/tokenEngine';
import { notifyRankChange } from '../services/fcmNotifier';

const router = Router();
const adminWriteLimiter = authenticatedRateLimit({
  envName: 'ADMIN_RATE_LIMIT_PER_MINUTE',
  fallback: 60,
  message: 'Too many admin actions. Please try again in a minute.',
});

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
router.post('/submissions/:id/approve', adminWriteLimiter, async (req: AuthRequest, res) => {
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
    await awardTokens(submission.sourcerId, submission.tokensAwarded, `Approved submission: ${req.params.id}`);
  }

  // FR-07: Welcome bonus on first approved submission
  await checkFirstSubmissionBonus(submission.sourcerId);

  // FR-46: Update streak
  await updateStreakOnApproval(submission.sourcerId);

  // FR-47: Update daily challenge progress
  await updateChallengeProgress(submission.sourcerId);

  res.json({ message: 'Approved', tokensAwarded: submission.tokensAwarded });
});

// POST /admin/submissions/:id/reject
router.post('/submissions/:id/reject', adminWriteLimiter, async (req: AuthRequest, res) => {
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
router.patch('/submissions/:id', adminWriteLimiter, async (req, res) => {
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
router.patch('/settings', adminWriteLimiter, async (req, res) => {
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

// POST /admin/vouchers/:id/approve — admin enters real voucher code before delivery
router.post('/vouchers/:id/approve', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { voucherCode, adminNote } = req.body as { voucherCode?: string; adminNote?: string };
  const cleanCode = voucherCode?.trim();

  if (!cleanCode || cleanCode.length < 4 || cleanCode.length > 120) {
    res.status(400).json({ error: 'voucherCode must be 4-120 characters' });
    return;
  }

  const voucher = await prisma.voucherRequest.findUnique({
    where: { id: req.params.id },
    include: { user: true },
  });
  if (!voucher) {
    res.status(404).json({ error: 'Voucher request not found' });
    return;
  }
  if (voucher.status !== 'pending') {
    res.status(400).json({ error: 'Voucher request is already reviewed' });
    return;
  }
  if (voucher.user.tokenBalance < voucher.tokenCost) {
    res.status(400).json({ error: 'User no longer has enough tokens for this voucher' });
    return;
  }

  await spendTokens(voucher.userId, voucher.tokenCost, `Voucher approved: AED ${voucher.denominationAed} ${voucher.supermarket}`);
  const updated = await prisma.voucherRequest.update({
    where: { id: voucher.id },
    data: {
      status: 'approved',
      voucherCode: cleanCode,
      adminNote: adminNote?.trim() || null,
      reviewedAt: new Date(),
      deliveredAt: new Date(),
    },
  });

  res.json({
    id: updated.id,
    status: updated.status,
    denominationAed: updated.denominationAed,
    supermarket: updated.supermarket,
    deliveredAt: updated.deliveredAt,
  });
});

// POST /admin/vouchers/:id/reject — reject without deducting tokens
router.post('/vouchers/:id/reject', adminWriteLimiter, async (req, res) => {
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

  res.json({ id: updated.id, status: updated.status });
});

export default router;
