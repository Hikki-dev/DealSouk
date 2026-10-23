# DealSouk

[![CI](https://github.com/Hikki-dev/DealSouk/actions/workflows/ci.yml/badge.svg)](https://github.com/Hikki-dev/DealSouk/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Node](https://img.shields.io/badge/Node.js-20-339933?logo=nodedotjs&logoColor=white)
![Postgres](https://img.shields.io/badge/Postgres-Neon%20%2B%20Prisma-4169E1?logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Storage%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black)
[![Moderator console](https://img.shields.io/badge/live-moderator%20console-0B6B6B)](https://deal-souk.vercel.app)

Shoppers in Dubai share what things cost on the shelf, so everyone can see the cheapest supermarket before they leave home.

<p align="center"><img src="docs/images/app/home-desktop.jpg" alt="The DealSouk home page on a desktop: best prices near you, a daily challenge and a share-a-price card" width="100%"></p>

You search for an item and see its price in every nearby store, with how fresh each price is. When you spot a price on a shelf, you take a photo and earn tokens. Tokens turn into supermarket vouchers.

Nobody orders anything here. DealSouk only helps you decide where to go.

It works on phones, tablets and desktops, in English and in Arabic, and the text can be made larger for anyone who needs it.

## On this page

* [What you get](#what-you-get): what shoppers and moderators can do
* [How everything fits together](#how-everything-fits-together): the pieces, and the journey of one price
* [Try it first](#try-it-first): the live links
* [The app, step by step](#the-app-step-by-step)
  * [1. Welcome](#1-welcome)
  * [2. Home](#2-home)
  * [3. Search](#3-search)
  * [4. One product, every store](#4-one-product-every-store)
  * [5. Scan a barcode](#5-scan-a-barcode)
  * [6. The map](#6-the-map)
  * [7. My list](#7-my-list)
  * [8. Share a price](#8-share-a-price)
  * [9. Rewards](#9-rewards)
  * [10. Profile and settings](#10-profile-and-settings)
* [Made for everyone](#made-for-everyone): Arabic, large text, phones and desktops
* [The moderator console](#the-moderator-console)
* [Run it yourself](#run-it-yourself)
* [Putting it online](#putting-it-online)
* [Your privacy and safety](#your-privacy-and-safety)
* [Help and more reading](#help-and-more-reading)
* [Photo credits](#photo-credits)

## What you get

There are three parts. Each does one job.

| Part | Who it is for | What it does |
|---|---|---|
| **Shopper app** | Everyone | Compare prices, find stores, share prices, earn rewards |
| **Moderator console** | The team | Check shared prices, stop fraud, hand out vouchers |
| **API** | The apps | One safe place for the data, the sign-in checks and the token counts |

**For shoppers**

* Search for an item and see its price in every nearby store. Prices older than 72 hours are marked as old.
* **My list**: put your shopping in one list and see which store is cheapest for the whole basket.
* Scan a barcode to find a product straight away.
* See stores on a map, with their prices and how the price has moved.
* Share a price with a shelf or receipt photo. Ask for a price too, or answer someone else's request.
* Earn tokens, daily challenges, streaks and badges. Climb the monthly leaderboard. Swap tokens for supermarket vouchers.
* Works in English and Arabic (right to left), with a text size setting, and keeps working offline.

**For moderators**

* Approve, change or reject each shared price, with the photos next to a checklist.
* Review flagged prices. A price hides itself after three different people flag it.
* Warn, suspend or ban a user. Every action is written to an audit log.
* Manage products and users, approve vouchers, import voucher stock.
* See analytics and a map of where prices come from. Export CSV and PDF.

## How everything fits together

The shopper app and the moderator console both talk to one API. The API keeps the data in Postgres, and uses Firebase to know who you are, to store photos and to send alerts. Every photo is cleaned and scanned before anyone sees it.

<p align="center"><a href="docs/images/how-it-fits.svg"><img src="docs/images/how-it-fits.svg" alt="Diagram: the shopper app and moderator console talk to the API, which uses Postgres, Firebase and the photo checks" width="100%"></a></p>

Here is the journey of one price, from the shelf to everyone's phone:

<p align="center"><a href="docs/images/price-journey.svg"><img src="docs/images/price-journey.svg" alt="Diagram: a shopper shares a photo, it is cleaned and scanned, a moderator checks it, it goes live for 72 hours and the shopper earns tokens" width="100%"></a></p>

The longer version, with the folders and the code behind each step, is in [How it works](docs/How%20it%20works.md) and [How a price travels](docs/How%20a%20price%20travels.md).

## Try it first

* **[Moderator console](https://deal-souk.vercel.app)**: sign in with a moderator account. How to get one is in [Moderator access](docs/Moderator%20access.md).
* **Shopper app on the web**: a second link that shows the shopper app. How it is set up is in [Deploying](docs/Deploying.md).
* **Android**: every release has two downloads, `DealSouk-Shopper.apk` and `DealSouk-Admin.apk`. See [Putting it online](#putting-it-online).

## The app, step by step

Every screen below is a real picture of the app. Phones are on the left and desktops on the right where both exist. Click a picture to see it full size. Every design, side by side with the file that builds it, is in [Screens](docs/Screens.md).

### 1. Welcome

<a href="docs/images/app/welcome-desktop.jpg"><img src="docs/images/app/welcome-desktop.jpg" alt="Welcome screen on desktop: a Dubai Marina photo on the left and sign-in options on the right" width="100%"></a>

Sign in with Google, Apple or a phone number, or look around as a guest. You agree to the privacy policy once, before you start.

On a phone the photo sits on top and the buttons are underneath.

<a href="docs/images/app/welcome-phone.jpg"><img src="docs/images/app/welcome-phone.jpg" alt="Welcome screen on a phone" width="320"></a> <a href="docs/images/app/tutorial-phone.jpg"><img src="docs/images/app/tutorial-phone.jpg" alt="The five-slide tutorial" width="320"></a>

The first time you open the app, a five-slide tutorial shows what it does. You can skip it, and you can watch it again from your profile.

### 2. Home

<a href="docs/images/app/home-phone.jpg"><img src="docs/images/app/home-phone.jpg" alt="Home on a phone: search, offers, share a price card, categories and best prices near you" width="320"></a>

Home shows the best prices near you, a daily challenge, and a button to share a price. The search box and the barcode button are always on top.

### 3. Search

<a href="docs/images/app/search-desktop.jpg"><img src="docs/images/app/search-desktop.jpg" alt="Search on desktop with category and freshness filters on the side" width="100%"></a>

Type a product and pick a category or how fresh the price must be. Sort by lowest price, nearest or freshest. On a desktop the filters sit on the side.

### 4. One product, every store

<a href="docs/images/app/product-desktop.jpg"><img src="docs/images/app/product-desktop.jpg" alt="Product page on desktop with a table comparing stores" width="100%"></a>

The product page lists every store with its price, how far away it is and how old the price is. The cheapest price is green. A chart shows how the price moved. You can add the item to My list from here.

### 5. Scan a barcode

<a href="docs/images/app/scan-phone.jpg"><img src="docs/images/app/scan-phone.jpg" alt="Barcode scanner with a frame to line up the barcode" width="320"></a>

Point the camera at a barcode. If the camera does not work, you can type the number instead.

### 6. The map

<a href="docs/images/app/map-desktop.jpg"><img src="docs/images/app/map-desktop.jpg" alt="Map on desktop with a list of stores beside it" width="100%"></a>

Stores near you appear as pins with their logos. Tap one to see its prices. On a phone the store list slides up from the bottom of the map.

### 7. My list

<a href="docs/images/app/list-desktop.jpg"><img src="docs/images/app/list-desktop.jpg" alt="My list on desktop with the cheapest basket card and a store comparison" width="100%"></a>

Add the things you plan to buy. DealSouk shows the cheapest store for the whole basket and how much more every other store costs. It also tells you when a price on your list drops.

### 8. Share a price

<a href="docs/images/app/submit-phone.jpg"><img src="docs/images/app/submit-phone.jpg" alt="First step of sharing a price: choose the store" width="320"></a>

Sharing takes four short steps: choose the store, choose the product, enter the price, then add a photo as proof. Nothing is lost if you are offline. It is sent when the connection comes back.

You can also **ask** for a price. Other shoppers see the request and can answer it, and both of you earn tokens.

### 9. Rewards

<a href="docs/images/app/rewards-desktop.jpg"><img src="docs/images/app/rewards-desktop.jpg" alt="Rewards on desktop: token balance, voucher progress, daily challenge and the leaderboard" width="100%"></a>

Approved prices earn tokens. A bar shows how close you are to the next voucher. Daily challenges, streaks and badges give extra tokens, and the monthly leaderboard shows who shared the most.

### 10. Profile and settings

<a href="docs/images/app/profile-desktop.jpg"><img src="docs/images/app/profile-desktop.jpg" alt="Profile on desktop with your stats, vouchers and settings" width="100%"></a>

Your profile shows your level, your tokens, your vouchers and your past prices. Settings let you change the language and the **text size**, replay the tutorial and read the privacy policy.

## Made for everyone

DealSouk is built for ages 14 to 65.

* **Big targets.** Every button is at least 48 pixels tall, so it is easy to hit.
* **Words with colours.** A status is never shown with colour alone. It always has a word or a symbol too.
* **Text size.** Profile, Settings lets you pick Standard, Large or Extra large. Screens are tested at 160 percent text.
* **Arabic.** The whole app flips to right to left, and prices show as `٩٫٥٠ د.إ`.
* **Any screen.** A bottom bar on phones, a side rail on tablets and a top bar on desktops.

<a href="docs/images/app/home-arabic-large-text.jpg"><img src="docs/images/app/home-arabic-large-text.jpg" alt="Home in Arabic with the largest text size" width="320"></a> <a href="docs/images/app/map-tablet.jpg"><img src="docs/images/app/map-tablet.jpg" alt="The map on a tablet with a side rail" width="480"></a>

The colours, sizes and parts are written down in [Design system](docs/Design%20system.md).

## The moderator console

<a href="docs/images/app/admin-moderation-desktop.jpg"><img src="docs/images/app/admin-moderation-desktop.jpg" alt="Moderator console on desktop: a sidebar, three counters, the pending list and a review panel" width="100%"></a>

On a desktop the console has a sidebar. On a phone the same sections are in a menu.

1. **Price moderation.** Pick a price on the left. On the right you see the photos, a checklist and how reliable this person has been. Approve, edit or reject.
2. **Map density.** See where prices come from.
3. **Analytics.** How many prices, users and tokens over time.
4. **Voucher queue and stock.** Approve voucher requests and import new voucher codes.
5. **System settings, products and users.** Change thresholds, manage the catalogue, warn, suspend or ban.

Export CSV copies the current list so you can paste it into a spreadsheet.

New accounts are shoppers. To make someone a moderator, follow [Moderator access](docs/Moderator%20access.md).

## Run it yourself

You need Node 20 for the API and the Flutter SDK for the apps. The short version:

```bash
# 1. The API
cd backend
npm install
cp .env.example .env        # then fill in the keys
npx prisma generate
npx prisma migrate dev
npm run dev

# 2. The shopper app (in a second window)
flutter pub get
flutterfire configure
flutter run --dart-define=API_BASE_URL="http://localhost:3000"

# 3. The moderator console
flutter run --dart-define=API_BASE_URL="http://localhost:3000" --dart-define=ADMIN_MODE=true
```

Every step, every setting and what to do when it fails is in [Getting started](docs/Getting%20started.md).

## Putting it online

Two websites are built from this one project. They differ by one setting, `APP_MODE`.

| Vercel project | Setting | Shows |
|---|---|---|
| `deal-souk` | `APP_MODE=admin` (default) | The moderator console |
| `deal-souk-shopper` | `APP_MODE=shopper` | The shopper app |

The API runs on Render. Android builds come from GitHub Actions. Publish a release and both `.apk` files are attached to it. The full checklist, including the one Firebase setting that people forget, is in [Deploying](docs/Deploying.md).

## Your privacy and safety

* Phone numbers are encrypted in the database.
* Every photo is stripped of its location data and scanned for viruses before anyone sees it.
* Every moderator action is written to an audit log. Moderators can be required to use a second sign-in step.
* Every token change is written in a chain that can be checked later, so tokens cannot be quietly changed.
* Write requests are rate limited.

Please report a security problem privately. How is in [SECURITY.md](SECURITY.md). The full review is in [SECURITY_AUDIT.md](SECURITY_AUDIT.md) and the pre-launch list is in [SECURITY_CHECKLIST.md](SECURITY_CHECKLIST.md).

## Help and more reading

* [Getting started](docs/Getting%20started.md): run the API and the apps
* [How it works](docs/How%20it%20works.md): the folders and the code
* [How a price travels](docs/How%20a%20price%20travels.md): one price, from shelf to phone
* [API overview](docs/API%20overview.md): every route
* [Design system](docs/Design%20system.md) and [Screens](docs/Screens.md): the look, and every screen
* [The redesign](docs/The%20redesign.md): what changed in the redesign and what is left
* [Deploying](docs/Deploying.md) and [Moderator access](docs/Moderator%20access.md)
* [Fixing problems](docs/Fixing%20problems.md) and [FAQ](docs/FAQ.md)
* [Test plan](docs/Test%20plan.md) and [Automated test plan](docs/Automated%20test%20plan.md)
* [Changes](CHANGELOG.md): what is new, newest first
* [Contributing](CONTRIBUTING.md)

## Photo credits

* **Font:** Readex Pro, SIL Open Font License, bundled in the app. One family covers Latin and Arabic.
* **Dubai Marina:** Norlando Pobre, CC BY 2.0. **Vegetable market:** Ithra Dubai, CC BY-SA 4.0. **Carrefour UAE:** CC BY-SA 4.0, Wikimedia Commons. **Dubai Creek:** public domain. **Burj Khalifa and dunes:** Wikimedia Commons, free licences (the individual authors still need to be added).
* The same credits appear in the app under Privacy and Terms.
* **Maps:** © Mapbox, © OpenStreetMap contributors.
* The market photo shows a real person and has no confirmed model release. Replace it before launch.
