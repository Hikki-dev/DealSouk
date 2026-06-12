import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/responsive_container.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';

class _CatalogCategory {
  final String title;
  final String filterCategory;
  final IconData icon;
  final Color color;

  const _CatalogCategory(
    this.title,
    this.filterCategory,
    this.icon,
    this.color,
  );
}

const _catalogCategories = [
  _CatalogCategory('Fresh', 'Fresh', Icons.spa_outlined, Color(0xFF2E7D32)),
  _CatalogCategory('Fruits', 'Fruits', Icons.apple_outlined, Color(0xFFE65100)),
  _CatalogCategory(
    'Snacks',
    'Snacks',
    Icons.cookie_outlined,
    Color(0xFFD81B60),
  ),
  _CatalogCategory(
    'Grocery',
    'Dairy & Sweet',
    Icons.local_grocery_store_outlined,
    Color(0xFF1E88E5),
  ),
  _CatalogCategory('Oils', 'Bakery', Icons.opacity_outlined, Color(0xFF8D6E63)),
];

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final filterState = ref.watch(filterProvider);
    final cartItems = ref.watch(cartProvider);
    final requestCost = ref.watch(adminSettingsProvider).requestCostTokens;
    final savedCount = cartItems.length;

    final selectedCategory = filterState.selectedCategory == 'All'
        ? 'Fresh'
        : filterState.selectedCategory;

    // Apply text search & category filters reactively
    final displayedProducts = products.where((product) {
      final matchesCategory =
          product.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesSearch =
          product.name.toLowerCase().contains(
            filterState.searchQuery.toLowerCase(),
          ) ||
          product.brand.toLowerCase().contains(
            filterState.searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
            ),
            onPressed: () => context.go('/'),
          ),
          title: Text(
            'Daily Foods',
            style: GoogleFonts.fredoka(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => context.go('/cart'),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.bookmark_border_rounded,
                        color: AppTheme.forestDeep,
                        size: 20,
                      ),
                    ),
                    if (savedCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: const BoxDecoration(
                            color: AppTheme.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$savedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Horizontal Category Selector Tabs
            Container(
              color: Colors.white,
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _catalogCategories.length,
                itemBuilder: (context, index) {
                  final cat = _catalogCategories[index];
                  final isSelected =
                      selectedCategory.toLowerCase() ==
                      cat.filterCategory.toLowerCase();
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(filterProvider.notifier)
                          .setCategory(cat.filterCategory);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cat.title,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.forestDeep
                                  : Colors.grey.shade500,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 18 : 0,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.forestDeep,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: TextField(
                autofocus: false,
                onChanged: (query) {
                  ref.read(filterProvider.notifier).setSearchQuery(query);
                },
                decoration: InputDecoration(
                  hintText: 'Search vegetables, fruits and more',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  suffixIcon: filterState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            ref
                                .read(filterProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : IconButton(
                          tooltip: 'Scan barcode',
                          icon: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          onPressed: () => context.push('/scan-barcode'),
                        ),
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppTheme.forestDeep,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Products Grid
            Expanded(
              child: displayedProducts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              filterState.searchQuery.isEmpty
                                  ? 'No products found in this category'
                                  : 'We couldn\'t find "${filterState.searchQuery}"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              filterState.searchQuery.isEmpty
                                  ? 'Try changing category or check back later.'
                                  : 'Tap below to ask other shoppers to check the price for you!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                            if (filterState.searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _showSearchRequestSheet(
                                  context,
                                  ref,
                                  filterState.searchQuery,
                                  requestCost,
                                ),
                                icon: const Icon(
                                  Icons.add_comment_rounded,
                                  size: 16,
                                ),
                                label: const Text('Ask shoppers to check'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.forestDeep,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                      itemCount: displayedProducts.length,
                      itemBuilder: (context, index) {
                        return ProductGridCard(
                          product: displayedProducts[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchRequestSheet(
    BuildContext context,
    WidgetRef ref,
    String initialQuery,
    int requestCost,
  ) {
    final formKey = GlobalKey<FormState>();
    String productName = initialQuery;
    String selectedStore = 'Carrefour';

    final List<String> stores = [
      'Carrefour',
      'Lulu Hypermarket',
      'Spinneys',
      'Union Coop',
      'Nesto',
      'Choithrams',
      'Grandiose',
      'Waitrose',
      'Al Maya',
      'Geant',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Request a price check',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Other shoppers will check the price of this item for you. This uses $requestCost tokens and refunds if it expires.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  initialValue: productName,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'e.g. Al Rawabi Fresh Milk 2L',
                  ),
                  onChanged: (val) => productName = val,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Enter product name'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedStore,
                  decoration: const InputDecoration(
                    labelText: 'Choose supermarket',
                  ),
                  items: stores.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) selectedStore = val;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      ref
                          .read(priceRequestsProvider.notifier)
                          .addPriceRequest(
                            productName: productName.trim(),
                            storeName: selectedStore,
                            requestCostTokens: requestCost,
                            requesterName: 'Shopper',
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Request posted! Shoppers near that store will be notified.',
                          ),
                          backgroundColor: AppTheme.forestDeep,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestDeep,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Ask for this price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
