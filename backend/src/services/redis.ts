import Redis from "ioredis";

/**
 * Shared Redis client for caching and cross-instance rate limiting (NFR-05).
 *
 * Gated entirely on the REDIS_URL env var. When it is absent (local dev, demo),
 * the backend runs exactly as before with in-memory state — nothing breaks.
 * When present (e.g. an Upstash connection string), Redis backs the rate
 * limiter and the leaderboard cache so horizontally-scaled instances share
 * state instead of each keeping their own.
 */
let client: Redis | null = null;

if (process.env.REDIS_URL) {
  client = new Redis(process.env.REDIS_URL, {
    // Don't crash the process if Redis is briefly unreachable; degrade instead.
    maxRetriesPerRequest: 2,
    enableOfflineQueue: false,
    lazyConnect: false,
    // Upstash and most managed providers require TLS on rediss:// URLs;
    // ioredis infers this from the scheme, so no extra config needed.
  });

  client.on("error", (err) => {
    // Log once-ish; never throw. A flaky cache must not take down the API.
    console.error("[redis] connection error:", err.message);
  });

  client.on("connect", () => {
    console.log("[redis] connected");
  });
} else {
  console.log("[redis] REDIS_URL not set — using in-memory fallbacks");
}

export const redis = client;
export const isRedisEnabled = client !== null;

/**
 * Read-through cache helper. Returns the cached value if present; otherwise
 * runs `produce`, caches the result for `ttlSeconds`, and returns it.
 * On any Redis error it silently falls back to calling `produce` directly.
 */
export async function cached<T>(
  key: string,
  ttlSeconds: number,
  produce: () => Promise<T>,
): Promise<T> {
  if (!client) return produce();

  try {
    const hit = await client.get(key);
    if (hit !== null) return JSON.parse(hit) as T;
  } catch {
    // ignore cache read failure — fall through to produce()
  }

  const value = await produce();

  try {
    await client.set(key, JSON.stringify(value), "EX", ttlSeconds);
  } catch {
    // ignore cache write failure
  }

  return value;
}
