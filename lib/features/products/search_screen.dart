import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/state/state.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

class _CatalogCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CatalogCategory(this.title, this.subtitle, this.icon, this.color);
}

const _catalogCategories = [
  _CatalogCategory(
    'Meat',
    'Butcher prices',
    Icons.kebab_dining_outlined,
    Color(0xFF0C3B2E),
  ),
  _CatalogCategory(
    'Vegetable',
    'Fresh market',
    Icons.spa_outlined,
    Color(0xFF1B5E20),
  ),
  _CatalogCategory(
    'Fruits',
    'Daily produce',
    Icons.apple_outlined,
    Color(0xFFE65100),
  ),
  _CatalogCategory(
    'Breads',
    'Bakery shelf',
    Icons.bakery_dining_outlined,
    Color(0xFF5D4037),
  ),
  _CatalogCategory(
    'Snacks',
    'Offers nearby',
    Icons.fastfood_outlined,
    Color(0xFFD81B60),
  ),
  _CatalogCategory(
    'Bakery',
    'Pantry staples',
    Icons.breakfast_dining_outlined,
    Color(0xFF8D6E63),
  ),
  _CatalogCategory(
    'Dairy & Sweet',
    'Cold aisle',
    Icons.egg_alt_outlined,
    Color(0xFF1E88E5),
  ),
  _CatalogCategory(
    'Chicken',
    'Fresh & frozen',
    Icons.restaurant_rounded,
    Color(0xFFD84315),
  ),
];

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final filterState = ref.watch(filterProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    final selectedCategory = filterState.selectedCategory == 'All'
        ? 'Vegetable'
        : filterState.selectedCategory;

    // Apply text search & category filters
    final displayedProducts = products.where((product) {
      final matchesSearch =
          product.name.toLowerCase().contains(
            filterState.searchQuery.toLowerCase(),
          ) ||
          product.brand.toLowerCase().contains(
            filterState.searchQuery.toLowerCase(),
          );
      return matchesSearch;
    }).toList();
    final gridProducts = displayedProducts.length >= 6
        ? displayedProducts
        : [
            ...displayedProducts,
            ...products.where(
              (p) => !displayedProducts.any((shown) => shown.id == p.id),
            ),
          ];

    return ResponsiveContainer(
      child: Container(
        color: AppTheme.forestDeep,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 10,
                16,
                4,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          context.go('/');
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Daily foods',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _CircleButton(
                            icon: Icons.shopping_cart_outlined,
                            onTap: () => context.go('/cart'),
                          ),
                          if (cartCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 17,
                                height: 17,
                                decoration: BoxDecoration(
                                  color: AppTheme.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.forestDeep,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$cartCount',
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Horizontal scrollable tabs
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _catalogCategories.map((cat) {
                        final isSelected = selectedCategory == cat.title;
                        return GestureDetector(
                          onTap: () => ref
                              .read(filterProvider.notifier)
                              .setCategory(cat.title),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat.title == 'Meat'
                                      ? 'Frozen'
                                      : (cat.title == 'Vegetable'
                                            ? 'Fresh'
                                            : cat.title),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.limeAccent
                                        : Colors.white.withValues(alpha: 0.6),
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: isSelected ? 18 : 0,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.limeAccent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY SHEET ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildCategoryProductsDetail(
                  context,
                  ref,
                  filterState,
                  gridProducts.take(12).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STATE B: Selected Category Products Detail ---
  Widget _buildCategoryProductsDetail(
    BuildContext context,
    WidgetRef ref,
    FilterState filterState,
    List<Product> displayedProducts,
  ) {
    return Column(
      children: [
        // Search text field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            autofocus: false,
            onChanged: (query) {
              ref.read(filterProvider.notifier).setSearchQuery(query);
            },
            decoration: InputDecoration(
              hintText: 'Search for "Grocery"',
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade500,
                size: 20,
              ),
              suffixIcon: filterState.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        ref.read(filterProvider.notifier).setSearchQuery('');
                      },
                    )
                  : Icon(
                      Icons.tune_rounded,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                  color: AppTheme.forestDeep,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // Products grid (3 columns)
        Expanded(
          child: displayedProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 56,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No products found',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.61,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: displayedProducts.length,
                  itemBuilder: (context, index) {
                    return ProductGridCard(product: displayedProducts[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.forestDeep, size: 17),
      ),
    );
  }
}
