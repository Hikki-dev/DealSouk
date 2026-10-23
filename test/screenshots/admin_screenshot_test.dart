import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_screen.dart';
import 'harness.dart';

class _Queue extends AdminSubmissionsNotifier {
  @override
  List<AdminSubmission> build() => [
    AdminSubmission(
      id: '1',
      productName: 'Al Rawabi Low Fat Milk 1.5L',
      brand: 'Al Rawabi',
      storeName: 'Lulu, Al Barsha',
      price: 9.50,
      hasReceipt: false,
      hasPhoto: true,
      promoType: 'None',
      tokensReward: 10,
      timestampLabel: '5m ago',
      sourcerName: 'Sara',
      sourcerAccuracyRating: 92,
    ),
    AdminSubmission(
      id: '2',
      productName: 'Rozana Basmati Rice 5kg',
      brand: 'Rozana',
      storeName: 'Carrefour, MOE',
      price: 31.00,
      hasReceipt: true,
      hasPhoto: true,
      promoType: 'Flagged Report',
      tokensReward: 0,
      timestampLabel: '1h ago',
      sourcerName: 'Aisha',
    ),
  ];

  @override
  Future<void> fetchQueue() async {}
}

class _Vouchers extends AdminVouchersNotifier {
  @override
  Future<void> fetchVouchers({String status = 'pending'}) async {}
}

class _Settings extends AdminSettingsNotifier {
  @override
  Future<void> fetchSettings() async {}
}

class _Inventory extends AdminVoucherInventoryNotifier {
  @override
  Future<void> fetchInventoryStatus() async {}
}

class _Map extends AdminMapDataNotifier {
  @override
  Future<void> fetchMapData() async {}
}

class _Analytics extends AdminAnalyticsNotifier {
  @override
  Future<void> fetchAnalytics() async {}
}

final _overrides = [
  adminSubmissionsProvider.overrideWith(_Queue.new),
  adminVouchersProvider.overrideWith(_Vouchers.new),
  adminSettingsProvider.overrideWith(_Settings.new),
  adminVoucherInventoryProvider.overrideWith(_Inventory.new),
  adminMapDataProvider.overrideWith(_Map.new),
  adminAnalyticsProvider.overrideWith(_Analytics.new),
];

void main() {
  testWidgets('moderation desktop', (tester) async {
    await shoot(
      tester,
      const AdminScreen(),
      name: 'admin_desktop',
      size: Sizes.desktop,
      overrides: _overrides,
    );
  });

  testWidgets('moderation tablet', (tester) async {
    await shoot(
      tester,
      const AdminScreen(),
      name: 'admin_tablet',
      size: Sizes.tablet,
      overrides: _overrides,
    );
  });

  testWidgets('moderation phone', (tester) async {
    await shoot(
      tester,
      const AdminScreen(),
      name: 'admin_phone',
      overrides: _overrides,
    );
  });

  testWidgets('moderation phone Arabic comfort text', (tester) async {
    await shoot(
      tester,
      const AdminScreen(),
      name: 'admin_phone_ar',
      locale: const Locale('ar'),
      textScale: 1.6,
      overrides: _overrides,
    );
  });

  for (final tab in ['analytics', 'vouchers', 'stock', 'settings']) {
    testWidgets('$tab desktop', (tester) async {
      await shoot(
        tester,
        AdminScreen(initialTab: tab),
        name: 'admin_${tab}_desktop',
        size: Sizes.desktop,
        overrides: _overrides,
      );
    });
  }
}
