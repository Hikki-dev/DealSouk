import 'package:flutter/widgets.dart' show Locale, Size, Widget;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/core/widgets/shell_layout.dart';
import 'package:dealsouk/features/leaderboard/domain/leaderboard_user.dart';
import 'package:dealsouk/features/leaderboard/presentation/leaderboard_providers.dart';
import 'package:dealsouk/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/requests/domain/price_request.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/features/submissions/presentation/submit_price_screen.dart';
import 'package:dealsouk/features/tokens/domain/daily_challenge.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'harness.dart';

class _Products extends ProductsNotifier {
  @override
  List<Product> build() => _products;
  @override
  Future<void> fetch({String query = "", String? category}) async {}
}

class _Stores extends StoresNotifier {
  @override
  List<Store> build() => _stores;
  @override
  Future<void> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 15,
  }) async {}
}

class _Tokens extends UserTokensNotifier {
  @override
  int build() => 340;
}

class _Board extends LeaderboardNotifier {
  @override
  List<LeaderboardUser> build() => [
    LeaderboardUser(
      rank: 1,
      name: 'Fatima A.',
      tokens: 820,
      streak: 12,
      isCurrentUser: false,
    ),
    LeaderboardUser(
      rank: 2,
      name: 'Rahul K.',
      tokens: 610,
      streak: 4,
      isCurrentUser: false,
    ),
    LeaderboardUser(
      rank: 3,
      name: 'You',
      tokens: 340,
      isCurrentUser: true,
      streak: 5,
    ),
    LeaderboardUser(
      rank: 4,
      name: 'Omar S.',
      tokens: 290,
      streak: 0,
      isCurrentUser: false,
    ),
  ];
  @override
  Future<void> fetch() async {}
}

class _Requests extends PriceRequestsNotifier {
  @override
  List<PriceRequest> build() => [
    PriceRequest(
      id: 'r1',
      productName: 'Almarai Fresh Milk 2L',
      storeName: 'Spinneys',
      requestRewardTokens: 8,
      requesterName: 'Layla',
      timestampLabel: '12m ago',
    ),
    PriceRequest(
      id: 'r2',
      productName: 'Rozana Basmati Rice 5kg',
      storeName: 'Lulu',
      requestRewardTokens: 8,
      requesterName: 'Sam',
      timestampLabel: '1h ago',
    ),
  ];
  @override
  Future<void> fetchBoard() async {}
}

class _Mine extends MyRequestsNotifier {
  @override
  List<PriceRequest> build() => [
    PriceRequest(
      id: 'm1',
      productName: 'Nescafe Gold 200g',
      storeName: 'Carrefour',
      requestRewardTokens: 8,
      requesterName: 'You',
      status: 'open',
      timestampLabel: '2h ago',
    ),
  ];
  @override
  Future<void> fetchMyRequests() async {}
}

class _Challenge extends DailyChallengeNotifier {
  @override
  DailyChallenge build() => const DailyChallenge(
    id: 'd',
    description: 'Submit 3 fresh prices today',
    targetStore: 'Any',
    targetCount: 3,
    bonusTokens: 30,
    progressCount: 1,
  );
  @override
  Future<void> fetchToday() async {}
}

final _products = [
  Product(
    id: '1',
    name: 'Al Rawabi Low Fat Milk',
    brand: 'Al Rawabi',
    packSize: '1 L',
    category: 'Dairy',
    lowestPrice: 9.5,
    lowestPriceStore: 'Lulu',
    updatedAtLabel: '',
    hoursAgo: 2,
    imageUrl: 'asset:assets/images/samples/rawabi_lowfat.jpg',
  ),
  Product(
    id: '2',
    name: 'Farm Fresh Eggs, 15 pcs',
    brand: 'Farm Fresh',
    packSize: '15 pcs',
    category: 'Dairy',
    lowestPrice: 14.75,
    lowestPriceStore: 'Union Coop',
    updatedAtLabel: '',
    hoursAgo: 26,
    imageUrl: 'asset:assets/images/samples/eggs.jpg',
  ),
];

Store _s(String id, String name, String branch, double km) => Store(
  id: id,
  name: name,
  branch: branch,
  distance: km,
  pricesCount: 40,
  freshness: 'Updated 2h ago',
  xOffset: 0,
  yOffset: 0,
  lastUpdatedHoursAgo: 2,
  lat: 25.08,
  lng: 55.14,
);

final _stores = [
  _s('s1', 'Lulu Hypermarket', 'Al Barsha', 1.2),
  _s('s2', 'Carrefour', 'Marina Mall', 2.4),
  _s('s3', 'Union Coop', 'Marina', 0.8),
];

List<Override> _data() => [
  fakeAuth(),
  hallOfFameProvider.overrideWith((ref) async => <LeaderboardUser>[]),
  productsProvider.overrideWith(_Products.new),
  storesProvider.overrideWith(_Stores.new),
  userTokensProvider.overrideWith(_Tokens.new),
  leaderboardProvider.overrideWith(_Board.new),
  priceRequestsProvider.overrideWith(_Requests.new),
  myRequestsProvider.overrideWith(_Mine.new),
  dailyChallengeProvider.overrideWith(_Challenge.new),
];

Widget _shell(Size s, String route, Widget w) =>
    s.width >= 600 ? ShellFrame(locationOverride: route, child: w) : w;

void main() {
  for (final (name, size) in [
    ('phone', Sizes.phone),
    ('tablet', Sizes.tablet),
    ('desktop', Sizes.desktop),
  ]) {
    testWidgets('rewards $name', (t) async {
      await shoot(
        t,
        _shell(size, '/leaderboard', const LeaderboardScreen()),
        name: 'rewards_$name',
        size: size,
        overrides: _data(),
      );
    });
  }

  testWidgets('rewards Arabic comfort text', (t) async {
    await shoot(
      t,
      const LeaderboardScreen(),
      name: 'rewards_phone_ar',
      locale: const Locale('ar'),
      textScale: 1.6,
      overrides: _data(),
    );
  });

  testWidgets('submit store step phone', (t) async {
    await shoot(
      t,
      const SubmitPriceScreen(),
      name: 'submit_store_phone',
      overrides: _data(),
    );
  });

  testWidgets('submit Arabic comfort text', (t) async {
    await shoot(
      t,
      const SubmitPriceScreen(),
      name: 'submit_store_phone_ar',
      locale: const Locale('ar'),
      textScale: 1.6,
      overrides: _data(),
    );
  });

  testWidgets('submit desktop', (t) async {
    await shoot(
      t,
      const SubmitPriceScreen(),
      name: 'submit_store_desktop',
      size: Sizes.desktop,
      overrides: _data(),
    );
  });
}
