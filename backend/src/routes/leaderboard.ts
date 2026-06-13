import { Router } from 'express';
import { prisma } from '../index';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { cached } from '../services/redis';

const router = Router();

// GET /leaderboard/monthly
router.get('/monthly', requireAuth, async (req: AuthRequest, res) => {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  // The board itself (top 10 + hall of fame) is identical for every user, so
  // cache it for 60s in Redis when available — FR-44/45 only require updates
  // within 5 minutes, and this absorbs leaderboard read load at scale (NFR-05).
  // The per-user "your rank" portion is computed fresh below, outside the cache.
  const board = await cached(
    `leaderboard:monthly:${startOfMonth.toISOString().slice(0, 7)}`,
    60,
    () => computeBoard(now, startOfMonth),
  );
  const { top10, hallOfFame } = board;

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

  res.json({ top10, currentUser: existingEntry ?? currentUserRank, hallOfFame });
});

interface BoardEntry {
  rank: number;
  userId: string;
  displayName: string;
  tokensThisMonth: number;
}

/**
 * Builds the user-agnostic part of the leaderboard: the current month's top 10
 * (FR-44) and the previous month's top 3 Hall of Fame (FR-45). Cached by month.
 */
async function computeBoard(
  now: Date,
  startOfMonth: Date,
): Promise<{ top10: BoardEntry[]; hallOfFame: BoardEntry[] }> {
  const rankings = await prisma.tokenTransaction.groupBy({
    by: ['userId'],
    where: { createdAt: { gte: startOfMonth }, amount: { gt: 0 } },
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
    }),
  );

  const startOfPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const prevRankings = await prisma.tokenTransaction.groupBy({
    by: ['userId'],
    where: {
      createdAt: { gte: startOfPrevMonth, lt: startOfMonth },
      amount: { gt: 0 },
    },
    _sum: { amount: true },
    orderBy: { _sum: { amount: 'desc' } },
    take: 3,
  });
  const hallOfFame = await Promise.all(
    prevRankings.map(async (r, idx) => {
      const user = await prisma.user.findUnique({ where: { id: r.userId } });
      return {
        rank: idx + 1,
        userId: r.userId,
        displayName: user?.displayName ?? 'Unknown',
        tokensThisMonth: r._sum.amount ?? 0,
      };
    }),
  );

  return { top10, hallOfFame };
}

export default router;
