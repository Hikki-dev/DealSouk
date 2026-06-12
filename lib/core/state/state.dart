import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/products_service.dart';
import '../services/profile_service.dart';
import '../services/submissions_service.dart';
import '../services/requests_service.dart';
import '../services/leaderboard_service.dart';
import '../services/admin_service.dart';
import '../services/stores_service.dart';

// --- Products State ---
class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => [];

  Future<void> fetch({String query = '', String? category}) async {
    try {
      final results = await productsService.search(query: query, category: category);
      state = results;
    } catch (_) {
      // keep current state on error
    }
  }

  void updateProductPrice(String productId, double price, String storeName) {
    state = state.map((product) {
      if (product.id == productId) {
        if (price < product.lowestPrice || product.lowestPrice == 0) {
          return product.copyWith(
            lowestPrice: price,
            lowestPriceStore: storeName,
            updatedAtLabel: 'Updated Just Now',
          );
        } else {
          return product.copyWith(updatedAtLabel: 'Updated Just Now');
        }
      }
      return product;
    }).toList();
  }
}

final productsProvider = NotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);

// --- Stores State ---
class StoresNotifier extends Notifier<List<Store>> {
  @override
  List<Store> build() => [];

  Future<void> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      final results = await storesService.getNearby(lat: lat, lng: lng, radiusKm: radiusKm);
      state = results;
    } catch (_) {
      // keep current state
    }
  }
}

final storesProvider = NotifierProvider<StoresNotifier, List<Store>>(
  StoresNotifier.new,
);

// --- Leaderboard State ---
class LeaderboardNotifier extends Notifier<List<LeaderboardUser>> {
  @override
  List<LeaderboardUser> build() => [];

  Future<void> fetch() async {
    try {
      final results = await leaderboardService.getMonthly();
      state = results;
    } catch (_) {
      // keep current state
    }
  }
}

final leaderboardProvider = NotifierProvider<LeaderboardNotifier, List<LeaderboardUser>>(
  LeaderboardNotifier.new,
);

// --- User Tokens State ---
class UserTokensNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void sync(int balance) => state = balance;

  void addTokens(int amount) => state = state + amount;

  void deductTokens(int amount) => state = state - amount;
}

final userTokensProvider = NotifierProvider<UserTokensNotifier, int>(
  UserTokensNotifier.new,
);

// --- User Transactions State ---
class UserTransactionsNotifier extends Notifier<List<TokenTransaction>> {
  @override
  List<TokenTransaction> build() => [];

  Future<void> fetch() async {
    try {
      final results = await profileService.getTransactions();
      state = results;
    } catch (_) {}
  }

  void addTransaction(int amount, String title) {
    final newTx = TokenTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      title: title,
      timestampLabel: 'Just now',
    );
    state = [newTx, ...state];
  }
}

final userTransactionsProvider =
    NotifierProvider<UserTransactionsNotifier, List<TokenTransaction>>(
      UserTransactionsNotifier.new,
    );

// --- Cart State ---
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addToCart(Product product) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        existingItem.copyWith(quantity: existingItem.quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1, priceAtAdd: product.lowestPrice)];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

