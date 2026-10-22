// Demo data for a LOCAL copy of DealSouk: extra shoppers, a leaderboard, price requests,
// a moderation queue, vouchers and a shopper with a history (but no saved cart: a cart restored from the server shows no prices, see the README). Run it after `npm run seed`.
// It refuses to run against anything but a database on this computer.
//   set -a; . ./.env; set +a; npm run seed && npm run seed:demo
// All the people are made up. See docs/Demo mode.md.
import { PrismaClient } from '@prisma/client';
import crypto from 'crypto';

const prisma = new PrismaClient();

const dbUrl = process.env.DATABASE_URL ?? '';
if (!/@(127\.0\.0\.1|localhost)[:/]/.test(dbUrl)) {
  console.error('DATABASE_URL must point at this computer (127.0.0.1 or localhost). Stopping.');
  process.exit(1);
}

const DAY = 24 * 60 * 60 * 1000;
const ago = (days: number, hours = 0) => new Date(Date.now() - days * DAY - hours * 3600_000);
const ahead = (days: number) => new Date(Date.now() + days * DAY);
let seed = 7;
const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
const pick = <T,>(a: T[]) => a[Math.floor(rnd() * a.length)];

const hashOf = (userId: string, amount: number, reason: string, createdAt: Date, previousHash: string | null) =>
  crypto.createHash('sha256').update([userId, amount, reason, createdAt.toISOString(), previousHash ?? 'GENESIS'].join('|')).digest('hex');

async function ledger(userId: string, entries: { amount: number; reason: string; at: Date }[]) {
  let prev: string | null = null;
  const last = await prisma.tokenTransaction.findFirst({ where: { userId }, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], select: { hash: true } });
  prev = last?.hash ?? null;
  for (const e of entries.sort((a, b) => a.at.getTime() - b.at.getTime())) {
    const hash = hashOf(userId, e.amount, e.reason, e.at, prev);
    await prisma.tokenTransaction.create({ data: { userId, amount: e.amount, reason: e.reason, previousHash: prev, hash, createdAt: e.at } });
    prev = hash;
  }
}

const PEOPLE: { uid: string; name: string; area: string; tokens: number; level: number; streak: number; admin?: boolean }[] = [
  { uid: 'demo-shopper-1', name: 'Priya Nair', area: 'Dubai Marina', tokens: 620, level: 3, streak: 6 },
  { uid: 'demo-admin-1', name: 'Moderator Omar', area: 'Business Bay', tokens: 0, level: 1, streak: 0, admin: true },
  { uid: 'demo-user-02', name: 'Hassan Al Mansoori', area: 'Deira', tokens: 2140, level: 5, streak: 21 },
  { uid: 'demo-user-03', name: 'Meera Krishnan', area: 'JLT', tokens: 1860, level: 4, streak: 14 },
  { uid: 'demo-user-04', name: 'Tariq Rahman', area: 'Al Barsha', tokens: 1510, level: 4, streak: 9 },
  { uid: 'demo-user-05', name: 'Sofia Petrova', area: 'Downtown Dubai', tokens: 1275, level: 3, streak: 11 },
  { uid: 'demo-user-06', name: 'Joseph Mathew', area: 'Mirdif', tokens: 990, level: 3, streak: 4 },
  { uid: 'demo-user-07', name: 'Aisha Khan', area: 'Jumeirah', tokens: 870, level: 2, streak: 5 },
  { uid: 'demo-user-08', name: 'Ravi Shankar', area: 'Karama', tokens: 640, level: 2, streak: 3 },
  { uid: 'demo-user-09', name: 'Lina Haddad', area: 'Al Quoz', tokens: 410, level: 1, streak: 2 },
  { uid: 'demo-user-10', name: 'Daniel Okafor', area: 'Silicon Oasis', tokens: 260, level: 1, streak: 1 },
  { uid: 'demo-user-11', name: 'Yuki Tanaka', area: 'Dubai Marina', tokens: 180, level: 1, streak: 1 },
];

