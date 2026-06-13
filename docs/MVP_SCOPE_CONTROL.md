# DealSouk MVP Scope Control

Date: 2026-06-12
Purpose: keep the current branch focused on production MVP readiness instead of expanding into every PRD idea at once.

## MVP Principle

DealSouk MVP should help a Dubai shopper answer four questions quickly:

1. What is the best nearby price?
2. Can I trust this price?
3. How do I save or compare it?
4. How do I ask/share a price if it is missing?

Anything that does not improve those answers should be deferred until the core loop is stable.

## In MVP

| Area | Included |
|---|---|
| Auth | Firebase phone, Google, Apple, guest browse, role-based admin access. |
| Product search | Name/category search, fresh price display, request missing price. |
| Store map | Nearby branch discovery, fresh store price list, submit price from branch. |
| Cart/My List | Save prices and compare cheapest basket. |
| Price submission | Store, product/photo, price, submit, token reward after approval path. |
| Requests | Ask shoppers to check a price, deduct/refund request tokens. |
| Tokens | Balance, transaction history, daily cap, submission reward, basic leaderboard. |
| Moderation | Admin approve/reject, edit submission, hide after 3 unique flags. |
| Localization | English/Arabic strings and RTL smoke coverage. |
| Security | Route guards, HTTPS client guard, no hardcoded admin email, ignored secrets. |
| Tests | Pure business-logic tests for cart, tokens, moderation, expiry, ranking, localization, route guard. |

## Deferred After MVP

| Area | Reason |
|---|---|
| 90-day price history charts | Useful, but not required for the first price-check loop. |
| Full product heatmap analytics | Admin-only insight; backend summary exists, but true heatmaps should wait until live data volume exists. |
| Heatmaps/coverage density | Depends on production data quality and privacy review. |
| PDF exports | CSV export exists; PDF can wait until reporting format is approved. |
| Offline cache | Important reliability improvement; needs explicit cache design. |
| Voucher inventory import/export | Voucher threshold, request queue, admin approval, token deduction, and user visibility are now wired. Bulk inventory management and fraud review remain after MVP. |
| Advanced map marker pricing overlays | Nice-to-have after branch price sheets are stable. |
| UI animation polish | Avoid until copy, trust, loading, and error states are stable. |

## Release Blockers

Current code-level release blockers:

- None known for admin-route security or plaintext API defaults.

Must still be completed before public production release:

- Regenerate/document Firebase config for clean clones and CI.
- Rotate/purge any Firebase/service-account material that appeared in git history.
- Verify backend TLS/HSTS deployment.
- Move remaining demo fallback data behind dev-only providers or clearly label fallback states.
- Confirm App Store/Play Store privacy policy text in English and Arabic.
- Configure production `ALLOWED_ORIGINS`, request body limits, and rate-limit env values before backend deployment.
- Run the secret-rotation/history-purge runbook before any public repo or production launch.

## Guardrails

- Do not add a feature unless it supports the four MVP shopper questions.
- Do not add charts, exports, or dashboards until backend data is trustworthy.
- Do not let production screens silently read mock data.
- Do not treat tokens as cash value.
- Do not store precise GPS persistently.
- Do not expose admin navigation or screens to normal users.
