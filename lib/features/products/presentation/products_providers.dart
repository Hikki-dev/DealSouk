import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/data/products_service.dart';
import 'package:dealsouk/features/submissions/data/submissions_service.dart';

class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => [];

  Future<void> fetch({String query = '', String? category}) async {
    try {
      final results = await productsService.search(
        query: query,
        category: category,
      );
      state = results;
    } catch (_) {}
  }

  void updateProductPrice(String productId, double price, String storeName) {
    state = state.map((product) {
      if (product.id == productId) {
        if (price < product.lowestPrice || product.lowestPrice == 0) {
          return product.copyWith(
            lowestPrice: price,
            lowestPriceStore: storeName,
            updatedAtLabel: 'Updated Just Now',
            hoursAgo: 0,
          );
        } else {
          return product.copyWith(
            updatedAtLabel: 'Updated Just Now',
            hoursAgo: 0,
          );
        }
      }
      return product;
    }).toList();
  }
}

final productsProvider = NotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);

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
