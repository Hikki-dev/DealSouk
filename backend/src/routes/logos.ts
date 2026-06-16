import { Router } from "express";

const router = Router();

// Supermarket chain -> the domain whose favicon is its logo mark.
const CHAIN_DOMAINS: Record<string, string> = {
  carrefour: "carrefouruae.com",
  lulu: "luluhypermarket.com",
  spinneys: "spinneys.com",
  waitrose: "waitrose.com",
  union_coop: "unioncoop.ae",
  choithrams: "choithrams.com",
  geant: "geantonline.ae",
  nesto: "nestogroup.com",
  al_maya: "almaya.ae",
  grandiose: "grandiose.ae",
};

// In-process cache of fetched logo bytes so we don't hit Google on every load.
const cache = new Map<string, { body: Buffer; contentType: string }>();
const LOGO_FETCH_TIMEOUT_MS = 5_000;

// GET /logos/:slug — proxies a chain's logo (Google favicon) with permissive
// CORS + long cache headers. Flutter Web (CanvasKit) can't render Google's
// favicon directly because that endpoint sends no Access-Control-Allow-Origin;
// serving it through our own origin with ACAO fixes it on web, and the bytes
// are cached so repeat loads are instant. No auth: logos are public assets.
router.get("/:slug", async (req, res) => {
  const slug = req.params.slug.toLowerCase().replace(/\.(png|jpg|jpeg)$/i, "");
  const domain = CHAIN_DOMAINS[slug];
  if (!domain) {
    res.status(404).json({ error: "Unknown chain" });
    return;
  }

  res.setHeader("Access-Control-Allow-Origin", "*");
  // helmet stamps a global Cross-Origin-Resource-Policy: same-origin, which makes
  // browsers refuse to *display* this logo when it's embedded by the Flutter Web
  // app on a different origin (localhost / the web host) — even though CORS passes.
  // Logos are public assets, so opt this route into cross-origin embedding.
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
  res.setHeader("Cache-Control", "public, max-age=604800, immutable");

  const hit = cache.get(slug);
  if (hit) {
    res.setHeader("Content-Type", hit.contentType);
    res.send(hit.body);
    return;
  }

  try {
    const upstream = await fetch(
      `https://www.google.com/s2/favicons?sz=128&domain=${domain}`,
      { signal: AbortSignal.timeout(LOGO_FETCH_TIMEOUT_MS) },
    );
    if (!upstream.ok) {
      res.status(502).json({ error: "Logo upstream failed" });
      return;
    }
    const body = Buffer.from(await upstream.arrayBuffer());
    const contentType = upstream.headers.get("content-type") ?? "image/png";
    cache.set(slug, { body, contentType });
    res.setHeader("Content-Type", contentType);
    res.send(body);
  } catch {
    res.status(502).json({ error: "Logo fetch error" });
  }
});

export default router;
