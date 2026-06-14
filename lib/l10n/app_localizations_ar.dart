// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ديل سوق';

  @override
  String get home => 'الرئيسية';

  @override
  String get map => 'الخريطة';

  @override
  String get cart => 'السلة';

  @override
  String get leaderboard => 'المتصدرون';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get greeting => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get freshPrices => 'أسعار حديثة';

  @override
  String get freshPricesSubtitle => 'أسعار مجتمعية مباشرة بالقرب منك';

  @override
  String get searchProducts => 'ابحث عن المنتجات…';

  @override
  String get searchNearbyStores => 'ابحث عن المتاجر القريبة في دبي';

  @override
  String get nearbyStores => 'السوبرماركت القريبة';

  @override
  String get storeMap => 'خريطة المتاجر';

  @override
  String get tokens => 'رموز';

  @override
  String get tokenBalance => 'رصيد الرموز';

  @override
  String get earnTokens => 'اكسب رموزاً';

  @override
  String get spendTokens => 'أنفق رموزاً';

  @override
  String get tokenHistory => 'سجل الرموز';

  @override
  String get voucherReady => 'القسيمة جاهزة!';

  @override
  String voucherProgress(int remaining) {
    return 'اكسب $remaining رمزاً إضافياً لاستبدال قسيمتك.';
  }

  @override
  String get claimVoucher => 'استرداد القسيمة الآن';

  @override
  String get voucherClaimed => 'تم استرداد القسيمة!';

  @override
  String get voucherDescription =>
      'أظهر الرمز الشريطي أو الكود أدناه لأمين الصندوق في أي فرع لـ Union Coop في دبي.';

  @override
  String get backToRewards => 'العودة إلى المكافآت';

  @override
  String get leaderboardTitle => 'المكافآت والمتصدرون';

  @override
  String get dubaiLeaderboard => 'متصدرو دبي';

  @override
  String get lastMonthChampions => 'أبطال الشهر الماضي';

  @override
  String get sourcerBadges => 'شارات المتسوق';

  @override
  String get todaysChallenges => 'تحديات اليوم';

  @override
  String get activeRequestBoard => 'لوحة الطلبات النشطة';

  @override
  String get leaderboardStreaks => 'المتصدرون والسلاسل';

  @override
  String yourRank(int rank) {
    return 'المرتبة #$rank';
  }

  @override
  String dayStreak(int days) {
    return 'سلسلة $days يوم';
  }

  @override
  String get submitPrice => 'رفع سعر';

  @override
  String get submitForReview => 'إرسال للمراجعة';

  @override
  String get priceSubmitted => 'تم إرسال السعر!';

  @override
  String get priceSubmittedDesc =>
      'طلب السعر قيد المراجعة.\nسيتم إضافة الرموز بعد موافقة المشرف.';

  @override
  String get openAdminReview => 'فتح لوحة المراجعة';

  @override
  String get viewTokenBalance => 'عرض رصيد الرموز';

  @override
  String get tokenRewardEstimate => 'تقدير مكافأة الرموز';

  @override
  String get totalRewardEstimate => 'إجمالي المكافأة المتوقعة';

  @override
  String get selectSupermarket => 'اختر السوبرماركت';

  @override
  String get selectProduct => 'اختر المنتج';

  @override
  String get enterPriceAed => 'أدخل السعر (درهم)';

  @override
  String get promotionType => 'نوع العرض';

  @override
  String get priceLabelPhoto => 'صورة بطاقة السعر';

  @override
  String get receiptPhoto => 'صورة الإيصال';

  @override
  String get photoUploaded => 'تم رفع الصورة';

  @override
  String get tapToUpload => 'اضغط للرفع';

  @override
  String dailyCapRemaining(int remaining, int cap) {
    return 'تبقّى $remaining من $cap تقديمات اليوم';
  }

  @override
  String get dailyChallenge => 'تحدي اليوم';

  @override
  String challengeBonus(int tokens) {
    return '+$tokens رمز إضافي';
  }

  @override
  String challengeCompleted(int tokens) {
    return 'تم! +$tokens رمز مكتسب';
  }

  @override
  String challengeProgress(int done, int total) {
    return '$done/$total مكتمل';
  }

  @override
  String get tapToComplete => 'اضغط لبدء التقديم';

  @override
  String get profileSettings => 'الملف الشخصي والإعدادات';

  @override
  String get mySubmissions => 'تقديماتي';

  @override
  String get myTokenHistory => 'سجل الرموز';

  @override
  String get myRequests => 'طلباتي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get displayName => 'الاسم المعروض';

  @override
  String get homeArea => 'المنطقة السكنية';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get accuracyRating => 'تقييم الدقة';

  @override
  String accuracyRatingDesc(int percent) {
    return '$percent٪ من تقديماتك تمت الموافقة عليها';
  }

  @override
  String get noSubmissionsYet => 'لا توجد تقديمات بعد.\nقدّم سعراً للبدء!';

  @override
  String get noRequestsYet => 'لا توجد طلبات أسعار بعد.';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get approved => 'معتمد';

  @override
  String get rejected => 'مرفوض';

  @override
  String get fulfilled => 'مكتمل';

  @override
  String get open => 'مفتوح';

  @override
  String get refunded => 'مسترجع';

  @override
  String get adminConsole => 'لوحة الإشراف';

  @override
  String get priceModeration => 'مراجعة الأسعار';

  @override
  String get analytics => 'التحليلات';

  @override
  String get sourcersIndex => 'دليل الموردين';

  @override
  String get systemSettings => 'إعدادات النظام';

  @override
  String get approve => 'اعتماد';

  @override
  String get reject => 'رفض';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get editSubmission => 'تعديل التقديم';

  @override
  String get tokenEarnRate => 'معدل كسب الرموز (أساسي)';

  @override
  String get voucherThreshold => 'حد استرداد القسيمة (رموز)';

  @override
  String get dailySubmissionCap => 'الحد اليومي للتقديمات';

  @override
  String get freshLabel => 'حديث';

  @override
  String updatedAgoLabel(int hours) {
    return 'محدّث منذ $hours ساعة';
  }

  @override
  String get unverifiedOutdated => 'غير موثّق — قد يكون قديماً';

  @override
  String get stalePriceWarning => 'بيانات السعر قد تكون قديمة (+72 ساعة)';

  @override
  String get staleStore => 'قديم';

  @override
  String get filterByChain => 'تصفية حسب السلسلة';

  @override
  String get allChains => 'الكل';

  @override
  String get submitPriceHere => 'قدّم سعراً هنا';

  @override
  String betterPriceFound(String item, String price, String store) {
    return 'سعر أفضل لـ $item! الآن $price درهم في $store.';
  }

  @override
  String get dismiss => 'إغلاق';

  @override
  String get requestFulfilled =>
      'تم استيفاء الطلب! تحويل الرموز إلى مقدم الطلب.';

  @override
  String get noResultsFound => 'لا توجد نتائج';

  @override
  String get cartEmpty => 'سلة التسوق فارغة';

  @override
  String get addItemsToCart => 'تصفح المنتجات وأضف العناصر لمقارنة الأسعار.';

  @override
  String get bestBasket => 'أفضل سلة';

  @override
  String get bestStore => 'أفضل متجر';

  @override
  String get checkout => 'إتمام الشراء';

  @override
  String get applyCoupon => 'تطبيق كوبون';

  @override
  String get guestMode => 'تصفح كضيف';

  @override
  String get signInWithGoogle => 'التسجيل عبر Google';

  @override
  String get signInWithApple => 'التسجيل عبر Apple';

  @override
  String get signInWithPhone => 'التسجيل برقم الهاتف';

  @override
  String level(int level) {
    return 'المستوى $level';
  }

  @override
  String earnMultiplier(int percent) {
    return '+$percent٪ معدل كسب';
  }

  @override
  String get homeCategories => 'الفئات';

  @override
  String get homeCategoryFresh => 'طازج';

  @override
  String get homeCategoryFruits => 'فواكه';

  @override
  String get homeCategorySnack => 'وجبات خفيفة';

  @override
  String get homeCategoryGrocery => 'بقالة';

  @override
  String get homeCategoryOils => 'زيوت';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String homeGreetingLine(Object greeting, Object name) {
    return '$greeting، $name';
  }

  @override
  String get homeFindNearbyPrices => 'اعرف الأسعار القريبة قبل أن تذهب';

  @override
  String get homeSearchHint => 'ابحث عن منتج لمقارنة الأسعار القريبة';

  @override
  String homeSearchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتائج',
      one: 'نتيجة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get homeHowItWorks =>
      'ببساطة: ابحث عن منتج، تحقق من المتاجر القريبة، ثم قرر أين يستحق الذهاب.';

  @override
  String get homeBestPricesNearYou => 'أفضل الأسعار القريبة منك';

  @override
  String homePricesCount(Object count) {
    return '$count سعر';
  }

  @override
  String get homeNoPricesMatch => 'لا توجد أسعار تطابق هذا الفلتر بعد';

  @override
  String get homeNoPricesHint =>
      'جرّب كل الأسعار، ابحث عن منتج، أو اطلب من المتسوقين التحقق من سعر.';

  @override
  String get homeFindAnItem => 'ابحث عن منتج';

  @override
  String get homeBrowseItems => 'تصفح المنتجات';

  @override
  String get homeFeaturedStores => 'متاجر مميزة';

  @override
  String get homeEarnRewardsToday => 'اكسب مكافآت اليوم';

  @override
  String homePriceSharesLeft(Object count) {
    return 'تبقى $count مشاركة سعر لكسب الرموز';
  }

  @override
  String get homeDailyChallenge => 'التحدي اليومي';

  @override
  String homeChallengeDoneBadge(Object tokens) {
    return 'تم! ‎+$tokens‎ رمز';
  }

  @override
  String get homeDailyChallengeDetails => 'تفاصيل التحدي اليومي';

  @override
  String get homeChallengeFinished => 'لقد أنهيت هذا التحدي!';

  @override
  String get homeChallengeEarnBonus => 'اكسب رموزًا إضافية بالمشاركة اليوم';

  @override
  String get homeTargetSupermarket => 'السوبر ماركت المستهدف';

  @override
  String get homeAnySupermarketChain => 'أي سلسلة سوبر ماركت';

  @override
  String get homeYourProgress => 'تقدمك';

  @override
  String homeProgressPrices(Object progress, Object target) {
    return '$progress / $target سعر';
  }

  @override
  String get homeRewardBonus => 'مكافأة إضافية';

  @override
  String homeRewardBonusValue(Object tokens) {
    return '‎+$tokens‎ رمز';
  }

  @override
  String get homeHowToComplete => 'كيفية الإكمال:';

  @override
  String homeStepVisitStore(Object store) {
    return 'زر أي فرع من $store.';
  }

  @override
  String get homeAGenericSupermarket => 'أي سوبر ماركت';

  @override
  String get homeStepVerifyPrices =>
      'ابحث عن منتجات البقالة وتحقق من أسعارها على الرفوف.';

  @override
  String get homeStepSubmitPrice =>
      'اضغط على \"إرسال السعر\" في التطبيق، أدخل تفاصيل السعر، ثم أرسله.';

  @override
  String get homeStepApproved =>
      'بعد الموافقة، سيتحدث تقدمك وستحصل على مكافأة الرموز!';

  @override
  String get homeCompletedRewardClaimed => 'اكتمل! تم استلام المكافأة';

  @override
  String get homeStartChallengeNow => 'ابدأ التحدي الآن';

  @override
  String get homeFreshnessAll => 'الكل';

  @override
  String get homeFreshnessUnder6h => 'أقل من 6 ساعات';

  @override
  String get homeFreshnessUnder24h => 'أقل من 24 ساعة';

  @override
  String get homeFreshnessUnder72h => 'أقل من 72 ساعة';

  @override
  String get homeUpdatedJustNow => 'تم التحديث الآن';

  @override
  String homeUpdatedHoursAgo(Object hours) {
    return 'تم التحديث قبل $hours ساعة';
  }

  @override
  String homeUpdatedDaysAgo(Object days) {
    return 'تم التحديث قبل $days يوم';
  }

  @override
  String get homeVerifiedWithPhoto => 'موثّق بصورة';

  @override
  String homeKmAway(Object distance) {
    return '$distance كم';
  }

  @override
  String homeStoreDistancePrices(Object distance, Object count) {
    return '$distance كم • $count سعر';
  }

  @override
  String get homeOffer1Title => 'اعرف أفضل سعر\nقبل أن تخرج';

  @override
  String get homeOffer1Subtitle => 'أسعار حديثة من متسوقين بقربك';

  @override
  String get homeOffer2Title => 'وفّر الرحلة\nوالدراهم';

  @override
  String get homeOffer2Subtitle => 'قارن المتاجر القريبة قبل أن تذهب';

  @override
  String get homeOffer3Title => 'تحتاج التحقق من سعر؟\nاسأل المجتمع';

  @override
  String get homeOffer3Subtitle => 'يمكن لمتسوق حقيقي التحقق من الرف';

  @override
  String get searchDailyFoods => 'أطعمة يومية';

  @override
  String get searchMyList => 'قائمتي';

  @override
  String get searchCatFresh => 'طازج';

  @override
  String get searchCatFruits => 'فواكه';

  @override
  String get searchCatSnacks => 'وجبات خفيفة';

  @override
  String get searchCatGrocery => 'بقالة';

  @override
  String get searchCatOils => 'زيوت';

  @override
  String get searchHint => 'ابحث عن الخضروات والفواكه والمزيد';

  @override
  String get searchScanBarcode => 'مسح الباركود';

  @override
  String get searchEmptyCategoryTitle => 'لا توجد منتجات في هذه الفئة';

  @override
  String searchEmptyQueryTitle(Object query) {
    return 'لم نتمكن من العثور على \"$query\"';
  }

  @override
  String get searchEmptyCategorySubtitle => 'جرّب تغيير الفئة أو عد لاحقًا.';

  @override
  String get searchEmptyQuerySubtitle =>
      'اضغط أدناه لتطلب من المتسوقين الآخرين التحقق من السعر نيابة عنك!';

  @override
  String get searchAskShoppersToCheck => 'اطلب من المتسوقين التحقق';

  @override
  String get searchRequestPriceCheckTitle => 'اطلب التحقق من السعر';

  @override
  String searchRequestPriceCheckDescription(Object requestCost) {
    return 'سيتحقق المتسوقون الآخرون من سعر هذا المنتج نيابة عنك. يستخدم هذا $requestCost رمزًا ويُسترد إذا انتهت صلاحيته.';
  }

  @override
  String get searchItemNameLabel => 'اسم المنتج';

  @override
  String get searchItemNameHint => 'مثال: حليب الروابي الطازج 2 لتر';

  @override
  String get searchEnterProductName => 'أدخل اسم المنتج';

  @override
  String get searchChooseSupermarket => 'اختر السوبر ماركت';

  @override
  String get searchRequestPosted =>
      'تم نشر الطلب! سيتم إخطار المتسوقين القريبين من ذلك المتجر.';

  @override
  String get searchAskForThisPrice => 'اطلب هذا السعر';

  @override
  String get cartNoStoreYet => 'لا يوجد متجر بعد';

  @override
  String get cartMyList => 'قائمتي';

  @override
  String get cartClearSavedPrices => 'مسح الأسعار المحفوظة';

  @override
  String get cartSavedPricesCleared => 'تم مسح الأسعار المحفوظة';

  @override
  String get cartItemsYouAreChecking => 'العناصر التي تتحقق منها';

  @override
  String get cartAddMore => 'أضف المزيد';

  @override
  String cartPriceDroppedOn(Object product) {
    return 'انخفض سعر $product!';
  }

  @override
  String cartItemsCheaperNow(Object count) {
    return '$count عناصر في قائمتك أصبحت أرخص الآن!';
  }

  @override
  String cartPriceDropDetail(Object price, Object store, Object old) {
    return 'الآن $price درهم في $store (كان $old درهم).';
  }

  @override
  String get cartNoSavedPricesYet => 'لا توجد أسعار محفوظة بعد';

  @override
  String get cartEmptyStateSubtitle =>
      'ابحث عن منتج واحفظه هنا لمعرفة المتجر القريب الذي يستحق الزيارة.';

  @override
  String get cartFindPricesNearby => 'ابحث عن الأسعار القريبة';

  @override
  String get cartShoppingListOptions => 'خيارات قائمة التسوق';

  @override
  String get cartCheapestBasket => 'أرخص سلة';

  @override
  String cartStoreWithDistance(Object store, Object distance) {
    return '$store ($distance كم)';
  }

  @override
  String get cartClosestOption => 'الخيار الأقرب';

  @override
  String cartSaveAtStore(Object amount, Object store) {
    return 'وفّر $amount درهم في $store';
  }

  @override
  String get cartClosestIsCheapest => 'متجرك الأقرب هو أيضًا الخيار الأرخص!';

  @override
  String cartBestSeenAt(Object store) {
    return 'أفضل سعر شوهد في $store';
  }

  @override
  String get cartRemove => 'إزالة';

  @override
  String get cartNearbyStoreComparison => 'مقارنة المتاجر القريبة';

  @override
  String cartKmAway(Object distance) {
    return 'على بُعد $distance كم';
  }

  @override
  String get cartBest => 'الأفضل';

  @override
  String cartExtraAmount(Object amount) {
    return '+$amount درهم';
  }

  @override
  String get cartPlainLanguageNote =>
      'ديل سوق لا يبيع البقالة. هذه القائمة تساعدك فقط على تحديد أين تتحقق من الأسعار القريبة.';

  @override
  String get storeLocationPromptTitle => 'اعثر على المتاجر القريبة منك';

  @override
  String get storeLocationPromptBody =>
      'يستخدم ديل سوق موقعك لعرض المسافة بينك وبين كل متجر في دبي.';

  @override
  String get storeLocationPromptSkip => 'تخطٍ';

  @override
  String get storeLocationPromptAllow => 'السماح';

  @override
  String get storeMapTitle => 'خريطة المتاجر — دبي';

  @override
  String get storeSearchHint => 'ابحث باسم المتجر أو المنطقة…';

  @override
  String get storeNoStoresFound => 'لم يتم العثور على متاجر';

  @override
  String get storeLoadingStores => 'جارٍ تحميل المتاجر القريبة…';

  @override
  String storeDubaiStoresCount(Object count) {
    return '$count متجر في دبي';
  }

  @override
  String get storeTapPinHint => 'اضغط على العلامة لعرض تفاصيل الفرع';

  @override
  String storeMarkerTooltipWithDistance(Object name, Object branch, Object km) {
    return '$name · $branch\nيبعد $km كم';
  }

  @override
  String storeMarkerTooltip(Object name, Object branch) {
    return '$name\n$branch';
  }

  @override
  String get storeResetDubai => 'دبي';

  @override
  String get storeNearYouTitle => 'بالقرب منك في دبي';

  @override
  String get storeAllStoresTitle => 'جميع متاجر دبي';

  @override
  String storeWithinRadiusSorted(Object km) {
    return 'ضمن $km كم · مرتبة حسب المسافة';
  }

  @override
  String storeStoresCount(Object count) {
    return '$count متجر';
  }

  @override
  String storeNoStoresMatch(Object query) {
    return 'لا توجد متاجر تطابق \"$query\"';
  }

  @override
  String get storeStaleBadge => 'قديم';

  @override
  String get storePricesLoadErrorTitle => 'تعذّر تحميل الأسعار';

  @override
  String get storePricesLoadErrorSubtitle =>
      'تحقق من اتصالك أو أرسل سعرًا جديدًا لهذا الفرع.';

  @override
  String get storeNoPricesTitle => 'لا توجد أسعار حديثة بعد';

  @override
  String get storeNoPricesSubtitle => 'كن أول من يشارك سعر رف في هذا الفرع.';

  @override
  String storePriceVerifiedWithPhoto(Object label) {
    return '$label · مؤكد بصورة';
  }

  @override
  String get storeSubmitPriceHere => 'أرسل السعر هنا';

  @override
  String storeDistanceKm(Object km) {
    return '$km كم';
  }

  @override
  String get storeViewPrices => 'عرض الأسعار';

  @override
  String get submitStepSelectSupermarket => 'اختر السوبر ماركت';

  @override
  String get submitStepSelectProduct => 'اختر المنتج';

  @override
  String get submitStepEnterPrice => 'أدخل السعر';

  @override
  String get submitStepConfirmSubmit => 'التأكيد والإرسال';

  @override
  String get submitWhereDidYouSeePrice => 'أين رأيت السعر؟';

  @override
  String get submitSelectSupermarketHint =>
      'اختر السوبر ماركت من قائمة الأماكن القريبة.';

  @override
  String submitSubmissionsLeftToday(Object remaining, Object cap) {
    return 'تبقى $remaining من $cap عمليات إرسال اليوم.';
  }

  @override
  String get submitWhichProduct => 'ما هو المنتج؟';

  @override
  String get submitSearchSelectProductHint =>
      'ابحث عن المنتج أو اختره وأرفق صورة إثبات.';

  @override
  String get submitSearchBarcodeHint =>
      'ابحث بالاسم أو العلامة التجارية أو امسح الباركود';

  @override
  String get submitScanBarcodeTooltip => 'مسح الباركود';

  @override
  String get submitNoProductsFound => 'لم يتم العثور على منتجات مطابقة لبحثك.';

  @override
  String get submitAttachProofRequired => 'أرفق إثباتًا (مطلوب)';

  @override
  String get submitPriceLabelPhoto => 'صورة ملصق السعر';

  @override
  String get submitReceiptPhoto => 'صورة الإيصال';

  @override
  String get submitUploading => 'جارٍ الرفع…';

  @override
  String get submitEnterPriceDetails => 'أدخل تفاصيل السعر';

  @override
  String get submitEnterShelfPriceHint =>
      'أدخل سعر الرف والعروض الترويجية النشطة.';

  @override
  String get submitEnterPriceAed => 'أدخل السعر (درهم)';

  @override
  String get submitManualShelfPriceHelper => 'إدخال يدوي لسعر الرف، مثال 14.75';

  @override
  String get submitPleaseEnterPrice => 'يرجى إدخال السعر';

  @override
  String get submitPleaseEnterValidNumber => 'يرجى إدخال رقم صالح';

  @override
  String get submitPromotionType => 'نوع العرض الترويجي';

  @override
  String get submitPromoNone => 'لا يوجد';

  @override
  String get submitPromoDiscount => 'خصم';

  @override
  String get submitPromoBogo => 'اشترِ واحدًا واحصل على آخر';

  @override
  String get submitPromoBundle => 'حزمة';

  @override
  String get submitConfirmDetails => 'تأكيد التفاصيل';

  @override
  String get submitReviewBeforeSubmission =>
      'يرجى مراجعة التفاصيل قبل الإرسال.';

  @override
  String get submitSummarySupermarket => 'السوبر ماركت';

  @override
  String get submitSummaryProduct => 'المنتج';

  @override
  String get submitSummaryPrice => 'السعر';

  @override
  String get submitSummaryPromotion => 'العرض الترويجي';

  @override
  String get submitSummaryProof => 'الإثبات';

  @override
  String get submitProofPhotoAttached => 'تم إرفاق صورة';

  @override
  String get submitTokenRewardEstimate => 'تقدير مكافأة التوكنات';

  @override
  String submitPlusTokens(Object tokens) {
    return '+$tokens توكن';
  }

  @override
  String get submitTokenFreshShelfPrice => 'سعر رف جديد';

  @override
  String get submitTokenStoreSelected => 'تم اختيار المتجر';

  @override
  String get submitTokenProductSelected => 'تم اختيار المنتج';

  @override
  String get submitTokenAedPriceEntered => 'تم إدخال السعر بالدرهم';

  @override
  String get submitTokenPriceLabelAttached => 'تم إرفاق ملصق السعر';

  @override
  String get submitTokenAttachPriceLabel => 'أرفق ملصق السعر';

  @override
  String get submitTokenNoPromotion => 'لم يتم اختيار عرض ترويجي';

  @override
  String submitTokenPromoNoted(Object promo) {
    return 'تم تسجيل عرض $promo';
  }

  @override
  String get submitTokenReceiptMultiplier => 'مضاعف الإيصال المُوثَّق 1.5×';

  @override
  String get submitTokenAttachReceiptBonus =>
      'أرفق الإيصال للحصول على مكافأة 1.5×';

  @override
  String get submitTokenMultiplierApplied => 'تم تطبيق ×1.5';

  @override
  String get submitTokenNotApplied => 'غير مطبق';

  @override
  String submitTokensAmount(Object count) {
    return '+$count توكن';
  }

  @override
  String submitTokenAmount(Object count) {
    return '+$count توكن';
  }

  @override
  String get submitTotalRewardEstimate => 'إجمالي تقدير المكافأة';

  @override
  String submitTokensTotal(Object tokens) {
    return '$tokens توكن';
  }

  @override
  String get submitBack => 'رجوع';

  @override
  String get submitNext => 'التالي';

  @override
  String get submitSubmitAPrice => 'إرسال سعر';

  @override
  String get submitCouldNotSendPrice =>
      'تعذّر إرسال هذا السعر. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';

  @override
  String get submitSavedOffline =>
      'تم الحفظ. سنرسل هذا السعر تلقائيًا عند عودة الاتصال بالإنترنت.';

  @override
  String get offlineBanner =>
      'أنت غير متصل بالإنترنت — تم حفظ تغييراتك وستتم مزامنتها عند عودة الاتصال.';

  @override
  String offlinePendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغييرات بانتظار المزامنة',
      one: 'تغيير واحد بانتظار المزامنة',
    );
    return '$_temp0';
  }

  @override
  String submitTransactionDescription(
    Object tokens,
    Object product,
    Object store,
  ) {
    return '+$tokens توكن — تم إرسال $product في $store';
  }

  @override
  String get submitPhotoUploaded => 'تم رفع الصورة';

  @override
  String get submitTapToUpload => 'اضغط للرفع';

  @override
  String get submitPriceSubmitted => 'تم إرسال السعر!';

  @override
  String submitTokensGained(Object tokens) {
    return '+$tokens توكن';
  }

  @override
  String submitPendingReviewMessage(Object name) {
    return 'إرسال السعر الخاص بك قيد المراجعة.\nسيتم إضافة التوكنات إلى $name بعد موافقة المسؤول.';
  }

  @override
  String get submitOpenAdminReview => 'فتح مراجعة المسؤول';

  @override
  String get submitViewTokenBalance => 'عرض رصيد التوكنات';

  @override
  String profileLevelBadge(Object level, Object title) {
    return 'مستوى $level $title';
  }

  @override
  String profileDayStreak(Object days) {
    return 'سلسلة $days يوم';
  }

  @override
  String get profileTabSubmissions => 'المساهمات';

  @override
  String get profileTabTokens => 'النقاط';

  @override
  String get profileTabRequests => 'الطلبات';

  @override
  String get profileTabSettings => 'الإعدادات';

  @override
  String get profilePhotoUpdated => 'تم تحديث صورة الملف الشخصي';

  @override
  String get profilePhotoRemoved => 'تمت إزالة صورة الملف الشخصي';

  @override
  String get profileAccuracyRating => 'تقييم الدقة';

  @override
  String profileAccuracyApproved(Object percent) {
    return 'تمت الموافقة على $percent% من مساهماتك';
  }

  @override
  String get profileNoSubmissions =>
      'لم تتم مشاركة أي أسعار بعد.\nشارك سعرًا من الرف لمساعدة المتسوقين وكسب النقاط.';

  @override
  String get profileCurrentBalance => 'الرصيد الحالي';

  @override
  String get profileTapLeaderboardRedeem => 'اضغط على لوحة المتصدرين للاستبدال';

  @override
  String get profileNoTokenActivity =>
      'لا يوجد نشاط نقاط بعد.\nشارك سعرًا أو ساعد في طلب لبدء الكسب.';

  @override
  String get profileNoPriceRequests =>
      'لا توجد طلبات أسعار بعد.\nاطلب سعرًا عندما لا تجد منتجًا.';

  @override
  String get profileCancelRequest => 'إلغاء الطلب';

  @override
  String get profileCancelRequestTitle => 'إلغاء الطلب؟';

  @override
  String profileCancelRequestBody(Object product) {
    return 'هل أنت متأكد أنك تريد إلغاء طلب السعر لـ \"$product\"؟ ستتم إعادة نقاط المكافأة إليك.';
  }

  @override
  String get profileNo => 'لا';

  @override
  String get profileYesCancel => 'نعم، إلغاء';

  @override
  String get profileVoucherApproved => 'تمت الموافقة على القسيمة';

  @override
  String get profileCodePending => 'الرمز قيد الإصدار';

  @override
  String get profileVoucherUnderReview => 'القسيمة قيد المراجعة';

  @override
  String profileVoucherPendingBody(Object amount, Object supermarket) {
    return 'قسيمتك بقيمة $amount درهم من $supermarket بانتظار موافقة المشرف.';
  }

  @override
  String get profileVoucherReady => 'القسيمة جاهزة!';

  @override
  String get profileVoucherReadyBody =>
      'توجه إلى تبويب لوحة المتصدرين لاستلام قسيمة يونيون كوب بقيمة 50 درهمًا.';

  @override
  String get profileClaimVoucherNow => 'استلم القسيمة الآن';

  @override
  String get profileVoucherGoalTitle => 'قسيمة يونيون كوب بقيمة 50 درهمًا';

  @override
  String profileEarnMoreTokens(Object count) {
    return 'اكسب $count نقطة إضافية لفتح قسيمتك.';
  }

  @override
  String get profilePhotoTitle => 'صورة الملف الشخصي';

  @override
  String get profilePhotoSubtitleEmpty =>
      'أضف صورة ودودة ليتعرف عليك المتسوقون';

  @override
  String get profilePhotoSubtitleSet => 'غيّر صورتك الحالية أو أزلها';

  @override
  String get profileChangePhoto => 'تغيير الصورة';

  @override
  String get profileRemovePhoto => 'إزالة الصورة';

  @override
  String get profilePhotoTakePhoto => 'التقاط صورة';

  @override
  String get profilePhotoChooseLibrary => 'اختيار من المعرض';

  @override
  String get profileEditPhotoTooltip => 'تعديل صورة الملف الشخصي';

  @override
  String get profileStatTokens => 'النقاط';

  @override
  String get profileStatAccuracy => 'الدقة';

  @override
  String get profileStatApproved => 'مقبولة';

  @override
  String get profileStatStreak => 'التتابع';

  @override
  String get profileSectionSubmissions => 'مساهماتي';

  @override
  String get profileSectionTokens => 'سجل النقاط';

  @override
  String get profileSectionRequests => 'طلباتي';

  @override
  String get profileSectionSettings => 'الإعدادات والحساب';

  @override
  String get profileDisplayName => 'الاسم المعروض';

  @override
  String get profileEditDisplayName => 'تعديل الاسم المعروض';

  @override
  String get profileNameLabel => 'الاسم';

  @override
  String get profileCancel => 'إلغاء';

  @override
  String get profileSave => 'حفظ';

  @override
  String get profileHomeArea => 'المنطقة السكنية';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileViewTutorial => 'عرض دليل التطبيق';

  @override
  String get profileViewTutorialSubtitle => 'إعادة تشغيل دليل مقدمة ديل سوق';

  @override
  String get profilePrivacyTerms => 'الخصوصية والشروط';

  @override
  String get profilePrivacyTermsSubtitle =>
      'الموقع والصور والنقاط والقسائم وحذف الحساب';

  @override
  String get profileAdminConsole => 'وحدة مراجعة المشرف';

  @override
  String get profileAdminConsoleSubtitle => 'مراجعة مساهمات الأسعار';

  @override
  String get profileLogOut => 'تسجيل الخروج';

  @override
  String get profileLogOutDemo => 'تسجيل الخروج من النسخة التجريبية';

  @override
  String get welcomePrivacyConsentRequired =>
      'يرجى الموافقة على سياسة الخصوصية للمتابعة.';

  @override
  String welcomeInvalidPhoneNumber(Object digits, Object country) {
    return 'يرجى إدخال رقم هاتف صالح مكون من $digits أرقام لـ $country.';
  }

  @override
  String get welcomeSelectCountry => 'اختر الدولة';

  @override
  String get welcomeModeratorToggleEnabled => 'تم تفعيل وضع المشرف';

  @override
  String get welcomeModeratorToggleDisabled => 'تم إيقاف وضع المشرف';

  @override
  String get welcomeTaglineAdmin =>
      'راجع أسعار السوبر ماركت التي يشاركها المتسوقون';

  @override
  String get welcomeTaglineCustomer => 'أسعار يشاركها المتسوقون بالقرب منك';

  @override
  String get welcomeCustomerModeTab => 'وضع العميل';

  @override
  String get welcomeAdminModeratorTab => 'مشرف الإدارة';

  @override
  String get welcomePillarAuditQueue => 'قائمة\nالمراجعة';

  @override
  String get welcomePillarFraudFilter => 'فلتر\nالاحتيال';

  @override
  String get welcomePillarIssueTokens => 'إصدار\nالرموز';

  @override
  String get welcomePillarComparePrices => 'قارن\nالأسعار';

  @override
  String get welcomePillarFindNearby => 'ابحث\nبالقرب';

  @override
  String get welcomePillarRequestPrice => 'اطلب\nسعراً';

  @override
  String get welcomeInfoBannerAdmin =>
      'لوحة المشرف: تحقق من الإيصالات وأسعار الرفوف.';

  @override
  String get welcomeInfoBannerCustomer =>
      'لا طلبات هنا. فقط تحقق من الأسعار قبل أن تذهب.';

  @override
  String get welcomePrivacyConsentPrefix => 'أوافق على ';

  @override
  String get welcomePrivacyPolicyLink => 'سياسة الخصوصية';

  @override
  String get welcomePrivacyConsentSuffix =>
      ' وأوافق على معالجة الموقع على مستوى الحي.';

  @override
  String get welcomeEnterAdminDashboard => 'ادخل لوحة الإدارة';

  @override
  String get welcomeContinueWithGoogle => 'المتابعة باستخدام جوجل';

  @override
  String get welcomeSignInWithPhone => 'تسجيل الدخول بالهاتف';

  @override
  String get welcomeSignInWithApple => 'تسجيل الدخول باستخدام آبل';

  @override
  String get welcomeBrowseAsGuest => 'التصفح كضيف';

  @override
  String get welcomeFooterAdmin => 'تُطبَّق صلاحيات وحدة تحكم المشرف.';

  @override
  String get welcomeFooterCustomer =>
      'أسعار السوبر ماركت التي يشاركها المتسوقون في دبي.';

  @override
  String get welcomeCancel => 'إلغاء';

  @override
  String get welcomeSendCode => 'إرسال الرمز';

  @override
  String welcomeOtpPrompt(Object phone) {
    return 'أدخل الرمز المكون من 6 أرقام المرسل إلى $phone';
  }

  @override
  String get welcomeVerify => 'تحقق';

  @override
  String get welcomeResendCode => 'إعادة إرسال الرمز';

  @override
  String get productDetailsTitle => 'التفاصيل';

  @override
  String get productAddToFavourites => 'إضافة إلى المفضلة';

  @override
  String get productRemoveFromFavourites => 'إزالة من المفضلة';

  @override
  String productBestPriceSeenAt(Object store) {
    return 'أفضل سعر شوهد في $store';
  }

  @override
  String get productRequestThisPrice => 'اطلب هذا السعر';

  @override
  String get productRequestPriceConfirmation =>
      'اطلب هذا السعر! سيتحقق منه متسوقون آخرون قريبًا.';

  @override
  String get productCompareStorePrices => 'قارن أسعار المتاجر';

  @override
  String get productNoFreshPrices => 'لا توجد أسعار محدثة بعد.';

  @override
  String get productNoFreshPricesHint =>
      'اطلب من متسوق آخر التحقق من هذا المنتج قبل أن تذهب.';

  @override
  String get productPriceFlaggedHidden =>
      'تم الإبلاغ عن السعر وإخفاؤه (بانتظار مراجعة المشرف)';

  @override
  String productStoreDistance(Object store, Object distance) {
    return '$store • على بُعد $distance كم';
  }

  @override
  String productFreshnessVerified(Object freshness) {
    return '$freshness • مُتحقق منه بالصورة';
  }

  @override
  String get productUpdatedJustNow => 'تم التحديث الآن';

  @override
  String productUpdatedHoursAgo(Object hours) {
    return 'تم التحديث قبل $hours ساعة';
  }

  @override
  String productUpdatedDaysAgo(Object days) {
    return 'تم التحديث قبل $days يوم';
  }

  @override
  String productUpdatedLabel(Object label) {
    return 'تم التحديث $label';
  }

  @override
  String get productBestPriceBadge => 'أفضل سعر';

  @override
  String get productReportHiddenMessage =>
      'شكرًا. تم إخفاء هذا السعر حتى يراجعه المشرف.';

  @override
  String get productReportPendingMessage =>
      'شكرًا. سنخفي هذا السعر بعد 3 بلاغات فريدة.';

  @override
  String get productReported => 'تم الإبلاغ';

  @override
  String get productReportWrongPrice => 'الإبلاغ عن سعر خاطئ';

  @override
  String get productPriceHistory90Day => 'سجل الأسعار لـ 90 يومًا';

  @override
  String get productYouMayAlsoLike => 'قد يعجبك أيضًا';

  @override
  String get productBestSeenPrice => 'أفضل سعر شوهد';

  @override
  String get productSignInToSavePrices =>
      'يرجى تسجيل الدخول لحفظ الأسعار ومقارنة سلال البقالة.';

  @override
  String get productSignInAction => 'تسجيل الدخول';

  @override
  String productSavedForComparison(Object name) {
    return 'تم حفظ $name لمقارنة الأسعار';
  }

  @override
  String get productViewAction => 'عرض';

  @override
  String get productSavePrice => 'حفظ السعر';

  @override
  String get productNoPriceHistory =>
      'لا يوجد سجل أسعار معتمد بعد. بمجرد أن يقدم المتسوقون أسعارًا محدثة، سترى الاتجاه هنا.';

  @override
  String productPriceRange(Object lowest, Object highest) {
    return 'الأدنى $lowest • الأعلى $highest';
  }

  @override
  String productLatestPrice(Object latest) {
    return 'الأحدث $latest';
  }

  @override
  String get requestBannerExplanation =>
      'هل تحتاج إلى التحقق من سعر؟ اسأل المتسوقين القريبين. إذا كان أحدهم في المتجر بالفعل، يمكنه إرسال سعر الرف لك.';

  @override
  String requestBoardTitle(Object count) {
    return 'عمليات التحقق من الأسعار المطلوبة ($count)';
  }

  @override
  String get requestAskForPrice => 'اطلب سعرًا';

  @override
  String get requestEmptyTitle => 'تم إنجاز جميع طلبات الأسعار!';

  @override
  String get requestEmptySubtitle =>
      'هل تحتاج إلى سعر؟ اضغط على \"اطلب سعرًا\" لطلب التحقق من السعر.';

  @override
  String get requestFormTitle => 'اطلب التحقق من سعر';

  @override
  String requestFormSubtitle(Object tokens) {
    return 'أخبرنا بالمنتج والمتجر. يستهلك هذا $tokens رمزًا ويُرد تلقائيًا إذا انتهت صلاحيته.';
  }

  @override
  String get requestItemNameLabel => 'اسم المنتج';

  @override
  String get requestItemNameHint => 'مثل: حليب، أرز، تفاح';

  @override
  String get requestItemNameValidation => 'يرجى إدخال اسم المنتج';

  @override
  String get requestStoreLabel => 'سلسلة المتاجر';

  @override
  String get requestSentTitle => 'تم إرسال طلب السعر';

  @override
  String requestSentBody(Object productName, Object storeName, Object tokens) {
    return 'يمكن للمتسوقين القريبين التحقق من $productName في $storeName. تم حجز $tokens رمزًا وسيُرد إذا انتهت صلاحية الطلب.';
  }

  @override
  String get requestSentConfirm => 'رائع';

  @override
  String get requestSubmitButton => 'اطلب هذا السعر';

  @override
  String requestCardSubtitle(
    Object storeName,
    Object distance,
    Object requesterName,
  ) {
    return '$storeName • $distance كم • نشره $requesterName';
  }

  @override
  String requestCheckPriceButton(Object tokens) {
    return 'تحقق من السعر (+$tokens رمزًا)';
  }

  @override
  String get leaderRewardsTitle => 'المكافآت ولوحة المتصدرين';

  @override
  String get leaderToggleStreaks => 'المتصدرون والسلاسل';

  @override
  String get leaderToggleRequestBoard => 'لوحة الطلبات النشطة';

  @override
  String leaderRankNumber(Object n) {
    return 'المرتبة #$n';
  }

  @override
  String get leaderRankUnknown => 'المرتبة —';

  @override
  String leaderDayStreak(Object days) {
    return 'سلسلة $days يوم';
  }

  @override
  String get leaderTokensLabel => 'النقاط';

  @override
  String get leaderVoucherName => 'قسيمة يونيون كوب بقيمة 50 درهم';

  @override
  String leaderTokenProgress(Object tokens, Object target) {
    return '$tokens / $target نقطة';
  }

  @override
  String get leaderVoucherRedeemed =>
      'تم استبدال قسيمة يونيون كوب بقيمة 50 درهم';

  @override
  String get leaderVoucherClaimedTitle => 'تم استلام القسيمة!';

  @override
  String get leaderVoucherClaimedBody =>
      'اعرض الباركود أو الرمز أدناه على أمين الصندوق في أي فرع يونيون كوب في دبي.';

  @override
  String get leaderBackToRewards => 'العودة إلى المكافآت';

  @override
  String get leaderClaimVoucher => 'استلم القسيمة الآن';

  @override
  String leaderEarnMoreTokens(Object count) {
    return 'اكسب $count نقطة إضافية لاستبدال قسيمتك.';
  }

  @override
  String get leaderShopperBadges => 'شارات المتسوق';

  @override
  String get leaderTodaysChallenges => 'تحديات اليوم';

  @override
  String leaderChallengeDone(Object tokens) {
    return 'تم! +$tokens نقطة';
  }

  @override
  String leaderChallengeBonus(Object tokens) {
    return '+$tokens نقطة إضافية';
  }

  @override
  String leaderChallengeProgress(Object progress, Object target) {
    return '$progress/$target مكتمل • اضغط لإرسال سعر';
  }

  @override
  String get leaderDubaiLeaderboard => 'لوحة متصدري دبي';

  @override
  String get leaderHallOfFame => 'قاعة المشاهير';

  @override
  String get leaderTopChampions => 'أبطال الشهر الماضي';

  @override
  String leaderYouMarker(Object name) {
    return '$name (أنت)';
  }

  @override
  String get privacyTitle => 'الخصوصية والشروط';

  @override
  String get privacySummaryTitle => 'ملخص مبسط';

  @override
  String get privacySummaryItem1 =>
      'يساعد ديل سوق المتسوقين على مقارنة أسعار البقالة باستخدام الأسعار المقدمة من المجتمع.';

  @override
  String get privacySummaryItem2 =>
      'نطلب فقط المعلومات اللازمة لتشغيل التطبيق: حسابك، ومنطقة سكنك، واللغة، والمساهمات، والطلبات، والرموز، وسجل الإشراف.';

  @override
  String get privacySummaryItem3 =>
      'نستخدم موقع جهازك فقط لعرض أسعار المتاجر القريبة. لا يُخزَّن موقع GPS الدقيق بشكل دائم.';

  @override
  String get privacySummaryItem4 =>
      'الرموز هي مكافآت داخل ديل سوق. وهي ليست نقوداً، ولا يمكن تحويلها، ولا يمكن بيعها.';

  @override
  String get privacySummaryItem5 =>
      'تُستخدم الصور للتحقق من ملصقات الأسعار أو الإيصالات. لا ترفع صوراً تحتوي على معلومات شخصية.';

  @override
  String get privacySummaryItem6 =>
      'يمكنك طلب حذف الحساب من إعدادات الملف الشخصي.';

  @override
  String get privacyCollectTitle => 'ما الذي نجمعه';

  @override
  String get privacyCollectItem1 =>
      'تفاصيل الحساب: معرّف حساب فايربيس، واسم العرض، ورقم الهاتف إذا استخدمت تسجيل الدخول بالهاتف، واللغة المفضلة.';

  @override
  String get privacyCollectItem2 =>
      'منطقة التسوق: الحي أو المنطقة، وليس سجل موقع GPS دقيق دائم.';

  @override
  String get privacyCollectItem3 =>
      'بيانات الأسعار: المنتجات، والمتاجر، والأسعار، والطوابع الزمنية، وصور ملصقات الرفوف أو الإيصالات الاختيارية، وعلامات الإشراف.';

  @override
  String get privacyCollectItem4 =>
      'بيانات المكافآت: رصيد الرموز، وسجل الرموز، وطلبات القسائم، والشارات، والسلاسل، ومجاميع لوحة المتصدرين.';

  @override
  String get privacyCollectItem5 =>
      'رمز المراسلة للجهاز: يُستخدم فقط لإشعارات ديل سوق مثل تلبية الطلبات أو تحديثات المكافآت.';

  @override
  String get privacyUseTitle => 'كيف نستخدم البيانات';

  @override
  String get privacyUseItem1 => 'لعرض أسعار حديثة بالقرب منك.';

  @override
  String get privacyUseItem2 => 'لحساب المدخرات والطلبات والرموز والمكافآت.';

  @override
  String get privacyUseItem3 =>
      'للكشف عن المساهمات الخاطئة أو القديمة أو المكررة أو المشبوهة.';

  @override
  String get privacyUseItem4 => 'لتشغيل إشراف المسؤولين والموافقة على القسائم.';

  @override
  String get privacyUseItem5 =>
      'لتحسين الموثوقية والأمان وسهولة الاستخدام بالعربية والإنجليزية.';

  @override
  String get privacyChoicesTitle => 'خياراتك';

  @override
  String get privacyChoicesItem1 => 'يمكنك التصفح كضيف مع ميزات محدودة.';

  @override
  String get privacyChoicesItem2 => 'يمكنك تغيير اسم العرض ومنطقة سكنك واللغة.';

  @override
  String get privacyChoicesItem3 =>
      'يمكنك رفض الوصول إلى الموقع والاستمرار في استخدام الميزات غير المعتمدة على الموقع.';

  @override
  String get privacyChoicesItem4 =>
      'يمكنك طلب حذف الحساب. ونقوم بإخفاء هوية بيانات الحساب اللازمة لمنع الاحتيال وسجلات تدقيق المعاملات المالية والمكافآت.';

  @override
  String get privacyArabicTitle => 'الملخص بالعربية';

  @override
  String get privacyArabicItem1 =>
      'نستخدم موقعك فقط لعرض أسعار المتاجر القريبة، ولا نخزن موقع GPS الدقيق بشكل دائم.';

  @override
  String get privacyArabicItem2 =>
      'الرموز مكافآت داخل التطبيق وليست نقوداً ولا يمكن بيعها أو تحويلها.';

  @override
  String get privacyArabicItem3 =>
      'صور الأسعار أو الإيصالات تستخدم للتحقق فقط. لا ترفع صوراً تحتوي على معلومات شخصية.';

  @override
  String get privacyArabicItem4 => 'يمكنك طلب حذف الحساب من الإعدادات.';

  @override
  String get tutorialCompareTitle => 'قارن أسعار البقالة';

  @override
  String get tutorialCompareDescription =>
      'اعثر على الأسعار القريبة للفواكه والخضروات ومنتجات الألبان والوجبات الخفيفة في متاجر دبي قبل مغادرة المنزل.';

  @override
  String get tutorialMapTitle => 'اعثر على المتاجر على الخريطة';

  @override
  String get tutorialMapDescription =>
      'شاهد المتاجر المشاركة في أنحاء دبي على الخريطة، ومدى حداثة أسعار كل متجر قبل أن تذهب.';

  @override
  String get tutorialAskTitle => 'اطلب التحقق من الأسعار';

  @override
  String get tutorialAskDescription =>
      'تحتاج سعراً لا يمكنك رؤيته؟ اطلب من المجتمع التحقق منه، أو ساعد الآخرين بمشاركة سعر من الرف.';

  @override
  String get tutorialEarnTitle => 'اكسب مكافآت التسوق';

  @override
  String get tutorialEarnDescription =>
      'شارك الأسعار أو تحقق من الرفوف لكسب الرموز، ثم استبدلها بقسائم متاجر حقيقية.';

  @override
  String get tutorialCompeteTitle => 'تسلّق لوحة المتصدرين';

  @override
  String get tutorialCompeteDescription =>
      'حافظ على سلسلتك اليومية، وأكمل التحديات، واكسب الأوسمة، وارتقِ في لوحة متصدري دبي مع مساهماتك.';

  @override
  String get tutorialSkip => 'تخطٍّ';

  @override
  String get tutorialNext => 'التالي';

  @override
  String get tutorialGetStarted => 'ابدأ الآن';
}
