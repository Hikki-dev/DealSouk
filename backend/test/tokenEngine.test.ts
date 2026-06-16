// Wire the app's Prisma + Firebase to our mocks BEFORE importing any app code.
jest.mock("@prisma/client", () => {
  const { mockPrisma } = require("./mocks");
  return { PrismaClient: jest.fn(() => mockPrisma), Prisma: {} };
});
jest.mock("firebase-admin", () => {
  const { mockVerifyIdToken } = require("./mocks");
  return {
    apps: [{}], // non-empty → middleware skips initializeApp()
    initializeApp: jest.fn(),
    credential: { cert: jest.fn() },
    auth: () => ({ verifyIdToken: mockVerifyIdToken }),
    messaging: () => ({ send: jest.fn(), sendEachForMulticast: jest.fn() }),
  };
});

import { mockPrisma, resetMocks } from "./mocks";
import {
  computeLevel,
  calculateReward,
  createTokenLedgerEntry,
  hashTokenTransaction,
  verifyTokenLedgerChain,
} from "../src/services/tokenEngine";

beforeEach(() => resetMocks());

describe("computeLevel (FR-48: levels 1–20, 500 tokens per level)", () => {
  it.each([
    [0, 1],
    [499, 1],
    [500, 2],
    [999, 2],
    [1000, 3],
    [9500, 20],
    [100000, 20], // capped at 20
  ])("lifetime %i tokens → level %i", (tokens, expected) => {
    expect(computeLevel(tokens)).toBe(expected);
  });
});

describe("calculateReward (FR-35 receipt 1.5x, FR-48 level mult, FR-33 decay)", () => {
  const baseParams = {
    productId: "p1",
    storeId: "s1",
    sourcerId: "u1",
    hasReceipt: false,
  };

  function settings(overrides: Partial<any> = {}) {
    return {
      id: 1,
      tokenEarnRate: 10,
      decayFactor: 0.5,
      voucherThreshold: 500,
      ...overrides,
    } as any;
  }

  it("returns the base earn rate for a plain level-1 submission", async () => {
    mockPrisma.adminSettings.findUnique.mockResolvedValue(settings());
    mockPrisma.user.findUnique.mockResolvedValue({
      id: "u1",
      lifetimeTokensEarned: 0,
    } as any);
    mockPrisma.priceSubmission.findFirst.mockResolvedValue(null);

    await expect(calculateReward(baseParams)).resolves.toBe(10);
  });

  it("applies the 1.5x receipt multiplier (FR-35)", async () => {
    mockPrisma.adminSettings.findUnique.mockResolvedValue(settings());
    mockPrisma.user.findUnique.mockResolvedValue({
      id: "u1",
      lifetimeTokensEarned: 0,
    } as any);
    mockPrisma.priceSubmission.findFirst.mockResolvedValue(null);

    await expect(
      calculateReward({ ...baseParams, hasReceipt: true }),
    ).resolves.toBe(15);
  });

  it("applies the level multiplier (+5% per level above 1)", async () => {
    mockPrisma.adminSettings.findUnique.mockResolvedValue(settings());
    // 2000 lifetime → level 5 → multiplier 1.20 → 10 * 1.2 = 12
    mockPrisma.user.findUnique.mockResolvedValue({
      id: "u1",
      lifetimeTokensEarned: 2000,
    } as any);
    mockPrisma.priceSubmission.findFirst.mockResolvedValue(null);

    await expect(calculateReward(baseParams)).resolves.toBe(12);
  });

  it("applies decay when the same product+store was submitted in the last 24h (FR-33)", async () => {
    mockPrisma.adminSettings.findUnique.mockResolvedValue(settings());
    mockPrisma.user.findUnique.mockResolvedValue({
      id: "u1",
      lifetimeTokensEarned: 0,
    } as any);
    // A recent approved submission exists → reward * decayFactor (0.5) = 5
    mockPrisma.priceSubmission.findFirst.mockResolvedValue({ id: "old" } as any);

    await expect(calculateReward(baseParams)).resolves.toBe(5);
  });

  it("never returns less than 1 token", async () => {
    mockPrisma.adminSettings.findUnique.mockResolvedValue(
      settings({ tokenEarnRate: 1, decayFactor: 0.1 }),
    );
    mockPrisma.user.findUnique.mockResolvedValue({
      id: "u1",
      lifetimeTokensEarned: 0,
    } as any);
    mockPrisma.priceSubmission.findFirst.mockResolvedValue({ id: "old" } as any);

    await expect(calculateReward(baseParams)).resolves.toBe(1);
  });

  it("returns 0 when the sourcer does not exist", async () => {
    mockPrisma.adminSettings.findUnique.mockResolvedValue(settings());
    mockPrisma.user.findUnique.mockResolvedValue(null);

    await expect(calculateReward(baseParams)).resolves.toBe(0);
  });
});

