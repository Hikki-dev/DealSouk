import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/tokens/domain/daily_challenge.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/core/widgets/platform_card.dart';
import 'package:dealsouk/features/requests/presentation/request_board_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productsProvider.notifier).fetch();
      ref
          .read(storesProvider.notifier)
          .fetchNearby(lat: 25.0771, lng: 55.1328, radiusKm: 5);
      ref.read(cartProvider.notifier).loadPersistedCart();
      ref.read(dailyChallengeProvider.notifier).fetchToday();
      ref.read(priceRequestsProvider.notifier).fetchBoard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final filterState = ref.watch(filterProvider);
    final tokens = ref.watch(userTokensProvider);
    final cartItems = ref.watch(cartProvider);
    final profile = ref.watch(userProfileProvider);
    final firstName = profile.name.split(' ').first;
    final dailyChallenge = ref.watch(dailyChallengeProvider);
    final settings = ref.watch(adminSettingsProvider);

    final savedCount = cartItems.length;
    final feedProducts =
        _filterByFreshness(products, filterState.freshnessFilter)..sort(
          (a, b) => _freshnessMinutes(
            a.updatedAtLabel,
          ).compareTo(_freshnessMinutes(b.updatedAtLabel)),
        );

    // Categories defined for Dribbble layout with premium transparent 3D clay illustrations
    final List<_CategoryInfo> homeCategories = [
      const _CategoryInfo(
        Icons.eco_rounded,
        'Fresh',
        'Fresh',
        Color(0xFFE8F5E9), // Pastel green background
      ),
      const _CategoryInfo(
        Icons.apple_rounded,
        'Fruits',
        'Fruits',
        Color(0xFFFFEBEE), // Pastel pink background
      ),
      const _CategoryInfo(
        Icons.fastfood_rounded,
        'Snack',
        'Snacks',
        Color(0xFFFFF8E1), // Pastel yellow background
      ),
      const _CategoryInfo(
        Icons.local_grocery_store_rounded,
        'Grocery',
        'Dairy & Sweet',
        Color(0xFFE0F2F1), // Pastel teal background
      ),
      const _CategoryInfo(
        Icons.water_drop_rounded,
        'Oils',
        'Bakery',
        Color(0xFFF3E5F5), // Pastel purple background
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Warm local-price discovery header.
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Gradient + Grid Pattern Background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF7A4A1D),
                          Color(0xFFC46A2D),
                          Color(0xFFFFD8A8),
                          Color(0xFFFFFAF2),
                          Color(0xFFFFFAF2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.22, 0.45, 0.65, 1.0],
                      ),
                    ),
                    child: CustomPaint(painter: GridPatternPainter()),
                  ),
                ),
                // Header Content Column
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 20,
                    20,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Greeting Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Active User Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                  image: profile.avatarUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            profile.avatarUrl,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: profile.avatarUrl.isEmpty
                                    ? const Center(
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Morning, $firstName',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Find nearby prices before you go',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Saved price list shortcut
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
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$savedCount',
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

                      // Local price discovery carousel
                      const _OfferCarousel(),
                      const SizedBox(height: 20),

                      // Search Bar (Glassmorphic)
                      GestureDetector(
                        onTap: () {
                          ref.read(filterProvider.notifier).reset();
                          context.push('/search');
                        },
                        child: GlassContainer(
                          height: 52,
                          borderRadius: 26,
                          color: Colors.white.withValues(alpha: 0.28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.38),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: Colors.white.withValues(alpha: 0.95),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Search an item to compare prices nearby',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.tune_rounded,
                                color: Colors.white.withValues(alpha: 0.95),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                            ref
                                .read(filterProvider.notifier)
                                .setCategory(cat.category);
                            context.push('/search');
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  cat.icon,
                                  color: AppTheme.forestDeep.withValues(
                                    alpha: 0.42,
                                  ),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.label,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
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

          // 3. Request section should be visible from the home page.
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: RequestBoardView(),
            ),
          ),

          // 4. Community points card.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: _HomeTokenBalance(
                tokens: tokens,
                submissionsToday: profile.submissionsToday,
                dailyCap: settings.dailySubmissionCap,
              ),
            ),
          ),

          // 4b. Daily Challenge Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _DailyChallengeCard(challenge: dailyChallenge),
            ),
          ),

          // 5. Quick-Tip concept banner: How it works
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC8E6C9),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: AppTheme.forestDeep,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Simple: search an item, check nearby stores, then decide where it is worth going.',
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

          // 6. Freshness chip filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _FreshnessChipRow(selected: filterState.freshnessFilter),
            ),
          ),

          // 7. Verified prices feed
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Best prices near you',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      '${feedProducts.length} prices',
                      key: ValueKey<int>(feedProducts.length),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Verified prices list cards (show up to 8 filtered results)
          if (feedProducts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No prices match this filter yet',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try All prices, search for an item, or ask shoppers to check a price.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: () => context.push('/search'),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Find an item'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: feedProducts.take(8).length,
                itemBuilder: (context, index) =>
                    _FreshPriceEntryCard(product: feedProducts[index]),
              ),
            ),

          // 8. Fresh Products Feed
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Browse items',
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

          // 2-column grid displaying filtered products
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
                (context, index) =>
                    ProductGridCard(product: feedProducts[index]),
                childCount: feedProducts.take(4).length,
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
            child: Builder(
              builder: (context) {
                final stores = ref.watch(storesProvider);
                if (stores.length < 2) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: _FeaturedStoreCard(store: stores[0])),
                      const SizedBox(width: 14),
                      Expanded(child: _FeaturedStoreCard(store: stores[1])),
                    ],
                  ),
                );
              },
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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

