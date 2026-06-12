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
  String get cart => 'Cart';

  @override
  String get leaderboard => 'Leaderboard';

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
  String get sourcerBadges => 'Sourcer Badges';

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
  String get unverifiedOutdated => 'Unverified — may be outdated';

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
}
