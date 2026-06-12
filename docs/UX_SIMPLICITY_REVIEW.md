# DealSouk UX Simplicity Review

This document provides a comprehensive user experience (UX) review of DealSouk for non-technical users in Dubai. The review identifies barriers to rapid comprehension (aiming for the "understandable in 10 seconds" UX goal) and specifies improvements in terminology, screen layouts, bilingual flow, and navigation clarity.

---

## Terminology Reference Guide
To ensure the app is understandable to families, grocery shoppers, and casual contributors, we must establish a consistent, non-technical vocabulary. The following substitutions should be applied system-wide:

| Technical/Confusing Term | Simple User-Facing Term | Purpose / Context |
| :--- | :--- | :--- |
| "Upload Price" / "Data Sourcer" | **"Submit a price"** | Contribution action |
| "Points" / "Credits" | **"Earn tokens"** | Reward mechanism |
| "Lowest Price" | **"Best price near you"** | Searching & filtering |
| "2h" / "Time-Since Label" | **"Updated 2 hours ago"** | Time freshness indicators |
| "Trusted" / "Fresh" status | **"Verified with photo"** | Proof of price validity |
| "Flag" / "Report Dispute" | **"Report wrong price"** | Community correction action |
| "Post Ask" / "Request Board" | **"Request this price"** | Asking for neighborhood price checks |
| "Sourcer" / "Regular Sourcer" | **"Shopper" / "Regular Contributor"** | Contributor ranking/levels |

---

## Screen-by-Screen Audit & Recommendations

### 1. Welcome Screen
* **Current Issue:** 
  - The welcome screen subtitle utilizes technical jargon: *"Find nearby grocery prices in Dubai"* is accompanied by descriptions about *"crowd-sourced grocery prices"*.
  - The tabs distinguish between *"Customer Mode"* and *"Admin Moderator"*, which exposes internal roles to normal consumers.
  - The bottom footer text says *"Crowd-sourced grocery prices for Dubai."*
* **Why Non-Tech Users Struggle:** 
  - Terms like "crowd-sourced" are technical and unfamiliar to typical grocery shoppers or families trying to save money.
  - Exposing "Admin Moderator" directly on the welcome tab makes the app feel like a database admin tool rather than a clean, premium product.
* **Better Wording / Layout:**
  - Change main subtitle to: **"Prices shared by shoppers near you"**
  - Hide the "Admin Moderator" tab for standard clients (e.g., access it via a developer tap gesture on the logo 5 times, or hide it behind authentication/role routing).
  - Simplify pillars to: **"Compare Prices"**, **"Find Nearby"**, **"Request Price"**
  - Change footer to: **"Supermarket prices shared by shoppers in Dubai."**
* **Priority:** High
* **Exact File Path:** [welcome_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/auth/welcome_screen.dart)

---

### 2. Onboarding Tutorial Overlay
* **Current Issue:** 
  - The onboarding has 3 slides: Slide 1 ("Compare Grocery Prices"), Slide 2 ("Ask For Price Checks"), and Slide 3 ("Save Useful Prices").
  - There is a graphic/text mismatch on **Slide 3**: The text title describes saving prices, but the visual displays a mock supermarket voucher card (`_buildRedeemVisual`).
  - It does not clearly explain the core loop: sharing prices = earning tokens = swapping for real grocery vouchers.
* **Why Non-Tech Users Struggle:** 
  - Seeing a voucher barcode while reading about "saving items to a simple price list" confuses the user on what the actual reward mechanism is.
  - The transition from shopping to contributing is not made clear in under 10 seconds.
* **Better Wording / Layout:**
  - Update **Slide 3** title to: **"Earn Shopping Rewards"**
  - Update Slide 3 description to: **"Share prices or check shelves to earn tokens, then swap them for real supermarket vouchers."**
  - Keep slide count at 3 (meets requirement) but align graphics to explicitly show the reward economy.
* **Priority:** Critical
* **Exact File Path:** [tutorial_overlay.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/tutorial_overlay.dart)

---

### 3. Home Feed (Price Cards & Daily Limits)
* **Current Issue:**
  - The balance card displays: `"${dailyCap - submissionsToday} price checks left today"`.
  - The price card (`_FreshPriceEntryCard`) lacks distance information and a clear verification status badge.
  - The category list uses tags like "Freshness" and "Trust" which are abstract.
* **Why Non-Tech Users Struggle:**
  - Shoppers will think they are restricted to 10 searches/views per day when they see "10 price checks left today". This blocks searching.
  - Users cannot tell if a cheap price is 15 km away or next door because the card lacks distance details.
