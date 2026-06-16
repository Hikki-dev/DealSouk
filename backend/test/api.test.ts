// Wire Prisma + Firebase mocks before importing the Express app.
jest.mock("@prisma/client", () => {
  const { mockPrisma } = require("./mocks");
  return { PrismaClient: jest.fn(() => mockPrisma), Prisma: {} };
});
jest.mock("firebase-admin", () => {
  const { mockVerifyIdToken, mockRevokeRefreshTokens, mockGetSignedUrl } = require("./mocks");
  return {
    apps: [{}],
    initializeApp: jest.fn(),
    credential: { cert: jest.fn() },
    auth: () => ({
      verifyIdToken: mockVerifyIdToken,
      revokeRefreshTokens: mockRevokeRefreshTokens,
    }),
    messaging: () => ({ send: jest.fn(), sendEachForMulticast: jest.fn() }),
    storage: () => ({
      bucket: () => ({
        file: () => ({
          getSignedUrl: mockGetSignedUrl,
        }),
      }),
    }),
  };
});

import request from "supertest";
import { app } from "../src/index";
import { mockGetSignedUrl, mockPrisma, mockRevokeRefreshTokens, mockVerifyIdToken, resetMocks } from "./mocks";

beforeEach(() => resetMocks());

/** Signs requests as a given user by wiring the token verifier + user lookup. */
function signInAs(user: Partial<any>) {
  mockVerifyIdToken.mockResolvedValue({
    uid: user.firebaseUid ?? "fb-uid",
    auth_time: Math.floor(Date.now() / 1000),
    ...(user.decodedToken ?? {}),
  });
  mockPrisma.user.findUnique.mockResolvedValue({
    id: "u1",
    firebaseUid: "fb-uid",
    isAdmin: false,
    bannedAt: null,
    isSuspended: false,
    suspendedUntil: null,
    lastActiveAt: new Date(),
    sessionStartedAt: new Date(),
    ...user,
  } as any);
  mockPrisma.user.update.mockResolvedValue({} as any);
}

describe("health", () => {
  it("GET /health → 200", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
  });
});

describe("auth gate (NFR-06/08, requireAuth)", () => {
  it("POST /submissions with no token → 401", async () => {
    const res = await request(app).post("/submissions").send({});
    expect(res.status).toBe(401);
    expect(res.body.error).toMatch(/authorization token/i);
  });

  it("GET /leaderboard/monthly with no token → 401", async () => {
    const res = await request(app).get("/leaderboard/monthly");
    expect(res.status).toBe(401);
  });

  it("rejects an unregistered (but token-valid) user → 401", async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: "ghost" });
    mockPrisma.user.findUnique.mockResolvedValue(null);
    const res = await request(app)
      .get("/leaderboard/monthly")
      .set("Authorization", "Bearer good-token");
    expect(res.status).toBe(401);
    expect(res.body.error).toMatch(/not registered/i);
  });

  it("blocks a banned account → 403", async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: "fb-uid" });
    mockPrisma.user.findUnique.mockResolvedValue({
      id: "u1",
      isAdmin: false,
      bannedAt: new Date(),
      banReason: "abuse",
      isSuspended: false,
    } as any);
    const res = await request(app)
      .get("/leaderboard/monthly")
      .set("Authorization", "Bearer good-token");
    expect(res.status).toBe(403);
  });
});

describe("admin gate (FR-57, requireAdmin)", () => {
  const originalAdminMfaRequired = process.env.ADMIN_MFA_REQUIRED;

  afterEach(() => {
    if (originalAdminMfaRequired == null) {
      delete process.env.ADMIN_MFA_REQUIRED;
    } else {
      process.env.ADMIN_MFA_REQUIRED = originalAdminMfaRequired;
    }
  });

  it("GET /admin/queue with no token → 401", async () => {
    const res = await request(app).get("/admin/queue");
    expect(res.status).toBe(401);
  });

  it("GET /admin/queue as a non-admin → 403", async () => {
    signInAs({ isAdmin: false });
    const res = await request(app)
      .get("/admin/queue")
      .set("Authorization", "Bearer good-token");
    expect(res.status).toBe(403);
    expect(res.body.error).toMatch(/admin access required/i);
  });

  it("GET /admin/queue as admin without MFA is blocked when MFA enforcement is enabled", async () => {
    process.env.ADMIN_MFA_REQUIRED = "true";
    signInAs({ isAdmin: true });
    const res = await request(app)
      .get("/admin/queue")
      .set("Authorization", "Bearer good-token");
    expect(res.status).toBe(403);
    expect(res.body.code).toBe("ADMIN_MFA_REQUIRED");
  });

  it("GET /admin/queue as admin with MFA passes the auth gate", async () => {
    process.env.ADMIN_MFA_REQUIRED = "true";
    signInAs({
      isAdmin: true,
      decodedToken: {
        firebase: { sign_in_attributes: { mfa_verified: true } },
      },
    });
    mockPrisma.priceSubmission.findMany.mockResolvedValue([]);
    const res = await request(app)
      .get("/admin/queue")
      .set("Authorization", "Bearer good-token");
    expect(res.status).toBe(200);
  });
});

describe("session expiry (NFR-08)", () => {
  it("rejects sessions inactive for more than 30 days and revokes refresh tokens", async () => {
    mockVerifyIdToken.mockResolvedValue({
      uid: "fb-uid",
      auth_time: Math.floor(Date.now() / 1000),
    });
    mockPrisma.user.findUnique.mockResolvedValue({
      id: "u1",
      firebaseUid: "fb-uid",
      isAdmin: false,
      bannedAt: null,
      isSuspended: false,
      suspendedUntil: null,
      lastActiveAt: new Date(Date.now() - 31 * 24 * 60 * 60 * 1000),
      sessionStartedAt: new Date(),
    } as any);

    const res = await request(app)
      .get("/leaderboard/monthly")
      .set("Authorization", "Bearer good-token");

    expect(res.status).toBe(401);
    expect(res.body.code).toBe("SESSION_EXPIRED");
    expect(mockRevokeRefreshTokens).toHaveBeenCalledWith("fb-uid");
  });
});

