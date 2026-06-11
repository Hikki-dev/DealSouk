import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/state.dart';
import '../../core/models/models.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/souk_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final filterState = ref.watch(filterProvider);
    final tokens = ref.watch(userTokensProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final feedProducts =
        _filterByFreshness(products, filterState.freshnessFilter)..sort(
          (a, b) => _freshnessMinutes(
            a.updatedAtLabel,
          ).compareTo(_freshnessMinutes(b.updatedAtLabel)),
        );

    // Categories defined for Dribbble layout
    final List<_CategoryInfo> homeCategories = [
      const _CategoryInfo(Icons.spa_outlined, 'Fresh', 'Fresh', Color(0xFF2E7D32)),
      const _CategoryInfo(Icons.apple_outlined, 'Fruits', 'Fruits', Color(0xFFE65100)),
      const _CategoryInfo(Icons.cookie_outlined, 'Snacks', 'Snacks', Color(0xFFD81B60)),
      const _CategoryInfo(Icons.shopping_basket_outlined, 'Grocery', 'Dairy & Sweet', Color(0xFF1E88E5)),
      const _CategoryInfo(Icons.opacity_outlined, 'Oils', 'Bakery', Color(0xFF8D6E63)),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Dribbble Screenshot Header: Green gradient, Avatar, Cart button, Special offer card, capsule search
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2E7D32), // Deep fresh green
                      Color(0xFF388E3C), // Medium green
                      Color(0xFF81C784), // Light green
                      AppTheme.background, // Fades to off-white background
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.35, 0.75, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Greeting Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Hannah Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Morning, Hannah',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'What would you buy today?',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12.5,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Basket Button (Green outline in white circle)
                        GestureDetector(
                          onTap: () => context.go('/cart'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_basket_outlined,
                                  color: AppTheme.forestDeep,
                                  size: 20,
                                ),
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$cartCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Special Offer Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enjoy The Special\nOffer Up To 30%',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'From 14th June, 2025',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Indicator Dots (one green pill, three grey circles)
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: AppTheme.forestDeep,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildIndicatorDot(),
                                    const SizedBox(width: 4),
                                    _buildIndicatorDot(),
                                    const SizedBox(width: 4),
                                    _buildIndicatorDot(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Vegetable Bundle Image on right
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1542838132-92c53300491e?w=200&q=80&auto=format&fit=crop',
                                height: 94,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(height: 94),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Bar (Capsule shape)
                    GestureDetector(
                      onTap: () {
                        ref.read(filterProvider.notifier).reset();
                        context.push('/search');
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Search vegetables, fruits and more',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.tune_rounded, color: AppTheme.forestDeep, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Categories Row (Static 5 items)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(filterProvider.notifier).reset();
                            context.push('/search');
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.forestDeep,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 94,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: homeCategories.length,
                      itemBuilder: (context, index) {
                        final cat = homeCategories[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              ref.read(filterProvider.notifier).setCategory(cat.category);
                              context.push('/search');
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cream,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(cat.icon, color: cat.color, size: 26),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat.label,
                                  style: GoogleFonts.nunito(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 3. DealSouk Token Balance Wallet Card (Clickable to Leaderboard)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: _HomeTokenBalance(tokens: tokens),
              ),
            ),

            // 4. Quick-Tip concept banner: How it works
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, color: AppTheme.forestDeep, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'How it works: Compare local supermarket prices, upload shelf labels to earn tokens, and redeem vouchers!',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppTheme.forestDeep,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Freshness chip filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _FreshnessChipRow(selected: filterState.freshnessFilter),
              ),
            ),

            // 6. Verified prices feed (Fresh Price Feed) moved ABOVE the Fresh Products grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fresh Price Feed',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${feedProducts.length} nearby',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Verified prices list cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: feedProducts.take(4).length,
                itemBuilder: (context, index) =>
                    _FreshPriceEntryCard(product: feedProducts[index]),
              ),
            ),

            // 7. Fresh Products Feed
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fresh Products',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(filterProvider.notifier).reset();
                        context.push('/search');
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.forestDeep,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2-column grid displaying products
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductGridCard(product: products[index]),
                  childCount: 4.clamp(0, products.length), // Display top items (Spinach, Apples, Lettuce, Beetroot)
                ),
              ),
            ),

            // 8. Featured stores header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Stores',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/stores'),
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Featured stores awning cards row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _FeaturedStoreCard(store: MockData.initialStores[0]),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _FeaturedStoreCard(store: MockData.initialStores[1]),
                    ),
                  ],
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
    );
  }
}

