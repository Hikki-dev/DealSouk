# PRD Deviations — PM Sign-off Record (D1–D3, D4)

NFR-24 requires **written Product Manager sign-off** for any divergence from the
PRD. This document records the known, deliberate deviations for Adil-ur Rahman
(PM) to review and sign. Each is a defensible MVP choice, not an accidental gap.

| ID | PRD requirement | Shipped instead | Rationale | Impact | PM decision |
|----|-----------------|-----------------|-----------|--------|-------------|
| **D1** | Google Maps SDK (FR-08, §12/§13) | `flutter_map` + OpenStreetMap (CartoDB Voyager tiles) | Avoids Google Maps API-key/billing setup for MVP; no key constraints. AGENTS.md records OSM as the deliberate MVP choice. | Visual/interaction differs from Google Maps; geofencing done client-side. pubspec still carries both deps — **action: confirm only `flutter_map` renders and drop the unused Google Maps dep.** | ☐ Approved ☐ Revisit |
| **D2** | TimescaleDB hypertables for price history (§11.2, FR-16/59) | Postgres **materialized view** `price_history_daily` (migration `20260613150000`) | TimescaleDB isn't available on Neon. The view serves FR-16/59 at MVP scale. | `REFRESH MATERIALIZED VIEW` is a full recompute — won't scale to NFR-05 (500k users). Accept as post-MVP debt or plan a Timescale-capable host. | ☐ Accept as debt ☐ Plan migration |
| **D3** | Metabase admin dashboard (§13.4, FR-57) | Flutter Web admin console (`--dart-define=ADMIN_MODE=true`) | Satisfies the "web tool, not in the mobile app" intent (FR-57) with the existing stack; no separate Metabase host. | Verify FR-58/59/60 coverage (price trends, demand heatmap, sourcer-activity map). Log any gaps as new tasks. | ☐ Sufficient ☐ Gaps logged |
| **D4** | Primary DB in GCP `me-central1` (Doha), §11.2 / PDPL NFR-11 | Neon Postgres in **`eu-central1` (Frankfurt)** | Neon has **no UAE region**; Frankfurt is the closest and is the EU region the PRD names as acceptable DR fallback. Migration done (see `NEON_FRANKFURT_CUTOVER.md`). | EU, not in-country UAE. **Action: PDPL legal sign-off for EU hosting**, or plan a future move to a true `me-central1` provider (GCP Cloud SQL / AWS Bahrain). | ☐ Approved (EU) ☐ Require UAE |

**Sign-off:** ______________________  (Adil-ur Rahman, PM)   Date: __________
