# DealSouk Privacy & PDPL Compliance Document

This document summarizes the privacy controls, user consent grids, and compliance status for DealSouk under the **UAE Personal Data Protection Law (Federal Decree-Law No. 45 of 2021 on Personal Data Protection - PDPL)**.

---

## 1. Regulatory Compliance (UAE PDPL)

### User Consent & Transparency
* **Requirements**: Personal data (such as phone numbers, display names, and home areas) may only be processed with clear, unambiguous user consent.
* **Consent Goggles**: During the onboarding flow on the Welcome Screen, users must check a box indicating they agree to the DealSouk Terms and Privacy Policy before registration or OTP verify can proceed.

### Location Consent
* **Wording & Purpose**: Location access is strictly required to calculate distances and filter nearby supermarket price listings.
* **Implementation**: The app uses location services under the "When In Use" minimum scope. A pre-permission explainer is shown in-app before triggering the OS location dialog to inform users: *"We use your location only to show nearby supermarket prices."* Precise coordinates are never stored on the backend or kept in database logs.

### Analytics Consent
* **Status**: Local/in-app analytics trackers must provide users with an opt-out toggle within the Profile settings screen.

---

## 2. Data Lifecycle & Retention

### Account Deletion
* **Database Anonymisation**: In accordance with the PDPL "Right to Be Forgotten," users can trigger account deletion from the profile screen (`DELETE /profile/me`). To preserve the integrity of the public token ledger and leaderboard analytics, the user record is anonymized:
  * Display name is replaced with `[Deleted User]`
  * Phone number is set to `null`
  * Home area is set to `null`
  * Firebase UID is replaced with `deleted_[userId]`
* **Firebase Account Deletion**: The anonymization process must also trigger the deletion of the corresponding user record in Firebase Auth:
  ```typescript
  // TODO: Add Firebase Auth deletion inside DELETE /profile/me
  // await adminFirebase.auth().deleteUser(req.firebaseUid!);
  ```
* **PII Expiry Bounds**: All personal identifiable information is completely scrubbed from active backups within 30 days of the request.

### GPS Non-Persistence Policy
* **Rule**: Shoppers' precise latitude and longitude values are sent to the backend only for live sorting queries. These coordinates are processed in-memory in Express server execution threads and are **never** written to database tables or file logs. Stores are stored with static coordinates, not shoppers.

### Receipt Retention & Image Handling
* **Image Deletion**: When a user's price submission is rejected by moderators or expires (after 72 hours), the uploaded receipt or price label image must be scheduled for deletion from the Firebase Storage bucket.
* **Storage Limit**: Inactive/expired receipt images are completely deleted within 30 days of submission expiration.

---

## 3. App Store & Play Store Compliance

### App Store Privacy Labels (iOS)
* **Data Linked to User**: Contact Info (Phone Number), Location (Coarse/Precise), User Content (Receipt Photos), Identifiers (Device ID, User ID).
* **Data Not Linked to User**: Diagnostic data (Sentry logs, crash reports).

### Google Play Data Safety (Android)
* **Location**: Approximate and precise location (accessed when in use).
* **Personal Info**: Name, Phone number, User ID.
* **Photos & Videos**: Photos of grocery receipts/price tags (optional for submission).
* **Security Practices**: Data is encrypted in transit (HTTPS/TLS 1.3). Users can request that their data be deleted.

---

## 4. Legal Disclosures & Documentation

### Privacy Policy & Terms (English / Arabic)
* **Status**: A complete draft is maintained in `docs/PRIVACY_POLICY.md` (English). An Arabic translation (`docs/PRIVACY_POLICY_AR.md`) must be provided for localization compliance in the UAE.
* **Updates**: The documents detail how customer information is processed, the rights to access/delete records, and contact emails for privacy requests.

### Vendor Processors
* **Authorized Processors**:
  * **Firebase** (Google Cloud): Authentication services, file storage, push notifications.
  * **Neon** (Serverless Postgres): Primary application database storage.
  * **Render**: Application backend hosting.
  * **Sentry**: Crash reporting and diagnostics (no PII sent).
