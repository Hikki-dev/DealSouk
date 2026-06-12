import { Router } from "express";
import { prisma } from "../index";
import { requireAuth, AuthRequest } from "../middleware/auth";
import { spendTokens, awardTokens } from "../services/tokenEngine";
import { notifyRequestFulfilled } from "../services/fcmNotifier";

const router = Router();

// GET /requests/board — open requests sorted by bounty, expire stale ones first
router.get("/board", async (req, res) => {
  // Lazy expiry: refund any requests that have passed their expiresAt (FR-29)
  const expired = await prisma.priceRequest.findMany({
    where: { status: "open", expiresAt: { lte: new Date() } },
    include: { requester: true },
  });
  for (const r of expired) {
    await prisma.priceRequest.update({
      where: { id: r.id },
      data: { status: "expired" },
    });
    await awardTokens(
      r.requesterId,
      r.bountyTokens,
      `Refund: expired request for ${r.productName}`,
    );
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
router.post("/", requireAuth, async (req: AuthRequest, res) => {
  const { productName, storeName, bountyTokens } = req.body as {
    productName: string;
    storeName: string;
    bountyTokens?: number;
  };

  if (!productName || !storeName) {
    res.status(400).json({ error: "productName and storeName are required" });
    return;
  }

  const settings = await prisma.adminSettings.findUnique({ where: { id: 1 } });
  const cost = bountyTokens ?? settings?.requestCostTokens ?? 10;

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
      productName,
      storeName,
      bountyTokens: cost,
      expiresAt,
    },
  });

  res.status(201).json(request);
});

// POST /requests/:id/fulfill — sourcer fulfills a request (FR-28: notify requester via FCM)
router.post("/:id/fulfill", requireAuth, async (req: AuthRequest, res) => {
  const request = await prisma.priceRequest.findUnique({
    where: { id: req.params.id },
    include: { requester: true },
  });

  if (!request) {
    res.status(404).json({ error: "Request not found" });
    return;
  }
  if (request.status !== "open") {
    res.status(400).json({ error: "Request is no longer open" });
    return;
  }
  if (request.requesterId === req.userId) {
    res.status(400).json({ error: "Cannot fulfill your own request" });
    return;
  }

  await prisma.priceRequest.update({
    where: { id: req.params.id },
    data: { status: "fulfilled", fulfilledBy: req.userId },
  });

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

export default router;
