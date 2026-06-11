import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/state.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

const _categories = [
  'All',
  'Dairy & Eggs',
  'Pantry',
  'Meat & Seafood',
  'Beverages',
  'Household',
];

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final filterState = ref.watch(filterProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    // Apply text search & category filters
    final displayedProducts = products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(filterState.searchQuery.toLowerCase()) ||
          product.brand.toLowerCase().contains(filterState.searchQuery.toLowerCase());
      final matchesCategory = filterState.selectedCategory == 'All' || product.category == filterState.selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return ResponsiveContainer(
      child: Container(
        color: AppTheme.forestDeep,
        child: Column(
          children: [
            // ── Dark green header: back / title / cart ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 4),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      ref.read(filterProvider.notifier).reset();
                      context.pop();
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Daily Groceries',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                              border: Border.all(color: AppTheme.forestDeep, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Category tabs (lime active) ──
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((category) {
                  final isSelected = filterState.selectedCategory == category;
                  return GestureDetector(
                    onTap: () => ref.read(filterProvider.notifier).setCategory(category),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? AppTheme.limeAccent : Colors.white.withOpacity(0.6),
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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

            // ── White rounded sheet: search + grid ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                      child: TextField(
                        autofocus: false,
                        onChanged: (query) {
                          ref.read(filterProvider.notifier).setSearchQuery(query);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for "Milk"',
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                          suffixIcon: filterState.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    ref.read(filterProvider.notifier).setSearchQuery('');
                                  },
                                )
                              : Icon(Icons.tune_rounded, color: Colors.grey.shade500, size: 20),
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(color: AppTheme.forestDeep, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    // Results grid
                    Expanded(
                      child: displayedProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Try searching for milk, eggs, rice, or chicken.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.62,
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
                ),
              ),
            ),
          ],
        ),
      ),
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
