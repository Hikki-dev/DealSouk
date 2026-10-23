import 'package:flutter/widgets.dart' show ColoredBox, Color, Locale, Size;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealsouk/features/home/presentation/home_screen.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/domain/product_price_history.dart';
import 'package:dealsouk/features/products/domain/store_product_price.dart';
import 'package:dealsouk/features/products/presentation/barcode_scan_screen.dart';
import 'package:dealsouk/features/products/presentation/product_detail_screen.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/products/presentation/search_screen.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/core/widgets/shell_layout.dart';
import 'harness.dart';

class _FakeProducts extends ProductsNotifier {
  @override
  List<Product> build() => _products;
}

class _FakeStores extends StoresNotifier {
  @override
  List<Store> build() => _stores;
}

Product _p(
  String id,
  String name,
  String category,
  double price,
  String store,
  int? hours,
  String sample,
) => Product(
  id: id,
  name: name,
  brand: 'Brand',
  packSize: '1 pc',
  category: category,
  lowestPrice: price,
  lowestPriceStore: store,
  updatedAtLabel: '',
  hoursAgo: hours,
  imageUrl: 'asset:assets/images/samples/$sample.jpg',
);

final _products = [
  _p(
    '1',
    'Al Rawabi Low Fat Milk',
    'Dairy & Sweet',
    9.5,
    'Lulu',
    2,
    'rawabi_lowfat',
  ),
  _p('2', 'Farm Fresh Eggs, 15 pcs', 'Fresh', 14.75, 'Union Coop', 26, 'eggs'),
  _p('3', 'Rozana Basmati Rice 5kg', 'Fresh', 31.0, 'Carrefour', 5, 'rice'),
  _p(
    '4',
    'Almarai Greek Yogurt',
    'Dairy & Sweet',
    6.25,
    'Spinneys',
    100,
    'yoghurt',
  ),
  _p('5', 'Rawabi Up Laban', 'Dairy & Sweet', 5.5, 'Union Coop', null, 'laban'),
];

final _stores = [
  Store(
    id: 's1',
    name: 'Lulu Hypermarket',
    branch: 'Al Barsha',
    distance: 1.2,
    pricesCount: 48,
    freshness: 'fresh',
    xOffset: 0,
    yOffset: 0,
  ),
  Store(
    id: 's2',
    name: 'Carrefour',
    branch: 'MOE',
    distance: 2.4,
    pricesCount: 61,
    freshness: 'fresh',
    xOffset: 0,
    yOffset: 0,
  ),
  Store(
    id: 's3',
    name: 'Union Coop',
    branch: 'Marina',
    distance: 0.8,
    pricesCount: 31,
    freshness: 'fresh',
    xOffset: 0,
    yOffset: 0,
  ),
  Store(
    id: 's4',
    name: 'Spinneys',
    branch: 'JBR',
    distance: 4.1,
    pricesCount: 22,
    freshness: 'fresh',
    xOffset: 0,
    yOffset: 0,
  ),
];

List<Override> _data() => [
  fakeAuth(),
  productsProvider.overrideWith(_FakeProducts.new),
  storesProvider.overrideWith(_FakeStores.new),
];

final _prices = [
  StoreProductPrice(
    storeId: 's1',
    storeName: 'Lulu – Al Barsha',
    price: 9.5,
    updatedAtLabel: '2h ago',
    submittedHoursAgo: 2,
  ),
  StoreProductPrice(
    storeId: 's2',
    storeName: 'Carrefour – MOE',
    price: 10.25,
    updatedAtLabel: '1d ago',
    submittedHoursAgo: 26,
  ),
  StoreProductPrice(
    storeId: 's3',
    storeName: 'Union Coop – Marina',
    price: 10.0,
    updatedAtLabel: '4d ago',
    submittedHoursAgo: 96,
  ),
];

final _history = [
  for (final (i, v) in [10.0, 10.1, 10.9, 10.4, 11.25, 10.2, 9.8, 9.5].indexed)
    ProductPriceHistory(
      id: '$i',
      priceAed: v,
      submittedAt: DateTime(2026, 1, 1).add(Duration(days: i * 12)),
      storeName: 'Lulu',
    ),
];

Future<void> _home(
  WidgetTester tester,
  String name, {
  Size size = Sizes.phone,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) async {
  SharedPreferences.setMockInitialValues({});
  await shoot(
    tester,
    size.width >= 600
        ? ShellFrame(
            locationOverride: '/',
            child: const HomeScreen(bootstrap: false),
          )
        : const HomeScreen(bootstrap: false),
    name: name,
    size: size,
    locale: locale,
    textScale: textScale,
    overrides: _data(),
  );
}

void main() {
  testWidgets('home phone', (t) => _home(t, 'home_phone'));
  testWidgets(
    'home phone Arabic comfort',
    (t) => _home(
      t,
      'home_phone_ar_comfort',
      locale: const Locale('ar'),
      textScale: 1.6,
    ),
  );
  testWidgets(
    'home tablet',
    (t) => _home(t, 'home_tablet', size: Sizes.tablet),
  );
  testWidgets(
    'home desktop',
    (t) => _home(t, 'home_desktop', size: Sizes.desktop),
  );

  Future<void> search(
    WidgetTester t,
    String name, {
    Size size = Sizes.phone,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await shoot(
      t,
      size.width >= 600
          ? ShellFrame(locationOverride: '/search', child: const SearchScreen())
          : const SearchScreen(),
      name: name,
      size: size,
      locale: locale,
      textScale: textScale,
      overrides: _data(),
    );
  }

  testWidgets('search phone', (t) => search(t, 'search_phone'));
  testWidgets(
    'search phone Arabic comfort',
    (t) => search(
      t,
      'search_phone_ar_comfort',
      locale: const Locale('ar'),
      textScale: 1.6,
    ),
  );
  testWidgets(
    'search tablet',
    (t) => search(t, 'search_tablet', size: Sizes.tablet),
  );
  testWidgets(
    'search desktop',
    (t) => search(t, 'search_desktop', size: Sizes.desktop),
  );

  Future<void> product(
    WidgetTester t,
    String name, {
    Size size = Sizes.phone,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await shoot(
      t,
      ProductDetailScreen(
        productId: '1',
        debugPrices: _prices,
        debugHistory: _history,
      ),
      name: name,
      size: size,
      locale: locale,
      textScale: textScale,
      overrides: _data(),
    );
  }

  testWidgets('product phone', (t) => product(t, 'product_phone'));
  testWidgets(
    'product phone Arabic comfort',
    (t) => product(
      t,
      'product_phone_ar_comfort',
      locale: const Locale('ar'),
      textScale: 1.6,
    ),
  );
  testWidgets(
    'product tablet',
    (t) => product(t, 'product_tablet', size: Sizes.tablet),
  );
  testWidgets(
    'product desktop',
    (t) => product(t, 'product_desktop', size: Sizes.desktop),
  );

  testWidgets('scan phone', (t) async {
    await shoot(
      t,
      const BarcodeScanScreen(
        debugPreview: ColoredBox(color: Color(0xFF3A3A3A)),
      ),
      name: 'scan_phone',
      overrides: _data(),
    );
  });
}
