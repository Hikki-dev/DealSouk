# Fixing problems

Find what you see, then follow the steps.

## "This domain is not authorized for OAuth operations" when I sign in on the web

The full message starts with `[firebase_auth/unauthorized-domain]`. Firebase only lets sign-in happen on websites you have listed.

1. Open the [Firebase console](https://console.firebase.google.com/) and choose the DealSouk project.
2. Go to **Authentication**, then **Settings**, then **Authorized domains**.
3. Press **Add domain** and add each address of your Vercel projects. The list is in [Deploying](Deploying.md#firebase-authorized-domains).
4. Reload the page and try again.

## I signed in and see "Unauthorized"

New accounts are shoppers. The moderator console only opens for moderators.

1. Make the account a moderator, as shown in [Moderator access](Moderator%20access.md).
2. Sign out of the console and sign in again. Your sign-in carries your role, so an old session still says shopper.

## The map is blank or grey

The map needs a Mapbox token. Without it, the tiles do not load.

1. Make a restricted public token (it starts with `pk.`) in the Mapbox dashboard.
2. Give it to the build as `MAPBOX_ACCESS_TOKEN`. On Vercel, add it as an environment variable and redeploy.

## The Vercel build says "Missing FIREBASE_OPTIONS_DART_B64"

The website build needs the Firebase settings. Add the variable in the Vercel project settings and redeploy.

1. Run `base64 -w0 lib/firebase_options.dart` on a computer where you ran `flutterfire configure`. On a Mac use `base64 -i lib/firebase_options.dart`.
2. Paste the result as `FIREBASE_OPTIONS_DART_B64`. The shopper and the admin project use the same value.

## The shopper website shows the moderator console

The two websites are the same code. `APP_MODE` picks which one. Check that the project you opened has `APP_MODE=shopper`. See [Deploying](Deploying.md).

## Release builds stop at start with a `StateError`

`API_BASE_URL` is empty or does not start with `https://`. Give a real HTTPS address.

## A screen overflows or the text is cut off

Run `flutter test test/screenshots/` and look at the picture in `build/screenshots/`. The tests draw the screen at a phone, a tablet and a desktop size, in Arabic and at 160 percent text, and fail on an overflow.

## `flutter` changed `analysis_options.yaml`

Flutter sometimes rewrites this file when you run it. Undo it before you commit: `git checkout analysis_options.yaml`.

## Still stuck

Open an issue with the "Something is not working" form. Say what you expected and what happened. Never paste keys, passwords or links that contain a token.
