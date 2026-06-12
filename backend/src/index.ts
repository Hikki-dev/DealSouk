import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { PrismaClient } from "@prisma/client";

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

app.use(helmet());
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(",") ?? "*" }));
app.use(express.json({ limit: "10mb" }));

const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(globalLimiter);

app.get("/health", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
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
