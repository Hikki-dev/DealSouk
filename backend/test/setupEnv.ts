// Dummy environment for the test process. Firebase + Prisma are mocked in each
// test file, so these values are never used to reach a real service — they just
// satisfy any requireEnv() calls that run at import time.
process.env.NODE_ENV = "test";
process.env.FIREBASE_PROJECT_ID = "test-project";
process.env.FIREBASE_CLIENT_EMAIL = "test@test.iam.gserviceaccount.com";
process.env.FIREBASE_PRIVATE_KEY = "test-key";
process.env.DATABASE_ENCRYPTION_KEY = "0".repeat(64);
process.env.DATABASE_URL = "postgresql://test:test@localhost:5432/testdb";
// Force in-memory rate limiting and stop dotenv/config (loaded by index.ts) from
// pulling a real REDIS_URL out of backend/.env and opening a live connection.
process.env.REDIS_URL = "";
