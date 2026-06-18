import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { authenticatedRateLimit } from '../middleware/rateLimits';
import {
  awardTokens,
  calculateReward,
  runApprovalEffects,
  TRUST_MIN_APPROVED,
  TRUST_MIN_ACCURACY,
} from '../services/tokenEngine';
import { notifyRequestFulfilled, notifySubmissionHidden } from '../services/fcmNotifier';
import { PRICE_FRESHNESS_MS } from '../config/constants';

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
const MAX_PRODUCT_NAME_LENGTH = 120;
const COMMUNITY_PRODUCT_CATEGORY = 'Community';

function isHttpsUrl(value: string): boolean {
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}

function normalizeProductName(value: string): string {
  return value.trim().replace(/\s+/g, ' ');
}

async function findOrCreateCommunityProduct(productName: string) {
  const cleanProductName = normalizeProductName(productName);
  const existing = await prisma.product.findFirst({
    where: { name: { equals: cleanProductName, mode: 'insensitive' } },
    orderBy: { id: 'asc' },
  });
  if (existing) return existing;

  return prisma.product.create({
    data: {
      name: cleanProductName,
      category: COMMUNITY_PRODUCT_CATEGORY,
    },
  });
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
  const { productId, productName, storeId, priceAed, hasReceipt = false, receiptUrl, priceLabelUrl, requestId } = req.body as {
    productId?: string;
    productName?: string;
    storeId: string;
    priceAed: number;
    hasReceipt: boolean;
    receiptUrl?: string;
    priceLabelUrl?: string;
    requestId?: string;
  };

  if ((!productId && !productName?.trim()) || !storeId || priceAed == null || priceAed <= 0 || priceAed > MAX_PRICE_AED) {
    res.status(400).json({ error: 'productId or productName, storeId, and a positive priceAed are required' });
    return;
  }
  if (productName && normalizeProductName(productName).length > MAX_PRODUCT_NAME_LENGTH) {
    res.status(400).json({ error: 'productName is too long' });
    return;
  }

  if (receiptUrl && (receiptUrl.length > MAX_URL_LENGTH || !isHttpsUrl(receiptUrl))) {
    res.status(400).json({ error: 'receiptUrl must be a valid HTTPS URL' });
    return;
  }
  if (priceLabelUrl && (priceLabelUrl.length > MAX_URL_LENGTH || !isHttpsUrl(priceLabelUrl))) {
    res.status(400).json({ error: 'priceLabelUrl must be a valid HTTPS URL' });
    return;
  }

  const store = await prisma.store.findUnique({ where: { id: storeId } });
  if (!store) {
    res.status(400).json({ error: 'Store not found' });
    return;
  }

  const request = requestId
    ? await prisma.priceRequest.findUnique({
        where: { id: requestId },
        include: { requester: true },
      })
    : null;
  if (requestId && !request) {
    res.status(404).json({ error: 'Request not found' });
    return;
  }
  if (request) {
    if (request.requesterId === req.userId) {
      res.status(400).json({ error: 'Cannot fulfill your own request' });
      return;
    }
    if (request.status !== 'open' || request.expiresAt <= new Date()) {
      res.status(400).json({ error: 'Request is no longer open' });
      return;
    }
    const requestStoreName = request.storeName.toLowerCase();
    const submissionStoreName = `${store.chain} ${store.branchName}`.toLowerCase();
    if (
      !submissionStoreName.includes(requestStoreName) &&
      !requestStoreName.includes(store.chain.toLowerCase())
    ) {
      res.status(400).json({ error: 'Submission store does not match the request' });
      return;
    }
  }

  let product;
  if (request) {
    product = await findOrCreateCommunityProduct(request.productName);
  } else if (productId) {
    product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product) {
      res.status(400).json({ error: 'Product not found' });
      return;
    }
  } else {
    product = await findOrCreateCommunityProduct(productName!);
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
    productId: product.id,
    storeId,
    sourcerId: req.userId!,
    hasReceipt,
  });

  const expiresAt = new Date(Date.now() + PRICE_FRESHNESS_MS);

  // FR-36: trusted sourcers (verified track record + 90%+ accuracy) publish
  // instantly so prices appear in the live feed within 60s. Everyone else stays
  // pending for admin review.
  const sourcer = await prisma.user.findUnique({
    where: { id: req.userId! },
    select: { accuracyRating: true },
  });
  const priorApproved = await prisma.priceSubmission.count({
    where: { sourcerId: req.userId!, status: 'approved' },
  });
  const autoApprove =
    priorApproved >= TRUST_MIN_APPROVED &&
    (sourcer?.accuracyRating ?? 0) >= TRUST_MIN_ACCURACY;

  const submission = await prisma.priceSubmission.create({
    data: {
      productId: product.id,
      storeId,
      sourcerId: req.userId!,
      priceAed,
      hasReceipt,
      receiptUrl: receiptUrl ?? null,
      priceLabelUrl: priceLabelUrl ?? null,
      status: autoApprove ? 'approved' : 'pending',
      tokensAwarded,
      expiresAt,
    },
  });

  if (autoApprove) {
    await runApprovalEffects({
      sourcerId: req.userId!,
      tokensAwarded,
      submissionId: submission.id,
    });
  }

  let requestBountyTokens = 0;
  if (request) {
    const updated = await prisma.priceRequest.updateMany({
      where: { id: request.id, status: 'open' },
      data: { status: 'fulfilled', fulfilledBy: req.userId! },
    });
    if (updated.count === 0) {
      res.status(400).json({ error: 'Request is no longer open' });
      return;
    }

    requestBountyTokens = request.bountyTokens;
    await awardTokens(
      req.userId!,
      requestBountyTokens,
      `Fulfilled request: ${request.productName} @ ${request.storeName}`,
    );

    const sourcer = await prisma.user.findUnique({
      where: { id: req.userId! },
      select: { displayName: true },
    });
    await notifyRequestFulfilled(
      request.requester.fcmToken,
      sourcer?.displayName ?? 'A sourcer',
      request.productName,
      request.storeName,
      request.bountyTokens,
    );
  }

  res.status(201).json({
    id: submission.id,
    status: submission.status,
    productId: product.id,
    productName: product.name,
    tokensAwarded,
    requestBountyTokens,
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
