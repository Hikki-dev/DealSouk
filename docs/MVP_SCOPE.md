# DealSouk MVP Scope Definition

This document outlines the roadmap scoping split for DealSouk across three development phases: Demo MVP, Launch MVP, and Post-MVP.

---

## 1. Demo MVP (Prototype)
* **Goal**: Establish initial visual concepts and static flow tests for feedback without backend integrations.
* **Scope Elements**:
  * **Static Client-Side Router**: Simple routing with mock inputs and basic page transitions.
  * **Mock Geolocator**: Uses hardcoded GPS locations (defaulting to central Dubai) without accessing real device GPS.
  * **Mock Authentication**: Allows clicking "Sign In" to transition immediately to home/profile screens without hitting SMS or OAuth networks.
  * **Centralized Mock State**: A flat client-side state file containing static product catalogs, mock price submissions, and pre-seeded vouchers.
  * **No Server Connectivity**: Operates entirely in-memory, local-only, and resets upon app reload.

---

## 2. Launch MVP (Production Release Candidate)
* **Goal**: Launch a secure, functional, and fully-connected product to test user engagement in Dubai.
* **Scope Elements**:
  * **Firebase Authentication**: Full integration with UAE Phone OTP verification, Google Sign-In, and Apple Sign-In.
  * **Guest Mode**: Read-only browsing. Guests can search and view prices/stores but are redirected to authentication for profile access, submissions, or request boards.
  * **OpenStreetMap & CartoDB Maps**: Renders nearby stores using a fast, responsive CartoDB Voyager tile layer. Native high-density Retina mode is enabled on iOS.
  * **Product Discovery**: Product lookup by name/category, barcode scanning, lowest-price calculation, and dimmed freshness alerts for submissions > 72 hours old.
  * **Grocery Cart Comparison**: Persistent cart list synced to the backend database. Compiles items and highlights the cheapest overall supermarket branch within the user's vicinity.
  * **Sourcing & Price Submission**: User submissions of supermarket prices, optional receipt/shelf photo capture, real-time token estimates, and a rolling 30-submission daily cap.
  * **Token Economy**: Complete token ledger, automated token transaction entries, and voucher queue requests (auto-allocated from active inventory upon moderator approval).
  * **Gamification**: Real-time monthly leaderboard (top 10), achievement badges, daily streak milestonings, and active daily challenges.
  * **Trust & Moderation**: In-app flag reports (duplicates, incorrect prices). Automatic submission hiding when flags >= 3. Moderator console to review queue, edit details, and issue warnings, suspensions, or bans.
  * **Push Notifications**: Firebase Cloud Messaging (FCM) integration for rank updates, flags, and account warnings/suspensions.
  * **Localization**: Full English and Arabic translation support with right-to-left (RTL) layout mirroring.
  * **Production Security**: Auth guards on routes, HTTPS-enforced API client, secure environment variable injections, and strict Express backend rate limits.

---

## 3. Post-MVP (Future Roadmap)
* **Goal**: Scale platform performance, add automated fraud analysis, and finalize commercial partner agreements.
* **Scope Elements**:
  * **Google Maps SDK Integration**: Migrating from CartoDB/OSM to native Google Maps SDK with restricted API keys once corporate billing is configured.
  * **TimescaleDB Scaling**: Transitioning Postgres price submission history to TimescaleDB hyper-tables for sub-second, multi-year price analytics querying.
  * **Redis Performance Caching**: Caching monthly leaderboard lists and rate limit states in Redis for low-latency scale.
  * **Advanced Upload Security**: Implementing backend-signed upload URLs for Firebase Storage, checking image MIME types, server-side malware scanning, and EXIF metadata stripping.
  * **Admin MFA**: Enforcing Firebase Multi-Factor Authentication claims on all moderator accounts.
  * **Offline Sync (Hive)**: Storing shopping carts and catalogs in a local database to permit full offline editing that auto-syncs when returning online.
  * **Transactional Email Alerts**: Wiring SMTP email alerts for moderation events and account transactions.
  * **Commercial Payment Gateways**: Integrating secure checkout options and automated merchant voucher APIs for direct purchasing.
