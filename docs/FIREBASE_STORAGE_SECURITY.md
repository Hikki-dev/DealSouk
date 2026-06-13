# DealSouk Firebase Storage Security & Upload Audit

**Date**: June 13, 2026
**Active Workspace Branch**: `stabilize/mvp-audit`

This document reviews image upload safety, folder-based authorization rules, and processing pipelines for receipt, shelf, and user avatar media.

---

## 🔒 1. Firebase Storage Security Rules

The storage bucket is configured with robust rules ([firebase/storage.rules](file:///Users/hikki/Desktop/DealSouk/firebase/storage.rules)) deployed for the project:

### Receipts & Price Labels
* **Path**: `/receipts/{userId}/{fileName}` and `/price-labels/{userId}/{fileName}`
* **Rules**:
  ```javascript
  allow read, write: if request.auth != null
    && request.auth.uid == userId
    && request.resource.size < 8 * 1024 * 1024
    && request.resource.contentType.matches('image/.*');
  ```
* **Security Controls**:
  * **Authentication**: Users must be authenticated to write or read receipt data.
  * **User Isolation**: A user can only access the directory matching their own Firebase UID (`request.auth.uid == userId`). Overwriting or reading other shoppers' receipt documents is blocked.
  * **Payload Limits**: File uploads are restricted to under `8MB` to prevent storage exhaust attacks.
  * **Type Enforcement**: Content-type is strictly validated to be image files only (`image/.*`).

### User Avatars
* **Path**: `/avatars/{userId}/{fileName}`
* **Rules**:
  ```javascript
  allow read: if true;
  allow write: if request.auth != null
    && request.auth.uid == userId
    && request.resource.size < 4 * 1024 * 1024
    && request.resource.contentType.matches('image/.*');
  ```
* **Security Controls**:
  * **Read Access**: Read access is public (`allow read: if true`) so avatars render correctly on leaderboard grids and price feeds.
  * **Write Access**: Restricted only to the owning authenticated user. Payload size is limited to `4MB`.

---

## 🧼 2. Server-Side Media Processing

The repository now includes a Firebase Functions image processor at:

* [firebase/functions/src/index.ts](file:///Users/hikki/Desktop/DealSouk/firebase/functions/src/index.ts)
* [services/malware-scanner](file:///Users/hikki/Desktop/DealSouk/services/malware-scanner)

The function is triggered when a file is finalized in Firebase Storage. It applies the following controls:

* Processes only managed DealSouk upload paths:
  * `receipts/{userId}/{fileName}`
  * `price-labels/{userId}/{fileName}`
  * `avatars/{userId}/{fileName}`
* Rejects unsupported content types and invalid sizes by moving the file into `quarantine/`.
### B. Client-Side EXIF Metadata Stripping (Implemented & Free)
* **Severity**: **Passed**
* **Details**: Audited [storage_service.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/network/storage_service.dart#L12-L30). The Flutter `ImagePicker` is configured with `imageQuality: 75` and `maxWidth: 1200` for all uploads. On Android and iOS, specifying compression parameters triggers native image re-encoding, which naturally strips EXIF GPS coordinates and camera metadata before upload. This is 100% free and consumes zero server resources.
* Marks processed objects with metadata:
  * `dealsoukProcessed=true`
  * `exifStripped=true`
  * `malwareScanStatus=clean|infected|not_configured`

### Malware Scanner Hook

The function calls a scanner endpoint through the `MALWARE_SCAN_URL` Firebase secret.

Expected scanner behavior:

```json
{ "status": "clean" }
```

Any non-`clean` response is treated as infected and the upload is moved to `quarantine/`.

**Production requirement**: deploy the Cloud Run scanner in [services/malware-scanner](file:///Users/hikki/Desktop/DealSouk/services/malware-scanner) and configure `MALWARE_SCAN_URL` before deploying the Firebase Function.

### Deploy Commands

From the repo root:

```bash
gcloud run deploy dealsouk-malware-scanner \
  --source services/malware-scanner \
  --project dealsouk-6e140 \
  --region me-central1 \
  --no-allow-unauthenticated

gcloud run services add-iam-policy-binding dealsouk-malware-scanner \
  --project dealsouk-6e140 \
  --region me-central1 \
  --member="serviceAccount:dealsouk-6e140@appspot.gserviceaccount.com" \
  --role="roles/run.invoker"

firebase functions:secrets:set MALWARE_SCAN_URL --project dealsouk-6e140
cd firebase/functions
npm install
npm run build
cd ../..
firebase deploy --only functions,storage --project dealsouk-6e140
```

After deployment, upload one test image and confirm object metadata includes:

```text
dealsoukProcessed=true
exifStripped=true
```

Also confirm:

```text
malwareScanStatus=clean
```

---

## 👁️ 3. Moderation & Trust Workflow

* **Pending Status**: Newly submitted prices are inserted with a status of `pending`. The receipt image URL is only visible to administrator role accounts via the `/admin/queue` endpoint.
* **Display Restriction**: Submissions do not appear in the public shopper feed (`GET /submissions/feed`) until an admin validates the receipt image and moves the status to `approved`.
* **Flag/Auto-Hide**: If a submission is flagged 3 times by independent users, the status transitions to `hidden`, and access is immediately revoked from the feed.
