// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DealSouk';

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get cart => 'My list';

  @override
  String get leaderboard => 'Rewards';

  @override
  String get profile => 'Profile';

  @override
  String get greeting => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get freshPrices => 'Fresh Prices';

  @override
  String get freshPricesSubtitle => 'Live crowd-sourced prices near you';

  @override
  String get searchProducts => 'Search products…';

  @override
  String get searchNearbyStores => 'Search nearby Dubai stores';

  @override
  String get nearbyStores => 'Nearby Supermarkets';

  @override
  String get storeMap => 'Store Map';

  @override
  String get tokens => 'Tokens';

  @override
  String get tokenBalance => 'Token Balance';

  @override
  String get earnTokens => 'Earn tokens';

  @override
  String get spendTokens => 'Spend tokens';

  @override
  String get tokenHistory => 'Token History';

  @override
  String get voucherReady => 'Voucher Ready!';

  @override
  String voucherProgress(int remaining) {
    return 'Earn $remaining more tokens to redeem your voucher.';
  }

  @override
  String get claimVoucher => 'Claim Voucher Now';

  @override
  String get voucherClaimed => 'Voucher Claimed!';

  @override
  String get voucherDescription =>
      'Show the barcode or code below to the cashier at any Union Coop checkout in Dubai.';

  @override
  String get backToRewards => 'Back to Rewards';

  @override
  String get leaderboardTitle => 'Rewards & Leaderboard';

  @override
  String get dubaiLeaderboard => 'Dubai Leaderboard';

  @override
  String get lastMonthChampions => 'Last Month\'s Champions';

  @override
  String get sourcerBadges => 'Shopper Badges';

  @override
  String get todaysChallenges => 'Today\'s Challenges';

  @override
  String get activeRequestBoard => 'Active Request Board';

  @override
  String get leaderboardStreaks => 'Leaderboard & Streaks';

  @override
  String yourRank(int rank) {
    return 'Rank #$rank';
  }

  @override
  String dayStreak(int days) {
    return '$days Day Streak';
  }

  @override
  String get submitPrice => 'Upload Price';

  @override
  String get submitForReview => 'Send for review';

  @override
  String get priceSubmitted => 'Price Submitted!';

  @override
  String get priceSubmittedDesc =>
      'Your price submission is pending review.\nTokens will be credited after admin approval.';

  @override
  String get openAdminReview => 'Open Admin Review';

  @override
  String get viewTokenBalance => 'View Token Balance';

  @override
  String get tokenRewardEstimate => 'Token reward estimate';

  @override
  String get totalRewardEstimate => 'Total Reward Estimate';

  @override
  String get selectSupermarket => 'Select Supermarket';

  @override
  String get selectProduct => 'Select Product';

  @override
  String get enterPriceAed => 'Enter Price (AED)';

  @override
  String get promotionType => 'Promotion Type';

  @override
  String get priceLabelPhoto => 'Price Label Photo';

  @override
  String get receiptPhoto => 'Receipt Photo';

  @override
  String get photoUploaded => 'Photo Uploaded';

  @override
  String get tapToUpload => 'Tap to Upload';

  @override
  String dailyCapRemaining(int remaining, int cap) {
    return '$remaining of $cap submissions left today';
  }

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String challengeBonus(int tokens) {
    return '+$tokens bonus tokens';
  }

  @override
  String challengeCompleted(int tokens) {
    return 'Done! +$tokens tokens earned';
  }

  @override
  String challengeProgress(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get tapToComplete => 'Tap to start submitting';

  @override
  String get profileSettings => 'Profile & Settings';

  @override
  String get mySubmissions => 'My Submissions';

  @override
  String get myTokenHistory => 'Token History';

  @override
  String get myRequests => 'My Requests';

  @override
  String get settings => 'Settings';

  @override
  String get displayName => 'Display Name';

  @override
  String get homeArea => 'Home Area';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get logOut => 'Log Out of Demo';

  @override
  String get accuracyRating => 'Accuracy Rating';

  @override
  String accuracyRatingDesc(int percent) {
    return '$percent% of your submissions approved';
  }

  @override
  String get noSubmissionsYet =>
      'No submissions yet.\nSubmit a price to get started!';

  @override
  String get noRequestsYet => 'No price requests yet.';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get fulfilled => 'Fulfilled';

  @override
  String get open => 'Open';

  @override
  String get refunded => 'Refunded';

  @override
  String get adminConsole => 'Moderator Console';

  @override
  String get priceModeration => 'Price Moderation';

  @override
  String get analytics => 'Analytics';

  @override
  String get sourcersIndex => 'Sourcers Index';

  @override
  String get systemSettings => 'System Settings';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get editSubmission => 'Edit Submission';

  @override
  String get tokenEarnRate => 'Token Earn Rate (base)';

  @override
  String get voucherThreshold => 'Voucher Threshold (tokens)';

  @override
  String get dailySubmissionCap => 'Daily Submission Cap';

  @override
  String get freshLabel => 'Fresh';

  @override
  String updatedAgoLabel(int hours) {
    return 'Updated ${hours}h ago';
  }

  @override
  String get unverifiedOutdated => 'Unverified, may be outdated';

  @override
  String get stalePriceWarning => 'Price data may be outdated (>72h)';

  @override
  String get staleStore => 'Stale';

  @override
  String get filterByChain => 'Filter by chain';

  @override
  String get allChains => 'All';

  @override
  String get submitPriceHere => 'Submit Price Here';

  @override
  String betterPriceFound(String item, String price, String store) {
    return 'Better price found for $item! Now AED $price at $store.';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get requestFulfilled =>
      'Request fulfilled! Tokens transferred to requester.';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get addItemsToCart =>
      'Browse products and add items to compare prices.';

  @override
  String get bestBasket => 'Best Basket';

  @override
  String get bestStore => 'Best Store';

  @override
  String get checkout => 'Checkout';

  @override
  String get applyCoupon => 'Apply Coupon';

  @override
  String get guestMode => 'Continue as Guest';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInWithApple => 'Continue with Apple';

  @override
  String get signInWithPhone => 'Continue with Phone';

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String earnMultiplier(int percent) {
    return '+$percent% earn rate';
  }

  @override
  String get homeCategories => 'Categories';

  @override
  String get homeCategoryFresh => 'Fresh';

  @override
  String get homeCategoryFruits => 'Fruits';

  @override
  String get homeCategorySnack => 'Snack';

  @override
  String get homeCategoryGrocery => 'Grocery';

  @override
  String get homeCategoryOils => 'Oils';

  @override
  String get homeSeeAll => 'See All';

  @override
  String homeGreetingLine(Object greeting, Object name) {
    return '$greeting, $name';
  }

  @override
  String get homeFindNearbyPrices => 'Find nearby prices before you go';

  @override
  String get homeSearchHint => 'Search an item to compare prices nearby';

  @override
  String homeSearchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get homeHowItWorks =>
      'Simple: search an item, check nearby stores, then decide where it is worth going.';

  @override
  String get homeBestPricesNearYou => 'Best prices near you';

  @override
  String homePricesCount(Object count) {
    return '$count prices';
  }

  @override
  String get savedTitle => 'Saved Items';

  @override
  String get savedEmptyTitle => 'No saved items yet';

  @override
  String get savedEmptyHint =>
      'Tap the heart on any product to save it here for quick access while you shop.';

  @override
  String get scanBarcodeTitle => 'Scan Barcode';

  @override
  String get scanBarcodeHint =>
      'Point the camera at the barcode. We will use it to find the product faster.';

  @override
  String get homeLoadError => 'Couldn\'t load prices';

  @override
  String get homeLoadErrorHint =>
      'Check your connection and try again. The server may be waking up.';

  @override
  String get retry => 'Retry';

  @override
  String get homeNoPricesMatch => 'No prices match this filter yet';

  @override
  String get homeNoPricesHint =>
      'Try All prices, search for an item, or ask shoppers to check a price.';

  @override
  String get homeFindAnItem => 'Find an item';

  @override
  String get homeBrowseItems => 'Browse items';

  @override
  String get homeFeaturedStores => 'Featured Stores';

  @override
  String get homeEarnRewardsToday => 'Earn rewards today';

  @override
  String homePriceSharesLeft(Object count) {
    return '$count price shares left to earn tokens';
  }

  @override
  String get homeDailyChallenge => 'Daily Challenge';

  @override
  String homeChallengeDoneBadge(Object tokens) {
    return 'Done! +${tokens}T';
  }

  @override
  String get homeDailyChallengeDetails => 'Daily Challenge Details';

  @override
  String get homeChallengeFinished => 'You have finished this challenge!';

  @override
  String get homeChallengeEarnBonus =>
      'Earn bonus tokens by participating today';

  @override
  String get homeTargetSupermarket => 'Target Supermarket';

  @override
  String get homeAnySupermarketChain => 'Any Supermarket Chain';

  @override
  String get homeYourProgress => 'Your Progress';

  @override
  String homeProgressPrices(Object progress, Object target) {
    return '$progress / $target prices';
  }

  @override
  String get homeRewardBonus => 'Reward Bonus';

  @override
  String homeRewardBonusValue(Object tokens) {
    return '+$tokens Tokens';
  }

  @override
  String get homeHowToComplete => 'How to complete:';

  @override
  String homeStepVisitStore(Object store) {
    return 'Visit any branch of $store.';
  }

  @override
  String get homeAGenericSupermarket => 'a supermarket';

  @override
  String get homeStepVerifyPrices =>
      'Find grocery products and verify their shelf prices.';

  @override
  String get homeStepSubmitPrice =>
      'Tap \"Submit Price\" in the app, fill in the price details, and submit.';

  @override
  String get homeStepApproved =>
      'Once approved, your progress will update and you\'ll receive the token bonus!';

  @override
  String get homeCompletedRewardClaimed => 'Completed! Reward Claimed';

  @override
  String get homeStartChallengeNow => 'Start Challenge Now';

  @override
  String get homeFreshnessAll => 'All';

  @override
  String get homeFreshnessUnder6h => 'Under 6h';

  @override
  String get homeFreshnessUnder24h => 'Under 24h';

  @override
  String get homeFreshnessUnder72h => 'Under 72h';

  @override
  String get homeUpdatedJustNow => 'Updated just now';

  @override
  String get homeNoRecentPrice => 'No recent price';

  @override
  String homeUpdatedHoursAgo(Object hours) {
    return 'Updated $hours hours ago';
  }

  @override
  String homeUpdatedDaysAgo(Object days) {
    return 'Updated $days days ago';
  }

  @override
  String get homeVerifiedWithPhoto => 'Verified with photo';

  @override
  String homeKmAway(Object distance) {
    return '$distance km away';
  }

  @override
  String homeStoreDistancePrices(Object distance, Object count) {
    return '$distance km away • $count prices';
  }

  @override
  String get homeOffer1Title => 'Know The Best Price\nBefore You Leave';

  @override
  String get homeOffer1Subtitle => 'Fresh prices from shoppers near you';

  @override
  String get homeOffer2Title => 'Save The Trip\nAnd The Dirhams';

  @override
  String get homeOffer2Subtitle => 'Compare nearby stores before you go';

  @override
  String get homeOffer3Title => 'Need A Price Checked?\nAsk The Community';

  @override
  String get homeOffer3Subtitle => 'A real shopper can check the shelf';

  @override
  String get searchDailyFoods => 'Daily Foods';

  @override
  String get searchMyList => 'My list';

  @override
  String get searchCatFresh => 'Fresh';

  @override
  String get searchCatFruits => 'Fruits';

  @override
  String get searchCatSnacks => 'Snacks';

  @override
  String get searchCatGrocery => 'Grocery';

  @override
  String get searchCatOils => 'Oils';

  @override
  String get searchHint => 'Search vegetables, fruits and more';

  @override
  String get searchScanBarcode => 'Scan barcode';

  @override
  String get searchEmptyCategoryTitle => 'No products found in this category';

  @override
  String searchEmptyQueryTitle(Object query) {
    return 'We couldn\'t find \"$query\"';
  }

  @override
  String get searchEmptyCategorySubtitle =>
      'Try changing category or check back later.';

  @override
  String get searchEmptyQuerySubtitle =>
      'Tap below to ask other shoppers to check the price for you!';

  @override
  String get searchAskShoppersToCheck => 'Ask shoppers to check';

  @override
  String get searchRequestPriceCheckTitle => 'Request a price check';

  @override
  String searchRequestPriceCheckDescription(Object requestCost) {
    return 'Other shoppers will check the price of this item for you. This uses $requestCost tokens and refunds if it expires.';
  }

  @override
  String get searchItemNameLabel => 'Item name';

  @override
  String get searchItemNameHint => 'e.g. Al Rawabi Fresh Milk 2L';

  @override
  String get searchEnterProductName => 'Enter product name';

  @override
  String get searchChooseSupermarket => 'Choose supermarket';

  @override
  String get searchRequestPosted =>
      'Request posted! Shoppers near that store will be notified.';

  @override
  String get searchAskForThisPrice => 'Ask for this price';

  @override
  String get cartNoStoreYet => 'No store yet';

  @override
  String get cartMyList => 'My List';

  @override
  String get cartClearSavedPrices => 'Clear saved prices';

  @override
  String get cartSavedPricesCleared => 'Saved prices cleared';

  @override
  String get cartItemsYouAreChecking => 'Items you are checking';

  @override
  String get cartAddMore => 'Add more';

  @override
  String cartPriceDroppedOn(Object product) {
    return 'Price dropped on $product!';
  }

  @override
  String cartItemsCheaperNow(Object count) {
    return '$count items in your list are cheaper now!';
  }

  @override
  String cartPriceDropDetail(Object price, Object store, Object old) {
    return 'Now AED $price at $store (was AED $old).';
  }

  @override
  String get cartNoSavedPricesYet => 'No saved prices yet';

  @override
  String get cartEmptyStateSubtitle =>
      'Search an item and save it here to see which nearby store is worth visiting.';

  @override
  String get cartFindPricesNearby => 'Find prices nearby';

  @override
  String get cartShoppingListOptions => 'Shopping List Options';

  @override
  String get cartCheapestBasket => 'Cheapest Basket';

  @override
  String cartStoreWithDistance(Object store, Object distance) {
    return '$store ($distance km)';
  }

  @override
  String get cartClosestOption => 'Closest Option';

  @override
  String cartSaveAtStore(Object amount, Object store) {
    return 'Save AED $amount at $store';
  }

  @override
  String get cartClosestIsCheapest =>
      'Your closest store is also the cheapest option!';

  @override
  String cartBestSeenAt(Object store) {
    return 'Best seen at $store';
  }

  @override
  String get cartRemove => 'Remove';

  @override
  String get cartNearbyStoreComparison => 'Nearby store comparison';

  @override
  String cartKmAway(Object distance) {
    return '$distance km away';
  }

  @override
  String get cartBest => 'Best';

  @override
  String cartExtraAmount(Object amount) {
    return '+AED $amount';
  }

  @override
  String get cartPlainLanguageNote =>
      'DealSouk does not sell groceries. This list only helps you decide where to check prices nearby.';

  @override
  String get storeLocationPromptTitle => 'Find Supermarkets Near You';

  @override
  String get storeLocationPromptBody =>
      'DealSouk uses your location to show how far each Dubai supermarket is from you.';

  @override
  String get storeLocationPromptSkip => 'Skip';

  @override
  String get storeLocationPromptAllow => 'Allow';

  @override
  String get storeMapTitle => 'Dubai Store Map';

  @override
  String get storeSearchHint => 'Search store name or area…';

  @override
  String get storeNoStoresFound => 'No stores found';

  @override
  String get storeLoadingStores => 'Loading nearby stores…';

  @override
  String storeDubaiStoresCount(Object count) {
    return '$count Dubai stores';
  }

  @override
  String get storeTapPinHint => 'Tap a pin to see branch details';

  @override
  String storeMarkerTooltipWithDistance(Object name, Object branch, Object km) {
    return '$name · $branch\n$km km away';
  }

  @override
  String storeMarkerTooltip(Object name, Object branch) {
    return '$name\n$branch';
  }

  @override
  String get storeResetDubai => 'Dubai';

  @override
  String get storeNearYouTitle => 'Near You in Dubai';

  @override
  String get storeAllStoresTitle => 'All Dubai Stores';

  @override
  String storeWithinRadiusSorted(Object km) {
    return 'Within $km km · sorted by distance';
  }

  @override
  String storeStoresCount(Object count) {
    return '$count stores';
  }

  @override
  String storeNoStoresMatch(Object query) {
    return 'No stores match \"$query\"';
  }

  @override
  String get storeStaleBadge => 'Stale';

  @override
  String get storePricesLoadErrorTitle => 'Could not load prices';

  @override
  String get storePricesLoadErrorSubtitle =>
      'Check your connection or submit a fresh price for this branch.';

  @override
  String get storeNoPricesTitle => 'No fresh prices yet';

  @override
  String get storeNoPricesSubtitle =>
      'Be the first to share a shelf price at this branch.';

  @override
  String storePriceVerifiedWithPhoto(Object label) {
    return '$label · Verified with photo';
  }

  @override
  String get storeSubmitPriceHere => 'Submit Price Here';

  @override
  String storeDistanceKm(Object km) {
    return '$km km';
  }

  @override
  String get storeViewPrices => 'View Prices';

  @override
  String get submitStepSelectSupermarket => 'Select Supermarket';

  @override
  String get submitStepSelectProduct => 'Select Product';

  @override
  String get submitStepEnterPrice => 'Enter Price';

  @override
  String get submitStepConfirmSubmit => 'Confirm & submit';

  @override
  String get submitWhereDidYouSeePrice => 'Where did you see the price?';

  @override
  String get submitSelectSupermarketHint =>
      'Select the supermarket from the nearby list.';

  @override
  String submitSubmissionsLeftToday(Object remaining, Object cap) {
    return '$remaining of $cap submissions left today.';
  }

  @override
  String get submitWhichProduct => 'Which product is it?';

  @override
  String get submitSearchSelectProductHint =>
      'Search or select product and attach proof photo.';

  @override
  String get submitSearchBarcodeHint => 'Search name, brand or scan barcode';

  @override
  String get submitScanBarcodeTooltip => 'Scan barcode';

  @override
  String get submitNoProductsFound => 'No products found matching your search.';

  @override
  String submitUseTypedProduct(Object productName) {
    return 'Use “$productName” as a new product';
  }

  @override
  String get submitCommunityProductHint =>
      'Submit the shelf price for this exact item.';

  @override
  String get submitAttachProofRequired => 'Attach Proof (Required)';

  @override
  String get submitPriceLabelPhoto => 'Price Label Photo';

  @override
  String get submitReceiptPhoto => 'Receipt Photo';

  @override
  String get submitUploading => 'Uploading…';

  @override
  String get submitEnterPriceDetails => 'Enter Price details';

  @override
  String get submitEnterShelfPriceHint =>
      'Enter the shelf price and active promotions.';

  @override
  String get submitEnterPriceAed => 'Enter Price (AED)';

  @override
  String get submitManualShelfPriceHelper =>
      'Manual shelf price entry, e.g. 14.75';

  @override
  String get submitPleaseEnterPrice => 'Please enter a price';

  @override
  String get submitPleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get submitPromotionType => 'Promotion Type';

  @override
  String get submitPromoNone => 'None';

  @override
  String get submitPromoDiscount => 'Discount';

  @override
  String get submitPromoBogo => 'BOGO';

  @override
  String get submitPromoBundle => 'Bundle';

  @override
  String get submitConfirmDetails => 'Confirm details';

  @override
  String get submitReviewBeforeSubmission =>
      'Please review details before submission.';

  @override
  String get submitSummarySupermarket => 'Supermarket';

  @override
  String get submitSummaryProduct => 'Product';

  @override
  String get submitSummaryPrice => 'Price';

  @override
  String get submitSummaryPromotion => 'Promotion';

  @override
  String get submitSummaryProof => 'Proof';

  @override
  String get submitProofPhotoAttached => 'Photo Attached';

  @override
  String get submitTokenRewardEstimate => 'Token reward estimate';

  @override
  String submitPlusTokens(Object tokens) {
    return '+$tokens Tokens';
  }

  @override
  String get submitTokenFreshShelfPrice => 'Fresh shelf price';

  @override
  String get submitTokenStoreSelected => 'Store selected';

  @override
  String get submitTokenProductSelected => 'Product selected';

  @override
  String get submitTokenAedPriceEntered => 'AED price entered';

  @override
  String get submitTokenPriceLabelAttached => 'Price label attached';

  @override
  String get submitTokenAttachPriceLabel => 'Attach price label';

  @override
  String get submitTokenNoPromotion => 'No promotion selected';

  @override
  String submitTokenPromoNoted(Object promo) {
    return '$promo promo noted';
  }

  @override
  String get submitTokenReceiptMultiplier => '1.5× Verified Receipt Multiplier';

  @override
  String get submitTokenAttachReceiptBonus => 'Attach Receipt for 1.5× Bonus';

  @override
  String get submitTokenMultiplierApplied => '×1.5 applied';

  @override
  String get submitTokenNotApplied => 'not applied';

  @override
  String submitTokensAmount(Object count) {
    return '+$count tokens';
  }

  @override
  String submitTokenAmount(Object count) {
    return '+$count token';
  }

  @override
  String get submitTotalRewardEstimate => 'Total Reward Estimate';

  @override
  String submitTokensTotal(Object tokens) {
    return '$tokens Tokens';
  }

  @override
  String get submitBack => 'Back';

  @override
  String get submitNext => 'Next';

  @override
  String get submitSubmitAPrice => 'Submit a price';

  @override
  String get submitCouldNotSendPrice =>
      'We could not send this price. Please check your connection and try again.';

  @override
  String get submitSavedOffline =>
      'Saved. We\'ll submit this price automatically when you\'re back online.';

  @override
  String get offlineBanner =>
      'You\'re offline. Changes are saved and will sync when you reconnect.';

  @override
  String offlinePendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String submitTransactionDescription(
    Object tokens,
    Object product,
    Object store,
  ) {
    return '+$tokens tokens for $product at $store';
  }

  @override
  String get submitPhotoUploaded => 'Photo Uploaded';

  @override
  String get submitPhotoUploadFailed =>
      'Couldn\'t add the photo. Tap to try again.';

  @override
  String get submitProofPhotoRequired =>
      'The proof photo did not finish uploading. Please tap the photo and try again.';

  @override
  String get submitReceiptPhotoRequired =>
      'The receipt photo did not finish uploading. Please retry it, or retake the price-label photo only.';

  @override
  String get submitTapToUpload => 'Tap to Upload';

  @override
  String get submitTapToRetry => 'Tap to retry';

  @override
  String get submitTapToRetake => 'Tap to retake';

  @override
  String get submitPriceSubmitted => 'Price Submitted!';

  @override
  String submitTokensGained(Object tokens) {
    return '+$tokens tokens';
  }

  @override
  String submitPendingReviewMessage(Object name) {
    return 'Your price submission is pending review.\nTokens will be credited to $name after admin approval.';
  }

  @override
  String get submitAwaitingApproval => 'Waiting for approval';

  @override
  String submitApprovedNowMessage(Object name) {
    return 'Nice work, $name. These tokens were added now. Pull down on your profile any time to refresh the latest balance.';
  }

  @override
  String get submitOpenAdminReview => 'Open Admin Review';

  @override
  String get submitViewTokenBalance => 'View Token Balance';

  @override
  String profileLevelBadge(Object level, Object title) {
    return 'Lv.$level $title';
  }

  @override
  String profileDayStreak(Object days) {
    return '$days day streak';
  }

  @override
  String get profileTabSubmissions => 'Prices';

  @override
  String get profileTabTokens => 'Tokens';

  @override
  String get profileTabRequests => 'Requests';

  @override
  String get profileTabSettings => 'Settings';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String get profilePhotoRemoved => 'Profile photo removed';

  @override
  String get profileAccuracyRating => 'Accuracy Rating';

  @override
  String profileAccuracyApproved(Object percent) {
    return '$percent% of your submissions approved';
  }

  @override
  String get profileNoSubmissions =>
      'No prices shared yet.\nShare a shelf price to help shoppers and earn tokens.';

  @override
  String get profileCurrentBalance => 'Current Balance';

  @override
  String get profileTapLeaderboardRedeem => 'Tap Leaderboard to redeem';

  @override
  String get profileNoTokenActivity =>
      'No token activity yet.\nShare a price or help with a request to start earning.';

  @override
  String get profileNoPriceRequests =>
      'No price requests yet.\nAsk for a price when you cannot find an item.';

  @override
  String get profileCancelRequest => 'Cancel request';

  @override
  String get profileCancelRequestTitle => 'Cancel Request?';

  @override
  String profileCancelRequestBody(Object product) {
    return 'Are you sure you want to cancel your price request for \"$product\"? Your bounty tokens will be refunded.';
  }

  @override
  String get profileNo => 'No';

  @override
  String get profileYesCancel => 'Yes, Cancel';

  @override
  String get profileVoucherApproved => 'Voucher Approved';

  @override
  String get profileCodePending => 'Code pending';

  @override
  String get profileVoucherUnderReview => 'Voucher Under Review';

  @override
  String profileVoucherPendingBody(Object amount, Object supermarket) {
    return 'Your AED $amount $supermarket voucher is waiting for admin approval.';
  }

  @override
  String get profileVoucherReady => 'Voucher Ready!';

  @override
  String get profileVoucherReadyBody =>
      'Head to the Leaderboard tab to claim your AED 50 Union Coop voucher.';

  @override
  String get profileClaimVoucherNow => 'Claim Voucher Now';

  @override
  String get profileVoucherGoalTitle => 'AED 50 Union Coop Voucher';

  @override
  String profileEarnMoreTokens(Object count) {
    return 'Earn $count more tokens to unlock your voucher.';
  }

  @override
  String get profilePhotoTitle => 'Profile Photo';

  @override
  String get profilePhotoSubtitleEmpty =>
      'Add a friendly photo so shoppers recognise you';

  @override
  String get profilePhotoSubtitleSet => 'Change or remove your current photo';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileRemovePhoto => 'Remove photo';

  @override
  String get profilePhotoTakePhoto => 'Take a photo';

  @override
  String get profilePhotoChooseLibrary => 'Choose from library';

  @override
  String get profileEditPhotoTooltip => 'Edit profile photo';

  @override
  String get profileStatTokens => 'Tokens';

  @override
  String get profileStatAccuracy => 'Accuracy';

  @override
  String get profileStatApproved => 'Approved';

  @override
  String get profileStatStreak => 'Streak';

  @override
  String get profileSectionSubmissions => 'My Submissions';

  @override
  String get profileSectionTokens => 'Token History';

  @override
  String get profileSectionRequests => 'My Requests';

  @override
  String get profileSectionSettings => 'Settings & Account';

  @override
  String get profileDisplayName => 'Display Name';

  @override
  String get profileEditDisplayName => 'Edit display name';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileSave => 'Save';

  @override
  String get profileHomeArea => 'Home Area';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileViewTutorial => 'View App Tutorial';

  @override
  String get profileViewTutorialSubtitle => 'Re-run the DealSouk intro guide';

  @override
  String get profilePrivacyTerms => 'Privacy & Terms';

  @override
  String get profilePrivacyTermsSubtitle =>
      'Location, photos, tokens, vouchers, and account deletion';

  @override
  String get profileAdminConsole => 'Admin Review Console';

  @override
  String get profileAdminConsoleSubtitle => 'Moderate price submissions';

  @override
  String get profileLogOut => 'Log Out';

  @override
  String get profileLogOutDemo => 'Log Out of Demo';

  @override
  String get welcomePrivacyConsentRequired =>
      'Please agree to the Privacy Policy to continue.';

  @override
  String welcomeInvalidPhoneNumber(Object digits, Object country) {
    return 'Please enter a valid $digits-digit phone number for $country.';
  }

  @override
  String get welcomeSelectCountry => 'Select Country';

  @override
  String get welcomeModeratorToggleEnabled => 'Moderator toggle enabled';

  @override
  String get welcomeModeratorToggleDisabled => 'Moderator toggle disabled';

  @override
  String get welcomeTaglineAdmin =>
      'Review supermarket prices shared by shoppers';

  @override
  String get welcomeTaglineCustomer => 'Prices shared by shoppers near you';

  @override
  String get welcomeCustomerModeTab => 'Customer Mode';

  @override
  String get welcomeAdminModeratorTab => 'Admin Moderator';

  @override
  String get welcomePillarAuditQueue => 'Audit\nQueue';

  @override
  String get welcomePillarFraudFilter => 'Fraud\nFilter';

  @override
  String get welcomePillarIssueTokens => 'Issue\nTokens';

  @override
  String get welcomePillarComparePrices => 'Compare\nPrices';

  @override
  String get welcomePillarFindNearby => 'Find\nNearby';

  @override
  String get welcomePillarRequestPrice => 'Request\nPrice';

  @override
  String get welcomeInfoBannerAdmin =>
      'Moderator Panel: Verify receipts and shelf prices.';

  @override
  String get welcomeInfoBannerCustomer =>
      'No ordering here. Just check prices before you go.';

  @override
  String get welcomePrivacyConsentPrefix => 'I agree to the ';

  @override
  String get welcomePrivacyPolicyLink => 'Privacy Policy';

  @override
  String get welcomePrivacyConsentSuffix =>
      ' and consent to neighbourhood-level location processing.';

  @override
  String get welcomeEnterAdminDashboard => 'Enter Admin Dashboard';

  @override
  String get welcomeContinueWithGoogle => 'Continue with Google';

  @override
  String get welcomeSignInWithPhone => 'Sign in with Phone';

  @override
  String get welcomeSignInWithApple => 'Sign in with Apple';

  @override
  String get welcomeBrowseAsGuest => 'Browse as Guest';

  @override
  String get welcomeFooterAdmin => 'Moderator console permissions apply.';

  @override
  String get welcomeFooterCustomer =>
      'Supermarket prices shared by shoppers in Dubai.';

  @override
  String get welcomeCancel => 'Cancel';

  @override
  String get welcomeSendCode => 'Send Code';

  @override
  String welcomeOtpPrompt(Object phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get welcomeVerify => 'Verify';

  @override
  String get welcomeResendCode => 'Resend code';

  @override
  String get productDetailsTitle => 'Details';

  @override
  String get productAddToFavourites => 'Add to favourites';

  @override
  String get productRemoveFromFavourites => 'Remove from favourites';

  @override
  String productBestPriceSeenAt(Object store) {
    return 'Best price seen at $store';
  }

  @override
  String get productRequestThisPrice => 'Request this price';

  @override
  String get productRequestPriceConfirmation =>
      'Request this price! Other shoppers will check it soon.';

  @override
  String get productCompareStorePrices => 'Compare Store Prices';

  @override
  String get productNoFreshPrices => 'No fresh prices yet.';

  @override
  String get productNoFreshPricesHint =>
      'Ask another shopper to check this item before you make the trip.';

  @override
  String get productPriceFlaggedHidden =>
      'Price flagged & hidden (Pending admin audit)';

  @override
  String productStoreDistance(Object store, Object distance) {
    return '$store • $distance km away';
  }

  @override
  String productFreshnessVerified(Object freshness) {
    return '$freshness • Verified with photo';
  }

  @override
  String get productUpdatedJustNow => 'Updated just now';

  @override
  String productUpdatedHoursAgo(Object hours) {
    return 'Updated $hours hours ago';
  }

  @override
  String productUpdatedDaysAgo(Object days) {
    return 'Updated $days days ago';
  }

  @override
  String productUpdatedLabel(Object label) {
    return 'Updated $label';
  }

  @override
  String get productBestPriceBadge => 'BEST PRICE';

  @override
  String get productReportHiddenMessage =>
      'Thanks. This price is hidden until an admin reviews it.';

  @override
  String get productReportPendingMessage =>
      'Thanks. We will hide this price after 3 unique reports.';

  @override
  String get productReported => 'Reported';

  @override
  String get productReportWrongPrice => 'Report wrong price';

  @override
  String get productPriceHistory90Day => '90-Day Price History';

  @override
  String get productYouMayAlsoLike => 'You may also like';

  @override
  String get productBestSeenPrice => 'Best seen price';

  @override
  String get productSignInToSavePrices =>
      'Please sign in to save prices and compare grocery baskets.';

  @override
  String get productSignInAction => 'SIGN IN';

  @override
  String productSavedForComparison(Object name) {
    return '$name saved for price comparison';
  }

  @override
  String get productViewAction => 'VIEW';

  @override
  String get productSavePrice => 'Save Price';

  @override
  String get productNoPriceHistory =>
      'No approved price history yet. Once shoppers submit fresh prices, you will see the trend here.';

  @override
  String productPriceRange(Object lowest, Object highest) {
    return 'Lowest $lowest • Highest $highest';
  }

  @override
  String productLatestPrice(Object latest) {
    return 'Latest $latest';
  }

  @override
  String get requestBannerExplanation =>
      'Need a price checked? Ask nearby shoppers. If someone is already at that store, they can send back the shelf price.';

  @override
  String requestMyRequestsTitle(Object count) {
    return 'My price requests ($count)';
  }

  @override
  String requestBoardTitle(Object count) {
    return 'Price checks people need ($count)';
  }

  @override
  String get requestAskForPrice => 'Ask for a price';

  @override
  String get requestPendingStatus => 'PENDING';

  @override
  String get requestEmptyTitle => 'All price requests are completed!';

  @override
  String get requestEmptySubtitle =>
      'Need a price? Tap \'Ask for a price\' to request a price check.';

  @override
  String get requestFormTitle => 'Ask for a price check';

  @override
  String requestFormSubtitle(Object tokens) {
    return 'Tell us the item and store. This uses $tokens tokens and refunds automatically if it expires.';
  }

  @override
  String get requestItemNameLabel => 'Item name';

  @override
  String get requestItemNameHint => 'e.g. milk, rice, apples';

  @override
  String get requestItemNameValidation => 'Please enter the item name';

  @override
  String get requestStoreLabel => 'Supermarket Chain';

  @override
  String get requestSentTitle => 'Price request sent';

  @override
  String requestSentBody(Object productName, Object storeName, Object tokens) {
    return 'Nearby shoppers can check $productName at $storeName. $tokens tokens were reserved and will refund if the request expires.';
  }

  @override
  String get requestSentConfirm => 'Great';

  @override
  String get requestSubmitButton => 'Ask for this price';

  @override
  String requestCardSubtitle(Object storeName, Object requesterName) {
    return '$storeName • Posted by $requesterName';
  }

  @override
  String requestCheckPriceButton(Object tokens) {
    return 'Check price (+$tokens Tokens)';
  }

  @override
  String get storeLoadErrorTitle => 'Couldn\'t load stores';

  @override
  String get storeLoadErrorSubtitle => 'Check your connection and try again.';

  @override
  String get storeRetryButton => 'Retry';

  @override
  String get storeChainAll => 'All';

  @override
  String get storeFilterTitle => 'Filter stores';

  @override
  String storeMaxDistance(Object km) {
    return 'Maximum distance: $km km';
  }

  @override
  String get storeSortBy => 'Sort by';

  @override
  String get storeSortClosest => 'Closest first';

  @override
  String get storeSortAlpha => 'Alphabetical (A–Z)';

  @override
  String get storeSortRecent => 'Recently updated';

  @override
  String get storeApplyFilters => 'Apply filters';

  @override
  String get storeGpsOnlyNote =>
      'The distance filter only applies when you are in Dubai with location turned on.';

  @override
  String get storeRequiresGps => 'Needs your location';

  @override
  String get storeDirections => 'Directions';

  @override
  String get storeFresh => 'Fresh';

  @override
  String storePricesCountLabel(Object count) {
    return '$count prices';
  }

  @override
  String storeUpdatedAgo(Object label) {
    return 'Updated $label';
  }

  @override
  String get storeSelectedHint => 'Select a store to see its prices';

  @override
  String get leaderRewardsTitle => 'Rewards & Leaderboard';

  @override
  String get leaderToggleStreaks => 'Leaderboard & Streaks';

  @override
  String get leaderToggleRequestBoard => 'Active Request Board';

  @override
  String leaderRankNumber(Object n) {
    return 'Rank #$n';
  }

  @override
  String get leaderRankUnknown => 'Unranked';

  @override
  String leaderDayStreak(Object days) {
    return '$days Day Streak';
  }

  @override
  String get leaderTokensLabel => 'Tokens';

  @override
  String get leaderVoucherName => 'AED 50 Union Coop Voucher';

  @override
  String leaderTokenProgress(Object tokens, Object target) {
    return '$tokens / $target T';
  }

  @override
  String get leaderVoucherRedeemed => 'Redeemed AED 50 Union Coop Voucher';

  @override
  String get leaderVoucherClaimedTitle => 'Voucher Claimed!';

  @override
  String get leaderVoucherClaimedBody =>
      'Show the barcode or code below to the cashier at any Union Coop checkout in Dubai.';

  @override
  String get leaderBackToRewards => 'Back to Rewards';

  @override
  String get leaderClaimVoucher => 'Claim Voucher Now';

  @override
  String leaderEarnMoreTokens(Object count) {
    return 'Earn $count more tokens to redeem your voucher.';
  }

  @override
  String get leaderShopperBadges => 'Shopper Badges';

  @override
  String get leaderTodaysChallenges => 'Today\'s Challenges';

  @override
  String leaderChallengeDone(Object tokens) {
    return 'Done! +${tokens}T';
  }

  @override
  String leaderChallengeBonus(Object tokens) {
    return '+$tokens bonus tokens';
  }

  @override
  String leaderChallengeProgress(Object progress, Object target) {
    return '$progress/$target done • Tap to submit a price';
  }

  @override
  String get leaderDubaiLeaderboard => 'Dubai Leaderboard';

  @override
  String get leaderHallOfFame => 'Hall of Fame';

  @override
  String get leaderTopChampions => 'Last month\'s top champions';

  @override
  String leaderYouMarker(Object name) {
    return '$name (You)';
  }

  @override
  String get privacyTitle => 'Privacy & Terms';

  @override
  String get privacySummaryTitle => 'Plain English Summary';

  @override
  String get privacySummaryItem1 =>
      'DealSouk helps shoppers compare grocery prices using community-submitted prices.';

  @override
  String get privacySummaryItem2 =>
      'We ask for only the information needed to run the app: your account, home area, language, submissions, requests, tokens, and moderation history.';

  @override
  String get privacySummaryItem3 =>
      'We use your device location only to show nearby supermarket prices. Precise GPS is not stored permanently.';

  @override
  String get privacySummaryItem4 =>
      'Tokens are rewards inside DealSouk. They are not cash, cannot be transferred, and cannot be sold.';

  @override
  String get privacySummaryItem5 =>
      'Photos are used to verify price labels or receipts. Do not upload photos with personal information.';

  @override
  String get privacySummaryItem6 =>
      'You can request account deletion from Profile settings.';

  @override
  String get privacyCollectTitle => 'What We Collect';

  @override
  String get privacyCollectItem1 =>
      'Account details: Firebase account ID, display name, phone number if you use phone login, and preferred language.';

  @override
  String get privacyCollectItem2 =>
      'Shopping area: neighbourhood or area, not a permanent precise GPS record.';

  @override
  String get privacyCollectItem3 =>
      'Price data: products, stores, prices, timestamps, optional shelf label or receipt photos, and moderation flags.';

  @override
  String get privacyCollectItem4 =>
      'Rewards data: token balance, token history, voucher requests, badges, streaks, and leaderboard totals.';

  @override
  String get privacyCollectItem5 =>
      'Device messaging token: used only for DealSouk notifications such as request fulfilment or reward updates.';

  @override
  String get privacyUseTitle => 'How We Use Data';

  @override
  String get privacyUseItem1 => 'To show fresh prices near you.';

  @override
  String get privacyUseItem2 =>
      'To calculate savings, requests, tokens, and rewards.';

  @override
  String get privacyUseItem3 =>
      'To detect wrong, stale, duplicate, or suspicious submissions.';

  @override
  String get privacyUseItem4 =>
      'To operate admin moderation and voucher approval.';

  @override
  String get privacyUseItem5 =>
      'To improve reliability, security, and Arabic/English usability.';

  @override
  String get privacyChoicesTitle => 'Your Choices';

  @override
  String get privacyChoicesItem1 =>
      'You may browse as a guest with limited features.';

  @override
  String get privacyChoicesItem2 =>
      'You can change your display name, home area, and language.';

  @override
  String get privacyChoicesItem3 =>
      'You can deny location access and still use non-location features.';

  @override
  String get privacyChoicesItem4 =>
      'You can request account deletion. We anonymise account data needed for fraud prevention and financial/reward audit records.';

  @override
  String get privacyArabicTitle => 'Arabic Summary';

  @override
  String get privacyArabicItem1 =>
      'We use your location only to show nearby store prices, and we do not permanently store precise GPS location.';

  @override
  String get privacyArabicItem2 =>
      'Tokens are in-app rewards, not cash, and cannot be sold or transferred.';

  @override
  String get privacyArabicItem3 =>
      'Price or receipt photos are used for verification only. Do not upload photos containing personal information.';

  @override
  String get privacyArabicItem4 =>
      'You can request account deletion from settings.';

  @override
  String get tutorialCompareTitle => 'Compare Grocery Prices';

  @override
  String get tutorialCompareDescription =>
      'Find nearby prices for fruits, vegetables, dairy, and snacks in Dubai supermarkets before you leave home.';

  @override
  String get tutorialMapTitle => 'Find Stores On The Map';

  @override
  String get tutorialMapDescription =>
      'See participating supermarkets across Dubai on the map, with how fresh each store\'s prices are before you go.';

  @override
  String get tutorialAskTitle => 'Ask For Price Checks';

  @override
  String get tutorialAskDescription =>
      'Need a price you cannot see? Ask the community to check it, or help others by sharing a shelf price.';

  @override
  String get tutorialEarnTitle => 'Earn Shopping Rewards';

  @override
  String get tutorialEarnDescription =>
      'Share prices or check shelves to earn tokens, then swap them for real supermarket vouchers.';

  @override
  String get tutorialCompeteTitle => 'Climb The Leaderboard';

  @override
  String get tutorialCompeteDescription =>
      'Keep a daily streak, complete challenges, earn badges, and rise up the Dubai leaderboard as you contribute.';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialGetStarted => 'Get Started';

  @override
  String get profileTextSize => 'Text size';

  @override
  String get textSizeStandard => 'Standard';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeExtraLarge => 'Extra large';

  @override
  String get profileTextSizeSubtitle => 'Makes all text in the app bigger';

  @override
  String get privacyCreditsTitle => 'Photo and map credits';

  @override
  String get tutorialBack => 'Back';

  @override
  String tutorialStep(int current, int total) {
    return 'STEP $current OF $total';
  }

  @override
  String get unauthorizedTitle => 'Moderators only';

  @override
  String get unauthorizedBody =>
      'This area is only available to moderator accounts. If you should have access, ask an administrator to add your account.';

  @override
  String get unauthorizedAction => 'Sign in with a different account';

  @override
  String get modTitle => 'Moderator';

  @override
  String get navModeration => 'Price moderation';

  @override
  String get navMap => 'Map density';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navVouchers => 'Voucher queue';

  @override
  String get navStock => 'Voucher stock';

  @override
  String get navSettings => 'System settings';

  @override
  String get navProducts => 'Manage products';

  @override
  String get navUsers => 'Manage users';

  @override
  String get modBackToApp => 'Back to app';

  @override
  String get modLogOut => 'Log out';

  @override
  String get modRoleViewerTag => 'Role: Viewer';

  @override
  String get modRoleTag => 'Role: Moderator';

  @override
  String get modRefresh => 'Refresh';

  @override
  String get modExportCsv => 'Export CSV';

  @override
  String get modMenu => 'Menu';

  @override
  String get modDemoBanner =>
      'Demo mode: you can look around, but changes are turned off. Only the owner can make changes, and personal details are hidden.';

  @override
  String get modSyncing => 'Syncing with server...';

  @override
  String get modPendingReviews => 'Pending reviews';

  @override
  String get modApprovedToday => 'Approved today';

  @override
  String get modTokensIssued => 'Tokens issued';

  @override
  String modSubmissionsHeader(int count) {
    return 'Submissions ($count)';
  }

  @override
  String modTabPending(int count) {
    return 'Pending ($count)';
  }

  @override
  String modTabFlagged(int count) {
    return 'Flagged ($count)';
  }

  @override
  String get modQueueClearedTitle => 'Queue cleared';

  @override
  String get modQueueClearedBody =>
      'No pending price reports need verification.';

  @override
  String get modPricePhoto => 'Price photo';

  @override
  String get modReceipt => 'Receipt';

  @override
  String get modCommunityFlagged => 'Community flagged';

  @override
  String modRewardPlus(int tokens) {
    return 'Reward +$tokens';
  }

  @override
  String get modReject => 'Reject';

  @override
  String get modDelete => 'Delete';

  @override
  String get modEdit => 'Edit';

  @override
  String get modApprove => 'Approve';

  @override
  String get modReinstate => 'Reinstate';

  @override
  String get modAuditTitle => 'Review submission';

  @override
  String get modFlaggedReview => 'Flagged report review';

  @override
  String get modStatusPending => 'Pending';

  @override
  String get modStatusFlagged => 'Flagged';

  @override
  String modIdSubmitted(String id, String time) {
    return 'ID: $id · Submitted $time';
  }

  @override
  String get modFlaggedAlertTitle => 'Accuracy alert';

  @override
  String modFlaggedAlertBody(String price, String product, String store) {
    return 'Shoppers flagged this price 3+ times. AED $price for $product at $store is reported as incorrect.';
  }

  @override
  String get modEvidence => 'Attached evidence (tap to view)';

  @override
  String get modPriceLabel => 'Price label';

  @override
  String get modChecklist => 'Checklist';

  @override
  String get modInvestigation => 'Investigation steps';

  @override
  String modChkStore(String store) {
    return 'Receipt matches store: $store';
  }

  @override
  String get modChkSize => 'Price matches the pack size';

  @override
  String get modChkPromo => 'Check for discount or promo tags';

  @override
  String get modChkFresh => 'Receipt date is recent';

  @override
  String get modInvCatalog => 'Compare with the store\'s online catalogue';

  @override
  String get modInvDistributor => 'Check for a distributor price change';

  @override
  String get modInvTrusted => 'Check whether a trusted user submitted it';

  @override
  String get modInvReason => 'Reason: shopper says the price is wrong';

  @override
  String get modAccuracyTitle => 'Submitter accuracy';

  @override
  String get modAccuracySub => 'Trust score from past reviews';

  @override
  String get modTrustTitle => 'Reporter trust level';

  @override
  String get modTrustSub => 'Based on reporter history';

  @override
  String get modEditSubmission => 'Edit submission';

  @override
  String get modConfirmDeletion => 'Confirm deletion';

  @override
  String get modNothingSelected => 'Nothing selected';

  @override
  String get modSelectToAudit => 'Pick a submission to review it';

  @override
  String get modSourcerControls => 'Contributor controls';

  @override
  String get modWarn => 'Warn user';

  @override
  String get modSuspend => 'Suspend';

  @override
  String get modBan => 'Ban';

  @override
  String modCsvCopied(int count) {
    return 'Copied $count rows as CSV';
  }

  @override
  String modPriceSubmissions(int count) {
    return 'Price submissions ($count)';
  }

  @override
  String get vqEmptyTitle => 'No voucher requests';

  @override
  String get vqEmptyBody =>
      'New requests appear here when shoppers reach the token threshold.';

  @override
  String vqLine(String user, int amount, String store) {
    return '$user · AED $amount $store';
  }

  @override
  String vqMeta(String area, int balance, int cost) {
    return '$area · $balance tokens available · cost $cost';
  }

  @override
  String get mapInfo =>
      'Active price submissions across Dubai. Bigger circles mean more submissions. Tap a pin for store details.';

  @override
  String get mapSearchHint => 'Search stores by name, branch or area';

  @override
  String get mapNoStores => 'No stores match the filters.';

  @override
  String mapStoreMeta(String area, int count) {
    return '$area · Approved: $count';
  }

  @override
  String mapApprovedCount(int count) {
    return 'Approved submissions: $count';
  }

  @override
  String mapArea(String area) {
    return 'Area: $area';
  }

  @override
  String get mapClose => 'Close';

  @override
  String get vsTitle => 'Voucher stock';

  @override
  String get vsImport => 'Import voucher codes';

  @override
  String get vsEmpty => 'No voucher stock yet. Import codes to add some.';

  @override
  String vsItem(String store, int amount) {
    return '$store (AED $amount)';
  }

  @override
  String get vsUsed => 'Used vouchers';

  @override
  String get vsAvailable => 'Available stock';

  @override
  String vsCodes(int count) {
    return '$count codes';
  }

  @override
  String get setTitle => 'Token economy settings';

  @override
  String get setEarn => 'Token earn rate (base)';

  @override
  String get setThreshold => 'Voucher threshold';

  @override
  String get setCap => 'Daily submission cap';

  @override
  String get setRequestCost => 'Request cost';

  @override
  String setTokens(int count) {
    return '$count tokens';
  }

  @override
  String setPerDay(int count) {
    return '$count per day';
  }

  @override
  String get setNote => 'Changes take effect immediately.';

  @override
  String get prSearch => 'Search products by name, brand or barcode';

  @override
  String get prAdd => 'Add product';

  @override
  String get prEmpty => 'No products match the filters.';

  @override
  String prMeta(String brand, String size, String category) {
    return '$brand · $size · $category';
  }

  @override
  String prTotal(int count) {
    return 'Total products: $count';
  }

  @override
  String prPage(int page) {
    return 'Page $page';
  }

  @override
  String get usSearch => 'Search users by name, phone or ID';

  @override
  String get usAdd => 'Add user';

  @override
  String get usEmpty => 'No users match the search.';

  @override
  String get usAdminTag => 'Admin';

  @override
  String usMeta(String area, int tokens, String accuracy) {
    return '$area · $tokens tokens · $accuracy% accuracy';
  }

  @override
  String usTotal(int count) {
    return 'Total users: $count';
  }

  @override
  String get anToday => 'Today';

  @override
  String get anMonth => 'This month';

  @override
  String get anPendingVouchers => 'Pending vouchers';

  @override
  String get anTrending => 'Trending products';

  @override
  String get anTrendingEmpty => 'No product trends yet.';

  @override
  String get anCoverage => 'Coverage hotspots';

  @override
  String get anCoverageEmpty => 'No coverage data yet.';

  @override
  String anSubmissions(int count) {
    return '$count submissions';
  }

  @override
  String anRecent(int count) {
    return '$count recent';
  }

  @override
  String get anExports => 'Data exports and reports';

  @override
  String get anCsvBtn => 'Download CSV report';

  @override
  String get anPdfBtn => 'Export PDF report';

  @override
  String get anDownloadingCsv => 'Downloading CSV...';

  @override
  String get anGeneratingPdf => 'Generating PDF...';

  @override
  String anFailed(String error) {
    return 'Could not complete the export: $error';
  }
}
