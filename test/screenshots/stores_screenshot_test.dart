import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale, Size, Widget;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealsouk/core/widgets/shell_layout.dart';
import 'package:dealsouk/features/cart/domain/cart_item.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/cart/presentation/cart_screen.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/saved/presentation/saved_providers.dart';
import 'package:dealsouk/features/saved/presentation/saved_screen.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/presentation/store_screen.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'harness.dart';

class _FakeProducts extends ProductsNotifier {
  @override
  List<Product> build() => _products;
}

class _FakeStores extends StoresNotifier {
  _FakeStores(this._list, {this.failed = false});
  final List<Store> _list;
  final bool failed;

  @override
  List<Store> build() {
    hadError = failed;
    return _list;
  }

  // The screen kicks off a fetch on open; keep the fake data instead.
  @override
  Future<void> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 15,
  }) async {}
}

class _FakeCart extends CartNotifier {
  _FakeCart(this._items);
  final List<CartItem> _items;

  @override
  List<CartItem> build() => _items;
}

class _FakeSaved extends SavedProductsNotifier {
  @override
  Set<String> build() => {'1', '2', '3'};
}

Product _p(
  String id,
  String name,
  double price,
  String store,
  int hours,
  String sample,
) => Product(
  id: id,
  name: name,
  brand: 'Brand',
  packSize: '1 pc',
  category: 'Fresh',
  lowestPrice: price,
  lowestPriceStore: store,
  updatedAtLabel: '',
  hoursAgo: hours,
  imageUrl: 'asset:assets/images/samples/$sample.jpg',
);

final _products = [
  _p('1', 'Al Rawabi Low Fat Milk', 9.5, 'Lulu', 2, 'rawabi_lowfat'),
  _p('2', 'Farm Fresh Eggs, 15 pcs', 14.75, 'Union Coop', 26, 'eggs'),
  _p('3', 'Rozana Basmati Rice 5kg', 31.0, 'Carrefour', 5, 'rice'),
];

Store _s(
  String id,
  String name,
  String branch,
  double km,
  int prices,
  int hours,
  double lat,
  double lng,
) => Store(
  id: id,
  name: name,
  branch: branch,
  distance: km,
  pricesCount: prices,
  freshness: 'Updated ${hours}h ago',
  xOffset: 0,
  yOffset: 0,
  lastUpdatedHoursAgo: hours,
  lat: lat,
  lng: lng,
);

final _stores = [
  _s('s1', 'Lulu Hypermarket', 'Al Barsha', 1.2, 48, 2, 25.1124, 55.2000),
  _s('s2', 'Carrefour', 'Marina Mall', 2.4, 61, 30, 25.0770, 55.1400),
  _s('s3', 'Union Coop', 'Marina', 0.8, 31, 5, 25.0800, 55.1380),
  _s('s4', 'Spinneys', 'Umm Suqeim', 4.1, 22, 80, 25.1500, 55.2000),
];

final _cart = [
  CartItem(product: _products[0], quantity: 1, priceAtAdd: 10.5),
  CartItem(product: _products[1], quantity: 2, priceAtAdd: 14.75),
  CartItem(product: _products[2], quantity: 1, priceAtAdd: 31.0),
];

Widget _inShell(Size size, String route, Widget child) => size.width >= 600
    ? ShellFrame(locationOverride: route, child: child)
    : child;

List<Override> _data({
  List<Store>? stores,
  bool failed = false,
  List<CartItem>? cart,
}) => [
  fakeAuth(),
  productsProvider.overrideWith(_FakeProducts.new),
  storesProvider.overrideWith(
    () => _FakeStores(stores ?? _stores, failed: failed),
  ),
  cartProvider.overrideWith(() => _FakeCart(cart ?? _cart)),
  savedProductsProvider.overrideWith(_FakeSaved.new),
];

Future<void> _shoot(
  WidgetTester t,
  Widget screen,
  String name, {
  String route = '/',
  Size size = Sizes.phone,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  List<Override>? overrides,
}) async {
  SharedPreferences.setMockInitialValues({});
  await shoot(
    t,
    _inShell(size, route, screen),
    name: name,
    size: size,
    locale: locale,
    textScale: textScale,
    overrides: overrides ?? _data(),
  );
}

void main() {
  const ar = Locale('ar');
  setUpAll(() {
    // flutter_map's tile cache asks path_provider for a directory.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
  });
  testWidgets(
    'map phone',
    (t) => _shoot(t, const StoreScreen(), 'stores_phone', route: '/stores'),
  );
  testWidgets(
    'map phone Arabic comfort',
    (t) => _shoot(
      t,
      const StoreScreen(),
      'stores_phone_ar_comfort',
      route: '/stores',
      locale: ar,
      textScale: 1.6,
    ),
  );
  testWidgets(
    'map tablet',
    (t) => _shoot(
      t,
      const StoreScreen(),
      'stores_tablet',
      route: '/stores',
      size: Sizes.tablet,
    ),
  );
  testWidgets(
    'map desktop',
    (t) => _shoot(
      t,
      const StoreScreen(),
      'stores_desktop',
      route: '/stores',
      size: Sizes.desktop,
    ),
  );
  testWidgets(
    'map error state',
    (t) => _shoot(
      t,
      const StoreScreen(),
      'stores_error_phone',
      route: '/stores',
      overrides: _data(stores: const [], failed: true),
    ),
  );

  testWidgets(
    'my list phone',
    (t) => _shoot(t, const CartScreen(), 'cart_phone', route: '/cart'),
  );
  testWidgets(
    'my list phone Arabic comfort',
    (t) => _shoot(
      t,
      const CartScreen(),
      'cart_phone_ar_comfort',
      route: '/cart',
      locale: ar,
      textScale: 1.6,
    ),
  );
  testWidgets(
    'my list desktop',
    (t) => _shoot(
      t,
      const CartScreen(),
      'cart_desktop',
      route: '/cart',
      size: Sizes.desktop,
    ),
  );
  testWidgets(
    'my list empty',
    (t) => _shoot(
      t,
      const CartScreen(),
      'cart_empty_phone',
      route: '/cart',
      overrides: _data(cart: const []),
    ),
  );

  testWidgets(
    'saved phone',
    (t) => _shoot(t, const SavedScreen(), 'saved_phone'),
  );
  testWidgets(
    'saved desktop',
    (t) => _shoot(t, const SavedScreen(), 'saved_desktop', size: Sizes.desktop),
  );
}
