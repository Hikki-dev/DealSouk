import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../mock_data/mock_data.dart';

// --- Products State ---
class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => MockData.initialProducts;

  void updateProductPrice(String productId, double price, String storeName) {
    state = state.map((product) {
      if (product.id == productId) {
        if (price < product.lowestPrice) {
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

// --- User Tokens State ---
class UserTokensNotifier extends Notifier<int> {
  @override
  int build() => 340;

  void addTokens(int amount) {
    state = state + amount;
  }

  void deductTokens(int amount) {
    state = state - amount;
  }
}

final userTokensProvider = NotifierProvider<UserTokensNotifier, int>(
  UserTokensNotifier.new,
);

// --- User Transactions State ---
class UserTransactionsNotifier extends Notifier<List<TokenTransaction>> {
  @override
  List<TokenTransaction> build() => MockData.initialTokenTransactions;

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
  List<CartItem> build() {
    final spinach = MockData.initialProducts.firstWhere((p) => p.id == 'spinach');
    final apples = MockData.initialProducts.firstWhere((p) => p.id == 'apples');
    final lettuce = MockData.initialProducts.firstWhere((p) => p.id == 'lettuce');

    return [
      CartItem(product: spinach, quantity: 1, priceAtAdd: spinach.lowestPrice + 0.30),
      CartItem(product: apples, quantity: 2, priceAtAdd: apples.lowestPrice + 0.20),
      CartItem(product: lettuce, quantity: 1, priceAtAdd: lettuce.lowestPrice),
    ];
  }

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
  List<AdminSubmission> build() => MockData.initialAdminSubmissions;

  void addSubmission({
    required String productName,
    required String brand,
    required String storeName,
    required double price,
    required bool hasReceipt,
    required bool hasPhoto,
    required String promoType,
    required int tokensReward,
    String sourcerName = 'Hessa Al Maktoum',
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

  void editSubmission(String id, {String? productName, String? storeName, double? price}) {
    state = state.map((s) {
      if (s.id == id) return s.copyWith(productName: productName, storeName: storeName, price: price);
      return s;
    }).toList();
  }

  void approveSubmission(String id, WidgetRef ref) {
    final submissionIndex = state.indexWhere((sub) => sub.id == id);
    if (submissionIndex >= 0) {
      final sub = state[submissionIndex];
      state = state.where((s) => s.id != id).toList();

      if (sub.promoType == 'Flagged Report') {
        final products = ref.read(productsProvider);
        final product = products.firstWhere(
          (p) => p.name.toLowerCase().contains(sub.productName.toLowerCase()) ||
                 sub.productName.toLowerCase().contains(p.name.toLowerCase()),
          orElse: () => products.first,
        );
        ref.read(flaggedPricesProvider.notifier).resetFlags(product.id, sub.storeName);
        return;
      }

      ref.read(userTokensProvider.notifier).addTokens(sub.tokensReward);
      ref
          .read(userTransactionsProvider.notifier)
          .addTransaction(
            sub.tokensReward,
            '+${sub.tokensReward} tokens - Approved ${sub.productName} price',
          );

      final products = ref.read(productsProvider);
      final product = products.firstWhere(
        (p) =>
            p.name.toLowerCase().contains(sub.productName.toLowerCase()) ||
            sub.productName.toLowerCase().contains(p.name.toLowerCase()),
        orElse: () => products.first,
      );
      ref
          .read(productsProvider.notifier)
          .updateProductPrice(product.id, sub.price, sub.storeName);

      ref.read(badgesProvider.notifier).checkAndUnlock('submission_approved');
    }
  }

  void rejectSubmission(String id) {
    state = state.where((s) => s.id != id).toList();
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
    this.submissionsToday = 3,
    this.homeArea = 'Dubai Marina',
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
        name: 'Hessa Al Maktoum',
        location: 'Dubai Marina sourcer',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
        submissionsToday: 3,
        homeArea: 'Dubai Marina',
      );

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
  List<PriceRequest> build() => MockData.initialPriceRequests;

  void addPriceRequest({
    required String productName,
    required String storeName,
    required int bounty,
    required String requesterName,
  }) {
    final newRequest = PriceRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      productName: productName,
      storeName: storeName,
      tokensBounty: bounty,
      requesterName: requesterName,
      status: 'pending',
      timestampLabel: 'Just now',
      distance: 1.0 + (DateTime.now().millisecondsSinceEpoch % 500) / 100.0,
    );

    ref.read(userTokensProvider.notifier).deductTokens(bounty);
    ref.read(userTransactionsProvider.notifier).addTransaction(
          -bounty,
          'Requested price check: $productName at $storeName',
        );

    state = [newRequest, ...state];
  }

  void fulfillPriceRequest(String requestId) {
    state = state.map((req) {
      if (req.id == requestId) {
        return req.copyWith(status: 'fulfilled', timestampLabel: 'Fulfilled Just Now');
      }
      return req;
    }).toList();
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

  void flagPrice(String productId, String storeName, String productName, double price) {
    final key = '${productId}_$storeName';
    final currentFlags = state[key] ?? 0;
    final newFlags = currentFlags + 1;

    state = {...state, key: newFlags};

    if (newFlags >= 3) {
      ref.read(adminSubmissionsProvider.notifier).addSubmission(
            productName: productName,
            brand: 'Community Flagged Report',
            storeName: storeName,
            price: price,
            hasReceipt: false,
            hasPhoto: false,
            promoType: 'Flagged Report',
            tokensReward: 0,
          );
    }
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
  StreakData build() => MockData.initialStreak;

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
  List<UserBadge> build() => MockData.initialBadges;

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
  DailyChallenge build() => MockData.initialDailyChallenge;

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

  void setTokenEarnRate(int rate) =>
      state = state.copyWith(tokenEarnRate: rate);
  void setVoucherThreshold(int threshold) =>
      state = state.copyWith(voucherThreshold: threshold);
  void setDailySubmissionCap(int cap) =>
      state = state.copyWith(dailySubmissionCap: cap);
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
