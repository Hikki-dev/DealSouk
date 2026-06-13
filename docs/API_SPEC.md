# DealSouk API Specification

This document details all 27 backend REST API endpoints available in the DealSouk backend service, categorised by module.

---

## 1. Authentication Module

### `POST /auth/verify`
* **Auth Level**: Public
* **Description**: Exchanges a Firebase ID token for a DealSouk user record. If the user does not exist in the Postgres database, a new record is created.
* **Payload**:
  ```json
  { "idToken": "string", "displayName": "string", "homeArea": "string" }
  ```
* **Response (200 OK / 201 Created)**:
  ```json
  { "id": "string", "displayName": "string", "tokenBalance": 0, "isAdmin": false }
  ```

---

## 2. Product Sourcing Module

### `GET /products/search`
* **Auth Level**: Public / Authenticated Guest
* **Query Params**:
  * `q` (string, max 120 chars, optional)
  * `category` (string, max 80 chars, optional)
* **Response (200 OK)**: Array of matching products, enriched with their cheapest approved price (< 72 hours old):
  ```json
  [
    {
      "id": "string",
      "name": "string",
      "brand": "string",
      "packSize": "string",
      "category": "string",
      "lowestPrice": 12.50,
      "lowestPriceStore": "Carrefour",
      "hoursAgo": 5
    }
  ]
  ```

### `GET /products/:id`
* **Auth Level**: Public / Authenticated Guest
* **Response (200 OK)**:
  ```json
  { "id": "string", "name": "string", "brand": "string", "packSize": "string", "category": "string" }
  ```

### `GET /products/:id/prices`
* **Auth Level**: Public / Authenticated Guest
* **Description**: Returns all fresh approved price submissions for a product (within last 72 hours).
* **Response (200 OK)**:
  ```json
  [
    {
      "id": "string",
      "priceAed": 10.50,
      "hasReceipt": true,
      "submittedAt": "date-string",
      "hoursAgo": 3,
      "store": { "id": "string", "chain": "string", "branchName": "string", "area": "string" }
    }
  ]
  ```

### `GET /products/:id/history`
* **Auth Level**: Public / Authenticated Guest
* **Query Params**: `days` (number, default 90, max 90)
* **Response (200 OK)**: Array of historical approved prices for trend views:
  ```json
  [
    {
      "id": "string",
      "priceAed": 11.00,
      "submittedAt": "date-string",
      "store": { "id": "string", "chain": "string", "branchName": "string" }
    }
  ]
  ```

---

## 3. Submissions Module

### `GET /submissions/feed`
* **Auth Level**: Public
* **Query Params**: `page` (number, default 0), `limit` (number, default 20)
* **Response (200 OK)**:
  ```json
  [
    {
      "id": "string",
      "priceAed": 5.90,
      "hasReceipt": false,
      "submittedAt": "date-string",
      "hoursAgo": 1,
      "product": { "id": "string", "name": "string" },
      "store": { "id": "string", "chain": "string" }
    }
  ]
  ```

### `POST /submissions`
* **Auth Level**: Authenticated User (Rate limited: 5/min)
* **Payload**:
  ```json
  { "productId": "string", "storeId": "string", "priceAed": 45.00, "hasReceipt": true, "receiptUrl": "string" }
  ```
* **Response (201 Created)**:
  ```json
  { "id": "string", "status": "pending", "tokensAwarded": 75, "expiresAt": "date-string" }
  ```

### `POST /submissions/:id/flag`
* **Auth Level**: Authenticated User (Rate limited: 10/min)
* **Payload**:
  ```json
  { "reason": "price_wrong | product_mismatch | store_wrong | duplicate" }
  ```
* **Response (200 OK)**:
  ```json
  { "flagCount": 1, "hidden": false }
  ```

### `GET /submissions/estimate`
* **Auth Level**: Authenticated User
* **Query Params**: `productId` (string), `storeId` (string), `hasReceipt` (boolean string)
* **Response (200 OK)**:
  ```json
  { "estimatedTokens": 50 }
  ```

---

## 4. Price Request Board Module

### `GET /requests/board`
* **Auth Level**: Public
* **Response (200 OK)**: List of active open price requests:
  ```json
  [
    { "id": "string", "productName": "string", "storeName": "string", "bountyTokens": 20, "createdAt": "date-string" }
  ]
  ```

### `GET /requests/mine`
* **Auth Level**: Authenticated User
* **Response (200 OK)**: Alias route returning active/fulfilled requests.
* **Consistency Note**: Superseded by `GET /profile/me/requests`. Mark for cleanup.

