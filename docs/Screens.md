# Screens

Every screen in the app, the mockup it follows and the file that implements it. Mockups were designed on the Claude Design canvas; each image here is the approved mockup. Implementation files are under `lib/features/*/presentation/` unless noted.

Screens adapt: bottom bar on phones, rail on tablets, top bar on desktop. See [Design%20system.md](Design%20system.md).


## Onboarding

### Welcome / sign in
`features/auth/presentation/welcome_screen.dart`

![Welcome / sign in](images/mockups/01-Welcome.jpg)

### Phone number
`same`

![Phone number](images/mockups/02-PhoneSignIn.jpg)

### One-time code
`same`

![One-time code](images/mockups/03-Otp.jpg)

### Tutorial
`core/widgets/tutorial_overlay.dart`

![Tutorial](images/mockups/04-Tutorial.jpg)

### Location
`tutorial / onboarding`

![Location](images/mockups/05-Location.jpg)


## Discover

### Home
`features/home/presentation/home_screen.dart`

![Home](images/mockups/06-Home.jpg)

### Search
`search_screen.dart`

![Search](images/mockups/07-Search.jpg)

### Search, no results
`search_screen.dart`

![Search, no results](images/mockups/08-SearchEmpty.jpg)

### Product price comparison
`product_detail_screen.dart`

![Product price comparison](images/mockups/09-Product.jpg)

### Barcode scan
`barcode_scan_screen.dart`

![Barcode scan](images/mockups/10-Scan.jpg)


## Stores and lists

### Map
`stores`

![Map](images/mockups/11-Map.jpg)

### Store
`store_screen.dart`

![Store](images/mockups/12-Store.jpg)

### My list
`cart_screen.dart`

![My list](images/mockups/13-MyList.jpg)

### Saved
`saved_screen.dart`

![Saved](images/mockups/14-Saved.jpg)

### Empty, offline, error states
`DsEmptyState / DsBanner`

![Empty, offline, error states](images/mockups/15-States.jpg)


## Contribute

### Submit step 1
`submit_price_screen.dart`

![Submit step 1](images/mockups/16-Submit1.jpg)

### Submit step 2
`same`

![Submit step 2](images/mockups/17-Submit2.jpg)

### Submit step 3
`same`

![Submit step 3](images/mockups/18-Submit3.jpg)

### Submit step 4
`same`

![Submit step 4](images/mockups/19-Submit4.jpg)

### Submitted
`same`

![Submitted](images/mockups/20-SubmitDone.jpg)

### Requests
`request_board_view.dart`

![Requests](images/mockups/21-Requests.jpg)

### Ask for a price
`same`

![Ask for a price](images/mockups/22-AskForm.jpg)


## Rewards and profile

### Rewards
`leaderboard_screen.dart`

![Rewards](images/mockups/23-Rewards.jpg)

### Voucher
`same`

![Voucher](images/mockups/24-Voucher.jpg)

### Challenge
`same`

![Challenge](images/mockups/25-Challenge.jpg)

### Profile
`profile_screen.dart`

![Profile](images/mockups/26-Profile.jpg)

### Tokens
`same`

![Tokens](images/mockups/27-Tokens.jpg)

### Settings and text size
`same`

![Settings and text size](images/mockups/28-Settings.jpg)

### Privacy and terms
`privacy_policy_screen.dart`

![Privacy and terms](images/mockups/29-Privacy.jpg)

### Unauthorized
`unauthorized_screen.dart`

![Unauthorized](images/mockups/30-Unauthorized.jpg)


## Arabic and comfort text

### Home, Arabic RTL
`home_screen.dart`

![Home, Arabic RTL](images/mockups/31-HomeArabic.jpg)

### Home, 160% text
`home_screen.dart`

![Home, 160% text](images/mockups/32-HomeComfort.jpg)

### Product, Arabic
`product_detail_screen.dart`

![Product, Arabic](images/mockups/33-ProductArabic.jpg)


## Tablet

### Home
`rail navigation`

![Home](images/mockups/T1-HomeTablet.jpg)

### Map
`rail navigation`

![Map](images/mockups/T2-MapTablet.jpg)

### Product
`rail navigation`

![Product](images/mockups/T3-ProductTablet.jpg)


## Desktop

### Sign in
`welcome_screen.dart`

![Sign in](images/mockups/D1-LoginDesktop.jpg)

### Home
`home_screen.dart`

![Home](images/mockups/D2-HomeDesktop.jpg)

### Search
`search_screen.dart`

![Search](images/mockups/D3-SearchDesktop.jpg)

### Map
`stores`

![Map](images/mockups/D4-MapDesktop.jpg)

### Product
`product_detail_screen.dart`

![Product](images/mockups/D5-ProductDesktop.jpg)

### Rewards
`leaderboard_screen.dart`

![Rewards](images/mockups/D6-RewardsDesktop.jpg)


## Moderator console

### Sign in
`welcome_screen.dart (ADMIN_MODE)`

![Sign in](images/mockups/A1-AdminLogin.jpg)

### Moderation queue
`admin_screen.dart`

![Moderation queue](images/mockups/A2-Moderation.jpg)

### Map density
`admin panels`

![Map density](images/mockups/A3-MapDensity.jpg)

### Analytics
`admin panels`

![Analytics](images/mockups/A4-Analytics.jpg)

### Voucher queue
`admin panels`

![Voucher queue](images/mockups/A5-VoucherQueue.jpg)

### Voucher stock
`admin panels`

![Voucher stock](images/mockups/A6-VoucherStock.jpg)

### Settings
`admin panels`

![Settings](images/mockups/A7-Settings.jpg)

### Products
`admin panels`

![Products](images/mockups/A8-Products.jpg)

### Users
`admin panels`

![Users](images/mockups/A9-Users.jpg)
