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
