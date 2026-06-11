import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Dark forest header: search + cart, centered location.
          // Smooth arc bottom edge with category circles straddling it. ──
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Column(
                  children: [
                    ClipPath(
                      clipper: const ArcBottomClipper(depth: 26),
                      child: Container(
                        color: AppTheme.forestDeep,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          MediaQuery.of(context).padding.top + 14,
                          20,
                          60,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // White search pill
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      ref.read(filterProvider.notifier).reset();
                                      context.push('/search');
                                    },
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color: Colors.grey.shade500,
                                            size: 19,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Search for "Grocery"',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Cart circle button
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
                                          Icons.shopping_cart_outlined,
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Centered current location in lime
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            GestureDetector(
                              onTap: () => context.go('/stores'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Dubai Marina, UAE',
                                    style: TextStyle(
                                      color: AppTheme.limeAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.navigation,
                                    color: AppTheme.limeAccent,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // White space below the arc — the circles straddle into it
                    const SizedBox(height: 46),
                  ],
                ),
                // Draggable category carousel overlapping the arc edge.
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(height: 92, child: _CategoryCarousel()),
                ),
              ],
            ),
          ),

          // ── Red dashed "smile" accent under the categories ──
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: CustomPaint(
                  size: const Size(56, 12),
                  painter: _SmileAccentPainter(),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: _HomeTokenBalance(tokens: tokens),
            ),
          ),
          SliverToBoxAdapter(
            child: _FreshnessChipRow(selected: filterState.freshnessFilter),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fresh price feed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${feedProducts.length} nearby',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: feedProducts.take(4).length,
              itemBuilder: (context, index) =>
                  _FreshPriceEntryCard(product: feedProducts[index]),
            ),
          ),

          // ── "You might need" header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'You might need',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(filterProvider.notifier)
                          .setCategory('Vegetable');
                      context.push('/search');
                    },
                    child: const Text(
                      'See more',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3-column product grid ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.62,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductGridCard(product: products[index]),
                childCount: 3,
              ),
            ),
          ),

          // ── Promo banners (Grocery / Wholesale style) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _PromoBanner(
                      title: 'Compare',
                      subtitle: 'Today\'s basket',
                      tag: 'Find lowest AED total',
                      bg: const Color(0xFFFFF6E5), // Light warm cream yellow
                      titleColor: const Color(0xFF5D4037),
                      subColor: Colors.deepOrange.shade800,
                      tagBg: Colors.transparent,
                      imageUrl:
                          'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=200&q=80&auto=format&fit=crop', // Avocado
                      onTap: () => context.push('/search'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PromoBanner(
                      title: 'Earn tokens',
                      subtitle: 'Nearby stores',
                      tag: 'Upload price labels',
                      bg: const Color(0xFFFFF0F3), // Soft pink
                      titleColor: const Color(0xFF6B1D2F), // Dark maroon/pink
                      subColor: Colors.pink.shade800,
                      tagBg: Colors.transparent,
                      imageUrl:
                          'https://images.unsplash.com/photo-1582515073490-39981397c445?w=200&q=80&auto=format&fit=crop', // Beetroot
                      onTap: () => context.push('/submit-price'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Featured store (awning cards, like the reference) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured store',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/stores'),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _FeaturedStoreCard(store: MockData.initialStores[0]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FeaturedStoreCard(store: MockData.initialStores[1]),
                  ),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.forestDeep,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestDeep.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppTheme.limeAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: AppTheme.forestDeep, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Token balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Earn more by uploading fresh shelf prices.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
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
                value.round().toString(),
                style: const TextStyle(
                  color: AppTheme.limeAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.limeAccent : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.limeAccent
                      : const Color(0xFFE3EADF),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: AppTheme.forestDeep,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EEE4)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: SoukProductVisual(
                product: product,
                fit: BoxFit.cover,
                borderRadius: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
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
                      fontWeight: FontWeight.w700,
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
                            ? AppTheme.limeAccent
                            : AppTheme.emeraldLight,
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
            SoukPrice(product.lowestPrice, size: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.forestDeep, size: 10),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.forestDeep,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color bg;
  final Color titleColor;
  final Color subColor;
  final Color tagBg;
  final String imageUrl;
  final VoidCallback onTap;

  const _PromoBanner({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.bg,
    required this.titleColor,
    required this.subColor,
    required this.tagBg,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Product image bottom-right, like the reference banners
            Positioned(
              right: -8,
              bottom: -8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  imageUrl,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(width: 58, height: 58),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: subColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tagBg == Colors.transparent ? null : tagBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tagBg == Colors.transparent
                            ? titleColor.withValues(alpha: 0.75)
                            : Colors.white,
                      ),
                    ),
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

class _CategoryInfo {
  final IconData icon;
  final String label;
  final String category;
  final Color color;

  const _CategoryInfo(this.icon, this.label, this.category, this.color);
}

const _homeCategories = [
  _CategoryInfo(
    Icons.kebab_dining_outlined,
    'Meats',
    'Meat',
    Color(0xFF0C3B2E),
  ),
  _CategoryInfo(Icons.spa_outlined, 'Vege', 'Vegetable', Color(0xFF1B5E20)),
  _CategoryInfo(Icons.apple_outlined, 'Fruits', 'Fruits', Color(0xFFE65100)),
  _CategoryInfo(
    Icons.bakery_dining_outlined,
    'Breads',
    'Breads',
    Color(0xFF5D4037),
  ),
  _CategoryInfo(
    Icons.egg_alt_outlined,
    'Dairy',
    'Dairy & Sweet',
    Color(0xFF1E88E5),
  ),
  _CategoryInfo(Icons.fastfood_outlined, 'Snacks', 'Snacks', Color(0xFFD81B60)),
  _CategoryInfo(
    Icons.restaurant_rounded,
    'Chicken',
    'Chicken',
    Color(0xFFD84315),
  ),
  _CategoryInfo(
    Icons.breakfast_dining_outlined,
    'Pantry',
    'Bakery',
    Color(0xFF8D6E63),
  ),
];

class _CategoryCarousel extends ConsumerStatefulWidget {
  const _CategoryCarousel();

  @override
  ConsumerState<_CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends ConsumerState<_CategoryCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.25);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      padEnds: false,
      physics: const BouncingScrollPhysics(),
      itemCount: _homeCategories.length,
      itemBuilder: (context, index) {
        final category = _homeCategories[index];
        return _CategoryCircle(category);
      },
    );
  }
}

class _CategoryCircle extends ConsumerWidget {
  final _CategoryInfo category;

  const _CategoryCircle(this.category);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(filterProvider.notifier).setCategory(category.category);
        context.push('/search');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.creamCircle,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(category.icon, color: category.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            category.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.forestDeep,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed red "smile" arc under the category circles — reference accent.
class _SmileAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF08A77)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, -size.height, size.width, size.height * 2.4);
    // Two dashes along the bottom arc of an oval — a subtle smile
    canvas.drawArc(rect, 0.45 * 3.14159, 0.22 * 3.14159, false, paint);
    canvas.drawArc(rect, 0.72 * 3.14159, 0.10 * 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Store card with the green-and-cream scalloped awning from the reference.
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Awning: forest band with cream scalloped valance + logo circle
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
                      child: Container(height: 14, color: AppTheme.creamCircle),
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
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 13,
                        color: Color(0xFFF2B33D),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${store.distance} km away',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
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
