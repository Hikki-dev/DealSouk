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
    // Initialize cart with mockup items
    final spinach = MockData.initialProducts.firstWhere((p) => p.id == 'spinach');
    final apples = MockData.initialProducts.firstWhere((p) => p.id == 'apples');
    final lettuce = MockData.initialProducts.firstWhere((p) => p.id == 'lettuce');

    return [
      CartItem(product: spinach, quantity: 1),
      CartItem(product: apples, quantity: 2),
      CartItem(product: lettuce, quantity: 1),
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
      state = [...state, CartItem(product: product, quantity: 1)];
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
    );
    state = [newSub, ...state];
  }

  void approveSubmission(String id, WidgetRef ref) {
    final submissionIndex = state.indexWhere((sub) => sub.id == id);
    if (submissionIndex >= 0) {
      final sub = state[submissionIndex];
      // Remove from submissions
      state = state.where((s) => s.id != id).toList();

      if (sub.promoType == 'Flagged Report') {
        // Find matching product id
        final products = ref.read(productsProvider);
        final product = products.firstWhere(
          (p) => p.name.toLowerCase().contains(sub.productName.toLowerCase()) ||
                 sub.productName.toLowerCase().contains(p.name.toLowerCase()),
          orElse: () => products.first,
        );
        ref.read(flaggedPricesProvider.notifier).resetFlags(product.id, sub.storeName);
        return;
      }

      // Award tokens to Hessa
      ref.read(userTokensProvider.notifier).addTokens(sub.tokensReward);
      ref
          .read(userTransactionsProvider.notifier)
          .addTransaction(
            sub.tokensReward,
            '+${sub.tokensReward} tokens - Approved ${sub.productName} price',
          );

      // Find the product and update its lowest price if applicable
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
  final String freshnessFilter; // 'All', 'Under 6h', 'Under 24h', 'Under 72h'

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

  UserProfile({
    required this.name,
    required this.location,
    required this.avatarUrl,
  });
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => UserProfile(
        name: 'Hessa Al Maktoum',
        location: 'Dubai Marina sourcer',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
      );
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

    // Deduct tokens from userTokensProvider
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
      // Refund tokens to user
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
  // Maps "productId_storeName" to flag count
  @override
  Map<String, int> build() => {};

  void flagPrice(String productId, String storeName, String productName, double price) {
    final key = '${productId}_$storeName';
    final currentFlags = state[key] ?? 0;
    final newFlags = currentFlags + 1;
    
    state = {...state, key: newFlags};

    if (newFlags >= 3) {
      // Create a flagged submission for the admin queue
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

// --- Navbar Visibility (hide when bottom sheets are open) ---
class NavbarVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void show() => state = true;
  void hide() => state = false;
}

final navbarVisibleProvider = NotifierProvider<NavbarVisibleNotifier, bool>(
  NavbarVisibleNotifier.new,
);
