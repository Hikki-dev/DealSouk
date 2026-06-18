import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, requireEmailVerified, AuthRequest } from '../middleware/auth';
import { authenticatedRateLimit } from '../middleware/rateLimits';
import {
  awardTokens,
  calculateReward,
  runApprovalEffects,
  TRUST_MIN_APPROVED,
  TRUST_MIN_ACCURACY,
} from '../services/tokenEngine';
import { notifyRequestFulfilled, notifySubmissionHidden } from '../services/fcmNotifier';
import { validateProofImage, deleteSubmissionProofs } from '../services/storageHelpers';
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

const MIN_PRICE_AED = 0.01;
const MAX_PRICE_AED = 10000;
const MAX_URL_LENGTH = 2048;
const MAX_PRODUCT_NAME_LENGTH = 120;
const COMMUNITY_PRODUCT_CATEGORY = 'Community';
const MAX_ID_LENGTH = 40;
// Minimum gap between same-user, same-product, same-store submissions
const DUPLICATE_WINDOW_MS = 60 * 60 * 1000; // 1 hour

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

// Proof photo URLs must come from Firebase Storage — no other host is accepted.
// This prevents SSRF: a crafted URL could otherwise be forwarded to the Anthropic
// Vision API or used to reference off-platform content.
function isFirebaseStorageUrl(value: string): boolean {
  try {
    const { protocol, hostname } = new URL(value);
    return protocol === 'https:' && hostname === 'firebasestorage.googleapis.com';
  } catch {
    return false;
  }
}

