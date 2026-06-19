// Operations: settings, vouchers, analytics, exports, map-data (R2 split of the former admin.ts).
import { Router } from 'express';
import { Prisma } from '@prisma/client';
import { prisma } from '../../index';
import { AuthRequest } from '../../middleware/auth';
import { recalculateAccuracyRating, runApprovalEffects, createTokenLedgerEntry } from '../../services/tokenEngine';
import { deleteSubmissionProofs } from '../../services/storageHelpers';
import { decrypt, encrypt } from '../../services/encryption';
import {
  notifyAccountBanned,
  notifyAccountSuspended,
  notifyAdminWarning,
  notifySubmissionHidden,
} from '../../services/fcmNotifier';
import * as adminFirebase from 'firebase-admin';
import { sendWarningEmail, sendSuspensionEmail, sendBanEmail } from '../../services/emailService';
import { generateAnalyticsReport } from '../../services/pdfService';
import { recordAdminAction } from '../../services/adminAudit';
import {
  adminWriteLimiter, MAX_ADMIN_REASON_LENGTH, MIN_PRICE_AED, MAX_PRICE_AED,
  MAX_TEXT_LENGTH, MAX_URL_LENGTH, MAX_BARCODE_LENGTH, cleanNullableText,
  cleanRequiredText, cleanOptionalUrl, isValidPrice, isNonNegativeInteger,
  decryptedPhoneNumber, serializeAdminUser, clampNumber, hasOversizedString,
  cleanReason, isHttpsUrl,
} from './shared';

const router = Router();

router.get('/settings', async (_req, res) => {
  const settings = await prisma.adminSettings.upsert({
    where: { id: 1 },
    update: {},
    create: { id: 1 },
  });
  res.json(settings);
});

// PATCH /admin/settings
router.patch('/settings', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { tokenEarnRate, voucherThreshold, dailySubmissionCap, requestCostTokens, decayFactor } = req.body as {
    tokenEarnRate?: number;
    voucherThreshold?: number;
    dailySubmissionCap?: number;
    requestCostTokens?: number;
    decayFactor?: number;
  };

  const update = {
    ...(tokenEarnRate != null && { tokenEarnRate: clampNumber(tokenEarnRate, 1, 500) }),
    ...(voucherThreshold != null && { voucherThreshold: clampNumber(voucherThreshold, 1, 100000) }),
    ...(dailySubmissionCap != null && { dailySubmissionCap: clampNumber(dailySubmissionCap, 1, 500) }),
    ...(requestCostTokens != null && { requestCostTokens: clampNumber(requestCostTokens, 0, 10000) }),
    ...(decayFactor != null && { decayFactor: clampNumber(decayFactor, 0, 1, false) }),
  };

  const updated = await prisma.adminSettings.upsert({
    where: { id: 1 },
    update,
    create: { id: 1 },
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: req.userId!,
    action: 'update_settings',
    reason: 'Updated admin settings',
  });

  res.json(updated);
});

// GET /admin/vouchers — real voucher approval queue (FR-40/FR-41)
router.get('/vouchers', async (req, res) => {
  const status = typeof req.query.status === 'string' ? req.query.status : 'pending';
  const vouchers = await prisma.voucherRequest.findMany({
    where: status === 'all' ? undefined : { status },
    include: {
      user: {
        select: {
          id: true,
          displayName: true,
          homeArea: true,
          tokenBalance: true,
        },
      },
    },
    orderBy: { requestedAt: 'asc' },
    take: 100,
  });

  res.json(
    vouchers.map((voucher) => ({
      id: voucher.id,
      status: voucher.status,
      thresholdTokens: voucher.thresholdTokens,
      tokenCost: voucher.tokenCost,
      denominationAed: voucher.denominationAed,
      supermarket: voucher.supermarket,
      voucherCode: voucher.status === 'approved' ? voucher.voucherCode : null,
      adminNote: voucher.adminNote,
      requestedAt: voucher.requestedAt,
      reviewedAt: voucher.reviewedAt,
      deliveredAt: voucher.deliveredAt,
      user: voucher.user,
    })),
  );
});

