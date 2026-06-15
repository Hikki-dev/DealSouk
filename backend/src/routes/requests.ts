import { Router } from "express";
import { prisma } from "../index";
import { requireAuth, requireEmailVerified, AuthRequest } from "../middleware/auth";
import { authenticatedRateLimit } from "../middleware/rateLimits";
import { spendTokens, awardTokens } from "../services/tokenEngine";
import { notifyRequestFulfilled } from "../services/fcmNotifier";

const router = Router();
const MAX_REQUEST_TEXT_LENGTH = 120;
const MAX_BOUNTY_TOKENS = 100;

const createRequestLimiter = authenticatedRateLimit({
  envName: "REQUEST_RATE_LIMIT_PER_MINUTE",
  fallback: 10,
  message: "Too many price requests. Please try again in a minute.",
});
const fulfillRequestLimiter = authenticatedRateLimit({
  envName: "REQUEST_FULFILL_RATE_LIMIT_PER_MINUTE",
  fallback: 10,
  message: "Too many request updates. Please try again in a minute.",
});

// GET /requests/board — open requests sorted by bounty, expire stale ones first
router.get("/board", async (req, res) => {
  // Lazy expiry: refund any requests that have passed their expiresAt (FR-29)
  const expired = await prisma.priceRequest.findMany({
    where: { status: "open", expiresAt: { lte: new Date() } },
    include: { requester: true },
  });
  for (const r of expired) {
    const updated = await prisma.priceRequest.updateMany({
      where: { id: r.id, status: "open" },
      data: { status: "expired" },
    });
    if (updated.count > 0) {
      await awardTokens(
        r.requesterId,
        r.bountyTokens,
        `Refund: expired request for ${r.productName}`,
      );
    }
  }

  const requests = await prisma.priceRequest.findMany({
    where: { status: "open", expiresAt: { gt: new Date() } },
    include: { requester: { select: { displayName: true, homeArea: true } } },
    orderBy: { bountyTokens: "desc" },
    take: 50,
  });
  res.json(
    requests.map((request) => ({
      ...request,
      requesterName: request.requester.displayName,
      requesterHomeArea: request.requester.homeArea,
    })),
  );
});

// GET /requests/mine — authenticated user's own requests (FR-30)
router.get("/mine", requireAuth, async (req: AuthRequest, res) => {
  const requests = await prisma.priceRequest.findMany({
    where: { requesterId: req.userId! },
    orderBy: { createdAt: "desc" },
    take: 50,
  });
  res.json(requests);
});

// POST /requests — create a new price request, deduct tokens
router.post("/", requireAuth, requireEmailVerified, createRequestLimiter, async (req: AuthRequest, res) => {
  const { productName, storeName, bountyTokens } = req.body as {
    productName: string;
    storeName: string;
    bountyTokens?: number;
  };

  const cleanProductName = productName?.trim();
  const cleanStoreName = storeName?.trim();

  if (!cleanProductName || !cleanStoreName) {
    res.status(400).json({ error: "productName and storeName are required" });
    return;
  }
  if (
    cleanProductName.length > MAX_REQUEST_TEXT_LENGTH ||
    cleanStoreName.length > MAX_REQUEST_TEXT_LENGTH
  ) {
    res.status(400).json({ error: "Request text is too long" });
    return;
  }

  const settings = await prisma.adminSettings.findUnique({ where: { id: 1 } });
  const cost = bountyTokens ?? settings?.requestCostTokens ?? 10;
  if (!Number.isInteger(cost) || cost < 1 || cost > MAX_BOUNTY_TOKENS) {
    res.status(400).json({ error: "bountyTokens must be between 1 and 100" });
    return;
  }

  try {
    await spendTokens(
      req.userId!,
      cost,
      `Price request: ${productName} @ ${storeName}`,
    );
  } catch {
    res.status(400).json({ error: "Insufficient token balance" });
    return;
  }

  const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000);
  const request = await prisma.priceRequest.create({
    data: {
      requesterId: req.userId!,
      productName: cleanProductName,
      storeName: cleanStoreName,
      bountyTokens: cost,
      expiresAt,
    },
  });

  res.status(201).json(request);
});

// POST /requests/:id/fulfill — sourcer fulfills a request (FR-28: notify requester via FCM)
router.post("/:id/fulfill", requireAuth, requireEmailVerified, fulfillRequestLimiter, async (req: AuthRequest, res) => {
  const request = await prisma.priceRequest.findUnique({
    where: { id: req.params.id },
    include: { requester: true },
  });

  if (!request) {
    res.status(404).json({ error: "Request not found" });
    return;
  }
  if (request.requesterId === req.userId) {
    res.status(400).json({ error: "Cannot fulfill your own request" });
    return;
  }

  // ABUSE-7: prevent sock-puppet bounty farming — require at least one approved
  // submission before collecting any bounty. A brand-new account cannot immediately
  // drain requests without contributing real price data first.
  const fulfillerApprovedCount = await prisma.priceSubmission.count({
    where: { sourcerId: req.userId!, status: 'approved' },
  });
  if (fulfillerApprovedCount === 0) {
    res.status(403).json({
      error: 'You must have at least one approved price submission before fulfilling requests.',
    });
    return;
  }

  const updated = await prisma.priceRequest.updateMany({
    where: { id: req.params.id, status: "open" },
    data: { status: "fulfilled", fulfilledBy: req.userId },
  });

  if (updated.count === 0) {
    res.status(400).json({ error: "Request is no longer open" });
    return;
  }

  await awardTokens(
    req.userId!,
    request.bountyTokens,
    `Fulfilled request: ${request.productName} @ ${request.storeName}`,
  );

  // FR-28: Push notification to requester
  const sourcer = await prisma.user.findUnique({
    where: { id: req.userId! },
    select: { displayName: true },
  });
  await notifyRequestFulfilled(
    request.requester.fcmToken,
    sourcer?.displayName ?? "A sourcer",
    request.productName,
    request.storeName,
    request.bountyTokens,
  );

  res.json({
    message: "Request fulfilled",
    tokensEarned: request.bountyTokens,
  });
});

// DELETE /requests/:id — cancel/delete a price request and refund bounty if still open (FR-30)
router.delete("/:id", requireAuth, async (req: AuthRequest, res) => {
  const request = await prisma.priceRequest.findUnique({
    where: { id: req.params.id },
  });

  if (!request) {
    res.status(404).json({ error: "Request not found" });
    return;
  }

  if (request.requesterId !== req.userId) {
    res.status(403).json({ error: "Not authorized to cancel this request" });
    return;
  }

  const updated = await prisma.priceRequest.updateMany({
    where: { id: req.params.id, requesterId: req.userId!, status: "open" },
    data: { status: "refunded" },
  });

  if (updated.count === 0) {
    res.status(400).json({ error: "Request is no longer open and cannot be cancelled" });
    return;
  }

  await awardTokens(
    req.userId!,
    request.bountyTokens,
    `Refund: cancelled request for ${request.productName}`,
  );

  res.json({ message: "Request cancelled successfully" });
});

export default router;
