# Firebase Authentication IAM Configuration & Audit Guide

This document provides instructions on configuring the Google Cloud Platform (GCP) IAM permissions for the DealSouk service account, enabling custom claims management, user listings, and running security audits.

---

## Google Cloud Console IAM Setup

To audit and assign custom user claims (such as `admin: true`), the GCP service account used by the backend API needs the proper administrative role for Firebase Authentication.

### Step-by-Step Instructions

1. **Open Google Cloud Console**:
   Go to the [GCP IAM & Admin Console](https://console.cloud.google.com/iam-admin/iam).
2. **Select the Project**:
   Select your Firebase project: `dealsouk-6e140`.
3. **Locate the Service Account**:
   Find the service account principal named:
   `dealsouk@dealsouk-6e140.iam.gserviceaccount.com` (or the one matching your backend `FIREBASE_CLIENT_EMAIL` environment variable).
4. **Edit Permissions**:
   Click the **Edit principal** (pencil icon) next to the service account.
5. **Add Role**:
   * Click **Add another role**.
   * Search for and select **Firebase Authentication Admin** (`roles/firebaseauth.admin`).
   * *Note*: This role grants the service account read and write access to authentication users, user metadata, and custom attributes (claims).
6. **Save**:
   Click **Save** to apply the IAM policy change. The permission update usually propagates within 60 seconds.

> [!WARNING]
> Do not grant owner or super-admin credentials to your backend service account key file in production. Limit the permissions strictly to the Firebase Authentication Admin role and Neon database access to satisfy security compliance.

---

## Local Auditing CLI Commands

Once the IAM role is granted, you can run automated claims audits and manage user roles using the following backend scripts:

### 1. Privilege Audit
This script fetches all users from Firebase Auth and cross-references them with the Neon Postgres `User` database rows to detect inconsistencies:
```bash
# Navigate to the backend directory
cd backend

# Run the audit claims script
npx ts-node scripts/audit-claims.ts
```

### 2. Set Admin Role / Sync Privileges
To make a user an Admin (granting both Firebase custom claims and database `isAdmin: true` flag), run:
```bash
# Using email
npx ts-node scripts/set-admin.ts --email admin@dealsouk.com --admin

# Using UID
npx ts-node scripts/set-admin.ts --uid YOUR_FIREBASE_UID --admin
```

To revoke Admin status from a user, run:
```bash
npx ts-node scripts/set-admin.ts --uid YOUR_FIREBASE_UID --no-admin
```

---

## Inconsistency Checklist

The audit script checks for the following security drifts:
* **Firebase-only Admin**: Users with `{ admin: true }` in Firebase who are not flagged as `isAdmin` in the database.
* **Database-only Admin**: Users marked as `isAdmin: true` in Neon Postgres who are missing custom claims in Firebase.
* **Orphaned Firebase Admins**: Admin accounts that were deleted from Postgres but remain active in Firebase Auth.
