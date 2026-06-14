// Wire Prisma + Firebase mocks before importing the Express app.
jest.mock("@prisma/client", () => {
  const { mockPrisma } = require("./mocks");
  return { PrismaClient: jest.fn(() => mockPrisma), Prisma: {} };
});
jest.mock("firebase-admin", () => {
  const { mockVerifyIdToken } = require("./mocks");
  return {
    apps: [{}],
    initializeApp: jest.fn(),
    credential: { cert: jest.fn() },
    auth: () => ({ verifyIdToken: mockVerifyIdToken }),
    messaging: () => ({ send: jest.fn(), sendEachForMulticast: jest.fn() }),
  };
});

import request from "supertest";
import { app } from "../src/index";
import { mockPrisma, mockVerifyIdToken, resetMocks } from "./mocks";

beforeEach(() => resetMocks());

/** Signs requests as a given user by wiring the token verifier + user lookup. */
function signInAs(user: Partial<any>) {
  mockVerifyIdToken.mockResolvedValue({ uid: user.firebaseUid ?? "fb-uid" });
  mockPrisma.user.findUnique.mockResolvedValue({
    id: "u1",
    firebaseUid: "fb-uid",
    isAdmin: false,
    bannedAt: null,
    isSuspended: false,
    suspendedUntil: null,
    ...user,
  } as any);
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
