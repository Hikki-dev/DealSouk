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
  /// **'Cart'**
  String get cart;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
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
  /// **'Sourcer Badges'**
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
  /// **'Unverified — may be outdated'**
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
