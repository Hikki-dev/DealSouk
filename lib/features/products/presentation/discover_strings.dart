import 'package:flutter/widgets.dart';

/// Short labels used only by the redesigned discover screens (search filters,
/// product comparison table). They sit outside the ARB files so the generated
/// localisation code stays untouched; migrate them when the ARB is next
/// regenerated.
class DiscoverStrings {
  DiscoverStrings._(this._ar);

  final bool _ar;

  factory DiscoverStrings.of(BuildContext context) =>
      DiscoverStrings._(Localizations.localeOf(context).languageCode == 'ar');

  String _t(String en, String ar) => _ar ? ar : en;

  String get category => _t('Category', 'الفئة');
  String get freshness => _t('Price freshness', 'حداثة السعر');
  String get sortLowest => _t('Lowest price', 'الأقل سعراً');
  String get sortNearest => _t('Nearest', 'الأقرب');
  String get sortFreshest => _t('Freshest', 'الأحدث');
  String get cheapestNow => _t('Cheapest right now', 'الأرخص الآن');
  String get store => _t('Store', 'المتجر');
  String get distance => _t('Distance', 'المسافة');
  String get updated => _t('Updated', 'التحديث');
  String get price => _t('Price', 'السعر');
  String get cantFind => _t(
    "Can't find it? Ask shoppers to check the price.",
    'لم تجده؟ اطلب من المتسوّقين التحقق من السعر.',
  );
  String get typeBarcode =>
      _t('Type the number instead', 'اكتب الرقم بدلاً من ذلك');
  String get barcodeNumber => _t('Barcode number', 'رقم الباركود');
  String get search => _t('Search', 'بحث');
  String get notFound => _t('Product not found', 'المنتج غير موجود');
  String get seenPrice => _t('Seen a price? Share it', 'شاهدت سعراً؟ شاركه');
  String get seenPriceHint => _t(
    'Earn tokens for every approved price',
    'اكسب رموزاً مقابل كل سعر معتمد',
  );
  String get share => _t('Share', 'شارك');
  String get filters => _t('Filters', 'تصفية');
  String get sortBy => _t('Sort by', 'الترتيب حسب');
  String justNow() => _t('Just now', 'الآن');
  String hoursAgo(int h) => _t('${h}h ago', 'منذ $h ساعة');
  String daysAgo(int d) => _t('${d}d ago', 'منذ $d يوم');
  String get all => _t('All', 'الكل');
  String get shopperPhoto => _t('Shopper photo', 'صورة من متسوّق');
}
