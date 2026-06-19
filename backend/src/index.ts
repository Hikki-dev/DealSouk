import "dotenv/config";
import express from "express";
import cors from "cors";
import compression from "compression";
import helmet from "helmet";
import rateLimit, { Store } from "express-rate-limit";
import { RedisStore } from "rate-limit-redis";
import { PrismaClient } from "@prisma/client";
import { requireProductionEnv } from "./config/env";
import { redis, isRedisEnabled } from "./services/redis";
import * as Sentry from "@sentry/node";

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
import uploadRoutes from "./routes/uploads";
import configRoutes from "./routes/config";
import { startMaintenanceScheduler } from "./services/maintenance";

// Safety net: a stray async rejection (e.g. a flaky/misconfigured cache) must
// never crash the API and trigger a Render deploy crash-loop. Log loudly and
// keep serving.
process.on("unhandledRejection", (reason) => {
  console.error("[unhandledRejection]", reason);
});

export const prisma = new PrismaClient();

export const app = express();
const PORT = process.env.PORT ?? 3000;
const isProduction = process.env.NODE_ENV === "production";

// G1: crash/error monitoring (PRD §12). No-op unless SENTRY_DSN is configured,
// so local/dev and unconfigured deploys behave exactly as before.
if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV ?? "development",
    tracesSampleRate: Number(process.env.SENTRY_TRACES_SAMPLE_RATE ?? 0.1),
  });
}

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

export function isCorsOriginAllowed(
  origin: string | undefined,
  production = isProduction,
  origins = allowedOrigins,
): boolean {
  if (!production) {
    return true;
  }
  if (!origin) {
    return true;
  }
  // Allow localhost only in development (or when explicitly opted in via env var).
  // In production, localhost origins are blocked to prevent local pages from
  // making credentialed requests to the live API.
  if (origin === "http://localhost" || origin.startsWith("http://localhost:")) {
    return !production || process.env.ALLOW_LOCALHOST_CORS === "true";
  }
  return Boolean(origins?.includes(origin));
}

app.set("trust proxy", 1);
app.use(helmet());
app.use(compression());
app.use(
  cors({
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      callback(null, isCorsOriginAllowed(origin));
    },
    methods: ["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    credentials: true,
  }),
);
app.use(express.json({ limit: process.env.JSON_BODY_LIMIT ?? "1mb" }));

// Rate-limit store. A Redis-backed store only matters under horizontal scaling
// (multiple instances sharing counters, NFR-05). On a single instance it adds
// no benefit but DOES add failure modes: a bad/again-unreachable Redis makes
// rate-limit-redis reject every check (500s) and can crash the process at boot.
// So we only opt into RedisStore when explicitly asked (RATE_LIMIT_REDIS=true);
// otherwise the safe in-memory store is used and Redis is reserved for caching
// (which degrades gracefully on its own).
let rateLimitStore: Store | undefined;
if (isRedisEnabled && redis && process.env.RATE_LIMIT_REDIS === "true") {
  const r = redis;
  try {
    rateLimitStore = new RedisStore({
      sendCommand: (...args: string[]) =>
        r.call(args[0], ...args.slice(1)) as Promise<never>,
      prefix: "rl:global:",
    });
  } catch (err) {
    console.error(
      "[redis] rate-limit store init failed, using in-memory:",
      (err as Error).message,
    );
    rateLimitStore = undefined;
  }
}

const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: Number(process.env.GLOBAL_RATE_LIMIT_PER_MINUTE ?? 120),
  standardHeaders: true,
  legacyHeaders: false,
  store: rateLimitStore,
});
app.use(globalLimiter);

app.get("/", (_req, res) => {
  res.json({
    status: "ok",
    message: "Welcome to the DealSouk API Service. Refer to /health for server diagnostics.",
  });
});

app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    // RENDER_GIT_COMMIT is injected automatically by Render; lets us confirm
    // exactly which commit is live without a separate version endpoint.
    commit: process.env.RENDER_GIT_COMMIT?.slice(0, 7) ?? "dev",
  });
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
app.use("/uploads", uploadRoutes);
app.use("/admin", adminRoutes);
app.use("/challenges", challengeRoutes);
app.use("/translate", translateRoutes);
app.use("/logos", logoRoutes);
app.use("/config", configRoutes);

app.use(
  (
    err: Error,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction,
  ) => {
    if (process.env.SENTRY_DSN) {
      Sentry.captureException(err);
    }
    if (isProduction) {
      console.error("[error]", { name: err.name, message: err.message });
    } else {
      console.error(err.stack);
    }
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
