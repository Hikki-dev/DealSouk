import { prisma } from '../index';

export async function getSettings() {
  let settings = await prisma.adminSettings.findUnique({ where: { id: 1 } });
  if (!settings) {
    settings = await prisma.adminSettings.create({ data: { id: 1 } });
  }
  return settings;
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

  // Receipt bonus: 1.5x
  if (params.hasReceipt) {
    reward = Math.round(reward * 1.5);
  }

  // Level multiplier: every 500 lifetime tokens = 1 level, +5% per level (max level 20)
  const lifetimeTokens = await prisma.tokenTransaction.aggregate({
    where: { userId: params.sourcerId, amount: { gt: 0 } },
    _sum: { amount: true },
  });
  const totalEarned = lifetimeTokens._sum.amount ?? 0;
  const level = Math.min(20, Math.floor(totalEarned / 500) + 1);
  const levelMultiplier = 1 + (level - 1) * 0.05;
  reward = Math.round(reward * levelMultiplier);

  // Decay: if same product+store has an approved submission in past 24h, apply decay
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
  await prisma.$transaction([
    prisma.tokenTransaction.create({ data: { userId, amount, reason } }),
    prisma.user.update({
      where: { id: userId },
      data: { tokenBalance: { increment: amount } },
    }),
  ]);
  await checkVoucherThreshold(userId);
}

export async function spendTokens(userId: string, amount: number, reason: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user || user.tokenBalance < amount) {
    throw new Error('Insufficient token balance');
  }
  await prisma.$transaction([
    prisma.tokenTransaction.create({ data: { userId, amount: -amount, reason } }),
    prisma.user.update({
      where: { id: userId },
      data: { tokenBalance: { decrement: amount } },
    }),
  ]);
}

async function checkVoucherThreshold(userId: string) {
  const settings = await getSettings();
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;
  // Voucher logic placeholder: log when threshold is crossed.
  // In production this creates an admin queue entry and triggers an email.
  if (user.tokenBalance >= settings.voucherThreshold) {
    console.log(`[VOUCHER] User ${userId} crossed voucher threshold (${user.tokenBalance} tokens). Admin approval required.`);
  }
}
