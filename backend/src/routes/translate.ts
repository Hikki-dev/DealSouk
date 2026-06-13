import { Router } from "express";
import { requireAuth } from "../middleware/auth";

const router = Router();
router.use(requireAuth);

// In-process translation cache — survives restarts only within process lifetime.
// Evicts the oldest entry (insertion-order) once MAX_CACHE is reached.
const cache = new Map<string, string>();
const MAX_CACHE = 5000;

function cacheSet(key: string, value: string) {
  if (cache.size >= MAX_CACHE) {
    cache.delete(cache.keys().next().value as string);
  }
  cache.set(key, value);
}

router.post("/", async (req, res) => {
  const { text, target } = req.body as { text?: unknown; target?: unknown };

  if (
    typeof text !== "string" ||
    !text.trim() ||
    (target !== "ar" && target !== "en")
  ) {
    res.status(400).json({ error: "text (string) and target ('ar'|'en') required" });
    return;
  }

  const trimmed = text.trim().slice(0, 500);
  const cacheKey = `${target}:${trimmed}`;

  if (cache.has(cacheKey)) {
    res.json({ translatedText: cache.get(cacheKey) });
    return;
  }

  const apiKey = process.env.GOOGLE_TRANSLATE_API_KEY;
  if (!apiKey) {
    // Not configured — pass text through unchanged so the app stays functional.
    res.json({ translatedText: trimmed });
    return;
  }

  try {
    const response = await fetch(
      `https://translation.googleapis.com/language/translate/v2?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ q: trimmed, target, format: "text" }),
      },
    );

    if (!response.ok) {
      res.json({ translatedText: trimmed });
      return;
    }

    const data = (await response.json()) as {
      data?: { translations?: { translatedText?: string }[] };
    };

    const translated =
      data?.data?.translations?.[0]?.translatedText ?? trimmed;

    cacheSet(cacheKey, translated);
    res.json({ translatedText: translated });
  } catch {
    // Network / quota failure — return original text gracefully.
    res.json({ translatedText: trimmed });
  }
});

export default router;
