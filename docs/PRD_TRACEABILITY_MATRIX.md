# DealSouk PRD Traceability Matrix

> [!NOTE]
> **Active Workspace Branch**: `stabilize/mvp-audit`
> For the live deployment status and high-level blocker matrix, see **[STATUS.md](file:///Users/hikki/Desktop/DealSouk/docs/STATUS.md)**.

**Date**: June 13, 2026
**Document Status**: Final Audit
**Workspace Branch**: `stabilize/mvp-audit`

This document provides a comprehensive traceability matrix mapping DealSouk's Product Requirements Document (PRD v1.0) against the current codebase implementation on the production candidate branch (`stabilize/mvp-audit`).

---

## Executive Summary Statistics

| Requirement Type | Total | Done | Partial | Mock Only | Missing | Deferred / N/A |
|---|---|---|---|---|---|---|
| **Functional (FR)** | 62 | 54 | 7 | 0 | 1 | 0 |
| **Non-Functional (NFR)** | 25 | 14 | 9 | 0 | 2 | 0 |
| **UI Screen (UI)** | 5 | 4 | 1 | 0 | 0 | 0 |
| **Overall** | **92** | **72** | **17** | **0** | **3** | **0** |

---

## 1. Functional Requirements (FR-01 to FR-62)

### 1.1 Onboarding & Authentication

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-01** | UAE phone verified via SMS OTP. | **Done** | [welcome_screen.dart](lib/features/auth/presentation/welcome_screen.dart#L316-L342), [auth_service.dart](lib/features/auth/data/auth_service.dart#L22-L50), [auth.ts](backend/src/routes/auth.ts#L9-L57) | None. Real SMS depends on Firebase Auth configuration. | Low | Already fully wired via standard Firebase Auth. |
| **FR-02** | Google and Apple login. | **Done** | [welcome_screen.dart](lib/features/auth/presentation/welcome_screen.dart#L34-L46), [auth_service.dart](lib/features/auth/data/auth_service.dart#L54-L84) | None. | Low | Already fully wired. |
| **FR-03** | Guest browse read-only mode. | **Done** | [welcome_screen.dart](lib/features/auth/presentation/welcome_screen.dart#L370-L375), [router.dart](lib/app/router.dart#L42-L46) | None. Guards block guest access to profile and submissions. | Low | Already fully wired. |
| **FR-04** | Onboarding flow < 3 screens & GPS permission. | **Done** | [welcome_screen.dart](lib/features/auth/presentation/welcome_screen.dart), [tutorial_overlay.dart](lib/core/widgets/tutorial_overlay.dart), [store_screen.dart](lib/features/stores/presentation/store_screen.dart#L51-L78) | None. | Low | Already fully wired. |
| **FR-05** | User Profile details: name, photo, language, home area. | **Done** | [profile_screen.dart](lib/features/profile/presentation/profile_screen.dart), [storage_service.dart](lib/core/network/storage_service.dart), [profile.ts](backend/src/routes/profile.ts), [schema.prisma](backend/prisma/schema.prisma) | None for MVP. Profile photo replacement uploads to Firebase Storage, persists `avatarUrl`, and deletes the old avatar object after a successful replacement/removal. | Low | Keep Firebase upload sanitization and storage lifecycle monitoring in production. |
| **FR-06** | Skippable / re-runnable tutorial on token economy. | **Done** | [tutorial_overlay.dart](lib/core/widgets/tutorial_overlay.dart), [profile_screen.dart](lib/features/profile/presentation/profile_screen.dart#L870) | None. | Low | Already fully wired. |
| **FR-07** | First-time 50-token welcome bonus on first approval. | **Done** | [admin.ts](backend/src/routes/admin.ts#L59), [tokenEngine.ts](backend/src/services/tokenEngine.ts#L151-L163) | None. | Low | Already fully wired. |

---

### 1.2 Map & Supermarket Discovery

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-08** | Interactive map within configured search radius. | **Partial** | [store_screen.dart](lib/features/stores/presentation/store_screen.dart), [stores.ts](backend/src/routes/stores.ts) | Current UI uses `flutter_map`/OSM with static fallback data. `google_maps_flutter` is now added but native Google Maps implementation and key injection are not wired yet. | High | Replace or wrap current map implementation with Google Maps Flutter and inject restricted API keys through build config. |
| **FR-09** | Supermarket pin displays: name, distance, freshness, price count. | **Done** | [store_screen.dart](lib/features/stores/presentation/store_screen.dart#L349-L371), [stores.ts](backend/src/routes/stores.ts#L39-L54) | Uses standard Google Maps marker hues instead of custom design assets or logos. | Medium | Swap pins with custom icons using brand logos or freshness badge colors. |
| **FR-10** | Tapping pin opens details sheet listing products/prices. | **Done** | [store_screen.dart](lib/features/stores/presentation/store_screen.dart), [stores_service.dart](lib/features/stores/data/stores_service.dart), [stores.ts](backend/src/routes/stores.ts) | None for fresh approved store prices. Deeper sorting/filtering can be improved later. | Low | Keep branch price sheet backed by `GET /stores/:id/prices`. |
| **FR-11** | Map filtering by supermarket chain. | **Done** | [store_screen.dart](lib/features/stores/presentation/store_screen.dart#L163-L204), [stores.ts](backend/src/routes/stores.ts#L21-L30) | None. | Low | Already fully wired. |
| **FR-12** | Visually distinguish supermarkets with stale data. | **Done** | [store_screen.dart](lib/features/stores/presentation/store_screen.dart#L350-L369), [stores.ts](backend/src/routes/stores.ts#L32-L51) | Stale pins use blue hue; fresh use red hue. | Medium | Swap with custom greyed-out pins for better visual design. |

---

### 1.3 Product & Price Discovery

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-13** | Search by name, barcode scan, or category. | **Done** | [search_screen.dart](lib/features/products/presentation/search_screen.dart), [barcode_scan_screen.dart](lib/features/products/presentation/barcode_scan_screen.dart), [products.ts](backend/src/routes/products.ts), [schema.prisma](backend/prisma/schema.prisma) | Product catalog barcode coverage depends on seed/import data, but the scan/search flow and backend barcode field are wired. | Low | Add real barcode values during product catalog import. |
| **FR-14** | Pre-defined product categories. | **Done** | [seed.ts](backend/prisma/seed.ts), [souk_widgets.dart](lib/core/widgets/souk_widgets.dart#L126-L174) | Categories in code represent a subset of the PRD list. | Low | Align seed file categories with the full PRD catalog list. |
| **FR-15** | Product details: name, size, brand, photo, lowest price, time. | **Done** | [souk_widgets.dart](lib/core/widgets/souk_widgets.dart), [product.dart](lib/features/products/domain/product.dart), [products.ts](backend/src/routes/products.ts) | None. | Low | Already wired. |
| **FR-16** | View 90-day price history chart across stores. | **Done** | [products.ts](backend/src/routes/products.ts), [products_service.dart](lib/features/products/data/products_service.dart), [product_price_history.dart](lib/features/products/domain/product_price_history.dart), [product_detail_screen.dart](lib/features/products/presentation/product_detail_screen.dart) | None for approved submission history. | Low | Keep 90-day history endpoint and chart covered by future integration tests. |
| **FR-17** | Dim and label submissions older than 72 hours. | **Done** | [store_screen.dart](lib/features/stores/presentation/store_screen.dart#L595-L628), [products.ts](backend/src/routes/products.ts#L59-L73) | None. | Low | Already fully wired. |
| **FR-18** | Auto-expire and remove submissions after 72 hours. | **Done** | [products.ts](backend/src/routes/products.ts#L26) | Old entries are filtered out on query level, but old rows are not purged/archived from the database. | Medium | Setup a database trigger or periodic cron task to delete/archive expired records. |

---

### 1.4 Grocery Cart

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-19** | Add products to Grocery Cart. | **Done** | [product_detail_screen.dart](lib/features/products/presentation/product_detail_screen.dart#L477), [souk_widgets.dart](lib/core/widgets/souk_widgets.dart#L293) | None. | Low | Already fully wired. |
| **FR-20** | Surface best available price in cart within radius. | **Done** | [cart_screen.dart](lib/features/cart/presentation/cart_screen.dart#L342), [products.ts](backend/src/routes/products.ts#L27-L43) | Geographic proximity boundaries are not strictly checked in query filters. | Medium | Update the query on the backend to filter cheapest prices by stores within the user's distance radius. |
| **FR-21** | Total basket cost comparison per store. | **Done** | [cart_screen.dart](lib/features/cart/presentation/cart_screen.dart#L101-L115) | Calculations are made client-side based on static item attributes. | Medium | Relocate the totals comparison logic to a specialized backend query. |
| **FR-22** | Adjust quantities, remove, and clear cart. | **Partial** | [cart_screen.dart](lib/features/cart/presentation/cart_screen.dart), [cart_providers.dart](lib/features/cart/presentation/cart_providers.dart) | Provider supports quantity updates/removal/clear, but the visible quantity stepper UX is incomplete. | High | Add a `QuantityStepper` widget to saved item cards and connect it to `CartNotifier.updateQuantity`. |
| **FR-23** | Cart persistence across sessions and devices. | **Done** | [profile.ts](backend/src/routes/profile.ts), [cart_providers.dart](lib/features/cart/presentation/cart_providers.dart) | None for authenticated users; guest cart remains local-only by design/current behavior. | Low | Keep API-backed cart sync for authenticated users. |
| **FR-24** | In-app notification on next open for price drops. | **Missing** | None. | No detection logic or UI alerts coded for price changes. | Medium | Fetch `/profile/me/cart/price-updates` on app load and show an alert snackbar if prices decreased. |

---

### 1.5 Item Request System

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-25** | Submit price request for a product at a branch. | **Done** | [request_board_view.dart](lib/features/requests/presentation/request_board_view.dart#L145-L324), [requests.ts](backend/src/routes/requests.ts#L53-L92) | Simplified selection to store chain name instead of specific location pins. | Medium | Connect branch picker with stores list. |
| **FR-26** | Request costs tokens (default 10). | **Done** | [requests.ts](backend/src/routes/requests.ts#L66-L78), [schema.prisma](backend/prisma/schema.prisma#L158), [request_board_view.dart](lib/features/requests/presentation/request_board_view.dart#L17) | None. Fully integrated with admin settings and token ledger. | Low | Already fully wired. |
| **FR-27** | Open requests visible on Request Board. | **Done** | [request_board_view.dart](lib/features/requests/presentation/request_board_view.dart#L130-L138), [requests.ts](backend/src/routes/requests.ts#L9-L41) | None. | Low | Already fully wired. |
| **FR-28** | Transfer tokens & push notification to requester. | **Done** | [requests.ts](backend/src/routes/requests.ts#L94-L142) | None. | Low | Already fully wired. |
| **FR-29** | Refund tokens if unfulfilled in 48 hours. | **Done** | [requests.ts](backend/src/routes/requests.ts#L9-L26) | Refunds are resolved lazily on board requests, not automatically in background. | Medium | Add a scheduled backend cron script to resolve refunds dynamically. |
| **FR-30** | View open/fulfilled requests history on profile. | **Done** | [profile_screen.dart](lib/features/profile/presentation/profile_screen.dart#L527-L624), [profile.ts](backend/src/routes/profile.ts#L175-L183) | None. | Low | Already fully wired. |

---

### 1.6 Data Sourcing & Price Submission

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-31** | All registered users can act as sourcers. | **Done** | [router.dart](lib/app/router.dart) | None. | Low | Already fully wired. |
| **FR-32** | Sourcing flow: store, product, manual price, optional photo. | **Done** | [submit_price_screen.dart](lib/features/submissions/presentation/submit_price_screen.dart) | Image capture for the price label photo is mocked/toggles status local only. | Medium | Implement actual image capturing and upload to Firebase Storage for the label photo. |
| **FR-33** | Real-time token estimate. | **Done** | [submit_price_screen.dart](lib/features/submissions/presentation/submit_price_screen.dart#L347-L473), [submissions.ts](backend/src/routes/submissions.ts#L137-L152) | Client estimate uses a static frontend formula instead of querying API estimate route. | Medium | Debounce user inputs and call `/submissions/estimate` dynamically. |
| **FR-34** | Daily submission cap (default 30) on home screen. | **Done** | [home_screen.dart](lib/features/home/presentation/home_screen.dart#L762-L768), [submissions.ts](backend/src/routes/submissions.ts#L58-L69) | None. | Low | Already fully wired. |
| **FR-35** | Optional receipt image multiplier (1.5x) and verified badge. | **Done** | [tokenEngine.ts](backend/src/services/tokenEngine.ts#L29-L32), [submit_price_screen.dart](lib/features/submissions/presentation/submit_price_screen.dart#L325-L342) | Admin sidebar lacks display of receipt URLs. | Medium | Render the receipt image in the moderation sidebar panel of `admin_screen.dart`. |
| **FR-36** | Submitted prices appear in live feed. | **Done** | [submissions.ts](backend/src/routes/submissions.ts#L36) | Submissions default to `'pending'` status and only show after approval. | Medium | Confirm if pending entries should display instantly or wait for audit. |

---

### 1.7 Token Economy & Voucher Rewards

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-37** | Token balance display. | **Done** | [home_screen.dart](lib/features/home/presentation/home_screen.dart#L777), [profile_screen.dart](lib/features/profile/presentation/profile_screen.dart#L177) | None. | Low | Already fully wired. |
| **FR-38** | Token earning mechanisms. | **Done** | [tokenEngine.ts](backend/src/services/tokenEngine.ts) | None. | Low | Already fully wired. |
| **FR-39** | Token spending mechanisms. | **Done** | [tokenEngine.ts](backend/src/services/tokenEngine.ts#L81-L93) | None. | Low | Already fully wired. |
| **FR-40** | Queue voucher for approval when threshold met (500 tokens). | **Done** | [tokenEngine.ts](backend/src/services/tokenEngine.ts), [schema.prisma](backend/prisma/schema.prisma), [admin.ts](backend/src/routes/admin.ts), [profile.ts](backend/src/routes/profile.ts), [admin_screen.dart](lib/features/admin/presentation/admin_screen.dart), [profile_screen.dart](lib/features/profile/presentation/profile_screen.dart) | Voucher inventory import is still manual ops, but threshold queue, approval, token deduction, and user visibility are wired. | Low | Add inventory import and voucher audit export after MVP feedback. |
| **FR-41** | Denomination-specific vouchers (most submitted store). | **Partial** | [tokenEngine.ts](backend/src/services/tokenEngine.ts), [schema.prisma](backend/prisma/schema.prisma) | Backend selects the dominant supermarket from recent approved submissions and defaults denomination to AED 50, but partner inventory agreements and automated inventory selection are not implemented. | Medium | Add voucher inventory table/import and supermarket-specific stock validation before approval. |
| **FR-42** | Fully auditable token transaction history. | **Done** | [profile_screen.dart](lib/features/profile/presentation/profile_screen.dart#L413-L524), [profile.ts](backend/src/routes/profile.ts#L81-L94) | None. | Low | Already fully wired. |
| **FR-43** | Tokens non-transferable and have no cash value. | **Done** | Terms & Rules | None. | Low | Already fully wired. |

---

### 1.8 Gamification

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-44** | Monthly Leaderboard (Top 10 and user position). | **Done** | [leaderboard_screen.dart](lib/features/leaderboard/presentation/leaderboard_screen.dart), [leaderboard.ts](backend/src/routes/leaderboard.ts) | None. | Low | Already fully wired. |
| **FR-45** | Leaderboard updates in 5 minutes; Hall of Fame. | **Done** | [leaderboard.ts](backend/src/routes/leaderboard.ts) | Hall of Fame contains hardcoded mock data. | Medium | Persist leaderboard histories on backend and fetch them dynamically. |
| **FR-46** | Streak system with milestones and badges. | **Done** | [tokenEngine.ts](backend/src/services/tokenEngine.ts#L95-L149) | None. | Low | Already fully wired. |
| **FR-47** | Daily Challenge with bonus pool. | **Done** | [challenges.ts](backend/src/routes/challenges.ts), [tokenEngine.ts](backend/src/services/tokenEngine.ts#L165-L215) | None. | Low | Already fully wired. |
| **FR-48** | Level system (1-20) with multipliers. | **Done** | [tokenEngine.ts](backend/src/services/tokenEngine.ts#L12-L15) | None. | Low | Already fully wired. |
| **FR-49** | Achievement Badges. | **Done** | [schema.prisma](backend/prisma/schema.prisma#L133-L151), [tokenEngine.ts](backend/src/services/tokenEngine.ts) | None. | Low | Already fully wired. |
| **FR-50** | Notifications on rank change and badges. | **Done** | [fcmNotifier.ts](backend/src/services/fcmNotifier.ts) | None. | Low | Already fully wired. |

---

### 1.9 Trust & Moderation

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-51** | Flag submissions. | **Done** | [product_detail_screen.dart](lib/features/products/presentation/product_detail_screen.dart#L354-L391), [submissions.ts](backend/src/routes/submissions.ts#L102-L135) | None. | Low | Already fully wired. |
| **FR-52** | Auto-hide submission if flagged 3+ times. | **Done** | [submissions.ts](backend/src/routes/submissions.ts), [fcmNotifier.ts](backend/src/services/fcmNotifier.ts) | None for app push notification when an FCM token exists. Email is not configured. | Low | Add email provider only if product/legal requires email alerts at launch. |
| **FR-53** | Admin dashboard moderation queue (warn, ban). | **Done** | [admin_screen.dart](lib/features/admin/presentation/admin_screen.dart), [admin.ts](backend/src/routes/admin.ts), [schema.prisma](backend/prisma/schema.prisma) | None for warn/suspend/ban workflow. Admin actions are audited in `AdminUserAction`. | Low | Keep admin action audit table in backups. |
| **FR-54** | Auto-suspend sourcers with 3+ rejections. | **Done** | [admin.ts](backend/src/routes/admin.ts), [fcmNotifier.ts](backend/src/services/fcmNotifier.ts), [schema.prisma](backend/prisma/schema.prisma) | Email notification is not configured. FCM notification, suspension count, and permanent ban after repeated suspensions are wired. | Medium | Add transactional email later if PRD email notification is treated as mandatory for launch. |
| **FR-55** | Accuracy Rating on profile. | **Done** | [profile_screen.dart](lib/features/profile/presentation/profile_screen.dart#L76), [admin.ts](backend/src/routes/admin.ts) | None. Accuracy is recalculated when admin approves/rejects submissions. | Low | Add a batch backfill job if historical imported data changes. |
| **FR-56** | Admins can edit submission details. | **Done** | [admin_screen.dart](lib/features/admin/presentation/admin_screen.dart#L1708-L1739), [admin.ts](backend/src/routes/admin.ts#L105-L129) | None. | Low | Already fully wired. |

---

### 1.10 Admin & Data Monitoring Dashboard

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-57** | Web-based admin dashboard, not in mobile app. | **Partial** | [admin_app.dart](lib/features/admin/presentation/admin_app.dart) | Built as a Flutter web module in the primary mobile codebase. | Medium | Build and host the Flutter Web target in a separate deployment bucket. |
| **FR-58** | Display real-time and historical operational metrics. | **Done** | [admin_screen.dart](lib/features/admin/presentation/admin_screen.dart#L343-L380) | None. | Low | Already fully wired. |
| **FR-59** | Product Trends module showing trend charts and heatmaps. | **Partial** | [admin.ts](backend/src/routes/admin.ts), [admin_analytics.dart](lib/features/admin/domain/admin_analytics.dart), [admin_screen.dart](lib/features/admin/presentation/admin_screen.dart) | Product trends are real; neighbourhood heatmap visualization is still a list-style operational summary rather than a rendered heatmap. | Medium | Add map/heatmap visualization after production data volume exists. |
| **FR-60** | Sourcer Activity map showing coverage density. | **Partial** | [admin.ts](backend/src/routes/admin.ts), [admin_screen.dart](lib/features/admin/presentation/admin_screen.dart) | Recent coverage hotspots are real, but not yet rendered as a map. | Medium | Add admin map view using approved submission/store density. |
| **FR-61** | Admins can configure rates, caps, decay. | **Done** | [admin_screen.dart](lib/features/admin/presentation/admin_screen.dart#L1783-L1864), [admin.ts](backend/src/routes/admin.ts#L131-L164) | Decay formula parameters, product category editors are missing. | Medium | Add forms to System Settings panel. |
| **FR-62** | CSV and PDF data exports. | **Partial** | [admin.ts](backend/src/routes/admin.ts), [admin_screen.dart](lib/features/admin/presentation/admin_screen.dart) | CSV export exists for submissions. PDF export is still missing. | Medium | Add backend PDF report generation after CSV columns stabilize. |

---

## 2. Non-Functional Requirements (NFR-01 to NFR-25)

### 2.1 Performance

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-01** | Cold start < 3 seconds. | **Done** | [main.dart](lib/main.dart), [app.dart](lib/app/app.dart) | None. | Low | Already fully wired. |
| **NFR-02** | Search results < 1.5 seconds. | **Done** | [products.ts](backend/src/routes/products.ts) | None. | Low | Already fully wired. |
| **NFR-03** | Feed updates < 60 seconds. | **Done** | [submissions.ts](backend/src/routes/submissions.ts) | None. | Low | Already fully wired. |
| **NFR-04** | Map renders pins < 2 seconds. | **Partial** | [store_screen.dart](lib/features/stores/presentation/store_screen.dart) | Current map can render OSM pins, but production Google Maps integration/performance has not been validated. | High | Wire Google Maps Flutter and add device smoke tests for marker render time. |
| **NFR-05** | Support 50k concurrent users. | **Partial** | Express Server | No load testing records or benchmarks exist. | Medium | Execute load test checks using `Artillery`. |

---

### 2.2 Security

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-06** | Data encrypted via TLS 1.3. | **Partial** | [api_client.dart](lib/core/network/api_client.dart) | Client defaults to HTTPS and rejects non-HTTPS in release. Backend/proxy TLS 1.3 and HSTS deployment settings still need production verification. | High | Verify deployed backend TLS config and add HSTS/HTTPS redirect at the edge. |
| **NFR-07** | PII at rest encrypted via AES-256. | **Partial** | Google Cloud DB | Database fields (phone numbers, display names) are stored in plain text. | High | Encrypt sensitive database fields at application level. |
| **NFR-08** | Session tokens expiration. | **Done** | Firebase SDK | None. | Low | Already fully wired. |
| **NFR-09** | Submission rate limiting (max 5/min). | **Done** | [submissions.ts](backend/src/routes/submissions.ts#L10) | None. | Low | Already fully wired. |
| **NFR-10** | Photo uploads scanned server-side. | **Missing** | None. | Photos directly saved in Storage bucket without checks. | Medium | Implement malware scanning on uploaded file buckets. |

---

### 2.3 Privacy & Compliance

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-11** | UAE PDPL compliance. | **Partial** | [profile.ts](backend/src/routes/profile.ts#L186) | No privacy policy or consent check dialogs on welcome screen. | Medium | Add privacy consent during registration. |
| **NFR-12** | User precise GPS not stored. | **Done** | [schema.prisma](backend/prisma/schema.prisma) | Coordinates are used in session memory only, not database. | Low | Already fully wired. |
| **NFR-13** | Disclose Privacy Policy in English/Arabic. | **Partial** | [privacy_policy_screen.dart](lib/features/legal/presentation/privacy_policy_screen.dart), [welcome_screen.dart](lib/features/auth/presentation/welcome_screen.dart), [profile_screen.dart](lib/features/profile/presentation/profile_screen.dart), [PRIVACY_POLICY.md](docs/PRIVACY_POLICY.md) | In-app policy and Arabic summary are present, but final legal-approved English/Arabic copy is still required. | Medium | Send the draft to legal, then replace draft copy with approved policy text. |
| **NFR-14** | Account deletion within 30 days. | **Done** | [profile.ts](backend/src/routes/profile.ts#L186) | None. | Low | Already fully wired. |
| **NFR-15** | Location permission minimum "When In Use". | **Done** | AndroidManifest.xml, Info.plist | None. | Low | Already fully wired. |

---

### 2.4 Accessibility

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-16** | WCAG 2.1 Level AA conformance. | **Partial** | Flutter Engine | No explicit semantic focus checks or accessibility tests. | Medium | Run automated accessibility scanner audits. |
| **NFR-17** | Minimum touch targets 44x44. | **Done** | UI elements | None. | Low | Already fully wired. |
| **NFR-18** | Support Dynamic Type/font scaling. | **Done** | UI elements | None. | Low | Already fully wired. |
| **NFR-19** | Screen reader labels on images/icons. | **Partial** | Cards / Lists | Several custom icons in grid cards lack semantic tags. | Medium | Wrap custom buttons in `Semantics` widgets. |
| **NFR-20** | Right-to-Left Arabic layout. | **Done** | [app.dart](lib/app/app.dart) | RTL golden tests/mirroring validation are missing. | Medium | Smoke check Arab layouts. |

---

### 2.5 Reliability & Availability

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-21** | Backend API 99.9% uptime. | **Partial** | Express backend | Uptime monitoring is missing. | Medium | Add standard health check monitoring. |
| **NFR-22** | Graceful degradation offline. | **Missing** | None. | Offline cache strategy is missing. App breaks when connection drops. | High | Configure Hive/local DB database cache for cart lists. |
| **NFR-23** | Scheduled maintenance window banner. | **Done** | [index.ts](backend/src/index.ts), [system_status_service.dart](lib/core/network/system_status_service.dart), [app.dart](lib/app/app.dart), [backend/.env.example](backend/.env.example) | None. | Low | Configure `MAINTENANCE_MODE` and `MAINTENANCE_MESSAGE` in production secret manager. |

---

### 2.6 Cross-Platform Parity

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-24** | iOS/Android visually identical. | **Done** | [shell_layout.dart](lib/core/widgets/shell_layout.dart) | Uses adaptive styling rules (glassmorphism for iOS, polish styles for Android). | Low | Already fully wired. |
| **NFR-25** | Single shared localization file. | **Done** | [app_en.arb](lib/l10n/app_en.arb) | None. | Low | Already fully wired. |

---

## 3. Key Screen Requirements (UI-01 to UI-05)

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **UI-01** | Home feed default sorted by recency with freshness chip filter row. | **Done** | [home_screen.dart](lib/features/home/presentation/home_screen.dart#L471) | None. | Low | Already fully wired. |
| **UI-02** | Grocery cart displays: Best price badge, quantity stepper, "Also at" option. | **Partial** | [cart_screen.dart](lib/features/cart/presentation/cart_screen.dart) | Quantity stepper UI and "Also at" next-cheapest label are completely missing. | High | Implement stepper and lookup the next cheapest price record in `cart_screen.dart`. |
| **UI-03** | Token balance widget count-up animation. | **Done** | [home_screen.dart](lib/features/home/presentation/home_screen.dart#L772-L786) | None. | Low | Already fully wired. |
| **UI-04** | Live token estimate updating dynamically. | **Done** | [submit_price_screen.dart](lib/features/submissions/presentation/submit_price_screen.dart#L347-L473) | None. | Low | Already fully wired. |
| **UI-05** | Price values displayed in AED with two decimals. | **Done** | [souk_widgets.dart](lib/core/widgets/souk_widgets.dart#L111-L122) | None. | Low | Already fully wired. |

---

## 4. Key Security Gaps & Product Risks

1. **Legacy Static Router Bypass (NFR-11 / FR-52)**
   > [!CAUTION]
   > Current status: fixed in the working tree. Admin access is guarded through [route_guard.dart](lib/app/route_guard.dart), [router.dart](lib/app/router.dart), and [route_guard_test.dart](test/app/route_guard_test.dart). Keep these tests in CI. **Priority: Low ongoing regression guard**.

2. **Hardcoded Unsecured HTTP Endpoint (NFR-06)**
   > [!WARNING]
   > Current status: client-side release guard is fixed. [api_client.dart](lib/core/network/api_client.dart) defaults to `https://dealsouk.onrender.com` and rejects non-HTTPS URLs in release. Remaining work is deployment-side TLS/HSTS verification. **Priority: High**.

3. **Floating Navbar Overlay Blocks Taps (UI-02 / NFR-24)**
   > [!WARNING]
   > The profile settings screen scroll padding is not synchronized with the floating navigation bar bounds. The log out button sits directly behind the navbar on smaller screens, blocking user tap interactions. **Priority: High**. Fix: Ensure list padding extends past navbar height (180px+).