class _HomeTokenBalance extends StatelessWidget {
  final int tokens;
  final int submissionsToday;
  final int dailyCap;

  const _HomeTokenBalance({
    required this.tokens,
    required this.submissionsToday,
    required this.dailyCap,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformCard(
      onTap: () => context.go('/leaderboard'),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      gradient: const LinearGradient(
        colors: [AppTheme.forestDeep, AppTheme.forestMid],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.forestDeep.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earn rewards today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dailyCap - submissionsToday} price shares left to earn tokens',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
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
    );
  }
}

class _DailyChallengeCard extends ConsumerWidget {
  final DailyChallenge challenge;

  const _DailyChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformCard(
      onTap: () => _showChallengeDetailsSheet(context, ref, challenge),
      padding: const EdgeInsets.all(14),
      borderRadius: 20,
      color: challenge.completed ? const Color(0xFFE8F5E9) : Colors.white,
      border: Border.all(
        color: challenge.completed
            ? AppTheme.forestDeep
            : const Color(0xFFE8EEE4),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: challenge.completed
                  ? AppTheme.forestDeep
                  : AppTheme.limeAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              challenge.completed ? Icons.check_rounded : Icons.flag_outlined,
              color: challenge.completed ? Colors.white : AppTheme.forestDeep,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Challenge',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  challenge.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                if (!challenge.completed) ...[
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (challenge.progressCount / challenge.targetCount)
                          .clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.forestDeep,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.amberAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              challenge.completed
                  ? 'Done! +${challenge.bonusTokens}T'
                  : '${challenge.progressCount}/${challenge.targetCount}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC77C02),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChallengeDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    DailyChallenge challenge,
  ) {
    // Hide navbar when sheet opens
    ref.read(navbarVisibleProvider.notifier).hide();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final progressPercent =
            (challenge.progressCount / challenge.targetCount).clamp(0.0, 1.0);
        final isIos =
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS;

        final sheetContent = Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: challenge.completed
                          ? AppTheme.forestDeep.withValues(alpha: 0.1)
                          : AppTheme.limeAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      challenge.completed
                          ? Icons.check_circle_rounded
                          : Icons.flag_rounded,
                      color: challenge.completed
                          ? AppTheme.forestDeep
                          : AppTheme.limeAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Challenge Details',
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestDeep,
                          ),
                        ),
                        Text(
                          challenge.completed
                              ? 'You have finished this challenge!'
                              : 'Earn bonus tokens by participating today',
                          style: GoogleFonts.nunito(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.limeAccent.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  challenge.description,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    color: AppTheme.forestDeep,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Target Store details
              _detailRow(
                icon: Icons.store_rounded,
                iconColor: Colors.blue.shade600,
                title: 'Target Supermarket',
                value: challenge.targetStore == 'Any'
                    ? 'Any Supermarket Chain'
                    : challenge.targetStore,
              ),
              const Divider(height: 24, color: Color(0xFFE8EEE4)),

              // Progress details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.query_stats_rounded,
                            size: 18,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Progress',
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${challenge.progressCount} / ${challenge.targetCount} prices',
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.forestDeep,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.forestDeep,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFE8EEE4)),

