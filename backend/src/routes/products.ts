import { Router } from 'express';
import { prisma } from '../index';

const router = Router();

// GET /products/search?q=&category=
router.get('/search', async (req, res) => {
  const q = String(req.query.q ?? '').trim();
  const category = req.query.category as string | undefined;

  const products = await prisma.product.findMany({
    where: {
      ...(q && {
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { brand: { contains: q, mode: 'insensitive' } },
        ],
      }),
      ...(category && { category }),
    },
    take: 50,
    orderBy: { name: 'asc' },
  });

  res.json(products);
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
