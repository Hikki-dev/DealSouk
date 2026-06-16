import crypto from 'crypto';
import { Prisma } from '@prisma/client';
import { prisma } from '../index';
import { notifyStreakMilestone, notifyBadgeEarned, notifyRankChange } from './fcmNotifier';

// FR-36: minimum approved track record before a sourcer's submissions
// publish instantly (combined with a 90%+ accuracy rating).
export const TRUST_MIN_APPROVED = 10;
export const TRUST_MIN_ACCURACY = 90;

export async function getSettings() {
  let settings = await prisma.adminSettings.findUnique({ where: { id: 1 } });
  if (!settings) {
    settings = await prisma.adminSettings.create({ data: { id: 1 } });
  }
  return settings;
}

export function computeLevel(lifetimeTokensEarned: number): number {
  // Level 1-20 based on cumulative lifetime tokens earned (every 500 tokens = 1 level)
  return Math.min(20, Math.floor(lifetimeTokensEarned / 500) + 1);
}

function canonicalLedgerPayload(params: {
  userId: string;
  amount: number;
  reason: string;
  createdAt: Date;
  previousHash: string | null;
}): string {
  return [
    params.userId,
    params.amount,
    params.reason,
    params.createdAt.toISOString(),
    params.previousHash ?? 'GENESIS',
  ].join('|');
}

export function hashTokenTransaction(params: {
  userId: string;
  amount: number;
  reason: string;
  createdAt: Date;
  previousHash: string | null;
}): string {
  return crypto.createHash('sha256').update(canonicalLedgerPayload(params)).digest('hex');
}

export async function createTokenLedgerEntry(
  tx: Prisma.TransactionClient,
  params: { userId: string; amount: number; reason: string },
) {
  // Scope the previous-hash lookup to this user so concurrent transactions for
  // different users don't fork each other's hash chain (C-3).
  const previous = await tx.tokenTransaction.findFirst({
    where: { userId: params.userId },
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    select: { hash: true },
  });
  const createdAt = new Date();
  const previousHash = previous?.hash ?? null;
  const hash = hashTokenTransaction({
    userId: params.userId,
    amount: params.amount,
    reason: params.reason,
    createdAt,
    previousHash,
  });

  return tx.tokenTransaction.create({
    data: {
      userId: params.userId,
      amount: params.amount,
      reason: params.reason,
      previousHash,
      hash,
      createdAt,
    },
  });
}

export async function verifyTokenLedgerChain(): Promise<{ ok: boolean; invalidTransactionId?: string }> {
  const rows = await prisma.tokenTransaction.findMany({
    orderBy: [{ userId: 'asc' }, { createdAt: 'asc' }, { id: 'asc' }],
    select: {
      id: true,
      userId: true,
      amount: true,
      reason: true,
      previousHash: true,
      hash: true,
      createdAt: true,
    },
  });

  const previousHashByUser = new Map<string, string | null>();
  for (const row of rows) {
    const previousHash = previousHashByUser.get(row.userId) ?? null;
    if (row.previousHash !== previousHash) {
      return { ok: false, invalidTransactionId: row.id };
    }
    const expectedHash = hashTokenTransaction({
      userId: row.userId,
      amount: row.amount,
      reason: row.reason,
      createdAt: row.createdAt,
      previousHash,
    });
    if (row.hash !== expectedHash) {
      return { ok: false, invalidTransactionId: row.id };
    }
    previousHashByUser.set(row.userId, row.hash);
  }

  return { ok: true };
}

export async function calculateReward(params: {
  productId: string;
  storeId: string;
  sourcerId: string;
  hasReceipt: boolean;
}): Promise<number> {
  const settings = await getSettings();
  const user = await prisma.user.findUnique({ where: { id: params.sourcerId } });
  if (!user) return 0;

  let reward = settings.tokenEarnRate;

  // Receipt bonus: 1.5x (FR-35)
  if (params.hasReceipt) {
    reward = Math.round(reward * 1.5);
  }

  // Level multiplier: +5% per level above 1 (FR-48)
  const level = computeLevel(user.lifetimeTokensEarned);
  const levelMultiplier = 1 + (level - 1) * 0.05;
  reward = Math.round(reward * levelMultiplier);

  // Decay: if same product+store has approved submission in past 24h (FR-33)
  const recentSub = await prisma.priceSubmission.findFirst({
    where: {
      productId: params.productId,
      storeId: params.storeId,
      status: 'approved',
      submittedAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
    },
  });
  if (recentSub) {
    reward = Math.round(reward * settings.decayFactor);
  }

  return Math.max(1, reward);
}