              // Bonus details
              _detailRow(
                icon: Icons.token_rounded,
                iconColor: AppTheme.amberAccent,
                title: 'Reward Bonus',
                value: '+${challenge.bonusTokens} Tokens',
                valueColor: const Color(0xFFC77C02),
              ),
              const Divider(height: 24, color: Color(0xFFE8EEE4)),

              // How to complete section
              Text(
                'How to complete:',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              _stepItem(
                number: '1',
                text:
                    'Visit any branch of ${challenge.targetStore == 'Any' ? 'a supermarket' : challenge.targetStore}.',
              ),
              _stepItem(
                number: '2',
                text: 'Find grocery products and verify their shelf prices.',
              ),
              _stepItem(
                number: '3',
                text:
                    'Tap "Submit Price" in the app, fill in the price details, and submit.',
              ),
              _stepItem(
                number: '4',
                text:
                    'Once approved, your progress will update and you\'ll receive the token bonus!',
              ),
              const SizedBox(height: 28),

              // Button
              challenge.completed
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.forestDeep.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.forestDeep,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Completed! Reward Claimed',
                            style: GoogleFonts.fredoka(
                              color: AppTheme.forestDeep,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/submit-price');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Start Challenge Now',
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        );

        return isIos
            ? ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: sheetContent,
                  ),
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: sheetContent,
              );
      },
    ).whenComplete(() {
      // Restore navbar when sheet is dismissed by any means
      ref.read(navbarVisibleProvider.notifier).show();
    });
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _stepItem({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.creamCircle,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.fredoka(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestDeep,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
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

class _FreshPriceEntryCard extends ConsumerWidget {
  final Product product;

  const _FreshPriceEntryCard({required this.product});

  double _getStoreDistance(WidgetRef ref, String storeName) {
    final stores = ref.read(storesProvider);
    final match = stores.where(
      (s) => s.name.toLowerCase().contains(storeName.toLowerCase()),
    );
    if (match.isNotEmpty) {
      return match.first.distance;
    }
    // Fallback to a stable hash-based mock distance
    return (storeName.hashCode % 15 + 8) / 10.0; // between 0.8 km and 2.2 km
  }

  String _formatFreshness(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('just now')) return 'Updated just now';
    final matches = RegExp(r'(\d+)').firstMatch(lower);
    if (matches != null) {
      final numStr = matches.group(1);
      if (lower.contains('h')) {
        return 'Updated $numStr hours ago';
      } else if (lower.contains('d')) {
        return 'Updated $numStr days ago';
      }
    }
    return label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      const _TrustPill(
                        label: 'Verified with photo',
                        icon: Icons.camera_alt_outlined,
                        color: Color(0xFFE8F5E9),
                      ),
                      _TrustPill(
                        label: _formatFreshness(product.updatedAtLabel),
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFFF3F1EA),
                      ),
                      _TrustPill(
                        label:
                            '${_getStoreDistance(ref, product.lowestPriceStore).toStringAsFixed(1)} km away',
                        icon: Icons.place_rounded,
                        color: const Color(0xFFE3F2FD),
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

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double gridSize = 24.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OfferCarousel extends StatefulWidget {
  const _OfferCarousel();

  @override
  State<_OfferCarousel> createState() => _OfferCarouselState();
}

class _OfferCarouselState extends State<_OfferCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentIndex + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_OfferCardData> offers = [
      const _OfferCardData(
        title: 'Know The Best Price\nBefore You Leave',
        subtitle: 'Fresh prices from shoppers near you',
        icon: Icons.savings_rounded,
      ),
      const _OfferCardData(
        title: 'Save The Trip\nAnd The Dirhams',
        subtitle: 'Compare nearby stores before you go',
        icon: Icons.route_rounded,
      ),
      const _OfferCardData(
        title: 'Need A Price Checked?\nAsk The Community',
        subtitle: 'A real shopper can check the shelf',
        icon: Icons.add_a_photo_rounded,
      ),
    ];

    return Stack(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            itemCount: offers.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
                      child: FractionallySizedBox(
                        widthFactor: 0.58,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.title,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              offer.subtitle,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: -15,
                      child: SizedBox(
                        height: 120,
                        width: 130,
                        child: _OfferIconArt(icon: offer.icon),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 14,
          bottom: 22,
          child: Row(
            children: List.generate(
              offers.length,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _currentIndex == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferIconArt extends StatelessWidget {
  final IconData icon;

  const _OfferIconArt({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.56),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: AppTheme.forestDeep.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.forestDeep.withValues(alpha: 0.78),
            size: 40,
          ),
        ),
      ],
    );
  }
}

class _OfferCardData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OfferCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
