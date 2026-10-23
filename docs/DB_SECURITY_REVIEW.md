# DealSouk Database Security & Integrity Review

**Date**: June 13, 2026
**Active Workspace Branch**: `stabilize/mvp-audit`

This document audits the database schemas, access patterns, parameterized query compliance, and transaction atomicity protections of the DealSouk platform.

---

## 🛡️ 1. Query Safety & SQL Injection Prevention

* **ORM Usage**: DealSouk utilizes Prisma ORM with standard query APIs (`findUnique`, `findFirst`, `create`, `update`, `updateMany`). Under the hood, Prisma compiles these into fully parameterized queries.
* **Raw SQL Scan**: Ran a static analysis query for raw query operators (`$queryRaw`, `$executeRaw`, `queryRawUnsafe`, `executeRawUnsafe`). No raw SQL calls exist in the codebase.
* **SQL Injection Risk**: **Passed**. Raw queries are not utilized, eliminating SQL injection vulnerability.

---

## ⚡ 2. Concurrency, Race Conditions, and Double-Spending Gaps

We hardened the API endpoints to handle concurrent operations atomically, preventing double-spend and duplicate state transition attacks:

### A. Price Request Creation & Token Deduction
* **Risk**: User attempts to create requests simultaneously.
* **Implementation**: Creation uses `spendTokens()` which queries the user's current token balance, verifies sufficiency, and executes a database `$transaction` to atomically record a negative `TokenTransaction` and decrement `User.tokenBalance`.

### B. Price Request Fulfillment & Double Rewards
* **Risk**: Two sourcers fulfill the same request concurrently.
* **Hardening**: `/requests/:id/fulfill` transitions status using an atomic conditional update:
  ```typescript
  const updated = await prisma.priceRequest.updateMany({
    where: { id: req.params.id, status: "open" },
    data: { status: "fulfilled", fulfilledBy: req.userId },
  });
  ```
  Only the single thread that successfully transitions the record from `"open"` to `"fulfilled"` (where `updated.count === 1`) is allowed to award the bounty tokens to the sourcer.

### C. Request Cancellation & Double Refunds
* **Risk**: A requester triggers cancellation requests concurrently.
* **Hardening**: `DELETE /requests/:id` transitions status atomically:
  ```typescript
  const updated = await prisma.priceRequest.updateMany({
    where: { id: req.params.id, requesterId: req.userId!, status: "open" },
    data: { status: "refunded" },
  });
  ```
  Tokens are refunded if and only if the single thread successfully transitions the record from `"open"` to `"refunded"`.

### D. Lazy Expiry Refunding
* **Risk**: Concurrent queries to `/requests/board` trigger duplicate refund operations on expired requests.
* **Hardening**: Refunding expired items is guarded atomically:
  ```typescript
  const updated = await prisma.priceRequest.updateMany({
    where: { id: r.id, status: "open" },
    data: { status: "expired" },
  });
  ```
  Tokens are refunded only to the thread that successfully transitions status to `"expired"`.

### E. Admin Submission Approval & Double Rewards
* **Risk**: Multiple administrators approve the same submission.
* **Hardening**: `/admin/submissions/:id/approve` enforces atomic state transitions:
  ```typescript
  const updated = await prisma.priceSubmission.updateMany({
    where: { id: req.params.id, status: { not: 'approved' } },
    data: { status: 'approved' },
  });
  ```
  Token rewards and user streaks are only updated if the transition successfully completes.

### F. Voucher Request Approval & Inventory Allocation
* **Risk**: Simultaneous voucher approval triggers double allocation, token overspending, or duplicate code deliveries.
* **Hardening**: `/admin/vouchers/:id/approve` is wrapped in an interactive database transaction block (`prisma.$transaction(async (tx) => { ... })`). It locks the request, verifies user balances, secures an unused inventory item (`isUsed: false`), locks the code, deducts the tokens, and updates the request status atomically.

---

## 🔍 3. Input Validation & Boundaries

The backend strictly validates inputs before writing to the database:
* **JSON Size Limits**: Request bodies are capped at `1MB` (via `express.json` parser).
* **Price Bounds**: Submissions require a positive `priceAed` value up to `10,000 AED`.
* **String Constraints**: Product requests are validated to be under `120 characters` to prevent buffer/UI overflows.
* **Receipt Formats**: Uploaded receipt references must be valid HTTPS URLs under `2048 characters`.
* **Expiration Rules**: Price submissions are assigned a server-computed 72-hour `expiresAt` timestamp, which is verified server-side on queries. Daily cap counters verify the user's total submissions since the start of the current calendar day.

---

## 📊 4. Database Schema Indexes & Constraints

Prisma schema maintains correct unique constraints (`User.firebaseUid`, `Product.barcode`, `VoucherInventory.code`). Essential indexes are established:
* **`Store`**: `@@index([lat, lng])` for proximity queries.
* **`Product`**: `@@index([name])`, `@@index([category])` for search.
* **`PriceSubmission`**: `@@index([productId, storeId, submittedAt])` and `@@index([status, submittedAt])` for feed sorting.

### ⚡ Index Addition (Implemented & Deployed)
* **Affected Table**: `PriceRequest`
* **Action**: Added `@@index([requesterId])` to the `PriceRequest` model in `schema.prisma` to optimize user request history lookup performance (`GET /requests/mine`).
* **Deployment**: The index `"PriceRequest_requesterId_idx"` was successfully created concurrently and verified on the live Neon Postgres database on June 13, 2026.

---

## 🛑 5. User Restriction Enforcement

* **Banned/Suspended Users**: Checked automatically by `requireAuth` middleware on every protected route. Affected users are blocked from creating submissions, flags, or creating/fulfilling requests.
* **Guest Users**: Welcome screen guards assign guests a read-only router token, blocking their access to any write routes on the backend.