describe("signed uploads", () => {
  it("rejects unsupported upload content types before signing", async () => {
    signInAs({ isAdmin: false });
    const res = await request(app)
      .post("/uploads/signed-url")
      .set("Authorization", "Bearer good-token")
      .send({ kind: "receipt", contentType: "application/pdf", sizeBytes: 100 });

    expect(res.status).toBe(400);
    expect(mockGetSignedUrl).not.toHaveBeenCalled();
  });

  it("returns a constrained signed upload URL for a valid receipt image", async () => {
    signInAs({ isAdmin: false });
    mockGetSignedUrl.mockResolvedValue(["https://storage.example/upload"]);

    const res = await request(app)
      .post("/uploads/signed-url")
      .set("Authorization", "Bearer good-token")
      .send({ kind: "receipt", contentType: "image/jpeg", sizeBytes: 1024 });

    expect(res.status).toBe(201);
    expect(res.body.uploadUrl).toBe("https://storage.example/upload");
    expect(res.body.objectPath).toMatch(/^receipts\/fb-uid\//);
    expect(res.body.requiredHeaders["Content-Type"]).toBe("image/jpeg");
    expect(res.body.requiredHeaders["x-goog-meta-firebasestoragedownloadtokens"]).toBeTruthy();
  });
});

describe("submission validation (FR-32)", () => {
  it("rejects a submission with a missing/invalid price → 400", async () => {
    signInAs({ isAdmin: false });
    const res = await request(app)
      .post("/submissions")
      .set("Authorization", "Bearer good-token")
      .send({ productId: "p1", storeId: "s1", priceAed: -5 });
    expect(res.status).toBe(400);
  });

  it("rejects a non-HTTPS receipt URL → 400", async () => {
    signInAs({ isAdmin: false });
    const res = await request(app)
      .post("/submissions")
      .set("Authorization", "Bearer good-token")
      .send({
        productId: "p1",
        storeId: "s1",
        priceAed: 9.99,
        hasReceipt: true,
        receiptUrl: "http://insecure.example/r.jpg",
      });
    expect(res.status).toBe(400);
  });

  it("fulfills a request against the exact requested product name, not a fuzzy catalog match", async () => {
    signInAs({
      isAdmin: false,
      lifetimeTokensEarned: 0,
      level: 1,
      tokenBalance: 0,
      accuracyRating: 100,
    });
    mockPrisma.store.findUnique.mockResolvedValue({
      id: "s1",
      chain: "Union Coop",
      branchName: "Al Wasl",
    } as any);
    mockPrisma.priceRequest.findUnique.mockResolvedValue({
      id: "r1",
      requesterId: "requester-1",
      productName: "Milk",
      storeName: "Union Coop",
      bountyTokens: 15,
      status: "open",
      expiresAt: new Date(Date.now() + 60_000),
      requester: { fcmToken: null },
    } as any);
    mockPrisma.product.findFirst.mockResolvedValue(null);
    mockPrisma.product.create.mockResolvedValue({
      id: "p-milk",
      name: "Milk",
      category: "Community",
    } as any);
    mockPrisma.adminSettings.findUnique.mockResolvedValue({
      id: 1,
      tokenEarnRate: 10,
      dailySubmissionCap: 30,
      decayFactor: 0.7,
      voucherThreshold: 500,
    } as any);
    mockPrisma.priceSubmission.count.mockResolvedValue(0);
    mockPrisma.priceSubmission.findFirst.mockResolvedValue(null);
    mockPrisma.priceSubmission.create.mockResolvedValue({
      id: "sub1",
      status: "pending",
      expiresAt: new Date(),
    } as any);
    mockPrisma.priceRequest.updateMany.mockResolvedValue({ count: 1 } as any);
    mockPrisma.$transaction.mockImplementation(async (callback: any) =>
      callback(mockPrisma),
    );
    mockPrisma.tokenTransaction.findFirst.mockResolvedValue(null);
    mockPrisma.tokenTransaction.create.mockResolvedValue({} as any);
    mockPrisma.userBadge.findUnique.mockResolvedValue(null);

    const res = await request(app)
      .post("/submissions")
      .set("Authorization", "Bearer good-token")
      .send({
        productId: "p-whole-milk",
        storeId: "s1",
        priceAed: 44,
        requestId: "r1",
      });

    expect(res.status).toBe(201);
    expect(mockPrisma.product.create).toHaveBeenCalledWith({
      data: { name: "Milk", category: "Community" },
    });
    expect(mockPrisma.priceSubmission.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ productId: "p-milk" }),
      }),
    );
    expect(res.body.requestBountyTokens).toBe(15);
  });
});

describe("store prices (FR-09..16, 72h freshness)", () => {
  it("GET /stores/:id/prices maps backend rows to the client shape", async () => {
    mockPrisma.priceSubmission.findMany.mockResolvedValue([
      {
        id: "sub1",
        priceAed: 7.95,
        hasReceipt: true,
        submittedAt: new Date(),
        product: {
          id: "p1",
          name: "Almarai Milk",
          brand: "Almarai",
          packSize: "1 L",
          category: "Dairy",
          imageUrl: null,
        },
        store: { id: "s1", chain: "Carrefour" },
      },
    ] as any);

    const res = await request(app).get("/stores/s1/prices");
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].priceAed).toBe(7.95);
    expect(res.body[0].product.name).toBe("Almarai Milk");
  });
});