describe("token ledger hash chain", () => {
  it("creates a chained hash entry using the previous ledger hash", async () => {
    const createdRows: any[] = [];
    const tx = {
      tokenTransaction: {
        findFirst: jest.fn().mockResolvedValue({ hash: "previous-hash" }),
        create: jest.fn(async (args) => {
          createdRows.push(args.data);
          return args.data;
        }),
      },
    };

    // Cast the minimal mock to satisfy the TransactionClient type — test-only.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await createTokenLedgerEntry(tx as any, {
      userId: "u1",
      amount: 25,
      reason: "Test award",
    });

    expect(createdRows).toHaveLength(1);
    expect(createdRows[0].previousHash).toBe("previous-hash");
    expect(createdRows[0].hash).toBe(
      hashTokenTransaction({
        userId: "u1",
        amount: 25,
        reason: "Test award",
        createdAt: createdRows[0].createdAt,
        previousHash: "previous-hash",
      }),
    );
  });

  it("detects tampered chained ledger rows", async () => {
    const firstCreatedAt = new Date("2026-06-14T00:00:00.000Z");
    const firstHash = hashTokenTransaction({
      userId: "u1",
      amount: 10,
      reason: "Initial award",
      createdAt: firstCreatedAt,
      previousHash: null,
    });
    mockPrisma.tokenTransaction.findMany.mockResolvedValue([
      {
        id: "tx1",
        userId: "u1",
        amount: 10,
        reason: "Initial award",
        createdAt: firstCreatedAt,
        previousHash: null,
        hash: firstHash,
      },
      {
        id: "tx2",
        userId: "u1",
        amount: 999,
        reason: "Tampered",
        createdAt: new Date("2026-06-14T00:01:00.000Z"),
        previousHash: firstHash,
        hash: "bad-hash",
      },
    ] as any);

    await expect(verifyTokenLedgerChain()).resolves.toEqual({
      ok: false,
      invalidTransactionId: "tx2",
    });
  });

  it("verifies independent per-user hash chains", async () => {
    const u1CreatedAt = new Date("2026-06-14T00:00:00.000Z");
    const u2CreatedAt = new Date("2026-06-14T00:00:30.000Z");
    const u1Hash = hashTokenTransaction({
      userId: "u1",
      amount: 10,
      reason: "Initial award",
      createdAt: u1CreatedAt,
      previousHash: null,
    });
    const u2Hash = hashTokenTransaction({
      userId: "u2",
      amount: 15,
      reason: "Initial award",
      createdAt: u2CreatedAt,
      previousHash: null,
    });
    mockPrisma.tokenTransaction.findMany.mockResolvedValue([
      {
        id: "tx1",
        userId: "u1",
        amount: 10,
        reason: "Initial award",
        createdAt: u1CreatedAt,
        previousHash: null,
        hash: u1Hash,
      },
      {
        id: "tx2",
        userId: "u2",
        amount: 15,
        reason: "Initial award",
        createdAt: u2CreatedAt,
        previousHash: null,
        hash: u2Hash,
      },
    ] as any);

    await expect(verifyTokenLedgerChain()).resolves.toEqual({ ok: true });
  });
});
