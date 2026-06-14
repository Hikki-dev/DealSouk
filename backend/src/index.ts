import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit, { Store } from "express-rate-limit";
import { RedisStore } from "rate-limit-redis";
import { PrismaClient } from "@prisma/client";
import { requireProductionEnv } from "./config/env";
import { redis, isRedisEnabled } from "./services/redis";

// TODO: Integrate TimescaleDB for time-series grocery price history data scaling.
// TODO: Integrate Redis for leaderboard ranking caches, API rate-limiting, and session caching.
// TODO: Integrate Swagger / OpenAPI UI middleware for live backend endpoint documentation.

import authRoutes from "./routes/auth";
import productRoutes from "./routes/products";
import submissionRoutes from "./routes/submissions";
import storeRoutes from "./routes/stores";
import leaderboardRoutes from "./routes/leaderboard";
import requestRoutes from "./routes/requests";
import profileRoutes from "./routes/profile";
import adminRoutes from "./routes/admin";
import challengeRoutes from "./routes/challenges";
import translateRoutes from "./routes/translate";
import logoRoutes from "./routes/logos";
import { startMaintenanceScheduler } from "./services/maintenance";

export const prisma = new PrismaClient();

export const app = express();
const PORT = process.env.PORT ?? 3000;
const isProduction = process.env.NODE_ENV === "production";

requireProductionEnv([
  "DATABASE_URL",
  "DATABASE_ENCRYPTION_KEY",
  "FIREBASE_PROJECT_ID",
  "FIREBASE_CLIENT_EMAIL",
  "FIREBASE_PRIVATE_KEY",
  "ALLOWED_ORIGINS",
]);

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ?.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

if (isProduction && (!allowedOrigins || allowedOrigins.length === 0)) {
  throw new Error("ALLOWED_ORIGINS must be configured in production");
}

app.set("trust proxy", 1);
app.use(helmet());
app.use(
  cors({
    origin: allowedOrigins ?? [
      "http://localhost:3000",
      "http://localhost:5000",
      "http://localhost:5173",
    ],
    methods: ["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
);
app.use(express.json({ limit: process.env.JSON_BODY_LIMIT ?? "1mb" }));

// When Redis is configured, share the rate-limit counters across all API
// instances so the limit holds under horizontal scaling (NFR-05). Otherwise
// fall back to the default per-instance in-memory store.
let rateLimitStore: Store | undefined;
if (isRedisEnabled && redis) {
  const r = redis;
  rateLimitStore = new RedisStore({
    sendCommand: (...args: string[]) =>
      r.call(args[0], ...args.slice(1)) as Promise<never>,
    prefix: "rl:global:",
  });
}

const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: Number(process.env.GLOBAL_RATE_LIMIT_PER_MINUTE ?? 120),
  standardHeaders: true,
  legacyHeaders: false,
  store: rateLimitStore,
});
app.use(globalLimiter);

app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.get("/system/status", (_req, res) => {
  const maintenance = process.env.MAINTENANCE_MODE === "true";

  res.json({
    maintenance,
    message: maintenance
      ? process.env.MAINTENANCE_MESSAGE ??
        "DealSouk is undergoing scheduled maintenance. Some features may be unavailable."
      : "DealSouk is operating normally.",
  });
});

app.use("/auth", authRoutes);
app.use("/products", productRoutes);
app.use("/submissions", submissionRoutes);
app.use("/stores", storeRoutes);
app.use("/leaderboard", leaderboardRoutes);
app.use("/requests", requestRoutes);
app.use("/profile", profileRoutes);
app.use("/admin", adminRoutes);
app.use("/challenges", challengeRoutes);
app.use("/translate", translateRoutes);
app.use("/logos", logoRoutes);

app.use(
  (
    err: Error,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction,
  ) => {
    console.error(err.stack);
    res.status(500).json({ error: "Internal server error" });
  },
);

async function main() {
  await prisma.$connect();
  console.log("Database connected");
  app.listen(PORT, () => {
    console.log(`DealSouk API running on port ${PORT}`);
    if (isRedisEnabled) {
      console.log("[redis] client initialised — rate limiters and cache are Redis-backed");
    } else {
      console.log("[redis] no REDIS_URL — using in-memory fallbacks");
    }
  });
  // Enforce time-based PRD rules (FR-18 expiry, FR-29 refunds, suspension lift).
  startMaintenanceScheduler();
}

// Only boot the HTTP server when run directly (node dist/index.js). When the
// module is imported by the test suite (supertest), we export `app` instead and
// never call listen() / connect to a real database.
if (require.main === module) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
