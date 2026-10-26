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

## The map looks plain, or is blank or grey

Without a Mapbox token the map uses the free OpenStreetMap tiles, so it still shows streets. For the Mapbox street style:

1. Make a restricted public token (it starts with `pk.`) in the Mapbox dashboard.
2. Give it to the build as `MAPBOX_ACCESS_TOKEN`. On Vercel, add it as an environment variable and redeploy.

An older build made without a token shows a blank grey map. Redeploy to fix it.

## The Vercel build says "Missing FIREBASE_OPTIONS_DART_B64"

The website build needs the Firebase settings. Add the variable in the Vercel project settings and redeploy.

1. Run `base64 -w0 lib/firebase_options.dart` on a computer where you ran `flutterfire configure`. On a Mac use `base64 -i lib/firebase_options.dart`.
2. Paste the result as `FIREBASE_OPTIONS_DART_B64`. The shopper and the admin project use the same value.

## The shopper website says "Couldn't load prices"

You are signed in, the home page shows, but the prices never load. The API is fine. It is refusing to let this website read its answers.

The API only answers websites on its allow-list, the `ALLOWED_ORIGINS` setting on Render. A new website address must be added to it.

1. Open the `DealSouk` service on Render, then **Environment**.
2. Add the shopper address to `ALLOWED_ORIGINS`. Keep the ones that are already there. Separate them with commas, with no spaces, no `https://` missing and no slash at the end. For example: `https://deal-souk.vercel.app,https://deal-souk-shopper.vercel.app`.
3. Save. Render redeploys by itself. The free server can take about a minute to wake up.
4. Refresh the website and press **Retry**.

To test it without the app, ask the API what it says to your website's address. A good answer includes a line `access-control-allow-origin` that repeats your address:

```bash
curl -i -X OPTIONS https://dealsouk.onrender.com/products/search \
  -H "Origin: https://deal-souk-shopper.vercel.app" \
  -H "Access-Control-Request-Method: GET"
```

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
