import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DealSouk'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'My list'**
  String get cart;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get leaderboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greeting;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @freshPrices.
  ///
  /// In en, this message translates to:
  /// **'Fresh Prices'**
  String get freshPrices;

  /// No description provided for @freshPricesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live crowd-sourced prices near you'**
  String get freshPricesSubtitle;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get searchProducts;

  /// No description provided for @searchNearbyStores.
  ///
  /// In en, this message translates to:
  /// **'Search nearby Dubai stores'**
  String get searchNearbyStores;

  /// No description provided for @nearbyStores.
  ///
  /// In en, this message translates to:
  /// **'Nearby Supermarkets'**
  String get nearbyStores;

  /// No description provided for @storeMap.
  ///
  /// In en, this message translates to:
  /// **'Store Map'**
  String get storeMap;

  /// No description provided for @tokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get tokens;

  /// No description provided for @tokenBalance.
  ///
  /// In en, this message translates to:
  /// **'Token Balance'**
  String get tokenBalance;

  /// No description provided for @earnTokens.
  ///
  /// In en, this message translates to:
  /// **'Earn tokens'**
  String get earnTokens;

  /// No description provided for @spendTokens.
  ///
  /// In en, this message translates to:
  /// **'Spend tokens'**
  String get spendTokens;

  /// No description provided for @tokenHistory.
  ///
  /// In en, this message translates to:
  /// **'Token History'**
  String get tokenHistory;

  /// No description provided for @voucherReady.
  ///
  /// In en, this message translates to:
  /// **'Voucher Ready!'**
  String get voucherReady;

  /// No description provided for @voucherProgress.
  ///
  /// In en, this message translates to:
  /// **'Earn {remaining} more tokens to redeem your voucher.'**
  String voucherProgress(int remaining);

  /// No description provided for @claimVoucher.
  ///
  /// In en, this message translates to:
  /// **'Claim Voucher Now'**
  String get claimVoucher;

  /// No description provided for @voucherClaimed.
  ///
  /// In en, this message translates to:
  /// **'Voucher Claimed!'**
  String get voucherClaimed;

  /// No description provided for @voucherDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the barcode or code below to the cashier at any Union Coop checkout in Dubai.'**
  String get voucherDescription;

  /// No description provided for @backToRewards.
  ///
  /// In en, this message translates to:
  /// **'Back to Rewards'**
  String get backToRewards;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @dubaiLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Dubai Leaderboard'**
  String get dubaiLeaderboard;

  /// No description provided for @lastMonthChampions.
  ///
  /// In en, this message translates to:
  /// **'Last Month\'s Champions'**
  String get lastMonthChampions;

  /// No description provided for @sourcerBadges.
  ///
  /// In en, this message translates to:
  /// **'Shopper Badges'**
  String get sourcerBadges;

  /// No description provided for @todaysChallenges.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Challenges'**
  String get todaysChallenges;

  /// No description provided for @activeRequestBoard.
  ///
  /// In en, this message translates to:
  /// **'Active Request Board'**
  String get activeRequestBoard;

  /// No description provided for @leaderboardStreaks.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard & Streaks'**
  String get leaderboardStreaks;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Rank #{rank}'**
  String yourRank(int rank);

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} Day Streak'**
  String dayStreak(int days);

  /// No description provided for @submitPrice.
  ///
  /// In en, this message translates to:
  /// **'Upload Price'**
  String get submitPrice;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get submitForReview;

  /// No description provided for @priceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Price Submitted!'**
  String get priceSubmitted;

  /// No description provided for @priceSubmittedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your price submission is pending review.\nTokens will be credited after admin approval.'**
  String get priceSubmittedDesc;

  /// No description provided for @openAdminReview.
  ///
  /// In en, this message translates to:
  /// **'Open Admin Review'**
  String get openAdminReview;

  /// No description provided for @viewTokenBalance.
  ///
  /// In en, this message translates to:
  /// **'View Token Balance'**
  String get viewTokenBalance;

  /// No description provided for @tokenRewardEstimate.
  ///
  /// In en, this message translates to:
  /// **'Token reward estimate'**
  String get tokenRewardEstimate;

  /// No description provided for @totalRewardEstimate.
  ///
  /// In en, this message translates to:
  /// **'Total Reward Estimate'**
  String get totalRewardEstimate;

  /// No description provided for @selectSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Select Supermarket'**
  String get selectSupermarket;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @enterPriceAed.
  ///
  /// In en, this message translates to:
  /// **'Enter Price (AED)'**
  String get enterPriceAed;

  /// No description provided for @promotionType.
  ///
  /// In en, this message translates to:
  /// **'Promotion Type'**
  String get promotionType;

  /// No description provided for @priceLabelPhoto.
  ///
  /// In en, this message translates to:
  /// **'Price Label Photo'**
  String get priceLabelPhoto;

  /// No description provided for @receiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Receipt Photo'**
  String get receiptPhoto;

  /// No description provided for @photoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo Uploaded'**
  String get photoUploaded;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to Upload'**
  String get tapToUpload;

  /// No description provided for @dailyCapRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {cap} submissions left today'**
  String dailyCapRemaining(int remaining, int cap);

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @challengeBonus.
  ///
  /// In en, this message translates to:
  /// **'+{tokens} bonus tokens'**
  String challengeBonus(int tokens);

  /// No description provided for @challengeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done! +{tokens} tokens earned'**
  String challengeCompleted(int tokens);

  /// No description provided for @challengeProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done'**
  String challengeProgress(int done, int total);

  /// No description provided for @tapToComplete.
  ///
  /// In en, this message translates to:
  /// **'Tap to start submitting'**
  String get tapToComplete;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileSettings;

  /// No description provided for @mySubmissions.
  ///
  /// In en, this message translates to:
  /// **'My Submissions'**
  String get mySubmissions;

  /// No description provided for @myTokenHistory.
  ///
  /// In en, this message translates to:
  /// **'Token History'**
  String get myTokenHistory;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @homeArea.
  ///
  /// In en, this message translates to:
  /// **'Home Area'**
  String get homeArea;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out of Demo'**
  String get logOut;

  /// No description provided for @accuracyRating.
  ///
  /// In en, this message translates to:
  /// **'Accuracy Rating'**
  String get accuracyRating;

  /// No description provided for @accuracyRatingDesc.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of your submissions approved'**
  String accuracyRatingDesc(int percent);

  /// No description provided for @noSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet.\nSubmit a price to get started!'**
  String get noSubmissionsYet;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No price requests yet.'**
  String get noRequestsYet;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @fulfilled.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled'**
  String get fulfilled;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Moderator Console'**
  String get adminConsole;

  /// No description provided for @priceModeration.
  ///
  /// In en, this message translates to:
  /// **'Price Moderation'**
  String get priceModeration;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @sourcersIndex.
  ///
  /// In en, this message translates to:
  /// **'Sourcers Index'**
  String get sourcersIndex;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @editSubmission.
  ///
  /// In en, this message translates to:
  /// **'Edit Submission'**
  String get editSubmission;

  /// No description provided for @tokenEarnRate.
  ///
  /// In en, this message translates to:
  /// **'Token Earn Rate (base)'**
  String get tokenEarnRate;

  /// No description provided for @voucherThreshold.
  ///
  /// In en, this message translates to:
  /// **'Voucher Threshold (tokens)'**
  String get voucherThreshold;

  /// No description provided for @dailySubmissionCap.
  ///
  /// In en, this message translates to:
  /// **'Daily Submission Cap'**
  String get dailySubmissionCap;

  /// No description provided for @freshLabel.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get freshLabel;

  /// No description provided for @updatedAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated {hours}h ago'**
  String updatedAgoLabel(int hours);

  /// No description provided for @unverifiedOutdated.
  ///
  /// In en, this message translates to:
  /// **'Unverified, may be outdated'**
  String get unverifiedOutdated;

  /// No description provided for @stalePriceWarning.
  ///
  /// In en, this message translates to:
  /// **'Price data may be outdated (>72h)'**
  String get stalePriceWarning;

  /// No description provided for @staleStore.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get staleStore;

  /// No description provided for @filterByChain.
  ///
  /// In en, this message translates to:
  /// **'Filter by chain'**
  String get filterByChain;

  /// No description provided for @allChains.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allChains;

  /// No description provided for @submitPriceHere.
  ///
  /// In en, this message translates to:
  /// **'Submit Price Here'**
  String get submitPriceHere;

  /// No description provided for @betterPriceFound.
  ///
  /// In en, this message translates to:
  /// **'Better price found for {item}! Now AED {price} at {store}.'**
  String betterPriceFound(String item, String price, String store);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @requestFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Request fulfilled! Tokens transferred to requester.'**
  String get requestFulfilled;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @addItemsToCart.
  ///
  /// In en, this message translates to:
  /// **'Browse products and add items to compare prices.'**
  String get addItemsToCart;

  /// No description provided for @bestBasket.
  ///
  /// In en, this message translates to:
  /// **'Best Basket'**
  String get bestBasket;

  /// No description provided for @bestStore.
  ///
  /// In en, this message translates to:
  /// **'Best Store'**
  String get bestStore;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @applyCoupon.
  ///
  /// In en, this message translates to:
  /// **'Apply Coupon'**
  String get applyCoupon;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get guestMode;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get signInWithPhone;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @earnMultiplier.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% earn rate'**
  String earnMultiplier(int percent);

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeCategories;

  /// No description provided for @homeCategoryFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get homeCategoryFresh;

  /// No description provided for @homeCategoryFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get homeCategoryFruits;

  /// No description provided for @homeCategorySnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get homeCategorySnack;

  /// No description provided for @homeCategoryGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get homeCategoryGrocery;

  /// No description provided for @homeCategoryOils.
  ///
  /// In en, this message translates to:
  /// **'Oils'**
  String get homeCategoryOils;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @homeGreetingLine.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String homeGreetingLine(Object greeting, Object name);

  /// No description provided for @homeFindNearbyPrices.
  ///
  /// In en, this message translates to:
  /// **'Find nearby prices before you go'**
  String get homeFindNearbyPrices;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search an item to compare prices nearby'**
  String get homeSearchHint;

  /// No description provided for @homeSearchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String homeSearchResultsCount(int count);

  /// No description provided for @homeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'Simple: search an item, check nearby stores, then decide where it is worth going.'**
  String get homeHowItWorks;

  /// No description provided for @homeBestPricesNearYou.
  ///
  /// In en, this message translates to:
  /// **'Best prices near you'**
  String get homeBestPricesNearYou;

  /// No description provided for @homePricesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} prices'**
  String homePricesCount(Object count);

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Items'**
  String get savedTitle;

  /// No description provided for @savedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved items yet'**
  String get savedEmptyTitle;

  /// No description provided for @savedEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any product to save it here for quick access while you shop.'**
  String get savedEmptyHint;

  /// No description provided for @scanBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcodeTitle;

  /// No description provided for @scanBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode. We will use it to find the product faster.'**
  String get scanBarcodeHint;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load prices'**
  String get homeLoadError;

  /// No description provided for @homeLoadErrorHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. The server may be waking up.'**
  String get homeLoadErrorHint;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @homeNoPricesMatch.
  ///
  /// In en, this message translates to:
  /// **'No prices match this filter yet'**
  String get homeNoPricesMatch;

  /// No description provided for @homeNoPricesHint.
  ///
  /// In en, this message translates to:
  /// **'Try All prices, search for an item, or ask shoppers to check a price.'**
  String get homeNoPricesHint;

  /// No description provided for @homeFindAnItem.
  ///
  /// In en, this message translates to:
  /// **'Find an item'**
  String get homeFindAnItem;

  /// No description provided for @homeBrowseItems.
  ///
  /// In en, this message translates to:
  /// **'Browse items'**
  String get homeBrowseItems;

  /// No description provided for @homeFeaturedStores.
  ///
  /// In en, this message translates to:
  /// **'Featured Stores'**
  String get homeFeaturedStores;

  /// No description provided for @homeEarnRewardsToday.
  ///
  /// In en, this message translates to:
  /// **'Earn rewards today'**
  String get homeEarnRewardsToday;

  /// No description provided for @homePriceSharesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} price shares left to earn tokens'**
  String homePriceSharesLeft(Object count);

  /// No description provided for @homeDailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get homeDailyChallenge;

  /// No description provided for @homeChallengeDoneBadge.
  ///
  /// In en, this message translates to:
  /// **'Done! +{tokens}T'**
  String homeChallengeDoneBadge(Object tokens);

  /// No description provided for @homeDailyChallengeDetails.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge Details'**
  String get homeDailyChallengeDetails;

  /// No description provided for @homeChallengeFinished.
  ///
  /// In en, this message translates to:
  /// **'You have finished this challenge!'**
  String get homeChallengeFinished;

  /// No description provided for @homeChallengeEarnBonus.
  ///
  /// In en, this message translates to:
  /// **'Earn bonus tokens by participating today'**
  String get homeChallengeEarnBonus;

  /// No description provided for @homeTargetSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Target Supermarket'**
  String get homeTargetSupermarket;

  /// No description provided for @homeAnySupermarketChain.
  ///
  /// In en, this message translates to:
  /// **'Any Supermarket Chain'**
  String get homeAnySupermarketChain;

  /// No description provided for @homeYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get homeYourProgress;

  /// No description provided for @homeProgressPrices.
  ///
  /// In en, this message translates to:
  /// **'{progress} / {target} prices'**
  String homeProgressPrices(Object progress, Object target);

  /// No description provided for @homeRewardBonus.
  ///
  /// In en, this message translates to:
  /// **'Reward Bonus'**
  String get homeRewardBonus;

  /// No description provided for @homeRewardBonusValue.
  ///
  /// In en, this message translates to:
  /// **'+{tokens} Tokens'**
  String homeRewardBonusValue(Object tokens);

  /// No description provided for @homeHowToComplete.
  ///
  /// In en, this message translates to:
  /// **'How to complete:'**
  String get homeHowToComplete;

  /// No description provided for @homeStepVisitStore.
  ///
  /// In en, this message translates to:
  /// **'Visit any branch of {store}.'**
  String homeStepVisitStore(Object store);

  /// No description provided for @homeAGenericSupermarket.
  ///
  /// In en, this message translates to:
  /// **'a supermarket'**
  String get homeAGenericSupermarket;

  /// No description provided for @homeStepVerifyPrices.
  ///
  /// In en, this message translates to:
  /// **'Find grocery products and verify their shelf prices.'**
  String get homeStepVerifyPrices;

  /// No description provided for @homeStepSubmitPrice.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Submit Price\" in the app, fill in the price details, and submit.'**
  String get homeStepSubmitPrice;

  /// No description provided for @homeStepApproved.
  ///
  /// In en, this message translates to:
  /// **'Once approved, your progress will update and you\'ll receive the token bonus!'**
  String get homeStepApproved;

  /// No description provided for @homeCompletedRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Completed! Reward Claimed'**
  String get homeCompletedRewardClaimed;

  /// No description provided for @homeStartChallengeNow.
  ///
  /// In en, this message translates to:
  /// **'Start Challenge Now'**
  String get homeStartChallengeNow;

  /// No description provided for @homeFreshnessAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeFreshnessAll;

  /// No description provided for @homeFreshnessUnder6h.
  ///
  /// In en, this message translates to:
  /// **'Under 6h'**
  String get homeFreshnessUnder6h;

  /// No description provided for @homeFreshnessUnder24h.
  ///
  /// In en, this message translates to:
  /// **'Under 24h'**
  String get homeFreshnessUnder24h;

  /// No description provided for @homeFreshnessUnder72h.
  ///
  /// In en, this message translates to:
  /// **'Under 72h'**
  String get homeFreshnessUnder72h;

  /// No description provided for @homeUpdatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get homeUpdatedJustNow;

  /// No description provided for @homeNoRecentPrice.
  ///
  /// In en, this message translates to:
  /// **'No recent price'**
  String get homeNoRecentPrice;

  /// No description provided for @homeUpdatedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {hours} hours ago'**
  String homeUpdatedHoursAgo(Object hours);

  /// No description provided for @homeUpdatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {days} days ago'**
  String homeUpdatedDaysAgo(Object days);

  /// No description provided for @homeVerifiedWithPhoto.
  ///
  /// In en, this message translates to:
  /// **'Verified with photo'**
  String get homeVerifiedWithPhoto;

  /// No description provided for @homeKmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String homeKmAway(Object distance);

  /// No description provided for @homeStoreDistancePrices.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away • {count} prices'**
  String homeStoreDistancePrices(Object distance, Object count);

  /// No description provided for @homeOffer1Title.
  ///
  /// In en, this message translates to:
  /// **'Know The Best Price\nBefore You Leave'**
  String get homeOffer1Title;

  /// No description provided for @homeOffer1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh prices from shoppers near you'**
  String get homeOffer1Subtitle;

  /// No description provided for @homeOffer2Title.
  ///
  /// In en, this message translates to:
  /// **'Save The Trip\nAnd The Dirhams'**
  String get homeOffer2Title;

  /// No description provided for @homeOffer2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare nearby stores before you go'**
  String get homeOffer2Subtitle;

  /// No description provided for @homeOffer3Title.
  ///
  /// In en, this message translates to:
  /// **'Need A Price Checked?\nAsk The Community'**
  String get homeOffer3Title;

  /// No description provided for @homeOffer3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'A real shopper can check the shelf'**
  String get homeOffer3Subtitle;

  /// No description provided for @searchDailyFoods.
  ///
  /// In en, this message translates to:
  /// **'Daily Foods'**
  String get searchDailyFoods;

  /// No description provided for @searchMyList.
  ///
  /// In en, this message translates to:
  /// **'My list'**
  String get searchMyList;

  /// No description provided for @searchCatFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get searchCatFresh;

  /// No description provided for @searchCatFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get searchCatFruits;

  /// No description provided for @searchCatSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get searchCatSnacks;

  /// No description provided for @searchCatGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get searchCatGrocery;

  /// No description provided for @searchCatOils.
  ///
  /// In en, this message translates to:
  /// **'Oils'**
  String get searchCatOils;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search vegetables, fruits and more'**
  String get searchHint;

  /// No description provided for @searchScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get searchScanBarcode;

  /// No description provided for @searchEmptyCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No products found in this category'**
  String get searchEmptyCategoryTitle;

  /// No description provided for @searchEmptyQueryTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find \"{query}\"'**
  String searchEmptyQueryTitle(Object query);

  /// No description provided for @searchEmptyCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try changing category or check back later.'**
  String get searchEmptyCategorySubtitle;

  /// No description provided for @searchEmptyQuerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap below to ask other shoppers to check the price for you!'**
  String get searchEmptyQuerySubtitle;

  /// No description provided for @searchAskShoppersToCheck.
  ///
  /// In en, this message translates to:
  /// **'Ask shoppers to check'**
  String get searchAskShoppersToCheck;

  /// No description provided for @searchRequestPriceCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a price check'**
  String get searchRequestPriceCheckTitle;

  /// No description provided for @searchRequestPriceCheckDescription.
  ///
  /// In en, this message translates to:
  /// **'Other shoppers will check the price of this item for you. This uses {requestCost} tokens and refunds if it expires.'**
  String searchRequestPriceCheckDescription(Object requestCost);

  /// No description provided for @searchItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get searchItemNameLabel;

  /// No description provided for @searchItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Al Rawabi Fresh Milk 2L'**
  String get searchItemNameHint;

  /// No description provided for @searchEnterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get searchEnterProductName;

  /// No description provided for @searchChooseSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Choose supermarket'**
  String get searchChooseSupermarket;

  /// No description provided for @searchRequestPosted.
  ///
  /// In en, this message translates to:
  /// **'Request posted! Shoppers near that store will be notified.'**
  String get searchRequestPosted;

  /// No description provided for @searchAskForThisPrice.
  ///
  /// In en, this message translates to:
  /// **'Ask for this price'**
  String get searchAskForThisPrice;

  /// No description provided for @cartNoStoreYet.
  ///
  /// In en, this message translates to:
  /// **'No store yet'**
  String get cartNoStoreYet;

  /// No description provided for @cartMyList.
  ///
  /// In en, this message translates to:
  /// **'My List'**
  String get cartMyList;

  /// No description provided for @cartClearSavedPrices.
  ///
  /// In en, this message translates to:
  /// **'Clear saved prices'**
  String get cartClearSavedPrices;

  /// No description provided for @cartSavedPricesCleared.
  ///
  /// In en, this message translates to:
  /// **'Saved prices cleared'**
  String get cartSavedPricesCleared;

  /// No description provided for @cartItemsYouAreChecking.
  ///
  /// In en, this message translates to:
  /// **'Items you are checking'**
  String get cartItemsYouAreChecking;

  /// No description provided for @cartAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get cartAddMore;

  /// No description provided for @cartPriceDroppedOn.
  ///
  /// In en, this message translates to:
  /// **'Price dropped on {product}!'**
  String cartPriceDroppedOn(Object product);

  /// No description provided for @cartItemsCheaperNow.
  ///
  /// In en, this message translates to:
  /// **'{count} items in your list are cheaper now!'**
  String cartItemsCheaperNow(Object count);

  /// No description provided for @cartPriceDropDetail.
  ///
  /// In en, this message translates to:
  /// **'Now AED {price} at {store} (was AED {old}).'**
  String cartPriceDropDetail(Object price, Object store, Object old);

  /// No description provided for @cartNoSavedPricesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved prices yet'**
  String get cartNoSavedPricesYet;

  /// No description provided for @cartEmptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search an item and save it here to see which nearby store is worth visiting.'**
  String get cartEmptyStateSubtitle;

  /// No description provided for @cartFindPricesNearby.
  ///
  /// In en, this message translates to:
  /// **'Find prices nearby'**
  String get cartFindPricesNearby;

  /// No description provided for @cartShoppingListOptions.
  ///
  /// In en, this message translates to:
  /// **'Shopping List Options'**
  String get cartShoppingListOptions;

  /// No description provided for @cartCheapestBasket.
  ///
  /// In en, this message translates to:
  /// **'Cheapest Basket'**
  String get cartCheapestBasket;

  /// No description provided for @cartStoreWithDistance.
  ///
  /// In en, this message translates to:
  /// **'{store} ({distance} km)'**
  String cartStoreWithDistance(Object store, Object distance);

  /// No description provided for @cartClosestOption.
  ///
  /// In en, this message translates to:
  /// **'Closest Option'**
  String get cartClosestOption;

  /// No description provided for @cartSaveAtStore.
  ///
  /// In en, this message translates to:
  /// **'Save AED {amount} at {store}'**
  String cartSaveAtStore(Object amount, Object store);

  /// No description provided for @cartClosestIsCheapest.
  ///
  /// In en, this message translates to:
  /// **'Your closest store is also the cheapest option!'**
  String get cartClosestIsCheapest;

  /// No description provided for @cartBestSeenAt.
  ///
  /// In en, this message translates to:
  /// **'Best seen at {store}'**
  String cartBestSeenAt(Object store);

  /// No description provided for @cartRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cartRemove;

  /// No description provided for @cartNearbyStoreComparison.
  ///
  /// In en, this message translates to:
  /// **'Nearby store comparison'**
  String get cartNearbyStoreComparison;

  /// No description provided for @cartKmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String cartKmAway(Object distance);

  /// No description provided for @cartBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get cartBest;

  /// No description provided for @cartExtraAmount.
  ///
  /// In en, this message translates to:
  /// **'+AED {amount}'**
  String cartExtraAmount(Object amount);

  /// No description provided for @cartPlainLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'DealSouk does not sell groceries. This list only helps you decide where to check prices nearby.'**
  String get cartPlainLanguageNote;

  /// No description provided for @storeLocationPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Supermarkets Near You'**
  String get storeLocationPromptTitle;

  /// No description provided for @storeLocationPromptBody.
  ///
  /// In en, this message translates to:
  /// **'DealSouk uses your location to show how far each Dubai supermarket is from you.'**
  String get storeLocationPromptBody;

  /// No description provided for @storeLocationPromptSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get storeLocationPromptSkip;

  /// No description provided for @storeLocationPromptAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get storeLocationPromptAllow;

  /// No description provided for @storeMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Dubai Store Map'**
  String get storeMapTitle;

  /// No description provided for @storeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search store name or area…'**
  String get storeSearchHint;

  /// No description provided for @storeNoStoresFound.
  ///
  /// In en, this message translates to:
  /// **'No stores found'**
  String get storeNoStoresFound;

  /// No description provided for @storeLoadingStores.
  ///
  /// In en, this message translates to:
  /// **'Loading nearby stores…'**
  String get storeLoadingStores;

  /// No description provided for @storeDubaiStoresCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Dubai stores'**
  String storeDubaiStoresCount(Object count);

  /// No description provided for @storeTapPinHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a pin to see branch details'**
  String get storeTapPinHint;

  /// No description provided for @storeMarkerTooltipWithDistance.
  ///
  /// In en, this message translates to:
  /// **'{name} · {branch}\n{km} km away'**
  String storeMarkerTooltipWithDistance(Object name, Object branch, Object km);

  /// No description provided for @storeMarkerTooltip.
  ///
  /// In en, this message translates to:
  /// **'{name}\n{branch}'**
  String storeMarkerTooltip(Object name, Object branch);

  /// No description provided for @storeResetDubai.
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get storeResetDubai;

  /// No description provided for @storeNearYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Near You in Dubai'**
  String get storeNearYouTitle;

  /// No description provided for @storeAllStoresTitle.
  ///
  /// In en, this message translates to:
  /// **'All Dubai Stores'**
  String get storeAllStoresTitle;

  /// No description provided for @storeWithinRadiusSorted.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km · sorted by distance'**
  String storeWithinRadiusSorted(Object km);

  /// No description provided for @storeStoresCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stores'**
  String storeStoresCount(Object count);

  /// No description provided for @storeNoStoresMatch.
  ///
  /// In en, this message translates to:
  /// **'No stores match \"{query}\"'**
  String storeNoStoresMatch(Object query);

  /// No description provided for @storeStaleBadge.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get storeStaleBadge;

  /// No description provided for @storePricesLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load prices'**
  String get storePricesLoadErrorTitle;

  /// No description provided for @storePricesLoadErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your connection or submit a fresh price for this branch.'**
  String get storePricesLoadErrorSubtitle;

  /// No description provided for @storeNoPricesTitle.
  ///
  /// In en, this message translates to:
  /// **'No fresh prices yet'**
  String get storeNoPricesTitle;

  /// No description provided for @storeNoPricesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share a shelf price at this branch.'**
  String get storeNoPricesSubtitle;

  /// No description provided for @storePriceVerifiedWithPhoto.
  ///
  /// In en, this message translates to:
  /// **'{label} · Verified with photo'**
  String storePriceVerifiedWithPhoto(Object label);

  /// No description provided for @storeSubmitPriceHere.
  ///
  /// In en, this message translates to:
  /// **'Submit Price Here'**
  String get storeSubmitPriceHere;

  /// No description provided for @storeDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String storeDistanceKm(Object km);

  /// No description provided for @storeViewPrices.
  ///
  /// In en, this message translates to:
  /// **'View Prices'**
  String get storeViewPrices;

  /// No description provided for @submitStepSelectSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Select Supermarket'**
  String get submitStepSelectSupermarket;

  /// No description provided for @submitStepSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get submitStepSelectProduct;

  /// No description provided for @submitStepEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter Price'**
  String get submitStepEnterPrice;

  /// No description provided for @submitStepConfirmSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm & submit'**
  String get submitStepConfirmSubmit;

  /// No description provided for @submitWhereDidYouSeePrice.
  ///
  /// In en, this message translates to:
  /// **'Where did you see the price?'**
  String get submitWhereDidYouSeePrice;

  /// No description provided for @submitSelectSupermarketHint.
  ///
  /// In en, this message translates to:
  /// **'Select the supermarket from the nearby list.'**
  String get submitSelectSupermarketHint;

  /// No description provided for @submitSubmissionsLeftToday.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {cap} submissions left today.'**
  String submitSubmissionsLeftToday(Object remaining, Object cap);

  /// No description provided for @submitWhichProduct.
  ///
  /// In en, this message translates to:
  /// **'Which product is it?'**
  String get submitWhichProduct;

  /// No description provided for @submitSearchSelectProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search or select product and attach proof photo.'**
  String get submitSearchSelectProductHint;

  /// No description provided for @submitSearchBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, brand or scan barcode'**
  String get submitSearchBarcodeHint;

  /// No description provided for @submitScanBarcodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get submitScanBarcodeTooltip;

  /// No description provided for @submitNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found matching your search.'**
  String get submitNoProductsFound;

  /// No description provided for @submitUseTypedProduct.
  ///
  /// In en, this message translates to:
  /// **'Use “{productName}” as a new product'**
  String submitUseTypedProduct(Object productName);

  /// No description provided for @submitCommunityProductHint.
  ///
  /// In en, this message translates to:
  /// **'Submit the shelf price for this exact item.'**
  String get submitCommunityProductHint;

  /// No description provided for @submitAttachProofRequired.
  ///
  /// In en, this message translates to:
  /// **'Attach Proof (Required)'**
  String get submitAttachProofRequired;

  /// No description provided for @submitPriceLabelPhoto.
  ///
  /// In en, this message translates to:
  /// **'Price Label Photo'**
  String get submitPriceLabelPhoto;

  /// No description provided for @submitReceiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Receipt Photo'**
  String get submitReceiptPhoto;

  /// No description provided for @submitUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get submitUploading;

  /// No description provided for @submitEnterPriceDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Price details'**
  String get submitEnterPriceDetails;

  /// No description provided for @submitEnterShelfPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the shelf price and active promotions.'**
  String get submitEnterShelfPriceHint;

  /// No description provided for @submitEnterPriceAed.
  ///
  /// In en, this message translates to:
  /// **'Enter Price (AED)'**
  String get submitEnterPriceAed;

  /// No description provided for @submitManualShelfPriceHelper.
  ///
  /// In en, this message translates to:
  /// **'Manual shelf price entry, e.g. 14.75'**
  String get submitManualShelfPriceHelper;

  /// No description provided for @submitPleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a price'**
  String get submitPleaseEnterPrice;

  /// No description provided for @submitPleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get submitPleaseEnterValidNumber;

  /// No description provided for @submitPromotionType.
  ///
  /// In en, this message translates to:
  /// **'Promotion Type'**
  String get submitPromotionType;

  /// No description provided for @submitPromoNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get submitPromoNone;

  /// No description provided for @submitPromoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get submitPromoDiscount;

  /// No description provided for @submitPromoBogo.
  ///
  /// In en, this message translates to:
  /// **'BOGO'**
  String get submitPromoBogo;

  /// No description provided for @submitPromoBundle.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get submitPromoBundle;

  /// No description provided for @submitConfirmDetails.
  ///
  /// In en, this message translates to:
  /// **'Confirm details'**
  String get submitConfirmDetails;

  /// No description provided for @submitReviewBeforeSubmission.
  ///
  /// In en, this message translates to:
  /// **'Please review details before submission.'**
  String get submitReviewBeforeSubmission;

  /// No description provided for @submitSummarySupermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get submitSummarySupermarket;

  /// No description provided for @submitSummaryProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get submitSummaryProduct;

  /// No description provided for @submitSummaryPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get submitSummaryPrice;

  /// No description provided for @submitSummaryPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get submitSummaryPromotion;

  /// No description provided for @submitSummaryProof.
  ///
  /// In en, this message translates to:
  /// **'Proof'**
  String get submitSummaryProof;

  /// No description provided for @submitProofPhotoAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo Attached'**
  String get submitProofPhotoAttached;

  /// No description provided for @submitTokenRewardEstimate.
  ///
  /// In en, this message translates to:
  /// **'Token reward estimate'**
  String get submitTokenRewardEstimate;

  /// No description provided for @submitPlusTokens.
  ///
  /// In en, this message translates to:
  /// **'+{tokens} Tokens'**
  String submitPlusTokens(Object tokens);

  /// No description provided for @submitTokenFreshShelfPrice.
  ///
  /// In en, this message translates to:
  /// **'Fresh shelf price'**
  String get submitTokenFreshShelfPrice;

  /// No description provided for @submitTokenStoreSelected.
  ///
  /// In en, this message translates to:
  /// **'Store selected'**
  String get submitTokenStoreSelected;

  /// No description provided for @submitTokenProductSelected.
  ///
  /// In en, this message translates to:
  /// **'Product selected'**
  String get submitTokenProductSelected;

  /// No description provided for @submitTokenAedPriceEntered.
  ///
  /// In en, this message translates to:
  /// **'AED price entered'**
  String get submitTokenAedPriceEntered;

  /// No description provided for @submitTokenPriceLabelAttached.
  ///
  /// In en, this message translates to:
  /// **'Price label attached'**
  String get submitTokenPriceLabelAttached;

  /// No description provided for @submitTokenAttachPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Attach price label'**
  String get submitTokenAttachPriceLabel;

  /// No description provided for @submitTokenNoPromotion.
  ///
  /// In en, this message translates to:
  /// **'No promotion selected'**
  String get submitTokenNoPromotion;

  /// No description provided for @submitTokenPromoNoted.
  ///
  /// In en, this message translates to:
  /// **'{promo} promo noted'**
  String submitTokenPromoNoted(Object promo);

  /// No description provided for @submitTokenReceiptMultiplier.
  ///
  /// In en, this message translates to:
  /// **'1.5× Verified Receipt Multiplier'**
  String get submitTokenReceiptMultiplier;

  /// No description provided for @submitTokenAttachReceiptBonus.
  ///
  /// In en, this message translates to:
  /// **'Attach Receipt for 1.5× Bonus'**
  String get submitTokenAttachReceiptBonus;

  /// No description provided for @submitTokenMultiplierApplied.
  ///
  /// In en, this message translates to:
  /// **'×1.5 applied'**
  String get submitTokenMultiplierApplied;

  /// No description provided for @submitTokenNotApplied.
  ///
  /// In en, this message translates to:
  /// **'not applied'**
  String get submitTokenNotApplied;

  /// No description provided for @submitTokensAmount.
  ///
  /// In en, this message translates to:
  /// **'+{count} tokens'**
  String submitTokensAmount(Object count);

  /// No description provided for @submitTokenAmount.
  ///
  /// In en, this message translates to:
  /// **'+{count} token'**
  String submitTokenAmount(Object count);

  /// No description provided for @submitTotalRewardEstimate.
  ///
  /// In en, this message translates to:
  /// **'Total Reward Estimate'**
  String get submitTotalRewardEstimate;

  /// No description provided for @submitTokensTotal.
  ///
  /// In en, this message translates to:
  /// **'{tokens} Tokens'**
  String submitTokensTotal(Object tokens);

  /// No description provided for @submitBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get submitBack;

  /// No description provided for @submitNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get submitNext;

  /// No description provided for @submitSubmitAPrice.
  ///
  /// In en, this message translates to:
  /// **'Submit a price'**
  String get submitSubmitAPrice;

  /// No description provided for @submitCouldNotSendPrice.
  ///
  /// In en, this message translates to:
  /// **'We could not send this price. Please check your connection and try again.'**
  String get submitCouldNotSendPrice;

  /// No description provided for @submitSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved. We\'ll submit this price automatically when you\'re back online.'**
  String get submitSavedOffline;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes are saved and will sync when you reconnect.'**
  String get offlineBanner;

  /// No description provided for @offlinePendingSync.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String offlinePendingSync(int count);

  /// No description provided for @submitTransactionDescription.
  ///
  /// In en, this message translates to:
  /// **'+{tokens} tokens for {product} at {store}'**
  String submitTransactionDescription(
    Object tokens,
    Object product,
    Object store,
  );

  /// No description provided for @submitPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo Uploaded'**
  String get submitPhotoUploaded;

  /// No description provided for @submitPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the photo. Tap to try again.'**
  String get submitPhotoUploadFailed;

  /// No description provided for @submitProofPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'The proof photo did not finish uploading. Please tap the photo and try again.'**
  String get submitProofPhotoRequired;

  /// No description provided for @submitReceiptPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'The receipt photo did not finish uploading. Please retry it, or retake the price-label photo only.'**
  String get submitReceiptPhotoRequired;

  /// No description provided for @submitTapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to Upload'**
  String get submitTapToUpload;

  /// No description provided for @submitTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get submitTapToRetry;

  /// No description provided for @submitTapToRetake.
  ///
  /// In en, this message translates to:
  /// **'Tap to retake'**
  String get submitTapToRetake;

  /// No description provided for @submitPriceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Price Submitted!'**
  String get submitPriceSubmitted;

  /// No description provided for @submitTokensGained.
  ///
  /// In en, this message translates to:
  /// **'+{tokens} tokens'**
  String submitTokensGained(Object tokens);

  /// No description provided for @submitPendingReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Your price submission is pending review.\nTokens will be credited to {name} after admin approval.'**
  String submitPendingReviewMessage(Object name);

  /// No description provided for @submitAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get submitAwaitingApproval;

  /// No description provided for @submitApprovedNowMessage.
  ///
  /// In en, this message translates to:
  /// **'Nice work, {name}. These tokens were added now. Pull down on your profile any time to refresh the latest balance.'**
  String submitApprovedNowMessage(Object name);

  /// No description provided for @submitOpenAdminReview.
  ///
  /// In en, this message translates to:
  /// **'Open Admin Review'**
  String get submitOpenAdminReview;

  /// No description provided for @submitViewTokenBalance.
  ///
  /// In en, this message translates to:
  /// **'View Token Balance'**
  String get submitViewTokenBalance;

  /// No description provided for @profileLevelBadge.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level} {title}'**
  String profileLevelBadge(Object level, Object title);

  /// No description provided for @profileDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String profileDayStreak(Object days);

  /// No description provided for @profileTabSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get profileTabSubmissions;

  /// No description provided for @profileTabTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get profileTabTokens;

  /// No description provided for @profileTabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get profileTabRequests;

  /// No description provided for @profileTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileTabSettings;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed'**
  String get profilePhotoRemoved;

  /// No description provided for @profileAccuracyRating.
  ///
  /// In en, this message translates to:
  /// **'Accuracy Rating'**
  String get profileAccuracyRating;

  /// No description provided for @profileAccuracyApproved.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of your submissions approved'**
  String profileAccuracyApproved(Object percent);

  /// No description provided for @profileNoSubmissions.
  ///
  /// In en, this message translates to:
  /// **'No prices shared yet.\nShare a shelf price to help shoppers and earn tokens.'**
  String get profileNoSubmissions;

  /// No description provided for @profileCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get profileCurrentBalance;

  /// No description provided for @profileTapLeaderboardRedeem.
  ///
  /// In en, this message translates to:
  /// **'Tap Leaderboard to redeem'**
  String get profileTapLeaderboardRedeem;

  /// No description provided for @profileNoTokenActivity.
  ///
  /// In en, this message translates to:
  /// **'No token activity yet.\nShare a price or help with a request to start earning.'**
  String get profileNoTokenActivity;

  /// No description provided for @profileNoPriceRequests.
  ///
  /// In en, this message translates to:
  /// **'No price requests yet.\nAsk for a price when you cannot find an item.'**
  String get profileNoPriceRequests;

  /// No description provided for @profileCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get profileCancelRequest;

  /// No description provided for @profileCancelRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request?'**
  String get profileCancelRequestTitle;

  /// No description provided for @profileCancelRequestBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your price request for \"{product}\"? Your bounty tokens will be refunded.'**
  String profileCancelRequestBody(Object product);

  /// No description provided for @profileNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get profileNo;

  /// No description provided for @profileYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get profileYesCancel;

  /// No description provided for @profileVoucherApproved.
  ///
  /// In en, this message translates to:
  /// **'Voucher Approved'**
  String get profileVoucherApproved;

  /// No description provided for @profileCodePending.
  ///
  /// In en, this message translates to:
  /// **'Code pending'**
  String get profileCodePending;

  /// No description provided for @profileVoucherUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Voucher Under Review'**
  String get profileVoucherUnderReview;

  /// No description provided for @profileVoucherPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your AED {amount} {supermarket} voucher is waiting for admin approval.'**
  String profileVoucherPendingBody(Object amount, Object supermarket);

  /// No description provided for @profileVoucherReady.
  ///
  /// In en, this message translates to:
  /// **'Voucher Ready!'**
  String get profileVoucherReady;

  /// No description provided for @profileVoucherReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Head to the Leaderboard tab to claim your AED 50 Union Coop voucher.'**
  String get profileVoucherReadyBody;

  /// No description provided for @profileClaimVoucherNow.
  ///
  /// In en, this message translates to:
  /// **'Claim Voucher Now'**
  String get profileClaimVoucherNow;

  /// No description provided for @profileVoucherGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'AED 50 Union Coop Voucher'**
  String get profileVoucherGoalTitle;

  /// No description provided for @profileEarnMoreTokens.
  ///
  /// In en, this message translates to:
  /// **'Earn {count} more tokens to unlock your voucher.'**
  String profileEarnMoreTokens(Object count);

  /// No description provided for @profilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhotoTitle;

  /// No description provided for @profilePhotoSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a friendly photo so shoppers recognise you'**
  String get profilePhotoSubtitleEmpty;

  /// No description provided for @profilePhotoSubtitleSet.
  ///
  /// In en, this message translates to:
  /// **'Change or remove your current photo'**
  String get profilePhotoSubtitleSet;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhoto;

  /// No description provided for @profilePhotoTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profilePhotoTakePhoto;

  /// No description provided for @profilePhotoChooseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get profilePhotoChooseLibrary;

  /// No description provided for @profileEditPhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile photo'**
  String get profileEditPhotoTooltip;

  /// No description provided for @profileStatTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get profileStatTokens;

  /// No description provided for @profileStatAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get profileStatAccuracy;

  /// No description provided for @profileStatApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get profileStatApproved;

  /// No description provided for @profileStatStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get profileStatStreak;

  /// No description provided for @profileSectionSubmissions.
  ///
  /// In en, this message translates to:
  /// **'My Submissions'**
  String get profileSectionSubmissions;

  /// No description provided for @profileSectionTokens.
  ///
  /// In en, this message translates to:
  /// **'Token History'**
  String get profileSectionTokens;

  /// No description provided for @profileSectionRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get profileSectionRequests;

  /// No description provided for @profileSectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings & Account'**
  String get profileSectionSettings;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get profileDisplayName;

  /// No description provided for @profileEditDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Edit display name'**
  String get profileEditDisplayName;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileHomeArea.
  ///
  /// In en, this message translates to:
  /// **'Home Area'**
  String get profileHomeArea;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileViewTutorial.
  ///
  /// In en, this message translates to:
  /// **'View App Tutorial'**
  String get profileViewTutorial;

  /// No description provided for @profileViewTutorialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-run the DealSouk intro guide'**
  String get profileViewTutorialSubtitle;

  /// No description provided for @profilePrivacyTerms.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get profilePrivacyTerms;

  /// No description provided for @profilePrivacyTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Location, photos, tokens, vouchers, and account deletion'**
  String get profilePrivacyTermsSubtitle;

  /// No description provided for @profileAdminConsole.
  ///
  /// In en, this message translates to:
  /// **'Admin Review Console'**
  String get profileAdminConsole;

  /// No description provided for @profileAdminConsoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moderate price submissions'**
  String get profileAdminConsoleSubtitle;

  /// No description provided for @profileLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogOut;

  /// No description provided for @profileLogOutDemo.
  ///
  /// In en, this message translates to:
  /// **'Log Out of Demo'**
  String get profileLogOutDemo;

  /// No description provided for @welcomePrivacyConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Privacy Policy to continue.'**
  String get welcomePrivacyConsentRequired;

  /// No description provided for @welcomeInvalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid {digits}-digit phone number for {country}.'**
  String welcomeInvalidPhoneNumber(Object digits, Object country);

  /// No description provided for @welcomeSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get welcomeSelectCountry;

  /// No description provided for @welcomeModeratorToggleEnabled.
  ///
  /// In en, this message translates to:
  /// **'Moderator toggle enabled'**
  String get welcomeModeratorToggleEnabled;

  /// No description provided for @welcomeModeratorToggleDisabled.
  ///
  /// In en, this message translates to:
  /// **'Moderator toggle disabled'**
  String get welcomeModeratorToggleDisabled;

  /// No description provided for @welcomeTaglineAdmin.
  ///
  /// In en, this message translates to:
  /// **'Review supermarket prices shared by shoppers'**
  String get welcomeTaglineAdmin;

  /// No description provided for @welcomeTaglineCustomer.
  ///
  /// In en, this message translates to:
  /// **'Prices shared by shoppers near you'**
  String get welcomeTaglineCustomer;

  /// No description provided for @welcomeCustomerModeTab.
  ///
  /// In en, this message translates to:
  /// **'Customer Mode'**
  String get welcomeCustomerModeTab;

  /// No description provided for @welcomeAdminModeratorTab.
  ///
  /// In en, this message translates to:
  /// **'Admin Moderator'**
  String get welcomeAdminModeratorTab;

  /// No description provided for @welcomePillarAuditQueue.
  ///
  /// In en, this message translates to:
  /// **'Audit\nQueue'**
  String get welcomePillarAuditQueue;

  /// No description provided for @welcomePillarFraudFilter.
  ///
  /// In en, this message translates to:
  /// **'Fraud\nFilter'**
  String get welcomePillarFraudFilter;

  /// No description provided for @welcomePillarIssueTokens.
  ///
  /// In en, this message translates to:
  /// **'Issue\nTokens'**
  String get welcomePillarIssueTokens;

  /// No description provided for @welcomePillarComparePrices.
  ///
  /// In en, this message translates to:
  /// **'Compare\nPrices'**
  String get welcomePillarComparePrices;

  /// No description provided for @welcomePillarFindNearby.
  ///
  /// In en, this message translates to:
  /// **'Find\nNearby'**
  String get welcomePillarFindNearby;

  /// No description provided for @welcomePillarRequestPrice.
  ///
  /// In en, this message translates to:
  /// **'Request\nPrice'**
  String get welcomePillarRequestPrice;

  /// No description provided for @welcomeInfoBannerAdmin.
  ///
  /// In en, this message translates to:
  /// **'Moderator Panel: Verify receipts and shelf prices.'**
  String get welcomeInfoBannerAdmin;

  /// No description provided for @welcomeInfoBannerCustomer.
  ///
  /// In en, this message translates to:
  /// **'No ordering here. Just check prices before you go.'**
  String get welcomeInfoBannerCustomer;

  /// No description provided for @welcomePrivacyConsentPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get welcomePrivacyConsentPrefix;

  /// No description provided for @welcomePrivacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get welcomePrivacyPolicyLink;

  /// No description provided for @welcomePrivacyConsentSuffix.
  ///
  /// In en, this message translates to:
  /// **' and consent to neighbourhood-level location processing.'**
  String get welcomePrivacyConsentSuffix;

  /// No description provided for @welcomeEnterAdminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Enter Admin Dashboard'**
  String get welcomeEnterAdminDashboard;

  /// No description provided for @welcomeContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get welcomeContinueWithGoogle;

  /// No description provided for @welcomeSignInWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone'**
  String get welcomeSignInWithPhone;

  /// No description provided for @welcomeSignInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get welcomeSignInWithApple;

  /// No description provided for @welcomeBrowseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as Guest'**
  String get welcomeBrowseAsGuest;

  /// No description provided for @welcomeFooterAdmin.
  ///
  /// In en, this message translates to:
  /// **'Moderator console permissions apply.'**
  String get welcomeFooterAdmin;

  /// No description provided for @welcomeFooterCustomer.
  ///
  /// In en, this message translates to:
  /// **'Supermarket prices shared by shoppers in Dubai.'**
  String get welcomeFooterCustomer;

  /// No description provided for @welcomeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get welcomeCancel;

  /// No description provided for @welcomeSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get welcomeSendCode;

  /// No description provided for @welcomeOtpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String welcomeOtpPrompt(Object phone);

  /// No description provided for @welcomeVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get welcomeVerify;

  /// No description provided for @welcomeResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get welcomeResendCode;

  /// No description provided for @productDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get productDetailsTitle;

  /// No description provided for @productAddToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get productAddToFavourites;

  /// No description provided for @productRemoveFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get productRemoveFromFavourites;

  /// No description provided for @productBestPriceSeenAt.
  ///
  /// In en, this message translates to:
  /// **'Best price seen at {store}'**
  String productBestPriceSeenAt(Object store);

  /// No description provided for @productRequestThisPrice.
  ///
  /// In en, this message translates to:
  /// **'Request this price'**
  String get productRequestThisPrice;

  /// No description provided for @productRequestPriceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Request this price! Other shoppers will check it soon.'**
  String get productRequestPriceConfirmation;

  /// No description provided for @productCompareStorePrices.
  ///
  /// In en, this message translates to:
  /// **'Compare Store Prices'**
  String get productCompareStorePrices;

  /// No description provided for @productNoFreshPrices.
  ///
  /// In en, this message translates to:
  /// **'No fresh prices yet.'**
  String get productNoFreshPrices;

  /// No description provided for @productNoFreshPricesHint.
  ///
  /// In en, this message translates to:
  /// **'Ask another shopper to check this item before you make the trip.'**
  String get productNoFreshPricesHint;

  /// No description provided for @productPriceFlaggedHidden.
  ///
  /// In en, this message translates to:
  /// **'Price flagged & hidden (Pending admin audit)'**
  String get productPriceFlaggedHidden;

  /// No description provided for @productStoreDistance.
  ///
  /// In en, this message translates to:
  /// **'{store} • {distance} km away'**
  String productStoreDistance(Object store, Object distance);

  /// No description provided for @productFreshnessVerified.
  ///
  /// In en, this message translates to:
  /// **'{freshness} • Verified with photo'**
  String productFreshnessVerified(Object freshness);

  /// No description provided for @productUpdatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get productUpdatedJustNow;

  /// No description provided for @productUpdatedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {hours} hours ago'**
  String productUpdatedHoursAgo(Object hours);

  /// No description provided for @productUpdatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {days} days ago'**
  String productUpdatedDaysAgo(Object days);

  /// No description provided for @productUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated {label}'**
  String productUpdatedLabel(Object label);

  /// No description provided for @productBestPriceBadge.
  ///
  /// In en, this message translates to:
  /// **'BEST PRICE'**
  String get productBestPriceBadge;

  /// No description provided for @productReportHiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'Thanks. This price is hidden until an admin reviews it.'**
  String get productReportHiddenMessage;

  /// No description provided for @productReportPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We will hide this price after 3 unique reports.'**
  String get productReportPendingMessage;

  /// No description provided for @productReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get productReported;

  /// No description provided for @productReportWrongPrice.
  ///
  /// In en, this message translates to:
  /// **'Report wrong price'**
  String get productReportWrongPrice;

  /// No description provided for @productPriceHistory90Day.
  ///
  /// In en, this message translates to:
  /// **'90-Day Price History'**
  String get productPriceHistory90Day;

  /// No description provided for @productYouMayAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You may also like'**
  String get productYouMayAlsoLike;

  /// No description provided for @productBestSeenPrice.
  ///
  /// In en, this message translates to:
  /// **'Best seen price'**
  String get productBestSeenPrice;

  /// No description provided for @productSignInToSavePrices.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to save prices and compare grocery baskets.'**
  String get productSignInToSavePrices;

  /// No description provided for @productSignInAction.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get productSignInAction;

  /// No description provided for @productSavedForComparison.
  ///
  /// In en, this message translates to:
  /// **'{name} saved for price comparison'**
  String productSavedForComparison(Object name);

  /// No description provided for @productViewAction.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get productViewAction;

  /// No description provided for @productSavePrice.
  ///
  /// In en, this message translates to:
  /// **'Save Price'**
  String get productSavePrice;

  /// No description provided for @productNoPriceHistory.
  ///
  /// In en, this message translates to:
  /// **'No approved price history yet. Once shoppers submit fresh prices, you will see the trend here.'**
  String get productNoPriceHistory;

  /// No description provided for @productPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Lowest {lowest} • Highest {highest}'**
  String productPriceRange(Object lowest, Object highest);

  /// No description provided for @productLatestPrice.
  ///
  /// In en, this message translates to:
  /// **'Latest {latest}'**
  String productLatestPrice(Object latest);

  /// No description provided for @requestBannerExplanation.
  ///
  /// In en, this message translates to:
  /// **'Need a price checked? Ask nearby shoppers. If someone is already at that store, they can send back the shelf price.'**
  String get requestBannerExplanation;

  /// No description provided for @requestMyRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My price requests ({count})'**
  String requestMyRequestsTitle(Object count);

  /// No description provided for @requestBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Price checks people need ({count})'**
  String requestBoardTitle(Object count);

  /// No description provided for @requestAskForPrice.
  ///
  /// In en, this message translates to:
  /// **'Ask for a price'**
  String get requestAskForPrice;

  /// No description provided for @requestPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get requestPendingStatus;

  /// No description provided for @requestEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All price requests are completed!'**
  String get requestEmptyTitle;

  /// No description provided for @requestEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Need a price? Tap \'Ask for a price\' to request a price check.'**
  String get requestEmptySubtitle;

  /// No description provided for @requestFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask for a price check'**
  String get requestFormTitle;

  /// No description provided for @requestFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us the item and store. This uses {tokens} tokens and refunds automatically if it expires.'**
  String requestFormSubtitle(Object tokens);

  /// No description provided for @requestItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get requestItemNameLabel;

  /// No description provided for @requestItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. milk, rice, apples'**
  String get requestItemNameHint;

  /// No description provided for @requestItemNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter the item name'**
  String get requestItemNameValidation;

  /// No description provided for @requestStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Supermarket Chain'**
  String get requestStoreLabel;

  /// No description provided for @requestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Price request sent'**
  String get requestSentTitle;

  /// No description provided for @requestSentBody.
  ///
  /// In en, this message translates to:
  /// **'Nearby shoppers can check {productName} at {storeName}. {tokens} tokens were reserved and will refund if the request expires.'**
  String requestSentBody(Object productName, Object storeName, Object tokens);

  /// No description provided for @requestSentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get requestSentConfirm;

  /// No description provided for @requestSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Ask for this price'**
  String get requestSubmitButton;

  /// No description provided for @requestCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{storeName} • Posted by {requesterName}'**
  String requestCardSubtitle(Object storeName, Object requesterName);

  /// No description provided for @requestCheckPriceButton.
  ///
  /// In en, this message translates to:
  /// **'Check price (+{tokens} Tokens)'**
  String requestCheckPriceButton(Object tokens);

  /// No description provided for @storeLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load stores'**
  String get storeLoadErrorTitle;

  /// No description provided for @storeLoadErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get storeLoadErrorSubtitle;

  /// No description provided for @storeRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get storeRetryButton;

  /// No description provided for @storeChainAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storeChainAll;

  /// No description provided for @storeFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter stores'**
  String get storeFilterTitle;

  /// No description provided for @storeMaxDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum distance: {km} km'**
  String storeMaxDistance(Object km);

  /// No description provided for @storeSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get storeSortBy;

  /// No description provided for @storeSortClosest.
  ///
  /// In en, this message translates to:
  /// **'Closest first'**
  String get storeSortClosest;

  /// No description provided for @storeSortAlpha.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical (A–Z)'**
  String get storeSortAlpha;

  /// No description provided for @storeSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get storeSortRecent;

  /// No description provided for @storeApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get storeApplyFilters;

  /// No description provided for @storeGpsOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'The distance filter only applies when you are in Dubai with location turned on.'**
  String get storeGpsOnlyNote;

  /// No description provided for @storeRequiresGps.
  ///
  /// In en, this message translates to:
  /// **'Needs your location'**
  String get storeRequiresGps;

  /// No description provided for @storeDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get storeDirections;

  /// No description provided for @storeFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get storeFresh;

  /// No description provided for @storePricesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} prices'**
  String storePricesCountLabel(Object count);

  /// No description provided for @storeUpdatedAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {label}'**
  String storeUpdatedAgo(Object label);

  /// No description provided for @storeSelectedHint.
  ///
  /// In en, this message translates to:
  /// **'Select a store to see its prices'**
  String get storeSelectedHint;

  /// No description provided for @leaderRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Leaderboard'**
  String get leaderRewardsTitle;

  /// No description provided for @leaderToggleStreaks.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard & Streaks'**
  String get leaderToggleStreaks;

  /// No description provided for @leaderToggleRequestBoard.
  ///
  /// In en, this message translates to:
  /// **'Active Request Board'**
  String get leaderToggleRequestBoard;

  /// No description provided for @leaderRankNumber.
  ///
  /// In en, this message translates to:
  /// **'Rank #{n}'**
  String leaderRankNumber(Object n);

  /// No description provided for @leaderRankUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unranked'**
  String get leaderRankUnknown;

  /// No description provided for @leaderDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} Day Streak'**
  String leaderDayStreak(Object days);

  /// No description provided for @leaderTokensLabel.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get leaderTokensLabel;

  /// No description provided for @leaderVoucherName.
  ///
  /// In en, this message translates to:
  /// **'AED 50 Union Coop Voucher'**
  String get leaderVoucherName;

  /// No description provided for @leaderTokenProgress.
  ///
  /// In en, this message translates to:
  /// **'{tokens} / {target} T'**
  String leaderTokenProgress(Object tokens, Object target);

  /// No description provided for @leaderVoucherRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed AED 50 Union Coop Voucher'**
  String get leaderVoucherRedeemed;

  /// No description provided for @leaderVoucherClaimedTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher Claimed!'**
  String get leaderVoucherClaimedTitle;

  /// No description provided for @leaderVoucherClaimedBody.
  ///
  /// In en, this message translates to:
  /// **'Show the barcode or code below to the cashier at any Union Coop checkout in Dubai.'**
  String get leaderVoucherClaimedBody;

  /// No description provided for @leaderBackToRewards.
  ///
  /// In en, this message translates to:
  /// **'Back to Rewards'**
  String get leaderBackToRewards;

  /// No description provided for @leaderClaimVoucher.
  ///
  /// In en, this message translates to:
  /// **'Claim Voucher Now'**
  String get leaderClaimVoucher;

  /// No description provided for @leaderEarnMoreTokens.
  ///
  /// In en, this message translates to:
  /// **'Earn {count} more tokens to redeem your voucher.'**
  String leaderEarnMoreTokens(Object count);

  /// No description provided for @leaderShopperBadges.
  ///
  /// In en, this message translates to:
  /// **'Shopper Badges'**
  String get leaderShopperBadges;

  /// No description provided for @leaderTodaysChallenges.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Challenges'**
  String get leaderTodaysChallenges;

  /// No description provided for @leaderChallengeDone.
  ///
  /// In en, this message translates to:
  /// **'Done! +{tokens}T'**
  String leaderChallengeDone(Object tokens);

  /// No description provided for @leaderChallengeBonus.
  ///
  /// In en, this message translates to:
  /// **'+{tokens} bonus tokens'**
  String leaderChallengeBonus(Object tokens);

  /// No description provided for @leaderChallengeProgress.
  ///
  /// In en, this message translates to:
  /// **'{progress}/{target} done • Tap to submit a price'**
  String leaderChallengeProgress(Object progress, Object target);

  /// No description provided for @leaderDubaiLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Dubai Leaderboard'**
  String get leaderDubaiLeaderboard;

  /// No description provided for @leaderHallOfFame.
  ///
  /// In en, this message translates to:
  /// **'Hall of Fame'**
  String get leaderHallOfFame;

  /// No description provided for @leaderTopChampions.
  ///
  /// In en, this message translates to:
  /// **'Last month\'s top champions'**
  String get leaderTopChampions;

  /// No description provided for @leaderYouMarker.
  ///
  /// In en, this message translates to:
  /// **'{name} (You)'**
  String leaderYouMarker(Object name);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get privacyTitle;

  /// No description provided for @privacySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Plain English Summary'**
  String get privacySummaryTitle;

  /// No description provided for @privacySummaryItem1.
  ///
  /// In en, this message translates to:
  /// **'DealSouk helps shoppers compare grocery prices using community-submitted prices.'**
  String get privacySummaryItem1;

  /// No description provided for @privacySummaryItem2.
  ///
  /// In en, this message translates to:
  /// **'We ask for only the information needed to run the app: your account, home area, language, submissions, requests, tokens, and moderation history.'**
  String get privacySummaryItem2;

  /// No description provided for @privacySummaryItem3.
  ///
  /// In en, this message translates to:
  /// **'We use your device location only to show nearby supermarket prices. Precise GPS is not stored permanently.'**
  String get privacySummaryItem3;

  /// No description provided for @privacySummaryItem4.
  ///
  /// In en, this message translates to:
  /// **'Tokens are rewards inside DealSouk. They are not cash, cannot be transferred, and cannot be sold.'**
  String get privacySummaryItem4;

  /// No description provided for @privacySummaryItem5.
  ///
  /// In en, this message translates to:
  /// **'Photos are used to verify price labels or receipts. Do not upload photos with personal information.'**
  String get privacySummaryItem5;

  /// No description provided for @privacySummaryItem6.
  ///
  /// In en, this message translates to:
  /// **'You can request account deletion from Profile settings.'**
  String get privacySummaryItem6;

  /// No description provided for @privacyCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'What We Collect'**
  String get privacyCollectTitle;

  /// No description provided for @privacyCollectItem1.
  ///
  /// In en, this message translates to:
  /// **'Account details: Firebase account ID, display name, phone number if you use phone login, and preferred language.'**
  String get privacyCollectItem1;

  /// No description provided for @privacyCollectItem2.
  ///
  /// In en, this message translates to:
  /// **'Shopping area: neighbourhood or area, not a permanent precise GPS record.'**
  String get privacyCollectItem2;

  /// No description provided for @privacyCollectItem3.
  ///
  /// In en, this message translates to:
  /// **'Price data: products, stores, prices, timestamps, optional shelf label or receipt photos, and moderation flags.'**
  String get privacyCollectItem3;

  /// No description provided for @privacyCollectItem4.
  ///
  /// In en, this message translates to:
  /// **'Rewards data: token balance, token history, voucher requests, badges, streaks, and leaderboard totals.'**
  String get privacyCollectItem4;

  /// No description provided for @privacyCollectItem5.
  ///
  /// In en, this message translates to:
  /// **'Device messaging token: used only for DealSouk notifications such as request fulfilment or reward updates.'**
  String get privacyCollectItem5;

  /// No description provided for @privacyUseTitle.
  ///
  /// In en, this message translates to:
  /// **'How We Use Data'**
  String get privacyUseTitle;

  /// No description provided for @privacyUseItem1.
  ///
  /// In en, this message translates to:
  /// **'To show fresh prices near you.'**
  String get privacyUseItem1;

  /// No description provided for @privacyUseItem2.
  ///
  /// In en, this message translates to:
  /// **'To calculate savings, requests, tokens, and rewards.'**
  String get privacyUseItem2;

  /// No description provided for @privacyUseItem3.
  ///
  /// In en, this message translates to:
  /// **'To detect wrong, stale, duplicate, or suspicious submissions.'**
  String get privacyUseItem3;

  /// No description provided for @privacyUseItem4.
  ///
  /// In en, this message translates to:
  /// **'To operate admin moderation and voucher approval.'**
  String get privacyUseItem4;

  /// No description provided for @privacyUseItem5.
  ///
  /// In en, this message translates to:
  /// **'To improve reliability, security, and Arabic/English usability.'**
  String get privacyUseItem5;

  /// No description provided for @privacyChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Choices'**
  String get privacyChoicesTitle;

  /// No description provided for @privacyChoicesItem1.
  ///
  /// In en, this message translates to:
  /// **'You may browse as a guest with limited features.'**
  String get privacyChoicesItem1;

  /// No description provided for @privacyChoicesItem2.
  ///
  /// In en, this message translates to:
  /// **'You can change your display name, home area, and language.'**
  String get privacyChoicesItem2;

  /// No description provided for @privacyChoicesItem3.
  ///
  /// In en, this message translates to:
  /// **'You can deny location access and still use non-location features.'**
  String get privacyChoicesItem3;

  /// No description provided for @privacyChoicesItem4.
  ///
  /// In en, this message translates to:
  /// **'You can request account deletion. We anonymise account data needed for fraud prevention and financial/reward audit records.'**
  String get privacyChoicesItem4;

  /// No description provided for @privacyArabicTitle.
  ///
  /// In en, this message translates to:
  /// **'Arabic Summary'**
  String get privacyArabicTitle;

  /// No description provided for @privacyArabicItem1.
  ///
  /// In en, this message translates to:
  /// **'We use your location only to show nearby store prices, and we do not permanently store precise GPS location.'**
  String get privacyArabicItem1;

  /// No description provided for @privacyArabicItem2.
  ///
  /// In en, this message translates to:
  /// **'Tokens are in-app rewards, not cash, and cannot be sold or transferred.'**
  String get privacyArabicItem2;

  /// No description provided for @privacyArabicItem3.
  ///
  /// In en, this message translates to:
  /// **'Price or receipt photos are used for verification only. Do not upload photos containing personal information.'**
  String get privacyArabicItem3;

  /// No description provided for @privacyArabicItem4.
  ///
  /// In en, this message translates to:
  /// **'You can request account deletion from settings.'**
  String get privacyArabicItem4;

  /// No description provided for @tutorialCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare Grocery Prices'**
  String get tutorialCompareTitle;

  /// No description provided for @tutorialCompareDescription.
  ///
  /// In en, this message translates to:
  /// **'Find nearby prices for fruits, vegetables, dairy, and snacks in Dubai supermarkets before you leave home.'**
  String get tutorialCompareDescription;

  /// No description provided for @tutorialMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Stores On The Map'**
  String get tutorialMapTitle;

  /// No description provided for @tutorialMapDescription.
  ///
  /// In en, this message translates to:
  /// **'See participating supermarkets across Dubai on the map, with how fresh each store\'s prices are before you go.'**
  String get tutorialMapDescription;

  /// No description provided for @tutorialAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask For Price Checks'**
  String get tutorialAskTitle;

  /// No description provided for @tutorialAskDescription.
  ///
  /// In en, this message translates to:
  /// **'Need a price you cannot see? Ask the community to check it, or help others by sharing a shelf price.'**
  String get tutorialAskDescription;

  /// No description provided for @tutorialEarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn Shopping Rewards'**
  String get tutorialEarnTitle;

  /// No description provided for @tutorialEarnDescription.
  ///
  /// In en, this message translates to:
  /// **'Share prices or check shelves to earn tokens, then swap them for real supermarket vouchers.'**
  String get tutorialEarnDescription;

  /// No description provided for @tutorialCompeteTitle.
  ///
  /// In en, this message translates to:
  /// **'Climb The Leaderboard'**
  String get tutorialCompeteTitle;

  /// No description provided for @tutorialCompeteDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep a daily streak, complete challenges, earn badges, and rise up the Dubai leaderboard as you contribute.'**
  String get tutorialCompeteDescription;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get tutorialGetStarted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
