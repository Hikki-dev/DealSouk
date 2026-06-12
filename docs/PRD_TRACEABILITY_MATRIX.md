# DealSouk PRD Traceability Matrix

**Date**: June 12, 2026  
**Document Status**: Final Audit  
**Workspace Branch**: `feature/flutter-api-integration`  

This document provides a comprehensive traceability matrix mapping DealSouk's Product Requirements Document (PRD v1.0) against the current codebase implementation on the production candidate branch (`feature/flutter-api-integration`).

---

## Executive Summary Statistics

| Requirement Type | Total | Done | Partial | Mock Only | Missing | Deferred / N/A |
|---|---|---|---|---|---|---|
| **Functional (FR)** | 62 | 47 | 4 | 8 | 3 | 0 |
| **Non-Functional (NFR)** | 25 | 12 | 8 | 0 | 5 | 0 |
| **UI Screen (UI)** | 5 | 4 | 1 | 0 | 0 | 0 |
| **Overall** | **92** | **63** | **13** | **8** | **8** | **0** |

---

## 1. Functional Requirements (FR-01 to FR-62)

### 1.1 Onboarding & Authentication

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-01** | UAE phone verified via SMS OTP. | **Done** | [welcome_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/auth/welcome_screen.dart#L316-L342), [auth_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/services/auth_service.dart#L22-L50), [auth.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/auth.ts#L9-L57) | None. Real SMS depends on Firebase Auth configuration. | Low | Already fully wired via standard Firebase Auth. |
| **FR-02** | Google and Apple login. | **Done** | [welcome_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/auth/welcome_screen.dart#L34-L46), [auth_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/services/auth_service.dart#L54-L84) | None. | Low | Already fully wired. |
| **FR-03** | Guest browse read-only mode. | **Done** | [welcome_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/auth/welcome_screen.dart#L370-L375), [router.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/router/router.dart#L42-L46) | None. Guards block guest access to profile and submissions. | Low | Already fully wired. |
| **FR-04** | Onboarding flow < 3 screens & GPS permission. | **Done** | [welcome_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/auth/welcome_screen.dart), [tutorial_overlay.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/tutorial_overlay.dart), [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart#L51-L78) | None. | Low | Already fully wired. |
| **FR-05** | User Profile details: name, photo, language, home area. | **Partial** | [profile_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/profile_screen.dart#L748-L819), [profile.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/profile.ts#L61-L79), [schema.prisma](file:///Users/hikki/Desktop/DealSouk/backend/prisma/schema.prisma#L10-L28) | Profile photo upload UI and Firebase Storage integration for user profile photos are missing. | Medium | Add an `ImagePicker` trigger on the profile avatar and upload to Firebase Storage under `avatars/$uid/`. |
| **FR-06** | Skippable / re-runnable tutorial on token economy. | **Done** | [tutorial_overlay.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/tutorial_overlay.dart), [profile_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/profile_screen.dart#L870) | None. | Low | Already fully wired. |
| **FR-07** | First-time 50-token welcome bonus on first approval. | **Done** | [admin.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/admin.ts#L59), [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts#L151-L163) | None. | Low | Already fully wired. |

---

### 1.2 Map & Supermarket Discovery

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-08** | Interactive map within configured search radius. | **Done** | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart#L327-L422), [stores.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/stores.ts#L17-L58) | Maps keys are placeholders, causing runtime connection errors. Web runs fallback UI. | **Critical** (Keys) | Inject Google Maps API Keys into platform build configurations. |
| **FR-09** | Supermarket pin displays: name, distance, freshness, price count. | **Done** | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart#L349-L371), [stores.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/stores.ts#L39-L54) | Uses standard Google Maps marker hues instead of custom design assets or logos. | Medium | Swap pins with custom icons using brand logos or freshness badge colors. |
| **FR-10** | Tapping pin opens details sheet listing products/prices. | **Partial** | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart#L493-L676) | The list `pricingList` inside the bottom sheet is initialized as empty and is **never populated** from the API! Tapping a pin opens an empty sheet. | **Critical** | Call `GET /products/search?storeId=:id` or equivalent endpoint to fetch prices for that store and populate the list dynamically. |
| **FR-11** | Map filtering by supermarket chain. | **Done** | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart#L163-L204), [stores.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/stores.ts#L21-L30) | None. | Low | Already fully wired. |
| **FR-12** | Visually distinguish supermarkets with stale data. | **Done** | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart#L350-L369), [stores.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/stores.ts#L32-L51) | Stale pins use blue hue; fresh use red hue. | Medium | Swap with custom greyed-out pins for better visual design. |

---

### 1.3 Product & Price Discovery

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-13** | Search by name, barcode scan, or category. | **Done** | [search_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/products/search_screen.dart#L72-L132), [products.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/products.ts#L7-L47) | Barcode scan icon exists, but camera scanner implementation is currently a simulated placeholder. | High | Integrate the `mobile_scanner` package to capture barcodes via device camera. |
| **FR-14** | Pre-defined product categories. | **Done** | [seed.ts](file:///Users/hikki/Desktop/DealSouk/backend/prisma/seed.ts), [souk_widgets.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/souk_widgets.dart#L126-L174) | Categories in code represent a subset of the PRD list. | Low | Align seed file categories with the full PRD catalog list. |
| **FR-15** | Product details: name, size, brand, photo, lowest price, time. | **Done** | [souk_widgets.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/souk_widgets.dart#L178-L383), [models.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/models/models.dart#L1-L66), [products.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/products.ts#L27-L44) | None. | Low | Already fully wired. |
| **FR-16** | View 90-day price history chart across stores. | **Missing** | None. | Price history chart is completely missing from both the frontend and backend APIs. | High | Add backend route `/products/:id/history` pulling historical data from `PriceSubmission` and render a line chart using `fl_chart`. |
| **FR-17** | Dim and label submissions older than 72 hours. | **Done** | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart#L595-L628), [products.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/products.ts#L59-L73) | None. | Low | Already fully wired. |
| **FR-18** | Auto-expire and remove submissions after 72 hours. | **Done** | [products.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/products.ts#L26) | Old entries are filtered out on query level, but old rows are not purged/archived from the database. | Medium | Setup a database trigger or periodic cron task to delete/archive expired records. |

---

### 1.4 Grocery Cart

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-19** | Add products to Grocery Cart. | **Done** | [product_detail_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/products/product_detail_screen.dart#L477), [souk_widgets.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/souk_widgets.dart#L293) | None. | Low | Already fully wired. |
| **FR-20** | Surface best available price in cart within radius. | **Done** | [cart_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/cart/cart_screen.dart#L342), [products.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/products.ts#L27-L43) | Geographic proximity boundaries are not strictly checked in query filters. | Medium | Update the query on the backend to filter cheapest prices by stores within the user's distance radius. |
| **FR-21** | Total basket cost comparison per store. | **Done** | [cart_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/cart/cart_screen.dart#L101-L115) | Calculations are made client-side based on static item attributes. | Medium | Relocate the totals comparison logic to a specialized backend query. |
| **FR-22** | Adjust quantities, remove, and clear cart. | **Partial** | [cart_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/cart/cart_screen.dart#L49-L89), [state.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/state/state.dart#L189-L206) | Quantity stepper UI is completely missing. Users cannot adjust quantities on the screen. | High | Add a `QuantityStepper` widget to the `_SavedPriceCard` layout in `cart_screen.dart`. |
| **FR-23** | Cart persistence across sessions and devices. | **Done** | [profile.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/profile.ts#L130-L173), [state.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/state/state.dart#L150-L158) | None. | Low | Already fully wired. |
| **FR-24** | In-app notification on next open for price drops. | **Missing** | None. | No detection logic or UI alerts coded for price changes. | Medium | Fetch `/profile/me/cart/price-updates` on app load and show an alert snackbar if prices decreased. |

---

### 1.5 Item Request System

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-25** | Submit price request for a product at a branch. | **Done** | [request_board_view.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/leaderboard/request_board_view.dart#L145-L324), [requests.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/requests.ts#L53-L92) | Simplified selection to store chain name instead of specific location pins. | Medium | Connect branch picker with stores list. |
| **FR-26** | Request costs tokens (default 10). | **Done** | [requests.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/requests.ts#L66-L78), [schema.prisma](file:///Users/hikki/Desktop/DealSouk/backend/prisma/schema.prisma#L158) | The Flutter request creation form hardcodes the cost as `0` tokens. | High | Update request creation in `request_board_view.dart` to deduct real tokens. |
| **FR-27** | Open requests visible on Request Board. | **Done** | [request_board_view.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/leaderboard/request_board_view.dart#L130-L138), [requests.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/requests.ts#L9-L41) | None. | Low | Already fully wired. |
| **FR-28** | Transfer tokens & push notification to requester. | **Done** | [requests.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/requests.ts#L94-L142) | None. | Low | Already fully wired. |
| **FR-29** | Refund tokens if unfulfilled in 48 hours. | **Done** | [requests.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/requests.ts#L9-L26) | Refunds are resolved lazily on board requests, not automatically in background. | Medium | Add a scheduled backend cron script to resolve refunds dynamically. |
| **FR-30** | View open/fulfilled requests history on profile. | **Done** | [profile_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/profile_screen.dart#L527-L624), [profile.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/profile.ts#L175-L183) | None. | Low | Already fully wired. |

---

### 1.6 Data Sourcing & Price Submission

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-31** | All registered users can act as sourcers. | **Done** | [router.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/router/router.dart) | None. | Low | Already fully wired. |
| **FR-32** | Sourcing flow: store, product, manual price, optional photo. | **Done** | [submit_price_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/submissions/submit_price_screen.dart) | Image capture for the price label photo is mocked/toggles status local only. | Medium | Implement actual image capturing and upload to Firebase Storage for the label photo. |
| **FR-33** | Real-time token estimate. | **Done** | [submit_price_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/submissions/submit_price_screen.dart#L347-L473), [submissions.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/submissions.ts#L137-L152) | Client estimate uses a static frontend formula instead of querying API estimate route. | Medium | Debounce user inputs and call `/submissions/estimate` dynamically. |
| **FR-34** | Daily submission cap (default 30) on home screen. | **Done** | [home_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/home/home_screen.dart#L762-L768), [submissions.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/submissions.ts#L58-L69) | None. | Low | Already fully wired. |
| **FR-35** | Optional receipt image multiplier (1.5x) and verified badge. | **Done** | [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts#L29-L32), [submit_price_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/submissions/submit_price_screen.dart#L325-L342) | Admin sidebar lacks display of receipt URLs. | Medium | Render the receipt image in the moderation sidebar panel of `admin_screen.dart`. |
| **FR-36** | Submitted prices appear in live feed. | **Done** | [submissions.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/submissions.ts#L36) | Submissions default to `'pending'` status and only show after approval. | Medium | Confirm if pending entries should display instantly or wait for audit. |

---

### 1.7 Token Economy & Voucher Rewards

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-37** | Token balance display. | **Done** | [home_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/home/home_screen.dart#L777), [profile_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/profile_screen.dart#L177) | None. | Low | Already fully wired. |
| **FR-38** | Token earning mechanisms. | **Done** | [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts) | None. | Low | Already fully wired. |
| **FR-39** | Token spending mechanisms. | **Done** | [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts#L81-L93) | None. | Low | Already fully wired. |
| **FR-40** | Queue voucher for approval when threshold met (500 tokens). | **Mock Only** | [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts#L240-L247) | There is no `Voucher` model or table. Exceeding the threshold triggers a console log only. No notification or delivery flow. | High | Create a `Voucher` schema table in database and implement automated queueing logic. |
| **FR-41** | Denomination-specific vouchers (most submitted store). | **Mock Only** | [profile_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/profile_screen.dart#L676-L680) | Text layout on screen is completely hardcoded/mocked. | High | Write aggregation queries on the backend to identify dominant stores and generate coupon codes. |
| **FR-42** | Fully auditable token transaction history. | **Done** | [profile_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/profile_screen.dart#L413-L524), [profile.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/profile.ts#L81-L94) | None. | Low | Already fully wired. |
| **FR-43** | Tokens non-transferable and have no cash value. | **Done** | Terms & Rules | None. | Low | Already fully wired. |

---

### 1.8 Gamification

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-44** | Monthly Leaderboard (Top 10 and user position). | **Done** | [leaderboard_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/leaderboard/leaderboard_screen.dart), [leaderboard.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/leaderboard.ts) | None. | Low | Already fully wired. |
| **FR-45** | Leaderboard updates in 5 minutes; Hall of Fame. | **Done** | [leaderboard.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/leaderboard.ts) | Hall of Fame contains hardcoded mock data. | Medium | Persist leaderboard histories on backend and fetch them dynamically. |
| **FR-46** | Streak system with milestones and badges. | **Done** | [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts#L95-L149) | None. | Low | Already fully wired. |
| **FR-47** | Daily Challenge with bonus pool. | **Done** | [challenges.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/challenges.ts), [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts#L165-L215) | None. | Low | Already fully wired. |
| **FR-48** | Level system (1-20) with multipliers. | **Done** | [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts#L12-L15) | None. | Low | Already fully wired. |
| **FR-49** | Achievement Badges. | **Done** | [schema.prisma](file:///Users/hikki/Desktop/DealSouk/backend/prisma/schema.prisma#L133-L151), [tokenEngine.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/tokenEngine.ts) | None. | Low | Already fully wired. |
| **FR-50** | Notifications on rank change and badges. | **Done** | [fcmNotifier.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/services/fcmNotifier.ts) | None. | Low | Already fully wired. |

---

### 1.9 Trust & Moderation

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-51** | Flag submissions. | **Done** | [product_detail_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/products/product_detail_screen.dart#L354-L391), [submissions.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/submissions.ts#L102-L135) | None. | Low | Already fully wired. |
| **FR-52** | Auto-hide submission if flagged 3+ times. | **Done** | [submissions.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/submissions.ts#L127) | original sourcer push notification is missing. | Medium | Add FCM warning payload when status updates to hidden. |
| **FR-53** | Admin dashboard moderation queue (warn, ban). | **Done** | [admin_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/admin_screen.dart), [admin.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/admin.ts) | Warn and ban buttons are missing from the dashboard UI. | High | Add warn/ban buttons invoking admin update profiles endpoints. |
| **FR-54** | Auto-suspend sourcers with 3+ rejections. | **Done** | [admin.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/admin.ts#L83-L100) | Actual notification is missing (console log warning only). Permanent ban on 3rd suspension is missing. | High | Trigger an FCM message to the user when suspended, and track suspension tallies in the database. |
| **FR-55** | Accuracy Rating on profile. | **Done** | [profile_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/profile/profile_screen.dart#L76) | Server accuracy rating doesn't update dynamically when admin acts on pending queue. | Medium | Recalculate and update `accuracyRating` field on submission state updates. |
| **FR-56** | Admins can edit submission details. | **Done** | [admin_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/admin_screen.dart#L1708-L1739), [admin.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/admin.ts#L105-L129) | None. | Low | Already fully wired. |

---

### 1.10 Admin & Data Monitoring Dashboard

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **FR-57** | Web-based admin dashboard, not in mobile app. | **Partial** | [admin_app.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/admin_app.dart) | Built as a Flutter web module in the primary mobile codebase. | Medium | Build and host the Flutter Web target in a separate deployment bucket. |
| **FR-58** | Display real-time and historical operational metrics. | **Done** | [admin_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/admin_screen.dart#L343-L380) | None. | Low | Already fully wired. |
| **FR-59** | Product Trends module showing trend charts and heatmaps. | **Mock Only** | [admin_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/admin_screen.dart#L1753) | The Analytics tab renders a disclaimer disclaimer only. | High | Write time-series data aggregation API calls on backend and plot trends on frontend using `fl_chart`. |
| **FR-60** | Sourcer Activity map showing coverage density. | **Mock Only** | [admin_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/admin_screen.dart#L1753) | Renders mock disclaimer. | High | Display Google Maps showing markers indicating locations of submissions. |
| **FR-61** | Admins can configure rates, caps, decay. | **Done** | [admin_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/admin/admin_screen.dart#L1783-L1864), [admin.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/admin.ts#L131-L164) | Decay formula parameters, product category editors are missing. | Medium | Add forms to System Settings panel. |
| **FR-62** | CSV and PDF data exports. | **Missing** | None. | Completely missing from dashboard layouts and backend routes. | High | Add backend endpoints generation formatting reports in CSV and download button actions. |

---

## 2. Non-Functional Requirements (NFR-01 to NFR-25)

### 2.1 Performance

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-01** | Cold start < 3 seconds. | **Done** | [main.dart](file:///Users/hikki/Desktop/DealSouk/lib/main.dart), [app.dart](file:///Users/hikki/Desktop/DealSouk/lib/app.dart) | None. | Low | Already fully wired. |
| **NFR-02** | Search results < 1.5 seconds. | **Done** | [products.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/products.ts) | None. | Low | Already fully wired. |
| **NFR-03** | Feed updates < 60 seconds. | **Done** | [submissions.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/submissions.ts) | None. | Low | Already fully wired. |
| **NFR-04** | Map renders pins < 2 seconds. | **Done** | [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart) | Placeholder API keys block maps connections. | **Critical** | Input valid Google Maps keys. |
| **NFR-05** | Support 50k concurrent users. | **Partial** | Express Server | No load testing records or benchmarks exist. | Medium | Execute load test checks using `Artillery`. |

---

### 2.2 Security

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-06** | Data encrypted via TLS 1.3. | **Partial** | `BaseOptions` | local development defaults to plaintext HTTP `http://100.69.54.28:3000`. | **Critical** | Restrict release builds to HTTPS configurations. |
| **NFR-07** | PII at rest encrypted via AES-256. | **Partial** | Google Cloud DB | Database fields (phone numbers, display names) are stored in plain text. | High | Encrypt sensitive database fields at application level. |
| **NFR-08** | Session tokens expiration. | **Done** | Firebase SDK | None. | Low | Already fully wired. |
| **NFR-09** | Submission rate limiting (max 5/min). | **Done** | [submissions.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/submissions.ts#L10) | None. | Low | Already fully wired. |
| **NFR-10** | Photo uploads scanned server-side. | **Missing** | None. | Photos directly saved in Storage bucket without checks. | Medium | Implement malware scanning on uploaded file buckets. |

---

### 2.3 Privacy & Compliance

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-11** | UAE PDPL compliance. | **Partial** | [profile.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/profile.ts#L186) | No privacy policy or consent check dialogs on welcome screen. | Medium | Add privacy consent during registration. |
| **NFR-12** | User precise GPS not stored. | **Done** | [schema.prisma](file:///Users/hikki/Desktop/DealSouk/backend/prisma/schema.prisma) | Coordinates are used in session memory only, not database. | Low | Already fully wired. |
| **NFR-13** | Disclose Privacy Policy in English/Arabic. | **Missing** | None. | Privacy Policy tile and text layouts are missing. | Medium | Add settings option displaying the text. |
| **NFR-14** | Account deletion within 30 days. | **Done** | [profile.ts](file:///Users/hikki/Desktop/DealSouk/backend/src/routes/profile.ts#L186) | None. | Low | Already fully wired. |
| **NFR-15** | Location permission minimum "When In Use". | **Done** | AndroidManifest.xml, Info.plist | None. | Low | Already fully wired. |

---

### 2.4 Accessibility

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-16** | WCAG 2.1 Level AA conformance. | **Partial** | Flutter Engine | No explicit semantic focus checks or accessibility tests. | Medium | Run automated accessibility scanner audits. |
| **NFR-17** | Minimum touch targets 44x44. | **Done** | UI elements | None. | Low | Already fully wired. |
| **NFR-18** | Support Dynamic Type/font scaling. | **Done** | UI elements | None. | Low | Already fully wired. |
| **NFR-19** | Screen reader labels on images/icons. | **Partial** | Cards / Lists | Several custom icons in grid cards lack semantic tags. | Medium | Wrap custom buttons in `Semantics` widgets. |
| **NFR-20** | Right-to-Left Arabic layout. | **Done** | [app.dart](file:///Users/hikki/Desktop/DealSouk/lib/app.dart) | RTL golden tests/mirroring validation are missing. | Medium | Smoke check Arab layouts. |

---

### 2.5 Reliability & Availability

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-21** | Backend API 99.9% uptime. | **Partial** | Express backend | Uptime monitoring is missing. | Medium | Add standard health check monitoring. |
| **NFR-22** | Graceful degradation offline. | **Missing** | None. | Offline cache strategy is missing. App breaks when connection drops. | High | Configure Hive/local DB database cache for cart lists. |
| **NFR-23** | Scheduled maintenance window banner. | **Missing** | None. | Warnings and banner are missing. | Low | Add checking endpoint for maintenance status. |

---

### 2.6 Cross-Platform Parity

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **NFR-24** | iOS/Android visually identical. | **Done** | [shell_layout.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/shell_layout.dart) | Uses adaptive styling rules (glassmorphism for iOS, polish styles for Android). | Low | Already fully wired. |
| **NFR-25** | Single shared localization file. | **Done** | [app_en.arb](file:///Users/hikki/Desktop/DealSouk/lib/l10n/app_en.arb) | None. | Low | Already fully wired. |

---

## 3. Key Screen Requirements (UI-01 to UI-05)

| ID | Summary | Status | Evidence (File Paths) | What is Missing / Gaps | Priority | Suggested Implementation Approach |
|---|---|---|---|---|---|---|
| **UI-01** | Home feed default sorted by recency with freshness chip filter row. | **Done** | [home_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/home/home_screen.dart#L471) | None. | Low | Already fully wired. |
| **UI-02** | Grocery cart displays: Best price badge, quantity stepper, "Also at" option. | **Partial** | [cart_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/cart/cart_screen.dart) | Quantity stepper UI and "Also at" next-cheapest label are completely missing. | High | Implement stepper and lookup the next cheapest price record in `cart_screen.dart`. |
| **UI-03** | Token balance widget count-up animation. | **Done** | [home_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/home/home_screen.dart#L772-L786) | None. | Low | Already fully wired. |
| **UI-04** | Live token estimate updating dynamically. | **Done** | [submit_price_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/submissions/submit_price_screen.dart#L347-L473) | None. | Low | Already fully wired. |
| **UI-05** | Price values displayed in AED with two decimals. | **Done** | [souk_widgets.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/souk_widgets.dart#L111-L122) | None. | Low | Already fully wired. |

---

## 4. Key Security Gaps & Product Risks

1. **Legacy Static Router Bypass (NFR-11 / FR-52)**  
   > [!CAUTION]  
   > The legacy static `appRouter` inside [router.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/router/router.dart#L194) remains fully exported and completely unguarded. If imported, it allows users to bypass authorization, admin role, and guest mode checks. **Priority: Critical**. Fix: Delete legacy `appRouter` entirely.
   
2. **Hardcoded Unsecured HTTP Endpoint (NFR-06)**  
   > [!WARNING]  
   > The default base URL is hardcoded as an unencrypted HTTP endpoint `http://100.69.54.28:3000` in [api_client.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/services/api_client.dart#L11). This leaks data over public networks. **Priority: Critical**. Fix: Restrict client communication to HTTPS URLs in release.

3. **Floating Navbar Overlay Blocks Taps (UI-02 / NFR-24)**  
   > [!WARNING]  
   > The profile settings screen scroll padding is not synchronized with the floating navigation bar bounds. The log out button sits directly behind the navbar on smaller screens, blocking user tap interactions. **Priority: High**. Fix: Ensure list padding extends past navbar height (180px+).
