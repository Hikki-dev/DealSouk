import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' show max;
import '../../core/state/state.dart';
import '../../core/models/models.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/souk_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(userTokensProvider);
    final products = ref.watch(productsProvider);
    final filterState = ref.watch(filterProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    // Filter products based on freshness filter chip
    List<Product> displayedProducts = products;
    if (filterState.freshnessFilter != 'All') {
      displayedProducts = products.where((product) {
        final label = product.updatedAtLabel.toLowerCase();
        if (filterState.freshnessFilter == 'Under 6h') {
          return label.contains('1h') || label.contains('2h') || label.contains('3h') || label.contains('4h') || label.contains('5h') || label.contains('just now');
        } else if (filterState.freshnessFilter == 'Under 24h') {
          return !label.contains('1d') && !label.contains('2d') && !label.contains('25h');
        } else if (filterState.freshnessFilter == 'Under 72h') {
          return true;
        }
        return true;
      }).toList();
    }

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
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.search, color: Colors.grey.shade500, size: 19),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Search for "Grocery"',
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
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
                                        child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.forestDeep, size: 20),
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Centered current location in lime
                            const Text(
                              'Current Location',
                              style: TextStyle(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 3),
                            GestureDetector(
                              onTap: () => context.go('/stores'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'California, USA',
                                    style: TextStyle(
                                      color: AppTheme.limeAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.navigation, color: AppTheme.limeAccent, size: 14),
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
                // Category circles overlapping the arc edge
                const Positioned(
                  left: 8,
                  right: 8,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CategoryCircle(Icons.kebab_dining_outlined, 'Meats', Color(0xFF0C3B2E)),
                      _CategoryCircle(Icons.spa_outlined, 'Veggies', Color(0xFF1B5E20)),
                      _CategoryCircle(Icons.apple_outlined, 'Fruits', Color(0xFFE65100)),
                      _CategoryCircle(Icons.bakery_dining_outlined, 'Breads', Color(0xFF5D4037)),
                    ],
                  ),
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

          // ── "You might need" header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                    onTap: () => context.push('/search'),
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
                      title: 'Grocery',
                      subtitle: 'By 12:15pm',
                      tag: 'Free delivery',
                      bg: const Color(0xFFFFF6E5), // Light warm cream yellow
                      titleColor: const Color(0xFF5D4037),
                      subColor: Colors.deepOrange.shade800,
                      tagBg: Colors.transparent,
                      imageUrl: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=200&q=80&auto=format&fit=crop', // Avocado
                      onTap: () => context.push('/search'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PromoBanner(
                      title: 'Wholesale',
                      subtitle: 'By 1:30pm',
                      tag: 'Free delivery',
                      bg: const Color(0xFFFFF0F3), // Soft pink
                      titleColor: const Color(0xFF6B1D2F), // Dark maroon/pink
                      subColor: Colors.pink.shade800,
                      tagBg: Colors.transparent,
                      imageUrl: 'https://images.unsplash.com/photo-1582515073490-39981397c445?w=200&q=80&auto=format&fit=crop', // Beetroot
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

          // ── Token Balance Card — PRD hero element, forest+lime palette ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: GestureDetector(
                onTap: () => context.go('/leaderboard'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.forestDeep, AppTheme.forestMid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.forestDeep.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.limeAccent.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.confirmation_num_outlined, size: 12, color: AppTheme.limeAccent),
                                  SizedBox(width: 5),
                                  Text(
                                    'Goal: AED 50 Voucher',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.limeAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$tokens',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    height: 0.9,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6, left: 7),
                                  child: Text(
                                    'tokens',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (tokens / 500).clamp(0.0, 1.0),
                                backgroundColor: Colors.white.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.limeAccent),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tokens >= 500
                                  ? 'Voucher ready to claim!'
                                  : '${500 - tokens} tokens to unlock your voucher',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: (tokens / 500).clamp(0.0, 1.0),
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.limeAccent),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Icon(
                            Icons.emoji_events_rounded,
                            color: tokens >= 500 ? AppTheme.limeAccent : Colors.white38,
                            size: 30,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── How it works (demo guide) ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _DemoGuideBanner(),
            ),
          ),

          // ── Live Price Feed label ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 8.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Price Feed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${displayedProducts.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Freshness filter chips (PRD UI-01) ──
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: ['All', 'Under 6h', 'Under 24h', 'Under 72h'].map((filter) {
                  final isSelected = filterState.freshnessFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(filterProvider.notifier).setFreshnessFilter(filter);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Price feed cards ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            sliver: displayedProducts.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.hourglass_empty, color: Colors.grey.shade400, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No prices match this filter yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = displayedProducts[index];
                        return _ProductPriceCard(product: product);
                      },
                      childCount: displayedProducts.length,
                    ),
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
                  errorBuilder: (_, __, ___) => const SizedBox(width: 58, height: 58),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: titleColor),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: subColor)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagBg == Colors.transparent ? null : tagBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tagBg == Colors.transparent ? titleColor.withOpacity(0.75) : Colors.white,
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

class _DemoGuideBanner extends StatelessWidget {
  const _DemoGuideBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primaryContainer, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.limeAccent.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppTheme.forestDeep, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Try the Demo Flow',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.forestDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStep(1, 'Submit Price', Icons.add_circle_outline, theme),
              _buildArrow(),
              _buildStep(2, 'Admin Approves', Icons.verified_outlined, theme),
              _buildArrow(),
              _buildStep(3, 'Tokens Credited', Icons.bolt, theme),
              _buildArrow(),
              _buildStep(4, 'Save on Cart', Icons.shopping_cart_outlined, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.chevron_right, size: 16, color: Color(0xFFB0BEC5)),
    );
  }

  Widget _buildStep(int num, String label, IconData icon, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CategoryCircle(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search'),
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
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
              color: Colors.black.withOpacity(0.05),
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
                      const Icon(Icons.bolt, size: 13, color: Color(0xFFF2B33D)),
                      const SizedBox(width: 2),
                      Text(
                        '${store.distance} km away',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

class _ProductPriceCard extends StatelessWidget {
  final Product product;

  const _ProductPriceCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = categoryColor(product.category);

    // Savings vs most expensive store
    final prices = MockData.productPrices[product.id] ?? [];
    double saving = 0;
    if (prices.length >= 2) {
      final maxPrice = prices.map((p) => p.price).reduce(max);
      saving = maxPrice - product.lowestPrice;
    }

    // Flutter forbids borderRadius with non-uniform border colors.
    // Use a Stack: shadow+radius on the outer container, accent strip as a Positioned child.
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/product/${product.id}'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 54,
                                height: 54,
                                color: accentColor.withOpacity(0.10),
                                child: Icon(categoryIcon(product.category), color: accentColor, size: 22),
                              ),
                            )
                          : Container(
                              width: 54,
                              height: 54,
                              color: accentColor.withOpacity(0.10),
                              child: Icon(categoryIcon(product.category), color: accentColor, size: 22),
                            ),
                    ),
                    const SizedBox(width: 14),

                    // Middle details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                product.brand,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                child: Text(product.packSize, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            product.name,
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.storefront_outlined, size: 12, color: accentColor),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  product.lowestPriceStore,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(product.updatedAtLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            ],
                          ),
                          if (saving >= 0.50) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.limeAccent.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Save AED ${saving.toStringAsFixed(2)} vs most expensive',
                                style: const TextStyle(fontSize: 9, color: AppTheme.forestDeep, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Price — superscript style
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SoukPrice(product.lowestPrice, size: 19),
                        const SizedBox(height: 2),
                        Text(
                          '${prices.length} stores',
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Left accent strip — drawn on top of content via Stack
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