async function main() {
  const stores = await prisma.store.findMany();
  const products = await prisma.product.findMany();
  if (stores.length === 0 || products.length === 0) throw new Error('Run `npm run seed` first.');
  const users: Record<string, string> = {};

  for (const p of PEOPLE) {
    const u = await prisma.user.upsert({
      where: { firebaseUid: p.uid },
      update: {},
      create: {
        firebaseUid: p.uid, displayName: p.name, homeArea: p.area, preferredLocale: 'en', isAdmin: !!p.admin,
        tokenBalance: p.tokens, lifetimeTokensEarned: p.tokens + 400, level: p.level,
        currentStreak: p.streak, longestStreak: Math.max(p.streak, 8), accuracyRating: 90 + Math.round(rnd() * 90) / 10,
        lastSubmissionDate: ago(0, 3), createdAt: ago(60),
      },
    });
    users[p.uid] = u.id;
  }

  // Token history this month, so the leaderboard has a spread of people.
  for (const p of PEOPLE.filter((x) => !x.admin)) {
    const uid = users[p.uid];
    if ((await prisma.tokenTransaction.count({ where: { userId: uid } })) > 0) continue;
    const entries: { amount: number; reason: string; at: Date }[] = [];
    let left = Math.round(p.tokens * 0.8);
    let day = 0;
    while (left > 0) {
      const amount = Math.min(left, 50 + Math.round(rnd() * 3) * 25);
      entries.push({ amount, reason: pick(['Price shared', 'Price shared', 'Price shared with receipt', 'Daily challenge bonus', 'Price request fulfilled']), at: ago(day % 20, Math.round(rnd() * 20)) });
      left -= amount; day += 1;
    }
    await ledger(uid, entries);
  }

  // Priya's history: approved prices, two waiting for review, a cart, badges, a request.
  const priya = users['demo-shopper-1'];
  if ((await prisma.priceSubmission.count({ where: { sourcerId: priya } })) === 0) {
    for (let i = 0; i < 14; i++) {
      const s = pick(stores), pr = pick(products);
      await prisma.priceSubmission.create({
        data: { productId: pr.id, storeId: s.id, sourcerId: priya, priceAed: (3 + rnd() * 20).toFixed(2), hasReceipt: i % 3 === 0, status: 'approved', tokensAwarded: 50, submittedAt: ago(Math.floor(i / 2), i), expiresAt: ahead(3) },
      });
    }
    for (let i = 0; i < 2; i++) {
      await prisma.priceSubmission.create({ data: { productId: pick(products).id, storeId: pick(stores).id, sourcerId: priya, priceAed: (4 + rnd() * 12).toFixed(2), status: 'pending', submittedAt: ago(0, 1 + i), expiresAt: ahead(3) } });
    }
  }
  for (const [id, days] of [['first_submission', 40], ['first_verified_submission', 30], ['streak_7', 3]] as const) {
    await prisma.userBadge.upsert({ where: { userId_badgeId: { userId: priya, badgeId: id } }, update: {}, create: { userId: priya, badgeId: id, unlockedAt: ago(days) } });
  }
  await prisma.voucherRequest.create({ data: { userId: priya, status: 'pending', thresholdTokens: 500, tokenCost: 500, denominationAed: 50, supermarket: 'Carrefour', requestedAt: ago(0, 5) } }).catch(() => {});

  // Price requests from other shoppers, with bounties.
  if ((await prisma.priceRequest.count()) === 0) {
    const reqs: [string, string, string, number][] = [
      ['demo-user-03', 'Almarai Fresh Milk 2 L', 'Spinneys JLT', 30], ['demo-user-05', 'Basmati Rice 5 kg', 'Lulu Hypermarket Al Barsha', 25],
      ['demo-user-07', 'Greek Yoghurt 400 gm', 'Waitrose Dubai Marina', 20], ['demo-user-08', 'Free Range Eggs 12 pcs', 'Union Coop Al Wasl', 20],
    ];
    for (const [uid, productName, storeName, bountyTokens] of reqs) {
      await prisma.priceRequest.create({ data: { requesterId: users[uid], productName, storeName, bountyTokens, status: 'open', createdAt: ago(0, 2), expiresAt: ahead(2) } });
    }
    await prisma.priceRequest.create({ data: { requesterId: priya, productName: 'Whole Milk 2 L', storeName: 'Carrefour Downtown Dubai', bountyTokens: 20, status: 'open', createdAt: ago(0, 6), expiresAt: ahead(2) } });
  }

  // The moderation queue: submissions waiting for review, a few already flagged.
  const queueSeed = await prisma.priceSubmission.count({ where: { status: 'pending', sourcerId: { not: priya } } });
  if (queueSeed === 0) {
    const flaggers = ['demo-user-03', 'demo-user-04', 'demo-user-05'].map((u) => users[u]);
    for (let i = 0; i < 9; i++) {
      const sourcer = users[pick(PEOPLE.filter((x) => !x.admin && x.uid !== 'demo-shopper-1')).uid];
      const sub = await prisma.priceSubmission.create({
        data: { productId: pick(products).id, storeId: pick(stores).id, sourcerId: sourcer, priceAed: (2 + rnd() * (i === 4 ? 90 : 18)).toFixed(2), hasReceipt: i % 2 === 0, status: 'pending', flagCount: i === 4 ? 2 : 0, submittedAt: ago(0, i * 2), expiresAt: ahead(3) },
      });
      if (i === 4) for (const f of flaggers.slice(0, 2)) await prisma.submissionFlag.create({ data: { submissionId: sub.id, flaggerId: f, reason: 'price_wrong' } });
    }
  }

  // Vouchers: stock, and two requests waiting for the admin.
  if ((await prisma.voucherInventory.count()) === 0) {
    for (const [shop, n] of [['Carrefour', 6], ['Lulu', 6], ['Spinneys', 4]] as const) {
      for (let i = 1; i <= n; i++) await prisma.voucherInventory.create({ data: { supermarket: shop, denominationAed: 50, code: `DEMO-${shop.slice(0, 3).toUpperCase()}-${String(i).padStart(4, '0')}` } });
    }
    for (const [uid, shop] of [['demo-user-02', 'Lulu'], ['demo-user-03', 'Spinneys']] as const) {
      await prisma.voucherRequest.create({ data: { userId: users[uid], status: 'pending', thresholdTokens: 500, tokenCost: 500, denominationAed: 50, supermarket: shop, requestedAt: ago(0, 8) } });
    }
  }

  // One warning in the admin's audit log.
  if ((await prisma.adminUserAction.count()) === 0) {
    await prisma.adminUserAction.create({ data: { targetUserId: users['demo-user-10'], adminUserId: users['demo-admin-1'], action: 'warn', reason: 'Two prices looked copied from a flyer. Please photograph the shelf tag.', createdAt: ago(2) } });
  }

  console.log('Demo data ready. Sign-in ids: demo-shopper-1 (a shopper) and demo-admin-1 (the moderator).');
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
