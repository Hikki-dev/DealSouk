import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/admin/domain/admin_analytics.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/admin/domain/voucher_request.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
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
  List<VoucherRequest> build() => [
    VoucherRequest(
      id: 'v1',
      status: 'pending',
      thresholdTokens: 500,
      tokenCost: 500,
      denominationAed: 50,
      supermarket: 'Carrefour',
      voucherCode: null,
      adminNote: null,
      requestedAt: DateTime(2026, 10, 20),
      reviewedAt: null,
      userName: 'Sara Al Hashimi',
      userHomeArea: 'Al Barsha',
      userTokenBalance: 620,
    ),
    VoucherRequest(
      id: 'v2',
      status: 'pending',
      thresholdTokens: 500,
      tokenCost: 500,
      denominationAed: 100,
      supermarket: 'Lulu',
      voucherCode: null,
      adminNote: null,
      requestedAt: DateTime(2026, 10, 21),
      reviewedAt: null,
      userName: 'Omar Khan',
      userHomeArea: 'Deira',
      userTokenBalance: 540,
    ),
  ];

  @override
  Future<void> fetchVouchers({String status = 'pending'}) async {}
}

class _Settings extends AdminSettingsNotifier {
  @override
  Future<void> fetchSettings() async {}
}

class _Inventory extends AdminVoucherInventoryNotifier {
  @override
  List<dynamic> build() => [
    {
      'supermarket': 'Carrefour',
      'denominationAed': 50,
      'count': 24,
      'isUsed': false,
    },
    {
      'supermarket': 'Lulu',
      'denominationAed': 100,
      'count': 9,
      'isUsed': false,
    },
    {
      'supermarket': 'Carrefour',
      'denominationAed': 50,
      'count': 61,
      'isUsed': true,
    },
  ];

  @override
  Future<void> fetchInventoryStatus() async {}
}

class _Map extends AdminMapDataNotifier {
  @override
  List<dynamic> build() => [
    {
      'chain': 'Lulu',
      'branchName': 'Al Barsha',
      'area': 'Al Barsha',
      'activeSubmissionsCount': 7,
      'lat': 25.11,
      'lng': 55.2,
    },
    {
      'chain': 'Carrefour',
      'branchName': 'MOE',
      'area': 'Al Barsha',
      'activeSubmissionsCount': 3,
      'lat': 25.118,
      'lng': 55.2,
    },
    {
      'chain': 'Union Coop',
      'branchName': 'Satwa',
      'area': 'Satwa',
      'activeSubmissionsCount': 1,
      'lat': 25.22,
      'lng': 55.27,
    },
  ];

  @override
  Future<void> fetchMapData() async {}
}

class _Analytics extends AdminAnalyticsNotifier {
  @override
  AdminAnalytics build() => AdminAnalytics(
    submissionsToday: 42,
    submissionsThisMonth: 1180,
    activeUsers: 310,
    tokensNet: 5400,
    pendingVouchers: 2,
    issuedVouchers: 18,
    trendingProducts: [
      TrendingProduct(
        name: 'Al Rawabi Milk 1.5L',
        category: 'Dairy & Eggs',
        submissions: 31,
      ),
      TrendingProduct(
        name: 'Basmati Rice 5kg',
        category: 'Pantry',
        submissions: 22,
      ),
    ],
    coverageAreas: [
      CoverageArea(
        chain: 'Lulu',
        branchName: 'Al Barsha',
        area: 'Al Barsha',
        recentSubmissions: 19,
      ),
    ],
  );

  @override
  Future<void> fetchAnalytics() async {}
}

class _Products extends AdminProductsNotifier {
  @override
  AdminProductsState build() => AdminProductsState(
    total: 2,
    products: [
      Product(
        id: 'p1',
        name: 'Al Rawabi Low Fat Milk 1.5L',
        brand: 'Al Rawabi',
        packSize: '1.5L',
        category: 'Dairy & Eggs',
        lowestPrice: 9.5,
        lowestPriceStore: 'Lulu',
        updatedAtLabel: '1h',
      ),
      Product(
        id: 'p2',
        name: 'Rozana Basmati Rice 5kg',
        brand: 'Rozana',
        packSize: '5kg',
        category: 'Pantry',
        lowestPrice: 31,
        lowestPriceStore: 'Carrefour',
        updatedAtLabel: '2h',
      ),
    ],
  );

  @override
  Future<void> fetch() async {}
}

class _Users extends AdminUsersNotifier {
  @override
  AdminUsersState build() => const AdminUsersState(
    total: 2,
    users: [
      ProfileData(
        id: 'u1',
        displayName: 'Sara Al Hashimi',
        homeArea: 'Al Barsha',
        preferredLocale: 'en',
        tokenBalance: 620,
        accuracyRating: 92,
        isAdmin: false,
        totalSubmissions: 40,
        approvedSubmissions: 37,
      ),
      ProfileData(
        id: 'u2',
        displayName: 'Omar Khan',
        homeArea: 'Deira',
        preferredLocale: 'ar',
        tokenBalance: 540,
        accuracyRating: 88,
        isAdmin: true,
        totalSubmissions: 22,
        approvedSubmissions: 19,
      ),
    ],
  );

  @override
  Future<void> fetch() async {}
}

final _overrides = [
  adminSubmissionsProvider.overrideWith(_Queue.new),
  adminVouchersProvider.overrideWith(_Vouchers.new),
  adminSettingsProvider.overrideWith(_Settings.new),
  adminVoucherInventoryProvider.overrideWith(_Inventory.new),
  adminMapDataProvider.overrideWith(_Map.new),
  adminAnalyticsProvider.overrideWith(_Analytics.new),
  adminProductsProvider.overrideWith(_Products.new),
  adminUsersProvider.overrideWith(_Users.new),
];

const _tabs = [
  'moderation',
  'map',
  'analytics',
  'vouchers',
  'stock',
  'settings',
  'products_crud',
  'users_crud',
];

void main() {
  setUp(() {
    // flutter_map's tile cache asks path_provider for a directory.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  for (final tab in _tabs) {
    testWidgets('$tab desktop', (tester) async {
      await shoot(
        tester,
        AdminScreen(initialTab: tab),
        name: 'admin_${tab}_desktop',
        size: Sizes.desktop,
        overrides: _overrides,
      );
    });
    testWidgets('$tab phone', (tester) async {
      await shoot(
        tester,
        AdminScreen(initialTab: tab),
        name: 'admin_${tab}_phone',
        overrides: _overrides,
      );
    });
    testWidgets('$tab phone Arabic 160%', (tester) async {
      await shoot(
        tester,
        AdminScreen(initialTab: tab),
        name: 'admin_${tab}_phone_ar',
        locale: const Locale('ar'),
        textScale: 1.6,
        overrides: _overrides,
      );
    });
  }

  testWidgets('moderation tablet', (tester) async {
    await shoot(
      tester,
      const AdminScreen(),
      name: 'admin_moderation_tablet',
      size: Sizes.tablet,
      overrides: _overrides,
    );
  });

  testWidgets('moderation demo viewer desktop', (tester) async {
    await shoot(
      tester,
      const AdminScreen(readOnly: true),
      name: 'admin_demo_desktop',
      size: Sizes.desktop,
      overrides: _overrides,
    );
  });
}