List<Product> _filterByFreshness(List<Product> products, String freshness) {
  if (freshness == 'All') return [...products];
  final maxMinutes = switch (freshness) {
    'Under 6h' => 6 * 60,
    'Under 24h' => 24 * 60,
    'Under 72h' => 72 * 60,
    _ => 999999,
  };
  return products
      .where(
        (product) => _freshnessMinutes(product.updatedAtLabel) <= maxMinutes,
      )
      .toList();
}

int _freshnessMinutes(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('just now')) return 0;
  final number =
      int.tryParse(RegExp(r'(\d+)').firstMatch(lower)?.group(1) ?? '') ?? 9999;
  if (lower.contains('m')) return number;
  if (lower.contains('h')) return number * 60;
  if (lower.contains('d')) return number * 24 * 60;
  return 9999;
}

String _expiryLabel(String updatedLabel) {
  final minutes = _freshnessMinutes(updatedLabel);
  final remaining = (72 * 60 - minutes).clamp(0, 72 * 60);
  final hours = (remaining / 60).ceil();
  return 'Expires in ${hours}h';
}

class _HomeTokenBalance extends StatelessWidget {
  final int tokens;

  const _HomeTokenBalance({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/leaderboard'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.forestDeep, AppTheme.forestMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.forestDeep.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Token Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Earn tokens by validating prices • Tap to claim',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: tokens.toDouble()),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  '${value.round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FreshnessChipRow extends ConsumerWidget {
  final String selected;

  const _FreshnessChipRow({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filters = ['All', 'Under 6h', 'Under 24h', 'Under 72h'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selected;
          return GestureDetector(
            onTap: () =>
                ref.read(filterProvider.notifier).setFreshnessFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.forestDeep : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.forestDeep
                      : const Color(0xFFE8EEE4),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.forestDeep,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }
}

class _FreshPriceEntryCard extends StatelessWidget {
  final Product product;

  const _FreshPriceEntryCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isFresh = _freshnessMinutes(product.updatedAtLabel) <= 6 * 60;
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: SoukProductVisual(
                product: product,
                fit: BoxFit.cover,
                borderRadius: 14,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.lowestPriceStore,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      _TrustPill(
                        label: isFresh ? 'Fresh' : 'Verified',
                        icon: isFresh
                            ? Icons.flash_on_rounded
                            : Icons.verified_outlined,
                        color: isFresh
                            ? AppTheme.cream
                            : const Color(0xFFE8F5E9),
                      ),
                      _TrustPill(
                        label: product.updatedAtLabel,
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFFF3F1EA),
                      ),
                      _TrustPill(
                        label: _expiryLabel(product.updatedAtLabel),
                        icon: Icons.hourglass_bottom_rounded,
                        color: const Color(0xFFFFF0F3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SoukPrice(product.lowestPrice, size: 14.5),
          ],
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TrustPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.forestDeep, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.forestDeep,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryInfo {
  final IconData icon;
  final String label;
  final String category;
  final Color color;

  const _CategoryInfo(this.icon, this.label, this.category, this.color);
}

class _FeaturedStoreCard extends StatelessWidget {
  final Store store;

  const _FeaturedStoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/stores'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scalloped awning design
            SizedBox(
              height: 74,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(height: 56, color: AppTheme.forestDeep),
                  Positioned(
                    top: 42,
                    left: 0,
                    right: 0,
                    child: ClipPath(
                      clipper: const ScallopClipper.down(scallopRadius: 7),
                      child: Container(height: 14, color: AppTheme.cream),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.forestMid,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          store.name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 13,
                        color: Color(0xFFFFA000),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${store.distance} km away • ${store.pricesCount} prices',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
