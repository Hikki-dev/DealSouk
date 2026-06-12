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
}
