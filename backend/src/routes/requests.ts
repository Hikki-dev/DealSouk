import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { spendTokens, awardTokens } from '../services/tokenEngine';

const router = Router();

// GET /requests/board — open requests sorted by bounty, with expiry filter
router.get('/board', async (req, res) => {
  const requests = await prisma.priceRequest.findMany({
    where: { status: 'open', expiresAt: { gt: new Date() } },
    orderBy: { bountyTokens: 'desc' },
    take: 50,
  });
  res.json(requests);
});

// POST /requests — create a new price request, deduct tokens
router.post('/', requireAuth, async (req: AuthRequest, res) => {
  const { productName, storeName, bountyTokens } = req.body as {
    productName: string;
    storeName: string;
    bountyTokens?: number;
  };

  if (!productName || !storeName) {
    res.status(400).json({ error: 'productName and storeName are required' });
    return;
  }

  const settings = await prisma.adminSettings.findUnique({ where: { id: 1 } });
  const cost = bountyTokens ?? (settings?.requestCostTokens ?? 10);

  try {
    await spendTokens(req.userId!, cost, `Price request: ${productName} @ ${storeName}`);
  } catch {
    res.status(400).json({ error: 'Insufficient token balance' });
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

// POST /requests/:id/fulfill — sourcer fulfills a request
router.post('/:id/fulfill', requireAuth, async (req: AuthRequest, res) => {
  const request = await prisma.priceRequest.findUnique({ where: { id: req.params.id } });

  if (!request) {
    res.status(404).json({ error: 'Request not found' });
    return;
  }
  if (request.status !== 'open') {
    res.status(400).json({ error: 'Request is no longer open' });
    return;
  }
  if (request.requesterId === req.userId) {
    res.status(400).json({ error: 'Cannot fulfill your own request' });
    return;
  }

  await prisma.priceRequest.update({
    where: { id: req.params.id },
    data: { status: 'fulfilled', fulfilledBy: req.userId },
  });

  await awardTokens(req.userId!, request.bountyTokens, `Fulfilled request: ${request.productName} @ ${request.storeName}`);

  res.json({ message: 'Request fulfilled', tokensEarned: request.bountyTokens });
});

export default router;
