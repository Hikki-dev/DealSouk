import { Router } from 'express';
import { prisma } from '../index';
import { PRICE_FRESHNESS_MS, DAY_MS } from '../config/constants';
import { ipRateLimit } from '../middleware/rateLimits';

const router = Router();

// ABUSE-6: unauthenticated search has no rate limit — add IP-based cap.
const searchRateLimiter = ipRateLimit({
  envName: 'SEARCH_RATE_LIMIT_PER_MINUTE',
  fallback: 30,
  message: 'Too many search requests. Please slow down.',
});

// GET /products/search?q=&category=
router.get('/search', searchRateLimiter, async (req, res) => {
  const q = String(req.query.q ?? '').trim();
  const category = req.query.category ? String(req.query.category).trim() : undefined;

  if (q.length > 120 || (category && category.length > 80)) {
    res.status(400).json({ error: 'Search text is too long' });
    return;
  }

  // Public, read-mostly catalogue data: let browsers and the CDN reuse it briefly.
  res.set('Cache-Control', 'public, max-age=30, stale-while-revalidate=60');

  const products = await prisma.product.findMany({
    where: {
      ...(q && {
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { brand: { contains: q, mode: 'insensitive' } },
          { barcode: q },
        ],
      }),
      ...(category && { category }),
    },
    take: 50,
    orderBy: { name: 'asc' },
  });

  // Augment each product with its cheapest fresh price (approved, < 72h)
  const cutoff = new Date(Date.now() - PRICE_FRESHNESS_MS);
  const enriched = await Promise.all(
    products.map(async (p) => {
      const cheapest = await prisma.priceSubmission.findFirst({
        where: { productId: p.id, status: 'approved', submittedAt: { gte: cutoff } },
        orderBy: { priceAed: 'asc' },
        include: { store: true },
      });
      const hoursAgo = cheapest
        ? Math.round((Date.now() - cheapest.submittedAt.getTime()) / 3_600_000)
        : null;
      return {
        ...p,
        lowestPrice: cheapest ? Number(cheapest.priceAed) : null,
        lowestPriceStore: cheapest ? cheapest.store.chain : null,
        hoursAgo,
      };
    })
  );

  res.json(enriched);
});

// GET /products/:id/history?days=90 — approved historical prices for trend view.
// Reads the pre-aggregated price_history_daily rollup (one row per store/day)
// so this stays fast as raw submission volume grows (NFR-05). If the rollup view
// isn't present yet (migration not deployed), falls back to scanning raw rows.
router.get('/:id/history', async (req, res) => {
  const days = Math.min(90, Math.max(1, Number(req.query.days ?? 90)));
  const cutoff = new Date(Date.now() - days * DAY_MS);

  try {
    const rows = await prisma.$queryRaw<
      Array<{
        store_id: string;
        bucket_day: Date;
        min_price: string;
        chain: string;
        branch_name: string;
      }>
    >`
      SELECT h.store_id,
             h.bucket_day,
             h.min_price,
             s.chain        AS chain,
             s."branchName" AS branch_name
      FROM price_history_daily h
      JOIN "Store" s ON s.id = h.store_id
      WHERE h.product_id = ${req.params.id}
        AND h.bucket_day >= ${cutoff}
      ORDER BY h.bucket_day ASC
      LIMIT 500
    `;

    res.json(
      rows.map((row) => ({
        id: `${row.store_id}:${row.bucket_day.toISOString().slice(0, 10)}`,
        priceAed: Number(row.min_price),
        submittedAt: row.bucket_day,
        store: {
          id: row.store_id,
          chain: row.chain,
          branchName: row.branch_name,
        },
      })),
    );
  } catch {
    // Rollup view missing/unavailable — fall back to raw approved submissions.
    const submissions = await prisma.priceSubmission.findMany({
      where: {
        productId: req.params.id,
        status: 'approved',
        submittedAt: { gte: cutoff },
      },
      include: { store: true },
      orderBy: { submittedAt: 'asc' },
      take: 500,
    });

    res.json(
      submissions.map((submission) => ({
        id: submission.id,
        priceAed: Number(submission.priceAed),
        submittedAt: submission.submittedAt,
        store: {
          id: submission.store.id,
          chain: submission.store.chain,
          branchName: submission.store.branchName,
        },
      })),
    );
  }
});

// GET /products/:id
router.get('/:id', async (req, res) => {
  const product = await prisma.product.findUnique({ where: { id: req.params.id } });
  if (!product) {
    res.status(404).json({ error: 'Product not found' });
    return;
  }
  res.json(product);
});

// GET /products/:id/prices — fresh approved submissions only (< 72h)
router.get('/:id/prices', async (req, res) => {
  const cutoff = new Date(Date.now() - PRICE_FRESHNESS_MS);
  const limit = Math.min(50, Math.max(1, Number(req.query.limit ?? 50)));

  const prices = await prisma.priceSubmission.findMany({
    where: {
      productId: req.params.id,
      status: 'approved',
      submittedAt: { gte: cutoff },
    },
    include: {
      store: true,
    },
    orderBy: { submittedAt: 'desc' },
    take: limit,
  });

  res.json(
    prices.map((p) => ({
      id: p.id,
      priceAed: Number(p.priceAed),
      hasReceipt: p.hasReceipt,
      submittedAt: p.submittedAt,
      hoursAgo: Math.round((Date.now() - p.submittedAt.getTime()) / 3_600_000),
      store: {
        id: p.store.id,
        chain: p.store.chain,
        branchName: p.store.branchName,
        area: p.store.area,
        lat: p.store.lat,
        lng: p.store.lng,
      },
    }))
  );
});

export default router;