// GET /admin/analytics — operational dashboard summary (FR-58/FR-59/FR-60)
router.get('/analytics', async (_req, res) => {
  const now = new Date();
  const dayStart = new Date(now);
  dayStart.setHours(0, 0, 0, 0);
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

  const [
    submissionsToday,
    submissionsThisMonth,
    activeUsers,
    pendingVouchers,
    issuedVouchers,
    tokenAggregate,
    trendingProducts,
    coverageAreas,
  ] = await Promise.all([
    prisma.priceSubmission.count({ where: { submittedAt: { gte: dayStart } } }),
    prisma.priceSubmission.count({ where: { submittedAt: { gte: monthStart } } }),
    prisma.user.count({ where: { createdAt: { gte: monthStart } } }),
    prisma.voucherRequest.count({ where: { status: 'pending' } }),
    prisma.voucherRequest.count({ where: { status: 'approved' } }),
    prisma.tokenTransaction.aggregate({ _sum: { amount: true } }),
    prisma.priceSubmission.groupBy({
      by: ['productId'],
      where: { submittedAt: { gte: monthStart } },
      _count: { productId: true },
      orderBy: { _count: { productId: 'desc' } },
      take: 10,
    }),
    prisma.priceSubmission.groupBy({
      by: ['storeId'],
      where: { submittedAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
      _count: { storeId: true },
      orderBy: { _count: { storeId: 'desc' } },
      take: 10,
    }),
  ]);

  const productIds = trendingProducts.map((item) => item.productId);
  const storeIds = coverageAreas.map((item) => item.storeId);
  const products = await prisma.product.findMany({ where: { id: { in: productIds } } });
  const stores = await prisma.store.findMany({ where: { id: { in: storeIds } } });

  res.json({
    submissionsToday,
    submissionsThisMonth,
    activeUsers,
    tokensNet: tokenAggregate._sum.amount ?? 0,
    pendingVouchers,
    issuedVouchers,
    trendingProducts: trendingProducts.map((item) => {
      const product = products.find((p) => p.id === item.productId);
      return {
        productId: item.productId,
        name: product?.name ?? 'Unknown product',
        category: product?.category ?? 'Unknown',
        submissions: item._count.productId,
      };
    }),
    coverageAreas: coverageAreas.map((item) => {
      const store = stores.find((s) => s.id === item.storeId);
      return {
        storeId: item.storeId,
        chain: store?.chain ?? 'Unknown',
        branchName: store?.branchName ?? '',
        area: store?.area ?? 'Unknown',
        recentSubmissions: item._count.storeId,
      };
    }),
  });
});

// GET /admin/exports/submissions.csv — CSV export for admin reporting (FR-62)
router.get('/exports/submissions.csv', async (_req, res) => {
  const submissions = await prisma.priceSubmission.findMany({
    include: { product: true, store: true, sourcer: true },
    orderBy: { submittedAt: 'desc' },
    take: 5000,
  });

  const escapeCsv = (value: unknown) => {
    const text = String(value ?? '');
    return `"${text.replace(/"/g, '""')}"`;
  };
  const rows = [
    ['id', 'product', 'store', 'area', 'priceAed', 'status', 'flagCount', 'hasReceipt', 'sourcer', 'submittedAt'],
    ...submissions.map((submission) => [
      submission.id,
      submission.product.name,
      `${submission.store.chain} ${submission.store.branchName}`.trim(),
      submission.store.area,
      Number(submission.priceAed).toFixed(2),
      submission.status,
      submission.flagCount,
      submission.hasReceipt,
      submission.sourcer.displayName,
      submission.submittedAt.toISOString(),
    ]),
  ];

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="dealsouk-submissions.csv"');
  res.send(rows.map((row) => row.map(escapeCsv).join(',')).join('\n'));
});

// POST /admin/vouchers/:id/approve — approve voucher by auto-allocating from inventory
router.post('/vouchers/:id/approve', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { adminNote } = req.body as { adminNote?: string };

  try {
    const result = await prisma.$transaction(async (tx) => {
      // 1. Lock the voucher request and verify status
      const voucher = await tx.voucherRequest.findUnique({
        where: { id: req.params.id },
        include: { user: true },
      });
      if (!voucher) {
        throw new Error('NOT_FOUND');
      }
      if (voucher.status !== 'pending') {
        throw new Error('ALREADY_REVIEWED');
      }
      if (voucher.user.tokenBalance < voucher.tokenCost) {
        throw new Error('INSUFFICIENT_TOKENS');
      }

      // 2. Find and lock an unused voucher code in inventory
      const inventoryItem = await tx.voucherInventory.findFirst({
        where: {
          supermarket: { equals: voucher.supermarket, mode: 'insensitive' },
          denominationAed: voucher.denominationAed,
          isUsed: false,
        },
      });
      if (!inventoryItem) {
        throw new Error('NO_STOCK');
      }

      // 3. Mark the inventory item as used
      await tx.voucherInventory.update({
        where: { id: inventoryItem.id },
        data: {
          isUsed: true,
          usedAt: new Date(),
          voucherRequestId: voucher.id,
        },
      });

      // 4. Deduct tokens from user
      await createTokenLedgerEntry(tx, {
        userId: voucher.userId,
        amount: -voucher.tokenCost,
        reason: `Voucher approved: AED ${voucher.denominationAed} ${voucher.supermarket}`,
      });
      await tx.user.update({
        where: { id: voucher.userId },
        data: { tokenBalance: { decrement: voucher.tokenCost } },
      });

      // 5. Update voucher request
      return tx.voucherRequest.update({
        where: { id: voucher.id },
        data: {
          status: 'approved',
          voucherCode: inventoryItem.code,
          adminNote: adminNote?.trim() || null,
          reviewedAt: new Date(),
          deliveredAt: new Date(),
        },
      });
    });
    await recordAdminAction({
      adminUserId: req.userId!,
      targetUserId: result.userId,
      action: 'approve_voucher',
      reason: `Approved voucher request ${result.id}`,
    });

    res.json({
      id: result.id,
      status: result.status,
      denominationAed: result.denominationAed,
      supermarket: result.supermarket,
      voucherCode: result.voucherCode,
      deliveredAt: result.deliveredAt,
    });
  } catch (err: any) {
    if (err.message === 'NOT_FOUND') {
      res.status(404).json({ error: 'Voucher request not found' });
    } else if (err.message === 'ALREADY_REVIEWED') {
      res.status(400).json({ error: 'Voucher request is already reviewed' });
    } else if (err.message === 'INSUFFICIENT_TOKENS') {
      res.status(400).json({ error: 'User no longer has enough tokens for this voucher' });
    } else if (err.message === 'NO_STOCK') {
      res.status(400).json({
        error: 'No voucher inventory available. Please import more voucher stock.',
      });
    } else {
      console.error('[Voucher Approval] Transaction failed:', err);
      res.status(500).json({ error: 'Failed to approve voucher request' });
    }
  }
});

