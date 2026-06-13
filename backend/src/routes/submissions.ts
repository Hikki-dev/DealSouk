import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { authenticatedRateLimit } from '../middleware/rateLimits';
import { calculateReward, awardTokens } from '../services/tokenEngine';
import { notifySubmissionHidden } from '../services/fcmNotifier';

const router = Router();

// Submission rate limit: max 5 per minute per account (NFR-09)
const submitLimiter = authenticatedRateLimit({
  envName: 'SUBMISSION_RATE_LIMIT_PER_MINUTE',
  fallback: 5,
  message: 'Too many submissions. Max 5 per minute.',
});
const flagLimiter = authenticatedRateLimit({
  envName: 'FLAG_RATE_LIMIT_PER_MINUTE',
  fallback: 10,
  message: 'Too many reports. Please try again in a minute.',
});

const MAX_PRICE_AED = 10000;
const MAX_URL_LENGTH = 2048;

function isHttpsUrl(value: string): boolean {
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}

// GET /submissions/feed?page=&limit=
router.get('/feed', async (req, res) => {
  const page = Math.max(0, Number(req.query.page ?? 0));
  const limit = Math.min(50, Number(req.query.limit ?? 20));

  const submissions = await prisma.priceSubmission.findMany({
    where: { status: 'approved' },
    include: { product: true, store: true },
    orderBy: { submittedAt: 'desc' },
    skip: page * limit,
    take: limit,
  });

  res.json(
    submissions.map((s) => ({
      id: s.id,
      priceAed: Number(s.priceAed),
      hasReceipt: s.hasReceipt,
      submittedAt: s.submittedAt,
      hoursAgo: Math.round((Date.now() - s.submittedAt.getTime()) / 3_600_000),
      product: { id: s.product.id, name: s.product.name, category: s.product.category, imageUrl: s.product.imageUrl },
      store: { id: s.store.id, chain: s.store.chain, branchName: s.store.branchName, area: s.store.area },
    }))
  );
});

// POST /submissions
router.post('/', requireAuth, submitLimiter, async (req: AuthRequest, res) => {
  const { productId, storeId, priceAed, hasReceipt = false, receiptUrl } = req.body as {
    productId: string;
    storeId: string;
    priceAed: number;
    hasReceipt: boolean;
    receiptUrl?: string;
  };

  if (!productId || !storeId || priceAed == null || priceAed <= 0 || priceAed > MAX_PRICE_AED) {
    res.status(400).json({ error: 'productId, storeId, and a positive priceAed are required' });
    return;
  }

  if (receiptUrl && (receiptUrl.length > MAX_URL_LENGTH || !isHttpsUrl(receiptUrl))) {
    res.status(400).json({ error: 'receiptUrl must be a valid HTTPS URL' });
    return;
  }

  const settings = await prisma.adminSettings.findUnique({ where: { id: 1 } });
  const cap = settings?.dailySubmissionCap ?? 30;

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const todayCount = await prisma.priceSubmission.count({
    where: { sourcerId: req.userId!, submittedAt: { gte: startOfDay } },
  });
  if (todayCount >= cap) {
    res.status(429).json({ error: `Daily submission cap of ${cap} reached` });
    return;
  }

  const tokensAwarded = await calculateReward({
    productId,
    storeId,
    sourcerId: req.userId!,
    hasReceipt,
  });

  const expiresAt = new Date(Date.now() + 72 * 60 * 60 * 1000);

  const submission = await prisma.priceSubmission.create({
    data: {
      productId,
      storeId,
      sourcerId: req.userId!,
      priceAed,
      hasReceipt,
      receiptUrl: receiptUrl ?? null,
      status: 'pending',
      tokensAwarded,
      expiresAt,
    },
  });

  res.status(201).json({
    id: submission.id,
    status: submission.status,
    tokensAwarded,
    expiresAt: submission.expiresAt,
  });
});

// POST /submissions/:id/flag
router.post('/:id/flag', requireAuth, flagLimiter, async (req: AuthRequest, res) => {
  const { reason } = req.body as { reason: string };
  const validReasons = ['price_wrong', 'product_mismatch', 'store_wrong', 'duplicate'];
  if (!validReasons.includes(reason)) {
    res.status(400).json({ error: `reason must be one of: ${validReasons.join(', ')}` });
    return;
  }

  const submission = await prisma.priceSubmission.findUnique({
    where: { id: req.params.id },
    include: { sourcer: true },
  });
  if (!submission) {
    res.status(404).json({ error: 'Submission not found' });
    return;
  }

  try {
    await prisma.submissionFlag.create({
      data: { submissionId: req.params.id, flaggerId: req.userId!, reason },
    });
  } catch {
    res.status(409).json({ error: 'You have already flagged this submission' });
    return;
  }

  const newFlagCount = submission.flagCount + 1;
  const newStatus = newFlagCount >= 3 ? 'hidden' : submission.status;

  await prisma.priceSubmission.update({
    where: { id: req.params.id },
    data: { flagCount: newFlagCount, status: newStatus },
  });
  if (newStatus === 'hidden') {
    await notifySubmissionHidden(submission.sourcer.fcmToken, reason);
  }

  res.json({ flagCount: newFlagCount, hidden: newStatus === 'hidden' });
});

// GET /submissions/estimate?productId=&storeId=&hasReceipt=
// Returns the token estimate before submitting (FR-33)
router.get('/estimate', requireAuth, async (req: AuthRequest, res) => {
  const { productId, storeId, hasReceipt } = req.query as Record<string, string>;
  if (!productId || !storeId) {
    res.status(400).json({ error: 'productId and storeId required' });
    return;
  }
  const tokens = await calculateReward({
    productId,
    storeId,
    sourcerId: req.userId!,
    hasReceipt: hasReceipt === 'true',
  });
  res.json({ estimatedTokens: tokens });
});

export default router;
