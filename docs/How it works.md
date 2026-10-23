# How it works

This page is for people who want to read or change the code.

## The big picture

One Flutter project builds two apps: the shopper app and the moderator console. A setting called `ADMIN_MODE` picks which one at build time.

Both apps call one API, written in TypeScript with Express. The API keeps its data in Postgres through Prisma. Firebase knows who people are, stores photos and sends alerts.

See the picture in the [README](../README.md#how-everything-fits-together).

## The folders

```
lib/                     The Flutter apps
├── app/                 Start-up, routes and the sign-in guard
├── core/
│   ├── design/          The design system: buttons, cards, navigation, photos
│   ├── theme/           Colours, fonts and the theme
│   ├── widgets/         The shell (bottom bar, rail, top bar) and shared pieces
│   ├── localization/    The text size setting
│   └── offline/         The queue that sends things when you are back online
├── features/            One folder per feature (see below)
└── l10n/                English and Arabic text
backend/                 The API
├── src/routes/          One router per area
├── src/services/        Tokens, notifications, encryption, PDF, Redis, storage
├── prisma/              The database schema, migrations and seed
├── scripts/             Make a moderator, audit sign-in claims
└── test/                The API tests
firebase/                Storage rules and Cloud Functions
services/malware-scanner The virus scanner (ClamAV on Cloud Run)
scripts/                 The secret scan
test/screenshots/        Tests that draw every screen
docs/                    This help
.github/workflows/       Checks, Android and iOS builds, web build, keep-warm
```

Features: `admin`, `auth`, `cart`, `home`, `leaderboard`, `legal`, `products`, `profile`, `requests`, `saved`, `stores`, `submissions`, `tokens`. Each has `data`, `domain` and `presentation` folders.

## The pieces, one at a time

1. **Sign-in.** Firebase signs people in with Google, Apple or a phone code. The API checks the Firebase token on every request and keeps a matching user in the database. The moderator role is stored in the database and as a Firebase claim.
2. **Tokens.** Every change to a token balance is written as a transaction that includes the hash of the one before it. The chain can be checked later, so no balance can be changed quietly.
3. **Uploads.** The app asks the API for a signed link, uploads the photo straight to Firebase Storage, and then a Cloud Function removes its location data and the scanner checks it for viruses.
4. **Offline.** If there is no connection, new prices and requests wait in a queue on the phone and are sent when the connection returns.
5. **Roles.** Routes under `/admin` need the moderator role. A moderator can also be forced to use a second sign-in step.

## The design system

The look lives in `lib/core/design/`. Import `design.dart` and use the parts. Read [Design system](Design%20system.md) for the colours, sizes and every part.

The app picks its layout from the width of the window:

| Width | Class | Navigation |
|---|---|---|
| Under 600 | compact | Bottom bar |
| 600 to 1023 | medium | Side rail |
| 1024 and up | expanded | Top bar |

## How the screens are tested

The tests in `test/screenshots/` draw each screen with pretend data at a phone, a tablet and a desktop size, in English, in Arabic and at 160 percent text. They save pictures to `build/screenshots/`. If a screen overflows, the test fails. These pictures are where the pictures in the README come from.

## The technology

* **Apps:** Flutter, Riverpod for state, GoRouter for routes, `flutter_map` with Mapbox tiles for maps, a bundled Readex Pro font.
* **API:** Node.js 20, Express, Prisma, Postgres on Neon, Helmet, CORS, rate limits.
* **Sign-in and storage:** Firebase Authentication, Cloud Storage, Cloud Messaging.
* **Hosting:** Vercel for the two websites, Render for the API, GitHub Actions for builds.
