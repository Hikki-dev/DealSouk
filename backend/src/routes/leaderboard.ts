import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

// GET /leaderboard/monthly
router.get('/monthly', requireAuth, async (req: AuthRequest, res) => {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  // Aggregate tokens earned this month per user
  const rankings = await prisma.tokenTransaction.groupBy({
    by: ['userId'],
    where: {
      createdAt: { gte: startOfMonth },
      amount: { gt: 0 },
    },
    _sum: { amount: true },
    orderBy: { _sum: { amount: 'desc' } },
    take: 10,
  });

  const top10 = await Promise.all(
    rankings.map(async (r, idx) => {
      const user = await prisma.user.findUnique({ where: { id: r.userId } });
      return {
        rank: idx + 1,
        userId: r.userId,
        displayName: user?.displayName ?? 'Unknown',
        tokensThisMonth: r._sum.amount ?? 0,
      };
    })
  );

  // Current user rank (may be outside top 10)
  let currentUserRank = null;
  const currentUserId = req.userId!;
  const existingEntry = top10.find((e) => e.userId === currentUserId);
  if (!existingEntry) {
    const userMonthlyTotal = await prisma.tokenTransaction.aggregate({
      where: { userId: currentUserId, createdAt: { gte: startOfMonth }, amount: { gt: 0 } },
      _sum: { amount: true },
    });
    const userTotal = userMonthlyTotal._sum.amount ?? 0;
    const usersAhead = await prisma.tokenTransaction.groupBy({
      by: ['userId'],
      where: { createdAt: { gte: startOfMonth }, amount: { gt: 0 } },
      having: { amount: { _sum: { gt: userTotal } } },
    });
    const user = await prisma.user.findUnique({ where: { id: currentUserId } });
    currentUserRank = {
      rank: usersAhead.length + 1,
      userId: currentUserId,
      displayName: user?.displayName ?? 'You',
      tokensThisMonth: userTotal,
    };
  }

  res.json({ top10, currentUser: existingEntry ?? currentUserRank });
});

export default router;
