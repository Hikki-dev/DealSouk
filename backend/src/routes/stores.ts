import { Router } from 'express';
import { prisma } from '../index';
import { PRICE_FRESHNESS_MS, STORE_STALE_MS } from '../config/constants';

const router = Router();

function distanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// GET /stores/nearby?lat=&lng=&radius=3&chain=
router.get('/nearby', async (req, res) => {
  const lat = parseFloat(req.query.lat as string);
  const lng = parseFloat(req.query.lng as string);
  const radiusKm = Math.min(50, Math.max(0.5, parseFloat((req.query.radius as string) ?? '3')));
  const chain = req.query.chain as string | undefined;

  if (isNaN(lat) || isNaN(lng)) {
    res.status(400).json({ error: 'lat and lng are required' });
    return;
  }

  const allStores = await prisma.store.findMany({
    where: chain ? { chain: { contains: chain, mode: 'insensitive' } } : undefined,
  });

  const staleThreshold = new Date(Date.now() - STORE_STALE_MS);

  const nearby = await Promise.all(
    allStores
      .map((store) => ({ store, dist: distanceKm(lat, lng, store.lat, store.lng) }))
      .filter(({ dist }) => dist <= radiusKm)
      .sort((a, b) => a.dist - b.dist)
      .map(async ({ store, dist }) => {
        const lastSubmission = await prisma.priceSubmission.findFirst({
          where: { storeId: store.id, status: 'approved' },
          orderBy: { submittedAt: 'desc' },
        });
        const submissionCount = await prisma.priceSubmission.count({
          where: { storeId: store.id, status: 'approved', submittedAt: { gte: staleThreshold } },
        });
        return {
          ...store,
          distanceKm: Math.round(dist * 10) / 10,
          lastUpdatedAt: lastSubmission?.submittedAt ?? null,
          isStale: !lastSubmission || lastSubmission.submittedAt < staleThreshold,
          activeSubmissionCount: submissionCount,
        };
      })
  );

  res.json(nearby);
});

// GET /stores/:id/prices — fresh approved prices available at one branch
router.get('/:id/prices', async (req, res) => {
  const cutoff = new Date(Date.now() - PRICE_FRESHNESS_MS);

  const prices = await prisma.priceSubmission.findMany({
    where: {
      storeId: req.params.id,
      status: 'approved',
      submittedAt: { gte: cutoff },
    },
    include: {
      product: true,
      store: true,
    },
    orderBy: { submittedAt: 'desc' },
    take: 50,
  });

  res.json(
    prices.map((p) => ({
      id: p.id,
      priceAed: Number(p.priceAed),
      hasReceipt: p.hasReceipt,
      submittedAt: p.submittedAt,
      hoursAgo: Math.round((Date.now() - p.submittedAt.getTime()) / 3_600_000),
      storeName: p.store.chain,
      product: {
        id: p.product.id,
        name: p.product.name,
        brand: p.product.brand,
        packSize: p.product.packSize,
        category: p.product.category,
        imageUrl: p.product.imageUrl,
      },
    }))
  );
});

// GET /stores/:id
router.get('/:id', async (req, res) => {
  const store = await prisma.store.findUnique({ where: { id: req.params.id } });
  if (!store) {
    res.status(404).json({ error: 'Store not found' });
    return;
  }
  res.json(store);
});

export default router;