export async function awardTokens(userId: string, amount: number, reason: string) {
  await prisma.$transaction(async (tx) => {
    await createTokenLedgerEntry(tx, { userId, amount, reason });
    await tx.user.update({
      where: { id: userId },
      data: {
        tokenBalance: { increment: amount },
        lifetimeTokensEarned: { increment: amount },
      },
    });
  });

  // Recompute level and persist it
  const user = await prisma.user.findUnique({ where: { id: userId }, select: { lifetimeTokensEarned: true, level: true, fcmToken: true } });
  if (user) {
    const newLevel = computeLevel(user.lifetimeTokensEarned);
    if (newLevel !== user.level) {
      await prisma.user.update({ where: { id: userId }, data: { level: newLevel } });
      // Award level badge if applicable
      await checkAndAwardLevelBadge(userId, newLevel, user.fcmToken);
    }
  }

  await checkVoucherThreshold(userId);
}

export async function spendTokens(userId: string, amount: number, reason: string) {
  // Atomic check-and-decrement: the WHERE guard on tokenBalance >= amount means
  // two concurrent calls can never both pass the check against the same stale
  // balance and drive it negative (C-1 TOCTOU fix).
  await prisma.$transaction(async (tx) => {
    const result = await tx.$executeRaw`
      UPDATE "User"
      SET "tokenBalance" = "tokenBalance" - ${amount}
      WHERE id = ${userId} AND "tokenBalance" >= ${amount}
    `;
    if (result === 0) {
      throw new Error('Insufficient token balance');
    }
    await createTokenLedgerEntry(tx, { userId, amount: -amount, reason });
  });
}

export async function updateStreakOnApproval(userId: string): Promise<number> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { currentStreak: true, longestStreak: true, lastSubmissionDate: true, fcmToken: true },
  });
  if (!user) return 0;

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const lastDate = user.lastSubmissionDate ? new Date(user.lastSubmissionDate) : null;
  if (lastDate) lastDate.setHours(0, 0, 0, 0);

  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  let newStreak = user.currentStreak;

  if (!lastDate || lastDate < yesterday) {
    // Streak broken or first submission
    newStreak = 1;
  } else if (lastDate.getTime() === yesterday.getTime()) {
    // Consecutive day
    newStreak = user.currentStreak + 1;
  } else if (lastDate.getTime() === today.getTime()) {
    // Already submitted today — no change
    return user.currentStreak;
  }

  const newLongest = Math.max(newStreak, user.longestStreak);

  await prisma.user.update({
    where: { id: userId },
    data: {
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastSubmissionDate: new Date(),
    },
  });

  // Notify + award bonus on streak milestones (FR-46)
  const milestones: Record<number, number> = { 7: 50, 30: 200, 100: 500 };
  const bonus = milestones[newStreak];
  if (bonus) {
    await awardTokens(userId, bonus, `Streak milestone: ${newStreak} days`);
    if (user.fcmToken) {
      await notifyStreakMilestone(user.fcmToken, newStreak, bonus);
    }
    // Award streak badge
    const badgeId = newStreak === 7 ? 'streak_7' : newStreak === 30 ? 'streak_30' : 'streak_100';
    await upsertUserBadge(userId, badgeId, user.fcmToken);
  }

  return newStreak;
}

export async function checkFirstSubmissionBonus(userId: string): Promise<boolean> {
  // FR-07: 50-token welcome bonus after first APPROVED submission
  const approvedCount = await prisma.priceSubmission.count({
    where: { sourcerId: userId, status: 'approved' },
  });
  if (approvedCount === 1) {
    await awardTokens(userId, 50, 'Welcome bonus: first approved submission');
    const user = await prisma.user.findUnique({ where: { id: userId }, select: { fcmToken: true } });
    await upsertUserBadge(userId, 'first_submission', user?.fcmToken);
    return true;
  }
  return false;
}

export async function updateChallengeProgress(userId: string): Promise<void> {
  // Find today's challenge
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const challenge = await prisma.dailyChallenge.findFirst({ where: { date: today } });
  if (!challenge) return;

  // Get or create user progress row
  let userChallenge = await prisma.userDailyChallenge.findUnique({
    where: { userId_challengeId: { userId, challengeId: challenge.id } },
  });
  if (!userChallenge) {
    userChallenge = await prisma.userDailyChallenge.create({
      data: { userId, challengeId: challenge.id, progress: 0 },
    });
  }
  if (userChallenge.completed) return;

  // Count today's approved submissions matching the challenge
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const whereClause: any = {
    sourcerId: userId,
    status: 'approved',
    submittedAt: { gte: startOfDay },
  };
  if (challenge.chainTarget) {
    whereClause.store = { chain: challenge.chainTarget };
  }

  const count = await prisma.priceSubmission.count({ where: whereClause });

  const completed = count >= challenge.targetCount;
  await prisma.userDailyChallenge.update({
    where: { userId_challengeId: { userId, challengeId: challenge.id } },
    data: {
      progress: count,
      completed,
      completedAt: completed ? new Date() : null,
    },
  });

  if (completed && !userChallenge.bonusAwarded) {
    await awardTokens(userId, challenge.bonusTokens, `Daily challenge: ${challenge.title}`);
    await prisma.userDailyChallenge.update({
      where: { userId_challengeId: { userId, challengeId: challenge.id } },
      data: { bonusAwarded: true },
    });
  }
}

