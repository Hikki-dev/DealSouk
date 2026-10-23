# Getting into the apps and showing them off

DealSouk is **one codebase that builds two apps**. A build setting called `ADMIN_MODE` decides which one you get.

| App | Who it is for | `ADMIN_MODE` | Where it lives |
|---|---|---|---|
| **Moderator console** | Moderators and admins | `true` | https://deal-souk.vercel.app |
| **Shopper app** | Customers | `false` (default) | https://deal-souk-shopper.vercel.app, and Android APKs from GitHub |

Each app is its own website (its own Vercel project), built from the same code. Want visitors to look around the console without being able to change anything? See [Demo mode](Demo%20mode.md).

---

## 1. Get into the moderator console

You need two things: the site, and an account that has been made a moderator.

### Step 1. Sign in once

1. Open https://deal-souk.vercel.app.
2. Sign in with Google, Apple or phone.
3. A brand new account is a **shopper**, so you land on **"Unauthorized: This area is only available to admin users."** That is expected. Go to step 2.

### Step 2. Make your account a moderator

This runs on a computer that has the backend settings. It does two things at once: it sets `isAdmin` in the database and it adds an `admin` claim to your Firebase account.

```bash
cd backend
cp .env.example .env        # then fill in DATABASE_URL, DATABASE_ENCRYPTION_KEY and the FIREBASE_* values
npm install
npm run admin:set -- --email you@example.com --admin
```

It prints `Your Name (uid) admin=true` when it works. To take the role away again, use `--no-admin`. You can also use `--uid <firebase uid>` instead of `--email`.

The account must already exist, so do step 1 first.

### Step 3. Sign in again

Sign out, then sign in. Your sign-in token carries the role, so an old session still says "shopper". The console also refreshes the token once by itself, but signing out and in is the sure way. You should now land on the moderator console.

### If it does not work

| What you see | Why | Fix |
|---|---|---|
| "Unauthorized" again after step 2 | The old token has no admin claim | Sign out and in again. If it persists, run the script again and check it printed `admin=true`. |
| The sign-in spins for about 50 seconds | The API on Render sleeps when idle | Wait once. The "Keep Backend Warm" GitHub workflow pings it every 10 minutes to reduce this. |
| `Admin multi-factor authentication required` | `ADMIN_MFA_REQUIRED=true` on the API | Sign in with a second factor, or set it to `false` for a demo. |
| Google sign-in is blocked on a new web address | The address is not an authorised domain in Firebase | Firebase Console, Authentication, Settings, **Authorized domains**, add it. |
| The map is blank | `MAPBOX_ACCESS_TOKEN` is not set in Vercel | See the next section. |

### Vercel settings the console needs

In the `deal-souk` Vercel project, Settings, Environment Variables:

| Name | What it is |
|---|---|
| `API_BASE_URL` | The backend address, for example `https://dealsouk.onrender.com` (required, must be https) |
| `FIREBASE_OPTIONS_DART_B64` | The generated `lib/firebase_options.dart`, base64 encoded (required) |
| `MAPBOX_ACCESS_TOKEN` | A restricted public Mapbox token starting with `pk.` (needed for the maps) |

Changing a variable needs a redeploy: Deployments, the latest one, Redeploy.

---

## 2. Show the shopper app

Pick whichever suits the moment. The quickest is the website: open https://deal-souk-shopper.vercel.app on a phone and use **Share, Add to Home Screen**.

### A. Android phone (best for a real demo)

Every push to `main` builds the APKs.

1. On GitHub open **Actions**, then **Android Internal APK**, then the latest green run.
2. Under **Artifacts** download `Dealsouk-Shopper-APK` (use `DealSouk-Shopper.apk`). `Dealsouk-Admin-APK` is the moderator app.
3. Send the file to a phone and open it. Android asks you to allow installs from that source.

When you push a tag such as `v2.1.0`, the same APKs are attached to a GitHub **Release**, which gives you a download link you can share.

### B. The shopper app on the web

https://deal-souk-shopper.vercel.app. How the two Vercel projects are set up is in [Deploying](Deploying.md).

### C. Run it on your own computer

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://dealsouk.onrender.com \
  --dart-define=MAPBOX_ACCESS_TOKEN=pk...
```

For the moderator console add `--dart-define=ADMIN_MODE=true`. To fake a phone, open the browser's developer tools and pick a phone size, or run `flutter run` with an Android emulator or a USB-connected phone.

You need your own `lib/firebase_options.dart`. It is not in git. The README explains `flutterfire configure`.

### D. Let visitors look around the console

See [Demo mode](Demo%20mode.md).

---

## Quick reference: build settings

| Setting | Used by | Meaning |
|---|---|---|
| `ADMIN_MODE` | Flutter build | `true` builds the moderator console, `false` the shopper app |
| `API_BASE_URL` | Flutter build | Backend address, must be https in release |
| `MAPBOX_ACCESS_TOKEN` | Flutter build | Map tiles |
| `APP_MODE` | `vercel_build.sh` | `admin` (default) or `shopper`, sets `ADMIN_MODE` for you |
| `ADMIN_MFA_REQUIRED` | Backend | Require a second factor for the admin API |
| `ADMIN_DEMO_VIEWERS` | Backend | Let any signed-in person view the console, read-only. See [Demo mode](Demo%20mode.md) |
