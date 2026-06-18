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
  const top10UserIds = rankings.map((r) => r.userId);
  const top10Users = await prisma.user.findMany({
    where: { id: { in: top10UserIds } },
    select: { id: true, displayName: true },
  });
  const top10UserMap = new Map(top10Users.map((u) => [u.id, u.displayName]));
  const top10 = rankings.map((r, idx) => ({
    rank: idx + 1,
    userId: r.userId,
    displayName: top10UserMap.get(r.userId) ?? 'Unknown',
    tokensThisMonth: r._sum.amount ?? 0,
  }));

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
  const hofUserIds = prevRankings.map((r) => r.userId);
  const hofUsers = await prisma.user.findMany({
    where: { id: { in: hofUserIds } },
    select: { id: true, displayName: true },
  });
  const hofUserMap = new Map(hofUsers.map((u) => [u.id, u.displayName]));
  const hallOfFame = prevRankings.map((r, idx) => ({
    rank: idx + 1,
    userId: r.userId,
    displayName: hofUserMap.get(r.userId) ?? 'Unknown',
    tokensThisMonth: r._sum.amount ?? 0,
  }));

  return { top10, hallOfFame };
}

export default router;
