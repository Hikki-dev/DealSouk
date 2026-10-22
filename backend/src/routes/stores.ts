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

  // Public store list for a location: safe to reuse for a short while.
  res.set('Cache-Control', 'public, max-age=30, stale-while-revalidate=60');

  // Load up to 500 stores (bounding box pre-filter uses lat/lng ranges; exact
  // Haversine distance is applied in JS below to avoid a raw-SQL extension dep).
  const latDelta = radiusKm / 111.0;
  const lngDelta = radiusKm / (111.0 * Math.cos((lat * Math.PI) / 180));
  const allStores = await prisma.store.findMany({
    where: {
      lat: { gte: lat - latDelta, lte: lat + latDelta },
      lng: { gte: lng - lngDelta, lte: lng + lngDelta },
      ...(chain ? { chain: { contains: chain, mode: 'insensitive' } } : {}),
    },
    take: 500,
  });

  const staleThreshold = new Date(Date.now() - STORE_STALE_MS);

  const nearbyStores = allStores
    .map((store) => ({ store, dist: distanceKm(lat, lng, store.lat, store.lng) }))
    .filter(({ dist }) => dist <= radiusKm)
    .sort((a, b) => a.dist - b.dist);

  if (nearbyStores.length === 0) {
    res.json([]);
    return;
  }

  const storeIds = nearbyStores.map(({ store }) => store.id);

  // Batch: one query for latest submission per store, one for active counts.
  // This replaces the previous N+1 pattern (2 queries per store).
  const [latestSubmissions, activeCounts] = await Promise.all([
    prisma.priceSubmission.findMany({
      where: { storeId: { in: storeIds }, status: 'approved' },
      orderBy: { submittedAt: 'desc' },
      select: { storeId: true, submittedAt: true },
      distinct: ['storeId'],
    }),
    prisma.priceSubmission.groupBy({
      by: ['storeId'],
      where: {
        storeId: { in: storeIds },
        status: 'approved',
        submittedAt: { gte: staleThreshold },
      },
      _count: { storeId: true },
    }),
  ]);

  const latestMap = new Map(latestSubmissions.map((s) => [s.storeId, s.submittedAt]));
  const countMap = new Map(activeCounts.map((c) => [c.storeId, c._count.storeId]));

  const nearby = nearbyStores.map(({ store, dist }) => {
    const lastUpdatedAt = latestMap.get(store.id) ?? null;
    return {
      ...store,
      distanceKm: Math.round(dist * 10) / 10,
      lastUpdatedAt,
      isStale: !lastUpdatedAt || lastUpdatedAt < staleThreshold,
      activeSubmissionCount: countMap.get(store.id) ?? 0,
    };
  });

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
