# DealSouk Admin Access

Date: 2026-06-13
Branch: `stabilize/mvp-audit`

DealSouk does not use a hardcoded production admin username or password.

Admin access is:

1. A Firebase Auth user account.
2. A Neon Postgres `User` row with `isAdmin=true`.
3. Firebase custom claims synced by the backend admin script.

## Create The Admin Login

Before creating admins, verify the backend Firebase service account can manage Firebase Auth custom claims:

```bash
cd backend
npx ts-node scripts/audit-claims.ts
```

If this fails with `auth/insufficient-permission`, grant the backend service account the Google Cloud IAM role:

```text
Firebase Authentication Admin
roles/firebaseauth.admin
```

Choose one of these options.

### Option A: Create The User In Firebase Console

1. Open Firebase Console.
2. Go to:

```text
Authentication -> Users -> Add user
```

3. Create the admin email/password account.
4. Copy the Firebase UID.

Then promote the user locally:

```bash
cd backend
npm run admin:set -- --uid FIREBASE_UID_HERE --admin
```

### Option B: Sign Up Through The App First

1. Open the DealSouk app or admin web login.
2. Sign in with the email/phone/Google/Apple account you want to use as admin.
3. Promote the same user:

```bash
cd backend
npm run admin:set -- --email admin@example.com --admin
```

## Revoke Admin Access

```bash
cd backend
npm run admin:set -- --email admin@example.com --no-admin
```

or:

```bash
cd backend
npm run admin:set -- --uid FIREBASE_UID_HERE --no-admin
```

## Audit Admin Claims

```bash
cd backend
npx ts-node scripts/audit-claims.ts
```

This checks for mismatches between Firebase custom claims and the Neon database `isAdmin` field.

## Login URL

Use the web admin portal:

```text
https://deal-souk.vercel.app
```

Only users with admin role can access the admin dashboard. Normal authenticated users are sent to the unauthorized screen.
