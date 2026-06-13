import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { PrismaClient } from "@prisma/client";
import { requireProductionEnv } from "./config/env";

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

export const prisma = new PrismaClient();

const app = express();
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

const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: Number(process.env.GLOBAL_RATE_LIMIT_PER_MINUTE ?? 120),
  standardHeaders: true,
  legacyHeaders: false,
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
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
