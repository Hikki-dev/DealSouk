# Changes

Newest first.

## The shopper website can reach the API

1. Fixed "Couldn't load prices" on the shopper website. The API only trusted the moderator website, so it refused to answer the shopper one. Both websites, and their Vercel aliases, are now in `ALLOWED_ORIGINS`.
2. New entry in [Fixing problems](docs/Fixing%20problems.md) with the steps and a test command, a section in [Deploying](docs/Deploying.md), and the example settings file now lists both websites.

## Demo mode for the moderator console

1. Anyone who signs in can now look around the console in **demo mode**, read-only. Only moderator accounts, which you make with `npm run admin:set`, can change anything. It is off until `ADMIN_DEMO_VIEWERS=true` is set on the API. See [Demo mode](docs/Demo%20mode.md).
2. Viewers see a banner, shoppers' names are shortened, and phone numbers, voucher codes, receipt photos and exports are hidden or refused.
3. The API refuses every write from a viewer, so the protection does not rely on the buttons.
4. Fixed the Android and iOS release builds, which had been failing: `sentry_flutter` upgraded to 9.30.1, and the unused Google Maps plugin removed.
5. Every picture in the README was taken again at 2.25 times the size (desktop pictures are now 3240 pixels wide instead of 1000), and there is a new one of the demo console. The role badge now says Viewer for demo viewers.
6. Rewrote the Moderator access guide, which still said the shopper app was not on the web.

## Deploying and documentation

1. Two live websites, one for each audience: the moderator console at `deal-souk.vercel.app` and the shopper app at `deal-souk-shopper.vercel.app`. Both are built from the same code; `APP_MODE=shopper` picks the customer app.
2. Fixed the shopper project's first builds, which failed because `FIREBASE_OPTIONS_DART_B64` and `API_BASE_URL` were missing.
3. All four production addresses and both `git-main` aliases are now in the Firebase authorized domains, which fixes `auth/unauthorized-domain`.
4. New guides: Deploying (both projects, the settings, the Firebase domains), Fixing problems, FAQ, Getting started, How it works, How a price travels and API overview.
5. The README now follows the app screen by screen, with real pictures, and the guides have plain names.
6. New files for contributors: this changes list, CONTRIBUTING, SECURITY, a pull request form and two issue forms.

## The redesign

1. Every screen was rebuilt from the approved mockups, for phones, tablets and desktops, in English and Arabic. See [Screens](docs/Screens.md).
2. A new design system in `lib/core/design/`: flat cards, 52 pixel buttons, 48 pixel touch targets, bundled Readex Pro and real Dubai photos. See [Design system](docs/Design%20system.md).
3. One shell, three layouts: a bottom bar on phones, a side rail on tablets and a top bar on desktops. The phone-shaped frame on the web is gone.
4. Sign-in is a split screen on desktop, with the Dubai Marina photo and the three things you get.
5. Home, search, product, scan, map, My list, saved, sharing a price, requests, rewards, profile, privacy and the tutorial all follow the new design.
6. New **Text size** setting: Standard, Large, Extra large, used by the whole app, capped at 160 percent.
7. The moderator console has a sidebar on desktop and a menu on phones. Every panel was restyled, there is a Pending and Flagged filter, and Export CSV. Its text is in English and Arabic.
8. New tests draw every screen at three sizes, in Arabic and at 160 percent text, and fail on any overflow.
9. Buttons wrap their text onto two lines instead of cutting it off.

## Maps and sign-in checks

1. Maps use Mapbox tiles, because the free tile service we used before began returning a key-required picture.
2. Fixed the build on the main branch, which had been failing since June because a generated file was formatted before it existed.
3. Fixed a stale API test about checking whether a sign-in token was revoked.

## Admin showcase

1. New guide, Moderator access: how to get into the moderator console and how to show both apps.
2. The web build can make either app with `APP_MODE`.

## Photos and fonts

1. Readex Pro is bundled, so nothing is fetched from the network and Arabic no longer falls back to a system font.
2. Real Dubai photos replaced the placeholders, resized for small screens.
3. Store logos and a Google sign-in button using the real logo.
