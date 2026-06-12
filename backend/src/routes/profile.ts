import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

// GET /profile/me
router.get('/me', requireAuth, async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }

  const totalSubmissions = await prisma.priceSubmission.count({ where: { sourcerId: user.id } });
  const approvedSubmissions = await prisma.priceSubmission.count({
    where: { sourcerId: user.id, status: 'approved' },
  });
  const accuracyRating = totalSubmissions > 0 ? Math.round((approvedSubmissions / totalSubmissions) * 100) : 100;

  // Update accuracy rating in DB
  await prisma.user.update({ where: { id: user.id }, data: { accuracyRating } });

  res.json({
    id: user.id,
    displayName: user.displayName,
    homeArea: user.homeArea,
    preferredLocale: user.preferredLocale,
    tokenBalance: user.tokenBalance,
    accuracyRating,
    isAdmin: user.isAdmin,
    isSuspended: user.isSuspended,
    suspendedUntil: user.suspendedUntil,
    createdAt: user.createdAt,
    totalSubmissions,
    approvedSubmissions,
  });
});

// PATCH /profile/me
router.patch('/me', requireAuth, async (req: AuthRequest, res) => {
  const { displayName, homeArea, preferredLocale } = req.body as {
    displayName?: string;
    homeArea?: string;
    preferredLocale?: string;
  };

  const validLocales = ['en', 'ar'];
  if (preferredLocale && !validLocales.includes(preferredLocale)) {
    res.status(400).json({ error: 'preferredLocale must be "en" or "ar"' });
    return;
  }

  const updated = await prisma.user.update({
    where: { id: req.userId! },
    data: {
      ...(displayName && { displayName }),
      ...(homeArea !== undefined && { homeArea }),
      ...(preferredLocale && { preferredLocale }),
    },
  });

  res.json({ displayName: updated.displayName, homeArea: updated.homeArea, preferredLocale: updated.preferredLocale });
});

// GET /profile/me/transactions
router.get('/me/transactions', requireAuth, async (req: AuthRequest, res) => {
  const page = Math.max(0, Number(req.query.page ?? 0));
  const limit = Math.min(100, Number(req.query.limit ?? 30));

  const transactions = await prisma.tokenTransaction.findMany({
    where: { userId: req.userId! },
    orderBy: { createdAt: 'desc' },
    skip: page * limit,
    take: limit,
  });

  res.json(transactions);
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

// GET /profile/me/requests
router.get('/me/requests', requireAuth, async (req: AuthRequest, res) => {
  const requests = await prisma.priceRequest.findMany({
    where: { requesterId: req.userId! },
    orderBy: { createdAt: 'desc' },
  });
  res.json(requests);
});

// POST /profile/me/fcm-token — register FCM token for push notifications
router.post('/me/fcm-token', requireAuth, async (req: AuthRequest, res) => {
  const { fcmToken } = req.body as { fcmToken: string };
  if (!fcmToken) {
    res.status(400).json({ error: 'fcmToken is required' });
    return;
  }
  await prisma.user.update({
    where: { id: req.userId! },
    data: { fcmToken },
  });
  res.json({ registered: true });
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