// POST /admin/vouchers/:id/reject — reject without deducting tokens
router.post('/vouchers/:id/reject', adminWriteLimiter, async (req: AuthRequest, res) => {
  const { adminNote } = req.body as { adminNote?: string };
  const voucher = await prisma.voucherRequest.findUnique({ where: { id: req.params.id } });
  if (!voucher) {
    res.status(404).json({ error: 'Voucher request not found' });
    return;
  }
  if (voucher.status !== 'pending') {
    res.status(400).json({ error: 'Voucher request is already reviewed' });
    return;
  }

  const updated = await prisma.voucherRequest.update({
    where: { id: voucher.id },
    data: {
      status: 'rejected',
      adminNote: adminNote?.trim() || null,
      reviewedAt: new Date(),
    },
  });
  await recordAdminAction({
    adminUserId: req.userId!,
    targetUserId: voucher.userId,
    action: 'reject_voucher',
    reason: adminNote?.trim() || `Rejected voucher request ${voucher.id}`,
  });

  res.json({ id: updated.id, status: updated.status });
});

// POST /admin/vouchers/inventory/import — bulk import voucher codes
router.post('/vouchers/inventory/import', adminWriteLimiter, async (req, res) => {
  const { supermarket, denominationAed, codes } = req.body as {
    supermarket: string;
    denominationAed: number;
    codes: string[];
  };

  if (!supermarket?.trim()) {
    res.status(400).json({ error: 'supermarket is required' });
    return;
  }
  const denom = Number(denominationAed);
  if (!denom || denom <= 0) {
    res.status(400).json({ error: 'denominationAed must be a positive number' });
    return;
  }
  if (!Array.isArray(codes) || codes.length === 0) {
    res.status(400).json({ error: 'codes must be a non-empty array' });
    return;
  }

  const validCodes = codes.map((c) => String(c).trim()).filter((c) => c.length >= 4);
  if (validCodes.length === 0) {
    res.status(400).json({ error: 'No valid codes provided (must be at least 4 characters)' });
    return;
  }

  try {
    let createdCount = 0;
    for (const code of validCodes) {
      try {
        await prisma.voucherInventory.create({
          data: {
            supermarket: supermarket.trim(),
            denominationAed: denom,
            code,
          },
        });
        createdCount++;
      } catch (err) {
        // Never log the raw voucher code (sensitive value, AGENTS.md log-safety).
        console.warn('[Inventory] Skipping import of a duplicate voucher code');
      }
    }

    res.json({
      message: `Successfully imported ${createdCount} of ${validCodes.length} voucher codes.`,
      importedCount: createdCount,
    });
  } catch (err) {
    console.error('[Inventory] Bulk import failed:', err);
    res.status(500).json({ error: 'Failed to import voucher inventory' });
  }
});

