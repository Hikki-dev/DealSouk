# Changes

Newest first.

## Deploying and documentation

1. New website project for the shopper app, `deal-souk-shopper`, built from the same code with `APP_MODE=shopper`. The moderator console stays on `deal-souk`.
2. New guides: Deploying (both projects, the settings, the Firebase domains), Fixing problems, FAQ, Getting started, How it works, How a price travels and API overview.
3. The README now follows the app screen by screen, with real pictures, and the guides have plain names.
4. New files for contributors: this changes list, CONTRIBUTING, SECURITY, a pull request form and two issue forms.

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
