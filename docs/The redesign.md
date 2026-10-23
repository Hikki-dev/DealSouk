# The redesign

This page tells the story of the redesign: what was wrong, what was built, how it was checked and what is left.

## Why

The first version worked, but it looked different on every screen. It used glass effects that were slow on cheaper phones, a phone-shaped frame on the web, and no real layout for tablets or desktops. Some text was hard to read, and Arabic fell back to a system font.

We wanted one look that works for everyone from 14 to 65, on any screen, in two languages, and that feels as calm and clear as the best apps.

## What was built

1. **A design system.** Colours, sizes and parts, written once in `lib/core/design/`. See [Design system](Design%20system.md).
2. **One shell, three layouts.** Bottom bar, side rail and top bar, chosen by window width.
3. **Every screen, from the mockups.** [Screens](Screens.md) shows each mockup beside the file that builds it.
4. **Real Dubai.** Real photographs, real store logos, the Google sign-in logo, Mapbox maps, and AED prices (`د.إ` in Arabic).
5. **Comfort.** A Text size setting, 48 pixel touch targets, and words with every colour.
6. **The moderator console.** A sidebar on desktop, a menu on phones, every panel restyled.

The story of how the work was built is in [Changes](../CHANGELOG.md).

## How it was checked

1. `flutter analyze` finds nothing, and every test passes.
2. The tests in `test/screenshots/` draw each screen with pretend data at a phone, a tablet and a desktop size, in English, in Arabic and at 160 percent text. A screen that overflows fails the test.
3. Someone looked at the pictures of the main screens: welcome, home, My list, rewards and the moderation queue.
4. The checks on every pull request run the formatter, the analyzer, the tests and the API tests.

## What is left

* The moderator dialogs (edit a price, forms for products and users, delete confirmations, voucher review) still use the older style and English text.
* The desktop map has no pop-up card for a chosen store. Tapping a store opens its prices.
* Settings has no Notifications switch, Help page or Delete my account row, because nothing in the app supports them yet.
* A few words are English only: the contributor level names, the photo credits, and some small hints on home and search. The new home and search words live in `discover_strings.dart` and should move into the translation files.
* Steps two to four of sharing a price, and the ask-for-a-price sheet, pass the layout tests, but nobody has looked at their pictures one by one.
* The Burj Khalifa and dunes photos need their individual authors added to the credits.