* **Better Wording / Layout:**
  - Change daily limit label to: **"Remaining price shares to earn rewards today"** or **"Shares left to earn tokens today"**.
  - Redesign `_FreshPriceEntryCard` to show:
    - **Price:** Clear colored text (e.g. `AED 3.90`)
    - **Store:** Store & branch name (e.g., `Union Coop - Al Barsha`)
    - **Distance:** `0.8 km away` (using GPS proximity calculations)
    - **Freshness:** `"Updated 2 hours ago"` (or `"Updated today"`)
    - **Verification:** `"Verified with photo"` (with a camera icon) if shelf/receipt photo is available.
* **Priority:** Critical
* **Exact File Path:** [home_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/home/home_screen.dart)

---

### 4. Search Screen & Catalog Empty States
* **Current Issue:**
  - The empty state for no search results is a static text label: *"No products found in this category"*. It contains no guidance on what to do next.
  - Missing an easy link to request a price check if a product is not listed.
* **Why Non-Tech Users Struggle:**
  - When users search for their preferred brand (e.g. "Al Rawabi Milk") and get no results, they assume the app is broken or useless and close it.
* **Better Wording / Layout:**
  - Revamp empty state to say: **"We couldn't find '${searchQuery}'. Would you like another shopper to check this price for you?"**
  - Include a large primary button: **"Request this price (+15 Tokens)"** which immediately opens the price request sheet pre-filled with the search query.
* **Priority:** High
* **Exact File Path:** [search_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/products/search_screen.dart)

---

### 5. Product Details Screen
* **Current Issue:**
  - The reporting flag is a small outline icon button `Icons.outlined_flag_rounded` with a tooltip *"Flag incorrect price"* but no visible text.
  - Individual store rows under "Compare Store Prices" only display the store name and price, omitting distance and verification details.
  - No option to trigger a fresh price check request for this specific item.
* **Why Non-Tech Users Struggle:**
  - Regular users will miss the small grey flag icon. They won't know they have the power to flag wrong prices.
  - Users cannot balance travel cost vs savings if they only see a cheap store name without its distance.
* **Better Wording / Layout:**
  - Replace the icon button with a clear text button: **"Report wrong price"** (positioned next to the price details).
  - Add a text button: **"Request updated price"** next to the main "Save Price" action, allowing users to ask for a fresh check if the last update was days ago.
  - Update store comparison rows to clearly list:
    - **Price** (e.g., `AED 14.50`)
    - **Store & Distance** (e.g., `Carrefour • 1.8 km away`)
    - **Freshness & Verification** (e.g., `Updated 2 hours ago • Verified with photo`)
* **Priority:** High
* **Exact File Path:** [product_detail_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/products/product_detail_screen.dart)

---

### 6. Cart & Basket Comparison Screen
* **Current Issue:**
  - Name drift: The bottom navigation bar tab is coded/labeled as "/cart" and uses a bookmark icon, but the screen header title is "Saved Prices".
  - The store comparison card lists the total price difference (+AED X) but misses store distances.
  - The screen does not display a quantity stepper (`UI-02` gap), making it impossible to scale up basket sizes.
  - Lack of a summary displaying the "cheapest basket" vs the "closest store" option.
* **Why Non-Tech Users Struggle:**
  - Calling a comparison list a "Cart" is misleading because they cannot buy things through DealSouk.
  - Without distances, users cannot make decisions: is saving AED 5 worth driving 10 km to Union Coop instead of walking 2 minutes to Carrefour?
* **Better Wording / Layout:**
  - Rename the bottom navigation tab from "/cart" to **"My List"** or **"Compare"**.
  - Redesign the top summary banner to clearly contrast options:
    - **Cheapest Basket:** `Union Coop (AED 42.50 • 3.2 km)`
    - **Closest Option:** `Carrefour (AED 48.00 • 0.8 km)`
    - **Your Savings:** `Save AED 5.50 at Union Coop`
  - Add standard `+` and `-` quantity steppers next to each saved item card so shoppers can calculate multi-item grocery totals.
  - Display store distance within the comparison cards.
* **Priority:** High
* **Exact File Paths:**
  - [cart_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/cart/cart_screen.dart)
  - [shell_layout.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/widgets/shell_layout.dart)

---

### 7. Price Submission Screen (Refactoring the Flow)
* **Current Issue:**
  - The screen is a crowded, single-page form with 6+ inputs (Store dropdown, Product dropdown, Price field, Promotion type, Shelf photo button, Receipt photo button, Live token estimate card, and a "Send for review" button).
  - High friction for shoppers who want to quickly snap a photo and earn rewards.
* **Why Non-Tech Users Struggle:**
  - Massive forms feel like work. Casual contributors will abandon the screen when confronted with multiple dropdowns and inputs at once.
