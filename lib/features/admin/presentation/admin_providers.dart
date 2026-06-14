import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/admin/domain/admin_submission.dart';
import 'package:dealsouk/features/admin/domain/admin_analytics.dart';
import 'package:dealsouk/features/admin/domain/admin_settings.dart';
import 'package:dealsouk/features/admin/domain/voucher_request.dart';
import 'package:dealsouk/features/admin/data/admin_service.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';
import 'package:dealsouk/features/products/domain/product.dart';

class AdminSubmissionsNotifier extends Notifier<List<AdminSubmission>> {
  @override
  List<AdminSubmission> build() => [];

  Future<void> fetchQueue() async {
    try {
      final results = await adminService.getQueue();
      state = results;
    } catch (_) {}
  }

  Future<void> approveSubmission(String id, WidgetRef ref) async {
    try {
      await adminService.approveSubmission(id);
      state = state.where((s) => s.id != id).toList();
      await ref.read(userTransactionsProvider.notifier).fetch();
      final profile = await profileService.getMyProfile();
      ref.read(userTokensProvider.notifier).sync(profile.tokenBalance);
    } catch (_) {
      state = state.where((s) => s.id != id).toList();
    }
  }

  Future<void> rejectSubmission(String id) async {
    try {
      await adminService.rejectSubmission(id);
    } catch (_) {}
    state = state.where((s) => s.id != id).toList();
  }

  Future<void> editSubmission(
    String id, {
    String? productName,
    String? storeName,
    double? price,
  }) async {
    try {
      await adminService.editSubmission(
        id,
        productName: productName,
        storeName: storeName,
        price: price,
      );
      state = state.map((s) {
        if (s.id == id) {
          return s.copyWith(
            productName: productName,
            storeName: storeName,
            price: price,
          );
        }
        return s;
      }).toList();
    } catch (_) {}
  }

  Future<void> warnUser(String userId, {required String reason}) async {
    await adminService.warnUser(userId, reason: reason);
  }

  Future<void> suspendUser(
    String userId, {
    required String reason,
    int days = 7,
  }) async {
    await adminService.suspendUser(userId, reason: reason, days: days);
  }

  Future<void> banUser(String userId, {required String reason}) async {
    await adminService.banUser(userId, reason: reason);
    state = state
        .where((submission) => submission.sourcerId != userId)
        .toList();
  }

  void addSubmission({
    required String productName,
    required String brand,
    required String storeName,
    required double price,
    required bool hasReceipt,
    required bool hasPhoto,
    required String promoType,
    required int tokensReward,
    String sourcerName = 'Shopper',
  }) {
    final newSub = AdminSubmission(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      productName: productName,
      brand: brand,
      storeName: storeName,
      price: price,
      hasReceipt: hasReceipt,
      hasPhoto: hasPhoto,
      promoType: promoType,
      tokensReward: tokensReward,
      timestampLabel: 'Just now',
      sourcerName: sourcerName,
      status: 'pending',
    );
    state = [newSub, ...state];
  }
}

final adminSubmissionsProvider =
    NotifierProvider<AdminSubmissionsNotifier, List<AdminSubmission>>(
      AdminSubmissionsNotifier.new,
    );

class AdminSettingsNotifier extends Notifier<AdminSettings> {
  @override
  AdminSettings build() => const AdminSettings();

  Future<void> fetchSettings() async {
    try {
      final settings = await adminService.getSettings();
      state = settings;
    } catch (_) {}
  }

  Future<void> setTokenEarnRate(int rate) async {
    state = state.copyWith(tokenEarnRate: rate);
    await adminService.updateSettings(state);
  }

  Future<void> setVoucherThreshold(int threshold) async {
    state = state.copyWith(voucherThreshold: threshold);
    await adminService.updateSettings(state);
  }

  Future<void> setDailySubmissionCap(int cap) async {
    state = state.copyWith(dailySubmissionCap: cap);
    await adminService.updateSettings(state);
  }

  Future<void> setRequestCostTokens(int cost) async {
    state = state.copyWith(requestCostTokens: cost);
    await adminService.updateSettings(state);
  }
}

final adminSettingsProvider =
    NotifierProvider<AdminSettingsNotifier, AdminSettings>(
      AdminSettingsNotifier.new,
    );

class AdminVouchersNotifier extends Notifier<List<VoucherRequest>> {
  @override
  List<VoucherRequest> build() => [];

  Future<void> fetchVouchers({String status = 'pending'}) async {
    try {
      state = await adminService.getVouchers(status: status);
    } catch (_) {}
  }

  Future<void> approveVoucher(
    String id, {
    String voucherCode = '',
    String? adminNote,
  }) async {
    await adminService.approveVoucher(
      id,
      voucherCode: voucherCode,
      adminNote: adminNote,
    );
    state = state.where((voucher) => voucher.id != id).toList();
    // Refresh inventory status after approval
    ref.read(adminVoucherInventoryProvider.notifier).fetchInventoryStatus();
  }

