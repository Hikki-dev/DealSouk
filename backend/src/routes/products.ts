import { Router } from 'express';
import { prisma } from '../index';

const router = Router();

// GET /products/search?q=&category=
router.get('/search', async (req, res) => {
  const q = String(req.query.q ?? '').trim();
  const category = req.query.category ? String(req.query.category).trim() : undefined;

  if (q.length > 120 || (category && category.length > 80)) {
    res.status(400).json({ error: 'Search text is too long' });
    return;
  }

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
  const cutoff = new Date(Date.now() - 72 * 60 * 60 * 1000);
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

// GET /products/:id/history?days=90 — approved historical prices for trend view
router.get('/:id/history', async (req, res) => {
  const days = Math.min(90, Math.max(1, Number(req.query.days ?? 90)));
  const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

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
  const cutoff = new Date(Date.now() - 72 * 60 * 60 * 1000);
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