* **Better Wording / Layout:**
  - Refactor the form into a progressive **4-step submission wizard**:
    - **Step 1: Store Selection** (Select supermarket from nearby stores list/map).
    - **Step 2: Product & Photo** (Select product and snap a shelf label or product photo).
    - **Step 3: Price & Promo** (Enter price in AED and select any active promotion tags like Discount or BOGO).
    - **Step 4: Submit & Earn** (Show the final points calculation screen with a large **"Submit a price"** button detailing the reward: *"Tap to earn +15 Tokens!"*).
  - Change "Send for review" button text to: **"Submit a price"**.
* **Priority:** High
* **Exact File Path:** [submit_price_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/submissions/submit_price_screen.dart)

---

### 8. Leaderboard & Price Request Board
* **Current Issue:**
  - Uses technical roles like "Sourcer Badges", "Regular Sourcer", and "Senior Sourcer" for user achievements.
  - The request item card uses a button label: *"I can check"*, which misses the reward incentive.
  - Empty state for requests says *"No price requests yet."* without instructing the user on how to ask.
* **Why Non-Tech Users Struggle:**
  - Users do not associate themselves with the word "Sourcer".
  - Contributors don't know that clicking "I can check" is the primary way to earn token bonuses.
* **Better Wording / Layout:**
  - Rename badge and ranking labels:
    - Change "Sourcer Badges" to **"Shopper Badges"** or **"Contributor Badges"**.
    - Change level titles in `state.dart` from "Regular Sourcer" to **"Regular Contributor"**, and "Senior Sourcer" to **"Expert Price-Sharer"**.
  - Update action button on request cards from "I can check" to: **"Check price (+15 Tokens)"** or **"Help Check Price"**.
  - Improve request empty state to: **"All price requests are completed! Need a price? Tap 'Ask for a price' to request a price check."**
* **Priority:** Medium
* **Exact File Paths:**
  - [leaderboard_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/leaderboard/leaderboard_screen.dart)
  - [request_board_view.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/leaderboard/request_board_view.dart)
  - [state.dart](file:///Users/hikki/Desktop/DealSouk/lib/core/state/state.dart)

---

### 9. Map & Stores Screen
* **Current Issue:**
  - The map uses standard red/blue location pins. It does not show price information directly on the markers.
  - If location permissions are denied, the screen silently loads Al Barsha stores fallback without explaining *why* the user is seeing a different neighborhood.
  - The store card list renders a dummy price `store.distance * 10` (AED 10 per km) if there is no sample total, which displays misleading price data to the user.
* **Why Non-Tech Users Struggle:**
  - Shoppers expect a "Petrol Spy" experience where they can scan the map and see where the cheap items are immediately.
  - Showing default Al Barsha stores when a user is in Dubai Marina without any warning card makes the app look buggy or inaccurate.
  - Showing fake price totals (e.g. AED 25.00 for a store 2.5 km away) makes users think they are being charged a fee or that those are real grocery prices.
* **Better Wording / Layout:**
  - Integrate customized markers displaying the cheapest price or index indicator directly on the pins.
  - Add a prominent info banner when showing default stores: **"Showing default stores. Grant location permission to find supermarkets near you."** with a button to trigger settings.
  - Remove fake price calculations on `_StoreChoiceCard`. Replace it with: **"Compare prices"** or show actual store pricing statistics (e.g., *"14 prices active"*).
* **Priority:** Critical
* **Exact File Path:** [store_screen.dart](file:///Users/hikki/Desktop/DealSouk/lib/features/stores/store_screen.dart)

---

## Arabic & RTL Layout Auditing Checklist
A critical requirement for Dubai users is supporting both English and Arabic. The current app is severely limited:

1. **Localization Extraction:**
   - **Current Issue:** None of the screens under `lib/features/` use `AppLocalizations.of(context)`. All UI texts are hardcoded English strings.
   - **Remedy:** Extract all hardcoded strings into localizable keys in `app_en.arb` and `app_ar.arb` and load them reactively.
2. **Directionality Alignments:**
   - **Current Issue:** Several custom row builders and layout elements (e.g., the scallop bottom-clipper graphic on the welcome screen, horizontal sliders, and custom navigation floating bars) use hardcoded offsets and alignment properties.
   - **Remedy:** Replace all left/right padding and alignment widgets with `directional` equivalents (e.g., `EdgeInsetsDirectional` instead of `EdgeInsets.only(left: ...)`), and ensure `TextDirection` flips automatically in RTL languages.
3. **Map Marker Details:**
   - **Current Issue:** Map info window snippets and popups are hardcoded in English formatting (`store.distance + " km"`).
   - **Remedy:** Format distances and names properly using localizable strings (e.g., `"{distance} كم"` in Arabic).