  Future<void> rejectVoucher(String id, {String? adminNote}) async {
    await adminService.rejectVoucher(id, adminNote: adminNote);
    state = state.where((voucher) => voucher.id != id).toList();
  }
}

final adminVouchersProvider =
    NotifierProvider<AdminVouchersNotifier, List<VoucherRequest>>(
      AdminVouchersNotifier.new,
    );

class AdminVoucherInventoryNotifier extends Notifier<List<dynamic>> {
  @override
  List<dynamic> build() => [];

  Future<void> fetchInventoryStatus() async {
    try {
      state = await adminService.getVoucherInventoryStatus();
    } catch (_) {}
  }

  Future<void> importVouchers({
    required String supermarket,
    required int denominationAed,
    required List<String> codes,
  }) async {
    await adminService.importVouchers(
      supermarket: supermarket,
      denominationAed: denominationAed,
      codes: codes,
    );
    await fetchInventoryStatus();
  }
}

final adminVoucherInventoryProvider =
    NotifierProvider<AdminVoucherInventoryNotifier, List<dynamic>>(
      AdminVoucherInventoryNotifier.new,
    );

class AdminMapDataNotifier extends Notifier<List<dynamic>> {
  @override
  List<dynamic> build() => [];

  Future<void> fetchMapData() async {
    try {
      state = await adminService.getMapData();
    } catch (_) {}
  }
}

final adminMapDataProvider =
    NotifierProvider<AdminMapDataNotifier, List<dynamic>>(
      AdminMapDataNotifier.new,
    );

class AdminAnalyticsNotifier extends Notifier<AdminAnalytics> {
  @override
  AdminAnalytics build() => AdminAnalytics.empty();

  Future<void> fetchAnalytics() async {
    try {
      state = await adminService.getAnalytics();
    } catch (_) {}
  }
}

final adminAnalyticsProvider =
    NotifierProvider<AdminAnalyticsNotifier, AdminAnalytics>(
      AdminAnalyticsNotifier.new,
    );

// Products CRUD State & Provider
class AdminProductsState {
  final List<Product> products;
  final int total;
  final bool isLoading;
  final String searchQuery;
  final String? selectedCategory;
  final int currentPage;

  const AdminProductsState({
    this.products = const [],
    this.total = 0,
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.currentPage = 0,
  });

  AdminProductsState copyWith({
    List<Product>? products,
    int? total,
    bool? isLoading,
    String? searchQuery,
    String? selectedCategory,
    int? currentPage,
  }) {
    return AdminProductsState(
      products: products ?? this.products,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class AdminProductsNotifier extends Notifier<AdminProductsState> {
  @override
  AdminProductsState build() => const AdminProductsState();

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await adminService.getProducts(
        query: state.searchQuery,
        category: state.selectedCategory,
        page: state.currentPage,
      );
      state = state.copyWith(
        products: res['products'] as List<Product>,
        total: res['total'] as int,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q, currentPage: 0);
    fetch();
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category, currentPage: 0);
    fetch();
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
    fetch();
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    await adminService.createProduct(data);
    fetch();
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await adminService.updateProduct(id, data);
    fetch();
  }

  Future<void> deleteProduct(String id) async {
    await adminService.deleteProduct(id);
    fetch();
  }
}

final adminProductsProvider =
    NotifierProvider<AdminProductsNotifier, AdminProductsState>(
      AdminProductsNotifier.new,
    );

// Users CRUD State & Provider
class AdminUsersState {
  final List<ProfileData> users;
  final int total;
  final bool isLoading;
  final String searchQuery;
  final int currentPage;

  const AdminUsersState({
    this.users = const [],
    this.total = 0,
    this.isLoading = false,
    this.searchQuery = '',
    this.currentPage = 0,
  });

  AdminUsersState copyWith({
    List<ProfileData>? users,
    int? total,
    bool? isLoading,
    String? searchQuery,
    int? currentPage,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  @override
  AdminUsersState build() => const AdminUsersState();

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await adminService.getUsers(
        query: state.searchQuery,
        page: state.currentPage,
      );
      state = state.copyWith(
        users: res['users'] as List<ProfileData>,
        total: res['total'] as int,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q, currentPage: 0);
    fetch();
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
    fetch();
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    await adminService.createUser(data);
    fetch();
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await adminService.updateUser(id, data);
    fetch();
  }

  Future<void> deleteUser(String id) async {
    await adminService.deleteUser(id);
    fetch();
  }
}

final adminUsersProvider =
    NotifierProvider<AdminUsersNotifier, AdminUsersState>(
      AdminUsersNotifier.new,
    );
