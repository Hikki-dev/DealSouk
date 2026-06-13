# DealSouk Owner Production Actions

Date: 2026-06-13
Branch: `stabilize/mvp-audit`

This checklist covers production blockers that require external account access or legal review. Repo-level implementation for upload sanitization is now present; deployment and console configuration still need owner action.

## 0. Fix Firebase Auth Admin IAM

Current local audit result:

```text
backend/scripts/audit-claims.ts fails with auth/insufficient-permission
```

This means the Firebase Admin service account used by the backend can initialize, but does not currently have enough IAM permission to list/audit Firebase Auth users or reliably sync admin custom claims.

Fix in Google Cloud Console:

1. Open:

```text
Google Cloud Console -> IAM & Admin -> IAM
```

2. Select project:

```text
dealsouk-6e140
```

3. Find the service account matching Render/backend `FIREBASE_CLIENT_EMAIL`.
4. Add this role:

```text
Firebase Authentication Admin
roles/firebaseauth.admin
```

5. Save and wait about 60 seconds.
6. Verify locally:

```bash
cd backend
npx ts-node scripts/audit-claims.ts
```

This must pass before treating admin creation/claim sync as production-ready.

## 1. Deploy Upload Scanning And EXIF Stripping

Repo implementation:

- Firebase Storage trigger: `firebase/functions/src/index.ts`
- ClamAV scanner service: `services/malware-scanner`
- Storage rules: `firebase/storage.rules`

Deploy scanner:

```bash
gcloud run deploy dealsouk-malware-scanner \
  --source services/malware-scanner \
  --project dealsouk-6e140 \
  --region me-central1 \
  --no-allow-unauthenticated
```

Grant scanner read access to the Firebase Storage bucket. Replace `PROJECT_NUMBER` with the Google Cloud project number:

```bash
gcloud storage buckets add-iam-policy-binding gs://dealsouk-6e140.firebasestorage.app \
  --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/storage.objectViewer" \
  --project dealsouk-6e140
```

Grant Firebase Functions permission to invoke the private scanner:

```bash
gcloud run services add-iam-policy-binding dealsouk-malware-scanner \
  --project dealsouk-6e140 \
  --region me-central1 \
  --member="serviceAccount:dealsouk-6e140@appspot.gserviceaccount.com" \
  --role="roles/run.invoker"
```

Set scanner URL secret:

```bash
firebase functions:secrets:set MALWARE_SCAN_URL --project dealsouk-6e140
```

Deploy function and rules:

```bash
cd firebase/functions
npm install
npm run build
cd ../..
firebase deploy --only functions,storage --project dealsouk-6e140
```

Verify by uploading a test image and checking object metadata:

```text
dealsoukProcessed=true
exifStripped=true
malwareScanStatus=clean
```

## 2. Restrict Google/Firebase Client API Keys

Open Google Cloud Console:

```text
APIs & Services -> Credentials
```

Restrict each DealSouk client key:

| Client | Application restriction | API restrictions |
|---|---|---|
| Android | Android apps: package `com.dealsouk.dealsouk` + SHA-1/SHA-256 signing fingerprints | Firebase Auth, FCM, Firebase Storage, Google Sign-In APIs used by the app |
| iOS | iOS apps: final bundle ID from Xcode/Firebase app registration | Firebase Auth, FCM, Firebase Storage, Google Sign-In APIs used by the app |
| Web/Admin | HTTP referrer: `https://deal-souk.vercel.app/*` plus protected preview domains if needed | Firebase Auth APIs required by admin web |

Get Android debug SHA locally:

```bash
cd android
./gradlew signingReport
```

For release SHA, use the upload/release keystore once App Store/Play Store signing is no longer deferred.

## 3. Configure APNs For iOS Push Notifications

In Apple Developer:

```text
Certificates, Identifiers & Profiles -> Keys -> Add Key
```

Create an APNs Auth Key with Apple Push Notifications enabled. Download the `.p8` file once.

In Firebase Console:

```text
Project Settings -> Cloud Messaging -> Apple app configuration
```

Upload:

- APNs Auth Key `.p8`
- Key ID
- Team ID
- iOS bundle ID

Then test FCM on a real iOS device with a production-capable profile.

## 4. Complete UAE PDPL Legal Review

Documents to send to legal counsel:

- `docs/PRIVACY_POLICY.md`
- `docs/PRIVACY_COMPLIANCE.md`
- in-app English/Arabic legal strings in `lib/l10n/`
- media upload behavior documented in `docs/FIREBASE_STORAGE_SECURITY.md`

Ask legal to confirm:

- Arabic and English policy wording.
- Explicit consent wording for location and photo uploads.
- Account deletion/anonymization wording.
- Data processor list: Firebase, Google Cloud, Render, Vercel, Neon.
- Region/data residency wording, especially because current Neon hosting may not match the PRD's preferred Google Cloud `me-central1` assumption.

Do not mark public production ready until approved copy is committed into the app.