// GET /admin/vouchers/inventory/status — view stock levels
router.get('/vouchers/inventory/status', async (_req, res) => {
  try {
    const summary = await prisma.voucherInventory.groupBy({
      by: ['supermarket', 'denominationAed', 'isUsed'],
      _count: {
        id: true,
      },
    });

    res.json(
      summary.map((item) => ({
        supermarket: item.supermarket,
        denominationAed: item.denominationAed,
        isUsed: item.isUsed,
        count: item._count.id,
      }))
    );
  } catch (err) {
    console.error('[Inventory] Failed to get status:', err);
    res.status(500).json({ error: 'Failed to get inventory status' });
  }
});

// GET /admin/map-data — return coordinates and active submission counts for heatmap
router.get('/map-data', async (_req, res) => {
  try {
    const storesWithSubmissions = await prisma.store.findMany({
      include: {
        submissions: {
          where: { status: 'approved' },
          select: { id: true },
        },
      },
    });

    res.json(
      storesWithSubmissions.map((store) => ({
        id: store.id,
        chain: store.chain,
        branchName: store.branchName,
        lat: store.lat,
        lng: store.lng,
        area: store.area,
        activeSubmissionsCount: store.submissions.length,
      }))
    );
  } catch (err) {
    console.error('[MapData] Failed to get map data:', err);
    res.status(500).json({ error: 'Failed to get map data' });
  }
});

// GET /admin/exports/analytics.pdf — operational analytics report in PDF format
router.get('/exports/analytics.pdf', async (_req, res) => {
  try {
    const now = new Date();
    const dayStart = new Date(now);
    dayStart.setHours(0, 0, 0, 0);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      submissionsToday,
      submissionsThisMonth,
      activeUsers,
      pendingVouchers,
      issuedVouchers,
      tokenAggregate,
      trendingProducts,
      coverageAreas,
    ] = await Promise.all([
      prisma.priceSubmission.count({ where: { submittedAt: { gte: dayStart } } }),
      prisma.priceSubmission.count({ where: { submittedAt: { gte: monthStart } } }),
      prisma.user.count({ where: { createdAt: { gte: monthStart } } }),
      prisma.voucherRequest.count({ where: { status: 'pending' } }),
      prisma.voucherRequest.count({ where: { status: 'approved' } }),
      prisma.tokenTransaction.aggregate({ _sum: { amount: true } }),
      prisma.priceSubmission.groupBy({
        by: ['productId'],
        where: { submittedAt: { gte: monthStart } },
        _count: { productId: true },
        orderBy: { _count: { productId: 'desc' } },
        take: 10,
      }),
      prisma.priceSubmission.groupBy({
        by: ['storeId'],
        where: { submittedAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
        _count: { storeId: true },
        orderBy: { _count: { storeId: 'desc' } },
        take: 10,
      }),
    ]);

    const productIds = trendingProducts.map((item) => item.productId);
    const storeIds = coverageAreas.map((item) => item.storeId);
    const [products, stores] = await Promise.all([
      prisma.product.findMany({ where: { id: { in: productIds } } }),
      prisma.store.findMany({ where: { id: { in: storeIds } } }),
    ]);

    const analyticsData = {
      submissionsToday,
      submissionsThisMonth,
      activeUsers,
      tokensNet: tokenAggregate._sum.amount ?? 0,
      pendingVouchers,
      issuedVouchers,
      trendingProducts: trendingProducts.map((item) => {
        const product = products.find((p) => p.id === item.productId);
        return {
          productId: item.productId,
          name: product?.name ?? 'Unknown product',
          category: product?.category ?? 'Unknown',
          submissions: item._count.productId,
        };
      }),
      coverageAreas: coverageAreas.map((item) => {
        const store = stores.find((s) => s.id === item.storeId);
        return {
          storeId: item.storeId,
          chain: store?.chain ?? 'Unknown',
          branchName: store?.branchName ?? '',
          area: store?.area ?? 'Unknown',
          recentSubmissions: item._count.storeId,
        };
      }),
    };

    const pdfBuffer = await generateAnalyticsReport(analyticsData);

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename="dealsouk-analytics.pdf"');
    res.send(pdfBuffer);
  } catch (err) {
    console.error('[PDF Export] Failed to generate PDF:', err);
    res.status(500).json({ error: 'Failed to generate PDF report' });
  }
});

// GET /admin/products — List all products with search & category filters

export default router;