export async function recalculateAccuracyRating(userId: string): Promise<number> {
  // FR-55: accuracy = percentage of submissions not rejected or removed.
  const [total, rejectedOrHidden] = await Promise.all([
    prisma.priceSubmission.count({ where: { sourcerId: userId } }),
    prisma.priceSubmission.count({
      where: { sourcerId: userId, status: { in: ['rejected', 'hidden'] } },
    }),
  ]);
  const accuracyRating =
    total === 0 ? 100 : Math.max(0, ((total - rejectedOrHidden) / total) * 100);
  await prisma.user.update({ where: { id: userId }, data: { accuracyRating } });
  return accuracyRating;
}

export async function computeMonthlyRank(userId: string): Promise<number> {
  // FR-44: rank by tokens earned in the current calendar month.
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const rankings = await prisma.tokenTransaction.groupBy({
    by: ['userId'],
    where: { createdAt: { gte: startOfMonth }, amount: { gt: 0 } },
    _sum: { amount: true },
    orderBy: { _sum: { amount: 'desc' } },
  });
  const index = rankings.findIndex((r) => r.userId === userId);
  return index === -1 ? rankings.length + 1 : index + 1;
}

// Shared approval pipeline used by both admin approval and trusted auto-approval
// (FR-36). Awards tokens, applies welcome bonus / streak / challenge progress,
// recomputes accuracy, and fires the leaderboard rank-change push (FR-50).
export async function runApprovalEffects(params: {
  sourcerId: string;
  tokensAwarded: number;
  submissionId: string;
}): Promise<number> {
  const oldRank = await computeMonthlyRank(params.sourcerId);

  if (params.tokensAwarded > 0) {
    await awardTokens(
      params.sourcerId,
      params.tokensAwarded,
      `Approved submission: ${params.submissionId}`,
    );
  }
  await checkFirstSubmissionBonus(params.sourcerId);
  await updateStreakOnApproval(params.sourcerId);
  await updateChallengeProgress(params.sourcerId);
  const accuracyRating = await recalculateAccuracyRating(params.sourcerId);

  // FR-50: notify on a leaderboard rank shift of 3+ positions (guarded inside).
  const newRank = await computeMonthlyRank(params.sourcerId);
  const user = await prisma.user.findUnique({
    where: { id: params.sourcerId },
    select: { fcmToken: true },
  });
  await notifyRankChange(user?.fcmToken, newRank, oldRank);

  return accuracyRating;
}

async function checkAndAwardLevelBadge(userId: string, level: number, fcmToken?: string | null): Promise<void> {
  const levelBadgeMap: Record<number, string> = { 5: 'level_5', 10: 'level_10', 20: 'level_20' };
  const badgeId = levelBadgeMap[level];
  if (badgeId) {
    await upsertUserBadge(userId, badgeId, fcmToken);
  }
}

async function upsertUserBadge(userId: string, badgeId: string, fcmToken?: string | null): Promise<void> {
  const badge = await prisma.badge.findUnique({ where: { id: badgeId } });
  if (!badge) return;

  const existing = await prisma.userBadge.findUnique({
    where: { userId_badgeId: { userId, badgeId } },
  });
  if (existing) return;

  await prisma.userBadge.create({ data: { userId, badgeId } });
  if (fcmToken) {
    await notifyBadgeEarned(fcmToken, badge.name, badge.emoji);
  }
}

async function checkVoucherThreshold(userId: string): Promise<void> {
  const settings = await getSettings();
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;
  if (user.tokenBalance < settings.voucherThreshold) return;

  const existing = await prisma.voucherRequest.findFirst({
    where: {
      userId,
      status: { in: ['pending', 'approved'] },
    },
  });
  if (existing) return;

  const dominantStore = await prisma.priceSubmission.groupBy({
    by: ['storeId'],
    where: {
      sourcerId: userId,
      status: 'approved',
      submittedAt: { gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
    },
    _count: { storeId: true },
    orderBy: { _count: { storeId: 'desc' } },
    take: 1,
  });

  let supermarket = 'Partner supermarket';
  if (dominantStore[0]) {
    const store = await prisma.store.findUnique({ where: { id: dominantStore[0].storeId } });
    supermarket = store?.chain ?? supermarket;
  }

  await prisma.voucherRequest.create({
    data: {
      userId,
      thresholdTokens: settings.voucherThreshold,
      tokenCost: settings.voucherThreshold,
      denominationAed: 50,
      supermarket,
    },
  });
}
