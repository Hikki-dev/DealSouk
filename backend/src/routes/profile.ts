import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { computeLevel } from '../services/tokenEngine';

const router = Router();

// GET /profile/me
router.get('/me', requireAuth, async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.userId! },
    include: {
      badges: { include: { badge: true } },
    },
  });
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }

  const totalSubmissions = await prisma.priceSubmission.count({ where: { sourcerId: user.id } });
  const approvedSubmissions = await prisma.priceSubmission.count({ where: { sourcerId: user.id, status: 'approved' } });

  // Daily cap remaining (FR-34)
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const settings = await prisma.adminSettings.findUnique({ where: { id: 1 } });
  const cap = settings?.dailySubmissionCap ?? 30;
  const todayCount = await prisma.priceSubmission.count({
    where: { sourcerId: user.id, submittedAt: { gte: startOfDay } },
  });

  res.json({
    id: user.id,
    displayName: user.displayName,
    homeArea: user.homeArea,
    preferredLocale: user.preferredLocale,
    tokenBalance: user.tokenBalance,
    accuracyRating: user.accuracyRating,
    isAdmin: user.isAdmin,
    isSuspended: user.isSuspended,
    suspendedUntil: user.suspendedUntil,
    totalSubmissions,
    approvedSubmissions,
    currentStreak: user.currentStreak,
    longestStreak: user.longestStreak,
    lifetimeTokensEarned: user.lifetimeTokensEarned,
    level: computeLevel(user.lifetimeTokensEarned),
    dailyCapRemaining: Math.max(0, cap - todayCount),
    dailyCap: cap,
    badges: user.badges.map((ub) => ({
      id: ub.badge.id,
      name: ub.badge.name,
      emoji: ub.badge.emoji,
      description: ub.badge.description,
      unlockedAt: ub.unlockedAt,
    })),
  });
});

// PATCH /profile/me
router.patch('/me', requireAuth, async (req: AuthRequest, res) => {
  const { displayName, homeArea, preferredLocale } = req.body as {
    displayName?: string;
    homeArea?: string;
    preferredLocale?: string;
  };

  const updated = await prisma.user.update({
    where: { id: req.userId! },
    data: {
      ...(displayName && { displayName }),
      ...(homeArea && { homeArea }),
      ...(preferredLocale && { preferredLocale }),
    },
  });

  res.json({ id: updated.id, displayName: updated.displayName, homeArea: updated.homeArea, preferredLocale: updated.preferredLocale });
});

// GET /profile/me/transactions
router.get('/me/transactions', requireAuth, async (req: AuthRequest, res) => {
  const page = Math.max(0, Number(req.query.page ?? 0));
  const limit = Math.min(50, Number(req.query.limit ?? 20));

  const transactions = await prisma.tokenTransaction.findMany({
    where: { userId: req.userId! },
    orderBy: { createdAt: 'desc' },
    skip: page * limit,
    take: limit,
  });

  res.json(transactions);
});

// GET /profile/me/vouchers — user's voucher requests and approved codes
router.get('/me/vouchers', requireAuth, async (req: AuthRequest, res) => {
  const vouchers = await prisma.voucherRequest.findMany({
    where: { userId: req.userId! },
    orderBy: { requestedAt: 'desc' },
    take: 20,
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
      requestedAt: voucher.requestedAt,
      reviewedAt: voucher.reviewedAt,
      deliveredAt: voucher.deliveredAt,
      adminNote: voucher.adminNote,
    })),
  );
});

// GET /profile/me/submissions
router.get('/me/submissions', requireAuth, async (req: AuthRequest, res) => {
  const submissions = await prisma.priceSubmission.findMany({
    where: { sourcerId: req.userId! },
    include: { product: true, store: true },
    orderBy: { submittedAt: 'desc' },
    take: 50,
  });

  res.json(
    submissions.map((s) => ({
      id: s.id,
      priceAed: Number(s.priceAed),
      status: s.status,
      hasReceipt: s.hasReceipt,
      tokensAwarded: s.tokensAwarded,
      submittedAt: s.submittedAt,
      product: { name: s.product.name, category: s.product.category },
      store: { chain: s.store.chain, branchName: s.store.branchName },
    }))
  );
});

// POST /profile/me/fcm-token
router.post('/me/fcm-token', requireAuth, async (req: AuthRequest, res) => {
  const { fcmToken } = req.body as { fcmToken: string };
  if (!fcmToken) {
    res.status(400).json({ error: 'fcmToken required' });
    return;
  }
  await prisma.user.update({ where: { id: req.userId! }, data: { fcmToken } });
  res.json({ ok: true });
});

// GET /profile/me/cart — load persisted cart (FR-23)
router.get('/me/cart', requireAuth, async (req: AuthRequest, res) => {
  const items = await prisma.cartItem.findMany({
    where: { userId: req.userId! },
    include: { product: true },
  });
  res.json(items.map((item) => ({
    productId: item.productId,
    quantity: item.quantity,
    product: {
      id: item.product.id,
      name: item.product.name,
      brand: item.product.brand,
      packSize: item.product.packSize,
      category: item.product.category,
      imageUrl: item.product.imageUrl,
    },
  })));
});

// PUT /profile/me/cart — sync cart from device (FR-23)
router.put('/me/cart', requireAuth, async (req: AuthRequest, res) => {
  const { items } = req.body as { items: Array<{ productId: string; quantity: number }> };
  if (!Array.isArray(items)) {
    res.status(400).json({ error: 'items array required' });
    return;
  }

  // Delete all existing cart items for this user, then upsert the new ones
  await prisma.cartItem.deleteMany({ where: { userId: req.userId! } });

  if (items.length > 0) {
    await prisma.cartItem.createMany({
      data: items.map((item) => ({
        userId: req.userId!,
        productId: item.productId,
        quantity: Math.max(1, item.quantity),
      })),
      skipDuplicates: true,
    });
  }

  res.json({ ok: true, count: items.length });
});

// GET /profile/me/requests — user's own request history (FR-30)
router.get('/me/requests', requireAuth, async (req: AuthRequest, res) => {
  const requests = await prisma.priceRequest.findMany({
    where: { requesterId: req.userId! },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });
  res.json(requests);
});

// DELETE /profile/me — account deletion (PDPL compliance: PII removed within 30 days)
router.delete('/me', requireAuth, async (req: AuthRequest, res) => {
  // Anonymise rather than hard-delete to preserve token ledger for analytics
  await prisma.user.update({
    where: { id: req.userId! },
    data: {
      displayName: '[Deleted User]',
      phoneNumber: null,
      homeArea: null,
      firebaseUid: `deleted_${req.userId}`,
    },
  });
  res.json({ message: 'Account deletion requested. PII will be removed within 30 days.' });
});

export default router;