// Runs after the HTTP 201 is sent. Checks each proof photo with Claude Haiku
// vision. If a photo clearly isn't a price label / receipt it auto-rejects the
// submission and deletes the files from Firebase Storage immediately.
async function validateAndRejectIfSpam(
  submissionId: string,
  priceLabelUrl: string | undefined,
  receiptUrl: string | undefined,
): Promise<void> {
  try {
    const checks = await Promise.all([
      priceLabelUrl
        ? validateProofImage(priceLabelUrl, 'price_label')
        : Promise.resolve(null),
      receiptUrl
        ? validateProofImage(receiptUrl, 'receipt')
        : Promise.resolve(null),
    ]);

    const [labelResult, receiptResult] = checks;
    const labelFailed = labelResult !== null && !labelResult.valid;
    const receiptFailed = receiptResult !== null && !receiptResult.valid;

    if (!labelFailed && !receiptFailed) return; // all good

    const reasons: string[] = [];
    if (labelFailed) reasons.push(`Price label photo rejected: ${labelResult!.reason}`);
    if (receiptFailed) reasons.push(`Receipt photo rejected: ${receiptResult!.reason}`);

    console.log(`[ProofValidation] Auto-rejecting submission ${submissionId}: ${reasons.join(' | ')}`);

    // Guard: only reject if still pending (admin may have already acted)
    const updated = await prisma.priceSubmission.updateMany({
      where: { id: submissionId, status: 'pending' },
      data: { status: 'rejected' },
    });

    if (updated.count > 0) {
      await deleteSubmissionProofs(receiptUrl, priceLabelUrl);
    }
  } catch (err) {
    console.error('[ProofValidation] Background validation error:', err);
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
router.post('/', requireAuth, requireEmailVerified, submitLimiter, async (req: AuthRequest, res) => {
  const {
    productId,
    productName,
    storeId,
    priceAed,
    hasReceipt = false,
    receiptUrl,
    priceLabelUrl,
    requestId,
  } = req.body as {
    productId?: string;
    productName?: string;
    storeId: string;
    priceAed: number;
    hasReceipt: boolean;
    receiptUrl?: string;
    priceLabelUrl?: string;
    requestId?: string;
  };

  // B9: either an existing productId or a typed productName is required — a
  // community submission can name a product that isn't in the catalog yet.
  if ((!productId && !productName?.trim()) || !storeId) {
    res.status(400).json({ error: 'productId or productName, and storeId are required' });
    return;
  }

  // --- ABUSE-1: type confusion ---
  // priceAed must be a finite number; NaN/Infinity/string bypass JS comparison operators.
  if (
    typeof priceAed !== 'number' ||
    !isFinite(priceAed) ||
    priceAed < MIN_PRICE_AED ||
    priceAed > MAX_PRICE_AED
  ) {
    res.status(400).json({ error: `priceAed must be a number between ${MIN_PRICE_AED} and ${MAX_PRICE_AED}` });
    return;
  }

  // --- ABUSE-2: ID format/length ---
  // storeId is always required; productId is optional (a typed productName or a
  // request fulfilment resolves to a product below), but must be a sane id string.
  if (
    typeof storeId !== 'string' || !storeId || storeId.length > MAX_ID_LENGTH ||
    (productId !== undefined && (typeof productId !== 'string' || productId.length > MAX_ID_LENGTH))
  ) {
    res.status(400).json({ error: 'Invalid productId or storeId' });
    return;
  }
  if (productName && normalizeProductName(productName).length > MAX_PRODUCT_NAME_LENGTH) {
    res.status(400).json({ error: 'productName is too long' });
    return;
  }

  // --- ABUSE-3: receipt bonus claim without proof ---
  // hasReceipt: true grants 1.5× tokens. Require the URL so there is at least a
  // stored artefact for admin review; a missing URL with hasReceipt=true is treated
  // as hasReceipt=false (no bonus).
  const claimsReceipt = hasReceipt === true && !!receiptUrl;

  if (receiptUrl && (receiptUrl.length > MAX_URL_LENGTH || !isFirebaseStorageUrl(receiptUrl))) {
    res.status(400).json({ error: 'receiptUrl must be a Firebase Storage HTTPS URL' });
    return;
  }
  if (priceLabelUrl && (priceLabelUrl.length > MAX_URL_LENGTH || !isFirebaseStorageUrl(priceLabelUrl))) {
    res.status(400).json({ error: 'priceLabelUrl must be a Firebase Storage HTTPS URL' });
    return;
  }

  // --- ABUSE-4: verify the store exists (clean 400, not an unhandled FK 500).
  // Product existence is enforced when the product is resolved below.
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

  // --- ABUSE-5: duplicate submission within 1 hour (reward farming while pending) ---
  // Decay only applies to *approved* submissions, so an attacker can spam the same
  // product+store while their previous submission is still pending and earn full
  // tokens on every one once they're bulk-approved. Block same-user same-product
  // same-store within a 1-hour window (rejected/hidden submissions are exempt so
  // a legitimate correction is always possible).
  const recentDuplicate = await prisma.priceSubmission.findFirst({
    where: {
      sourcerId: req.userId!,
      productId: product.id,
      storeId,
      status: { notIn: ['rejected', 'hidden'] },
      submittedAt: { gte: new Date(Date.now() - DUPLICATE_WINDOW_MS) },
    },
    select: { id: true },
  });
  if (recentDuplicate) {
    res.status(409).json({
      error: 'You already have a recent submission for this item at this store. Please wait at least 1 hour before resubmitting.',
    });
    return;
  }

  const tokensAwarded = await calculateReward({
    productId: product.id,
    storeId,
    sourcerId: req.userId!,
    hasReceipt: claimsReceipt,
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

  let submission;
  try {
    submission = await prisma.priceSubmission.create({
      data: {
        productId: product.id,
        storeId,
        sourcerId: req.userId!,
        priceAed,
        hasReceipt: claimsReceipt,
        receiptUrl: receiptUrl ?? null,
        priceLabelUrl: priceLabelUrl ?? null,
        status: autoApprove ? 'approved' : 'pending',
        tokensAwarded,
        expiresAt,
      },
    });
  } catch (err: any) {
    if (err.code === 'P2003') {
      res.status(400).json({ error: 'Invalid productId or storeId' });
    } else {
      res.status(500).json({ error: 'Failed to create submission' });
    }
    return;
  }

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

  // Run proof-photo validation in the background — never blocks the HTTP response.
  // Trusted sourcers (autoApprove) skip the check to keep their fast path fast;
  // their track record already signals reliability.
  if (!autoApprove && (priceLabelUrl || receiptUrl)) {
    setImmediate(() => void validateAndRejectIfSpam(submission.id, priceLabelUrl, receiptUrl));
  }
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

  const updated = await prisma.$transaction(async (tx) => {
    const incremented = await tx.priceSubmission.update({
      where: { id: req.params.id },
      data: { flagCount: { increment: 1 } },
      select: { flagCount: true, status: true },
    });
    if (incremented.flagCount >= 3 && incremented.status !== 'hidden') {
      await tx.priceSubmission.update({
        where: { id: req.params.id },
        data: { status: 'hidden' },
      });
      return { flagCount: incremented.flagCount, status: 'hidden' };
    }
    return incremented;
  });

  if (updated.status === 'hidden') {
    await notifySubmissionHidden(submission.sourcer.fcmToken, reason);
  }

  res.json({ flagCount: updated.flagCount, hidden: updated.status === 'hidden' });
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
