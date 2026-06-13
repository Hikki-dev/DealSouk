# DealSouk Security Audit & Risk Assessment

**Branch**: `stabilize/mvp-audit`
**Focus**: Mobile Auth, API Access Controls, Data Integrity, Infrastructure Compliance

---

## 1. Authentication & Access Control

### Firebase Auth Verification
* **Mechanisms**: Client authenticates with Firebase Auth (Phone OTP, Google, Apple). The Firebase ID Token (JWT) is sent in the `Authorization: Bearer <token>` header of all backend requests.
* **Backend Validation**: The Express backend uses `firebase-admin` to verify the ID token cryptographically (`admin.auth().verifyIdToken(token)`) on each request. No local user session database is kept, ensuring token validity is checked in real-time.

### Admin Role-Based Access Control (RBAC)
* **Design**: Standard users are limited to consumer routes. Admin access requires a specific boolean attribute `isAdmin` set to `true` in the PostgreSQL `User` record.
* **Code Enforcement**: The `requireAdmin` middleware checks `req.isAdmin`. Route guards on the frontend (`route_guard.dart`) redirect non-admin users trying to access `/admin` to `/unauthorized`.
* **MFA Gaps**: Admin multi-factor authentication (MFA) is currently **MISSING** in the MVP. In production, Firebase Auth must enforce MFA for all accounts with admin status, and the backend middleware must verify the MFA claim in the token:
  ```typescript
  // TODO: Verify decodedToken.firebase.sign_in_attributes.mfa_verified === true
  ```

---

## 2. Data Integrity & Ledger Security

### Token Ledger Immutability
* **Design**: User tokens are updated by the backend only. A separate `TokenTransaction` table records every balance modification (earn/spend/refund) with a timestamp, user ID, amount, and reason.
* **Risk**: PostgreSQL database records are mutable by admins with direct database access.
* **Mitigation**: Post-MVP, cryptographic hashing (chaining transactions) or a secure append-only audit trail should be configured to prevent database tampering.

---

## 3. Media & Upload Security

### Upload Vulnerabilities
* **Current Status**: Submissions allow passing a `receiptUrl` referencing Firebase Storage. The client uploads images directly to storage.
* **Signed URLs**: Instead of allowing the client direct write access to public storage, the backend should generate restricted, short-lived **Cryptographic Signed Upload URLs** for target folders.
* **Firebase Storage Rules**: Firebase Storage security rules must be strictly configured to restrict read access to authorized moderation roles and write access to authenticated users:
  ```javascript
  match /receipts/{userId}/{fileName} {
    allow read: if request.auth != null && (request.auth.uid == userId || request.auth.token.admin == true);
    allow write: if request.auth != null && request.auth.uid == userId && request.resource.size < 5 * 1024 * 1024;
  }
  ```
* **Server-Side Malware Scan**: Storage upload buckets should trigger an automated malware scanning function (e.g., ClamAV on Cloud Run) to verify images before they are approved or visible.
* **Image Metadata Stripping**: Uploaded image EXIF metadata (which contains precise GPS coordinates, device models, and camera details) must be stripped server-side (using sharp/imagemagick) before persistence to protect shopper privacy.

---

## 4. API & Network Security

### Rate Limiting
* **Global Rate Limiting**: Helmet and `express-rate-limit` protect the backend API.
* **Route Limits**: Specific endpoints have tight rate-limiting thresholds (e.g., auth check: 10/min, price submissions: 5/min, flags: 10/min, profile updates: 20/min, account deletions: 3/min) to prevent brute-force attacks and scraper spam.

### CORS Settings
* **Configuration**: CORS is strictly configured in `backend/src/index.ts`. Production environments require `ALLOWED_ORIGINS` to contain explicit frontend domains (e.g., `https://deal-souk.vercel.app`). Arbitrary origin requests fail.

### Secrets Management
* **Secrets Handling**: No API keys, credentials, or private credentials are committed to Git. `lib/firebase_options.dart` and `backend/.env` are ignored. Environment variables are injected through Vercel and Render settings panels.
* **API Validation**: Route parameters and JSON bodies are validated using size limits (1 MB body limit) and strict type boundaries.

---

## 5. Operations & Compliance

### Dependency Scanning
* **Current Checks**: `npm audit` is executed during CI builds to verify backend packages. Transitive advisories inside long-term SDKs (like Firebase Admin) are monitored.

### SAST / DAST
* **Status**: Automated static code scanning is handled through custom secret scanners (`scripts/secret_scan.py`) in GitHub Actions. Full DAST (Dynamic Application Security Testing) is deferred to post-MVP.

### Penetration Testing
* **Plan**: Independent penetration testing of the backend REST endpoints and mobile application security boundaries should be scheduled prior to the public app store launch.

### Audit Logs
* **System Logging**: The `AdminUserAction` database table logs all moderation events (warnings, suspensions, bans). System console output logs operational exceptions securely without printing user PII.

### Database Backup Encryption
* **Status**: Database backups on Neon Postgres are encrypted at rest using AES-256 and managed by the cloud host.

### Incident Response Plan
* **Gaps**: A formal security incident response runbook should be written post-MVP detailing steps for token balance inflation recovery, database leakage notifications, and Firebase credential rotation.

---

## 6. Related Security Reviews

For deeper deep-dives into specific components, refer to:
* **[DB_SECURITY_REVIEW.md](file:///Users/hikki/Desktop/DealSouk/docs/DB_SECURITY_REVIEW.md)**: Query safety, atomic transactions, double-spend protections, and index structures.
* **[FIREBASE_STORAGE_SECURITY.md](file:///Users/hikki/Desktop/DealSouk/docs/FIREBASE_STORAGE_SECURITY.md)**: Firebase Storage security rules, size limits, user directory isolation, and metadata blockers.