### `POST /requests`
* **Auth Level**: Authenticated User
* **Payload**:
  ```json
  { "productName": "string", "storeName": "string", "bountyTokens": 10 }
  ```
* **Response (201 Created)**:
  ```json
  { "id": "string", "productName": "string", "bountyTokens": 10 }
  ```

### `POST /requests/:id/fulfill`
* **Auth Level**: Authenticated User
* **Payload**:
  ```json
  { "submissionId": "string" }
  ```
* **Response (200 OK)**:
  ```json
  { "ok": true, "bountyAwarded": 10 }
  ```

---

## 5. Profile & Cart Module

### `GET /profile/me`
* **Auth Level**: Authenticated User
* **Response (200 OK)**:
  ```json
  {
    "id": "string",
    "displayName": "string",
    "tokenBalance": 120,
    "accuracyRating": 98.5,
    "dailyCapRemaining": 28,
    "level": 3,
    "badges": []
  }
  ```

### `GET /profile/me/cart`
* **Auth Level**: Authenticated User
* **Response (200 OK)**: Current grocery list items.

### `PUT /profile/me/cart`
* **Auth Level**: Authenticated User
* **Payload**:
  ```json
  { "items": [ { "productId": "string", "quantity": 1 } ] }
  ```
* **Response (200 OK)**:
  ```json
  { "ok": true, "count": 1 }
  ```

### `GET /profile/me/transactions`
* **Auth Level**: Authenticated User
* **Response (200 OK)**: History of token earns/spends.

### `GET /profile/me/vouchers`
* **Auth Level**: Authenticated User
* **Response (200 OK)**: Requested vouchers and codes.

### `GET /profile/me/submissions`
* **Auth Level**: Authenticated User
* **Response (200 OK)**: User's submission history.

### `GET /profile/me/requests`
* **Auth Level**: Authenticated User
* **Response (200 OK)**: User's request history.

### `POST /profile/me/fcm-token`
* **Auth Level**: Authenticated User
* **Payload**:
  ```json
  { "fcmToken": "string" }
  ```
* **Response (200 OK)**:
  ```json
  { "ok": true }
  ```

### `DELETE /profile/me`
* **Auth Level**: Authenticated User (Rate limited: 3/min)
* **Description**: Triggers account deletion and scrubs PII.
* **Response (200 OK)**:
  ```json
  { "message": "Account deletion requested. PII will be removed within 30 days." }
  ```

---

## 6. Admin Module

### `GET /admin/queue`
* **Auth Level**: Admin Only
* **Response (200 OK)**: Pending and flagged items for moderation.

### `POST /admin/submissions/:id/approve`
* **Auth Level**: Admin Only
* **Response (200 OK)**: Approves submission and awards tokens.

### `POST /admin/submissions/:id/reject`
* **Auth Level**: Admin Only
* **Response (200 OK)**: Rejects submission and deducts accuracy rating.

### `GET /admin/submissions/:id`
* **Auth Level**: Admin Only
* **Response (200 OK)**: Returns full moderation details.

### `POST /admin/users/:id/warn`
* **Auth Level**: Admin Only
* **Payload**:
  ```json
  { "reason": "string" }
  ```
* **Response (200 OK)**:
  ```json
  { "ok": true }
  ```

### `POST /admin/users/:id/suspend`
* **Auth Level**: Admin Only
* **Payload**:
  ```json
  { "reason": "string", "durationDays": 7 }
  ```
* **Response (200 OK)**:
  ```json
  { "ok": true }
  ```

### `POST /admin/users/:id/ban`
* **Auth Level**: Admin Only
* **Payload**:
  ```json
  { "reason": "string" }
  ```
* **Response (200 OK)**:
  ```json
  { "ok": true }
  ```

### `GET /admin/settings`
* **Auth Level**: Admin Only
* **Response (200 OK)**: System configuration constants (caps, earn rates, decay factor).

---

## 7. Consistency & Route Inconsistencies

1. **`GET /requests/mine` vs `GET /profile/me/requests`**: These are duplicate actions. `/requests/mine` should be deprecated in favour of `/profile/me/requests` to align with the rest of the `/profile/me/*` nested scheme.
2. **`GET /submissions/estimate`**: Placed under `/submissions/estimate` but does not perform a write action. Strictly speaking, it should be nested as a GET query parameter or under `/products/:id/estimate` since it estimates the value of a specific product submission.
3. **`GET /admin/submissions/:id`**: Missing route wrapper in actual code (currently admins retrieve individual submissions through the general `/queue` mapping). We must add this route post-MVP or verify client dashboard doesn't request it individually.