// --- Admin Submissions State ---
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
      // Refresh tokens and transactions from backend
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

  Future<void> editSubmission(String id, {
    String? productName,
    String? storeName,
    double? price,
  }) async {
    try {
      await adminService.editSubmission(id, productName: productName, storeName: storeName, price: price);
      state = state.map((s) {
        if (s.id == id) return s.copyWith(productName: productName, storeName: storeName, price: price);
        return s;
      }).toList();
    } catch (_) {}
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
    String sourcerName = 'Sourcer',
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

// --- Filters State ---
class FilterState {
  final String searchQuery;
  final String selectedCategory;
  final String freshnessFilter;

  FilterState({
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.freshnessFilter = 'All',
  });

  FilterState copyWith({
    String? searchQuery,
    String? selectedCategory,
    String? freshnessFilter,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      freshnessFilter: freshnessFilter ?? this.freshnessFilter,
    );
  }
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => FilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setFreshnessFilter(String filter) {
    state = state.copyWith(freshnessFilter: filter);
  }

  void reset() {
    state = FilterState();
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
);

// --- Active User Profile State ---
class UserProfile {
  final String name;
  final String location;
  final String avatarUrl;
  final int submissionsToday;
  final String homeArea;

  UserProfile({
    required this.name,
    required this.location,
    required this.avatarUrl,
    this.submissionsToday = 0,
    this.homeArea = 'Dubai',
  });

  UserProfile copyWith({
    String? name,
    String? location,
    int? submissionsToday,
    String? homeArea,
  }) {
    return UserProfile(
      name: name ?? this.name,
      location: location ?? this.location,
      avatarUrl: avatarUrl,
      submissionsToday: submissionsToday ?? this.submissionsToday,
      homeArea: homeArea ?? this.homeArea,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => UserProfile(
        name: 'Sourcer',
        location: 'Dubai',
        avatarUrl: '',
        submissionsToday: 0,
        homeArea: 'Dubai',
      );

  void syncFromProfile(ProfileData data) {
    state = UserProfile(
      name: data.displayName,
      location: data.homeArea ?? 'Dubai',
      avatarUrl: '',
      submissionsToday: 0,
      homeArea: data.homeArea ?? 'Dubai',
    );
  }

  void incrementSubmissions() {
    final settings = ref.read(adminSettingsProvider);
    if (state.submissionsToday < settings.dailySubmissionCap) {
      state = state.copyWith(submissionsToday: state.submissionsToday + 1);
    }
  }

  void updateName(String name) => state = state.copyWith(name: name);
  void updateHomeArea(String area) => state = state.copyWith(homeArea: area);
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(
  UserProfileNotifier.new,
);

// --- Price Requests State ---
class PriceRequestsNotifier extends Notifier<List<PriceRequest>> {
  @override
  List<PriceRequest> build() => [];

  Future<void> fetchBoard() async {
    try {
      final results = await requestsService.getBoard();
      state = results;
    } catch (_) {}
  }

  Future<void> addPriceRequest({
    required String productName,
    required String storeName,
    required int bounty,
    required String requesterName,
  }) async {
    try {
      final created = await requestsService.create(
        productName: productName,
        storeName: storeName,
        bountyTokens: bounty,
      );
      // Optimistic balance deduction — backend already deducted
      ref.read(userTokensProvider.notifier).deductTokens(bounty);
      ref.read(userTransactionsProvider.notifier).addTransaction(
            -bounty,
            'Requested price check: $productName at $storeName',
          );
      state = [created, ...state];
    } catch (_) {}
  }

  Future<void> fulfillPriceRequest(String requestId) async {
    try {
      final earned = await requestsService.fulfill(requestId);
      ref.read(userTokensProvider.notifier).addTokens(earned);
      ref.read(userTransactionsProvider.notifier).addTransaction(
            earned,
            'Fulfilled a price request',
          );
      state = state.map((req) {
        if (req.id == requestId) {
          return req.copyWith(status: 'fulfilled', timestampLabel: 'Fulfilled Just Now');
        }
        return req;
      }).toList();
    } catch (_) {}
  }

  void refundPriceRequest(String requestId) {
    final reqIndex = state.indexWhere((r) => r.id == requestId);
    if (reqIndex >= 0) {
      final req = state[reqIndex];
      ref.read(userTokensProvider.notifier).addTokens(req.tokensBounty);
      ref.read(userTransactionsProvider.notifier).addTransaction(
            req.tokensBounty,
            'Refunded request: ${req.productName} check',
          );
      state = state.where((r) => r.id != requestId).toList();
    }
  }
}

final priceRequestsProvider =
    NotifierProvider<PriceRequestsNotifier, List<PriceRequest>>(
  PriceRequestsNotifier.new,
);

// --- Flagged Prices State ---
class FlaggedPricesNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  Future<void> flagPrice(
    String productId,
    String storeName,
    String productName,
    double price, {
    String? submissionId,
  }) async {
    if (submissionId != null) {
      try {
        await submissionsService.flag(submissionId, 'price_wrong');
      } catch (_) {}
    }
    final key = '${productId}_$storeName';
    final newFlags = (state[key] ?? 0) + 1;
    state = {...state, key: newFlags};
  }

  void resetFlags(String productId, String storeName) {
    final key = '${productId}_$storeName';
    state = {...state, key: 0};
  }

  bool isPriceHidden(String productId, String storeName) {
    final key = '${productId}_$storeName';
    return (state[key] ?? 0) >= 3;
  }
}

final flaggedPricesProvider =
    NotifierProvider<FlaggedPricesNotifier, Map<String, int>>(
  FlaggedPricesNotifier.new,
);

// --- Navbar Visibility ---
class NavbarVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void show() => state = true;
  void hide() => state = false;
}

final navbarVisibleProvider = NotifierProvider<NavbarVisibleNotifier, bool>(
  NavbarVisibleNotifier.new,
);

// --- Streak State ---
class StreakNotifier extends Notifier<StreakData> {
  @override
  StreakData build() => const StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastActivityLabel: '—',
      );

  void sync(int current, int longest) {
    state = StreakData(
      currentStreak: current,
      longestStreak: longest,
      lastActivityLabel: 'Today',
    );
  }

  void recordActivity() {
    final current = state;
    final newStreak = current.currentStreak + 1;
    final longest = newStreak > current.longestStreak ? newStreak : current.longestStreak;
    state = current.copyWith(
      currentStreak: newStreak,
      longestStreak: longest,
      lastActivityLabel: 'Just now',
    );
    ref.read(badgesProvider.notifier).checkAndUnlock('streak_$newStreak');
  }
}

final streakProvider = NotifierProvider<StreakNotifier, StreakData>(
  StreakNotifier.new,
);

// --- Badges State ---
class BadgesNotifier extends Notifier<List<UserBadge>> {
  @override
  List<UserBadge> build() => const [
        UserBadge(id: 'first_submission', name: 'First Price', emoji: '🏷️', description: 'Submit your first price', unlocked: false),
        UserBadge(id: 'streak_7', name: '7-Day Streak', emoji: '🔥', description: 'Submit 7 days in a row', unlocked: false),
        UserBadge(id: 'streak_30', name: 'Monthly Regular', emoji: '📅', description: '30-day submission streak', unlocked: false),
        UserBadge(id: 'first_request', name: 'Price Detective', emoji: '🔍', description: 'Fulfill your first price request', unlocked: false),
        UserBadge(id: 'accuracy_90', name: 'Trusted Sourcer', emoji: '✅', description: 'Maintain 90%+ accuracy rating', unlocked: false),
        UserBadge(id: 'voucher_earned', name: 'Voucher Winner', emoji: '🎁', description: 'Earn your first voucher', unlocked: false),
      ];

  void checkAndUnlock(String event) {
    final updated = state.map((badge) {
      if (badge.unlocked) return badge;
      if (event == 'submission_approved' && badge.id == 'first_submission') {
        return badge.copyWith(unlocked: true);
      }
      if (event.startsWith('streak_')) {
        final streakCount = int.tryParse(event.split('_').last) ?? 0;
        if (badge.id == 'streak_7' && streakCount >= 7) return badge.copyWith(unlocked: true);
        if (badge.id == 'streak_30' && streakCount >= 30) return badge.copyWith(unlocked: true);
      }
      if (event == 'request_fulfilled' && badge.id == 'first_request') {
        return badge.copyWith(unlocked: true);
      }
      return badge;
    }).toList();
    state = updated;
  }
}

final badgesProvider = NotifierProvider<BadgesNotifier, List<UserBadge>>(
  BadgesNotifier.new,
);

// --- Daily Challenge State ---
class DailyChallengeNotifier extends Notifier<DailyChallenge> {
  @override
  DailyChallenge build() => const DailyChallenge(
        id: 'daily_1',
        description: 'Submit 3 fresh prices today',
        targetStore: 'Any',
        targetCount: 3,
        bonusTokens: 30,
      );

  void recordProgress() {
    if (state.completed) return;
    final newCount = state.progressCount + 1;
    final completed = newCount >= state.targetCount;
    state = state.copyWith(progressCount: newCount, completed: completed);

    if (completed) {
      ref.read(userTokensProvider.notifier).addTokens(state.bonusTokens);
      ref.read(userTransactionsProvider.notifier).addTransaction(
            state.bonusTokens,
            'Daily challenge bonus: ${state.description}',
          );
    }
  }
}

final dailyChallengeProvider =
    NotifierProvider<DailyChallengeNotifier, DailyChallenge>(
  DailyChallengeNotifier.new,
);

// --- User Level (derived from total tokens) ---
int tokensToLevel(int tokens) => (tokens ~/ 500).clamp(1, 20);
double levelMultiplier(int level) => 1.0 + (level - 1) * 0.05;
String levelTitle(int level) {
  if (level >= 15) return 'Souk Master';
  if (level >= 10) return 'Senior Sourcer';
  if (level >= 5) return 'Active Sourcer';
  if (level >= 3) return 'Regular Sourcer';
  return 'New Sourcer';
}

// --- Admin Settings State ---
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
}

final adminSettingsProvider =
    NotifierProvider<AdminSettingsNotifier, AdminSettings>(
  AdminSettingsNotifier.new,
);

// --- Locale State ---
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale locale) => state = locale;
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
