# Demo mode

Demo mode runs the **whole stack on your computer** with **no Firebase project, no Neon database and no accounts**: the real shopper app, the real moderator portal and the real API. It uses a Postgres on your computer and the Firebase **Auth emulator**, which is a pretend copy of Firebase Authentication. It is how the screenshots in the README were taken.

## What you get

* **18 Dubai stores, 20 products and 175 approved prices**, made by the project's own seed script, and 13 badges.
* **Twelve made-up people:** a shopper with a history, a moderator, and ten others who fill the leaderboard (for example Hassan Al Mansoori and Meera Krishnan).
* **A leaderboard** for this month, **price requests** with bounties, **a review queue** with 11 submissions (one flagged twice), a **voucher queue** with 3 requests, and a **voucher stock**.
* **Two accounts** in the Auth emulator:

| Account | Role | What it has |
|---|---|---|
| `priya@example.com` (Priya Nair) | Shopper | 14 approved prices, 2 waiting, 3 badges, a 6 day streak, 620 tokens, a voucher request |
| `omar@example.com` (Moderator Omar) | Moderator | The moderator console |

What it does **not** have: photo uploads (there is no Firebase Storage), push messages, the optional AI photo check, and product pictures, which come from Unsplash and need the internet.

## What you need

* The [Flutter SDK](https://docs.flutter.dev/get-started/install).
* Node 20 or newer, and `npx`.
* A Postgres on your computer (version 14 or newer). The easy way is Docker.
* `openssl`, which most computers already have.

## Run it

**1. Make the two git-ignored files.** This fills them with fake values and a throwaway key. It never overwrites a file you already have.

```bash
bash demo/prepare.sh
```

It makes `lib/firebase_options.dart` and `backend/.env`.

**2. Start a Postgres.** With Docker:

```bash
docker run -d --name dealsouk-db -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_DB=dealsouk -p 5432:5432 postgres:16
```

If you already have a Postgres, create an empty database and change `DATABASE_URL` in `backend/.env`.

**3. Start the Auth emulator** and leave this terminal open:

```bash
npx firebase-tools emulators:start --only auth --project demo-dealsouk
```

It listens on `127.0.0.1:9099` (see `firebase.json`).

**4. Fill the database**, in a second terminal:

```bash
bash demo/seed.sh
```

It applies the migrations, runs `npm run seed` and `npm run seed:demo`, and creates the two accounts in the emulator. It refuses to run against a database that is not on your computer.

**5. Start the API:**

```bash
cd backend
npm run dev
```

Check `http://localhost:3000/health`.

**6. Start an app**, in a third terminal. The shopper:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=USE_FIREBASE_EMULATORS=true
```

The moderator portal is the same command with `--dart-define=ADMIN_MODE=true`.

## Signing in

The apps sign in with Google, a phone code or Apple. In demo mode, **Continue with Google** opens a small page from the Firebase emulator where you pick an account instead of typing a password. Pick **Priya Nair** to be the shopper, or **Moderator Omar** to be the moderator in the portal. (Tick the privacy box first, or press **Browse as Guest** to look around without signing in.) Allow pop-ups for the page.

You can also add a brand new account on that page. A new account starts empty, and to make it a moderator run, in `backend`:

```bash
npm run admin:set -- --email you@example.com --admin
```

### Signing in from a script

`backend/scripts/demo-token.ts` prints a sign-in token for a demo account, which is handy for tests and screenshots:

```bash
cd backend
set -a; . ./.env; set +a
npx ts-node scripts/demo-token.ts demo-shopper-1             # a custom token
npx ts-node scripts/demo-token.ts demo-admin-1 --id-token    # an ID token for curl
curl http://localhost:3000/profile/me -H "Authorization: Bearer $(npx ts-node scripts/demo-token.ts demo-shopper-1 --id-token)"
```

## What the pieces do

| Piece | What it does |
|---|---|
| `demo/prepare.sh` | Makes `lib/firebase_options.dart` from `demo/firebase_options.demo.dart` and `backend/.env` with a throwaway key |
| `demo/seed.sh` | Migrates and seeds the database, and makes the two Auth emulator accounts |
| `backend/prisma/demo.ts` (`npm run seed:demo`) | The twelve people, the leaderboard, requests, the review queue and vouchers. It refuses a database that is not on your computer |
| `backend/scripts/demo-token.ts` | Makes the demo accounts in the emulator and prints a token |
| `USE_FIREBASE_EMULATORS` | A flag in `lib/main.dart` that points Firebase Auth at the emulator. Without it nothing changes |
| `FIREBASE_AUTH_EMULATOR_HOST` | Set in `backend/.env`. It tells the API's Firebase Admin library to accept the emulator's tokens |

## Good to know

* The emulator keeps nothing. When you stop it, the accounts are gone. Start it again and run `bash demo/seed.sh`, which makes them again. The database keeps its rows, so seeding twice is safe.
* A shopper's **cart** is not filled in on purpose. See the [known issues](../README.md#known-issues).
* To start the database again, run `docker rm -f dealsouk-db` and the `docker run` command above.
* On the web, Firebase's JavaScript comes from Google's servers, so you need the internet for that.
* Never use the demo's `lib/firebase_options.dart` or the demo accounts with a real project.
