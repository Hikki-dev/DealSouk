import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/state.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

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
                      : Icon(
                          Icons.tune_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
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
                            'No products found in this category',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
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
}
