// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealsouk/core/widgets/avatar_image.dart';
import 'package:dealsouk/core/widgets/store_logo_avatar.dart';
import 'package:dealsouk/core/util/greeting.dart';
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
import 'package:dealsouk/l10n/app_localizations.dart';

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.asin(math.sqrt(a));
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Live in-place search: typing in the hero bar filters the catalog instantly
  // and swaps the home content for results — no second screen, no second bar.
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  String _sortBy = 'freshness'; // 'freshness', 'name', 'price'

  static const List<String> _dubaiAreas = [
    'Dubai Marina',
    'Downtown Dubai',
    'JLT',
    'Deira',
    'Business Bay',
    'Al Barsha',
    'Jumeirah',
    'Mirdif',
    'Al Quoz',
    'Silicon Oasis',
    'International City',
    'Dubai Silicon Oasis',
    'Al Nahda',
    'Oud Metha',
  ];

  Future<void> _checkHomeAreaSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final chosen = prefs.getBool('home_area_chosen_v1') ?? false;
    if (!chosen && mounted) {
      _showHomeAreaPromptSheet();
    }
  }

  void _showHomeAreaPromptSheet() {
    ref.read(navbarVisibleProvider.notifier).hide();
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Home Area',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select your preferred home area to compare supermarket prices near you.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _dubaiAreas.length,
                  itemBuilder: (context, index) {
                    final area = _dubaiAreas[index];
                    return ListTile(
                      title: Text(
                        area,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        // Persist the choice locally FIRST so the user is never
                        // trapped in this non-dismissible sheet if the network
                        // sync fails (e.g. backend cold-start, auth hiccup).
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('home_area_chosen_v1', true);
                        await prefs.setString('home_area_v1', area);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        // Best-effort DB sync — runs after the sheet is gone so a
                        // failure can't block the user. The value is cached above
                        // and will reconcile on the next successful profile call.
                        try {
                          await ref
                              .read(userProfileProvider.notifier)
                              .updateHomeArea(area);
                        } catch (_) {
                          // Swallowed intentionally: choice is saved locally.
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      ref.read(navbarVisibleProvider.notifier).show();
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(productsProvider.notifier).fetch();
      ref.read(cartProvider.notifier).loadPersistedCart();
      ref.read(dailyChallengeProvider.notifier).fetchToday();
      ref.read(priceRequestsProvider.notifier).fetchBoard();
      ref.read(myRequestsProvider.notifier).fetchMyRequests();

      // Check onboarding home area prompt
      await _checkHomeAreaSelection();

      // Request location permission and obtain user coordinates to calculate distances
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          if (mounted) {
            ref.read(userLocationProvider.notifier).state = position;
            final lat = position.latitude;
            final lng = position.longitude;
            final isInDubai =
                lat >= 24.80 && lat <= 25.45 && lng >= 54.90 && lng <= 55.65;
            if (isInDubai) {
              ref
                  .read(storesProvider.notifier)
                  .fetchNearby(lat: lat, lng: lng, radiusKm: 40);
            } else {
              // Sri Lanka or abroad: Fetch Dubai stores around Dubai center so catalog remains populated
              ref
                  .read(storesProvider.notifier)
                  .fetchNearby(lat: 25.2048, lng: 55.2708, radiusKm: 40);
            }
          }
        } else {
          // No location: fetch default Dubai stores
          ref
              .read(storesProvider.notifier)
              .fetchNearby(lat: 25.2048, lng: 55.2708, radiusKm: 40);
        }
      } catch (_) {
        ref
            .read(storesProvider.notifier)
            .fetchNearby(lat: 25.2048, lng: 55.2708, radiusKm: 40);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final products = ref.watch(productsProvider);
    final filterState = ref.watch(filterProvider);
    final tokens = ref.watch(userTokensProvider);
    final cartItems = ref.watch(cartProvider);
    final profile = ref.watch(userProfileProvider);
    final firstName = profile.name.split(' ').first;
    final dailyChallenge = ref.watch(dailyChallengeProvider);
    final settings = ref.watch(adminSettingsProvider);

    final greeting = switch (dayPartForHour(DateTime.now().hour)) {
      DayPart.morning => l.greeting,
      DayPart.afternoon => l.greetingAfternoon,
      DayPart.evening => l.greetingEvening,
    };

    final savedCount = cartItems.length;
    final bool searching = _searchQuery.trim().isNotEmpty;
    final filtered = products.where((p) {
      if (filterState.selectedCategory != 'All' &&
          p.category.toLowerCase() !=
              filterState.selectedCategory.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    final feedProducts =
        _filterByFreshness(filtered, filterState.freshnessFilter)..sort((a, b) {
          if (_sortBy == 'name') {
            return a.name.compareTo(b.name);
          } else if (_sortBy == 'price') {
            return a.lowestPrice.compareTo(b.lowestPrice);
          } else {
            return _freshnessMinutes(
              a.updatedAtLabel,
            ).compareTo(_freshnessMinutes(b.updatedAtLabel));
          }
        });

    // Categories defined for Dribbble layout with premium transparent 3D clay illustrations
    final List<_CategoryInfo> homeCategories = [
      _CategoryInfo(
        Icons.eco_rounded,
        l.homeCategoryFresh,
        'Fresh',
        const Color(0xFFE8F5E9), // Pastel green background
      ),
      _CategoryInfo(
        Icons.apple_rounded,
        l.homeCategoryFruits,
        'Fruits',
        const Color(0xFFFFEBEE), // Pastel pink background
      ),
      _CategoryInfo(
        Icons.fastfood_rounded,
        l.homeCategorySnack,
        'Snacks',
        const Color(0xFFFFF8E1), // Pastel yellow background
      ),
      _CategoryInfo(
        Icons.local_grocery_store_rounded,
        l.homeCategoryGrocery,
        'Dairy & Sweet',
        const Color(0xFFE0F2F1), // Pastel teal background
      ),
      _CategoryInfo(
        Icons.water_drop_rounded,
        l.homeCategoryOils,
        'Bakery',
        const Color(0xFFF3E5F5), // Pastel purple background
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
                              // Active User Avatar (Google photo / uploaded /
                              // on-device demo avatar, else a person icon).
                              Builder(
                                builder: (context) {
                                  final photo = avatarImageProvider(
                                    profile.avatarUrl,
                                  );
                                  return Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        width: 1.5,
                                      ),
                                      image: photo != null
                                          ? DecorationImage(
                                              image: photo,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: photo == null
                                        ? const Center(
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.homeGreetingLine(greeting, firstName),
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l.homeFindNearbyPrices,
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

                      // Live search bar — filters the catalog instantly in
                      // place. Solid white so it stays readable wherever the
                      // hero gradient fades to cream.
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: const Color(0xFFE8EEE4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: AppTheme.forestDeep,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                textInputAction: TextInputAction.search,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                cursorColor: AppTheme.forestDeep,
                                style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: l.homeSearchHint,
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (searching)
                              GestureDetector(
                                onTap: _clearSearch,
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () => _showFilterBottomSheet(context),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: AppTheme.forestDeep,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // While searching: replace the whole home feed with live results.
          if (searching)
            SliverToBoxAdapter(
              child: _SearchResultsPanel(
                query: _searchQuery.trim(),
                onClose: _clearSearch,
              ),
            )
          else ...[
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
                          l.homeCategories,
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
                          child: Text(
                            l.homeSeeAll,
                            style: const TextStyle(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
                          l.homeHowItWorks,
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
                      l.homeBestPricesNearYou,
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
                        l.homePricesCount(feedProducts.length),
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
                          l.homeNoPricesMatch,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.homeNoPricesHint,
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
                          label: Text(l.homeFindAnItem),
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
                      l.homeBrowseItems,
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
                      child: Text(
                        l.homeSeeAll,
                        style: const TextStyle(
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
                      l.homeFeaturedStores,
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/stores'),
                      child: Text(
                        l.homeSeeAll,
                        style: const TextStyle(
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
          ],

          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 110 + MediaQuery.of(context).padding.bottom,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    ref.read(navbarVisibleProvider.notifier).hide();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final filterState = ref.watch(filterProvider);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Text(
                      'Filter & Sort Products',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Category',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: filterState.selectedCategory,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.forestDeep,
                          ),
                        ),
                      ),
                      items:
                          [
                            'All',
                            'Fresh',
                            'Fruits',
                            'Snacks',
                            'Dairy & Sweet',
                            'Bakery',
                          ].map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(filterProvider.notifier).setCategory(val);
                          setBottomSheetState(() {});
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Freshness Filter',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: filterState.freshnessFilter,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.forestDeep,
                          ),
                        ),
                      ),
                      items: ['All', 'Under 6h', 'Under 24h', 'Under 72h'].map((
                        fresh,
                      ) {
                        return DropdownMenuItem(
                          value: fresh,
                          child: Text(fresh),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(filterProvider.notifier)
                              .setFreshnessFilter(val);
                          setBottomSheetState(() {});
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sort Products By',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Recently Updated'),
                      value: 'freshness',
                      groupValue: _sortBy,
                      activeColor: AppTheme.forestDeep,
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() => _sortBy = val);
                          setState(() {});
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Alphabetical (A-Z)'),
                      value: 'name',
                      groupValue: _sortBy,
                      activeColor: AppTheme.forestDeep,
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() => _sortBy = val);
                          setState(() {});
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Lowest Price'),
                      value: 'price',
                      groupValue: _sortBy,
                      activeColor: AppTheme.forestDeep,
                      onChanged: (val) {
                        if (val != null) {
                          setBottomSheetState(() => _sortBy = val);
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      ref.read(navbarVisibleProvider.notifier).show();
    });
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
    final l = AppLocalizations.of(context)!;
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
                Text(
                  l.homeEarnRewardsToday,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.homePriceSharesLeft(dailyCap - submissionsToday),
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
    final l = AppLocalizations.of(context)!;
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
                  l.homeDailyChallenge,
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
                  ? l.homeChallengeDoneBadge(challenge.bonusTokens)
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
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
                          l.homeDailyChallengeDetails,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestDeep,
                          ),
                        ),
                        Text(
                          challenge.completed
                              ? l.homeChallengeFinished
                              : l.homeChallengeEarnBonus,
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
                iconColor: AppTheme.forestDeep,
                title: l.homeTargetSupermarket,
                value: challenge.targetStore == 'Any'
                    ? l.homeAnySupermarketChain
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
                          const Icon(
                            Icons.query_stats_rounded,
                            size: 18,
                            color: AppTheme.forestDeep,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.homeYourProgress,
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        l.homeProgressPrices(
                          challenge.progressCount,
                          challenge.targetCount,
                        ),
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
                title: l.homeRewardBonus,
                value: l.homeRewardBonusValue(challenge.bonusTokens),
                valueColor: const Color(0xFFC77C02),
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
                            l.homeCompletedRewardClaimed,
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
                        l.homeStartChallengeNow,
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
}

class _FreshnessChipRow extends ConsumerWidget {
  final String selected;

  const _FreshnessChipRow({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    const filters = ['All', 'Under 6h', 'Under 24h', 'Under 72h'];
    String labelFor(String filter) {
      switch (filter) {
        case 'Under 6h':
          return l.homeFreshnessUnder6h;
        case 'Under 24h':
          return l.homeFreshnessUnder24h;
        case 'Under 72h':
          return l.homeFreshnessUnder72h;
        default:
          return l.homeFreshnessAll;
      }
    }

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
                labelFor(filter),
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
    final pos = ref.read(userLocationProvider);
    final stores = ref.read(storesProvider);
    final match = stores.where(
      (s) => s.name.toLowerCase().contains(storeName.toLowerCase()),
    );
    if (match.isNotEmpty) {
      final store = match.first;
      if (pos != null) {
        return _haversineKm(pos.latitude, pos.longitude, store.lat, store.lng);
      }
      return store.distance;
    }
    // Fallback to a stable hash-based mock distance
    return (storeName.hashCode % 15 + 8) / 10.0; // between 0.8 km and 2.2 km
  }

  String _formatFreshness(AppLocalizations l, String label) {
    final lower = label.toLowerCase();
    if (lower.contains('just now')) return l.homeUpdatedJustNow;
    final matches = RegExp(r'(\d+)').firstMatch(lower);
    if (matches != null) {
      final numStr = matches.group(1);
      if (lower.contains('h')) {
        return l.homeUpdatedHoursAgo(numStr ?? '');
      } else if (lower.contains('d')) {
        return l.homeUpdatedDaysAgo(numStr ?? '');
      }
    }
    return label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
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
                        label: l.homeVerifiedWithPhoto,
                        icon: Icons.camera_alt_outlined,
                        color: const Color(0xFFE8F5E9),
                      ),
                      _TrustPill(
                        label: _formatFreshness(l, product.updatedAtLabel),
                        icon: Icons.schedule_rounded,
                        color: const Color(0xFFF3F1EA),
                      ),
                      _TrustPill(
                        label: l.homeKmAway(
                          _getStoreDistance(
                            ref,
                            product.lowestPriceStore,
                          ).toStringAsFixed(1),
                        ),
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

class _FeaturedStoreCard extends ConsumerWidget {
  final Store store;

  const _FeaturedStoreCard({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    // Real distance from the user's live GPS (same haversine the map uses),
    // falling back to the backend's Dubai-relative value only when location is
    // unknown. Whole km when far away (abroad testing), one decimal nearby.
    final pos = ref.read(userLocationProvider);
    final km = pos != null
        ? _haversineKm(pos.latitude, pos.longitude, store.lat, store.lng)
        : store.distance;
    final distLabel = km >= 100 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
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
                  PositionedDirectional(
                    start: 14,
                    bottom: 0,
                    // Real chain logo (bundled asset → backend → initial), the
                    // same resolution the store map uses. White ring keeps it
                    // readable against the forest-green awning.
                    child: StoreLogoAvatar(
                      name: store.name,
                      color: AppTheme.forestMid,
                      size: 40,
                      padding: 5,
                      borderColor: Colors.white,
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
                        l.homeStoreDistancePrices(distLabel, store.pricesCount),
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
    final l = AppLocalizations.of(context)!;
    final List<_OfferCardData> offers = [
      _OfferCardData(
        title: l.homeOffer1Title,
        subtitle: l.homeOffer1Subtitle,
        icon: Icons.savings_rounded,
      ),
      _OfferCardData(
        title: l.homeOffer2Title,
        subtitle: l.homeOffer2Subtitle,
        icon: Icons.route_rounded,
      ),
      _OfferCardData(
        title: l.homeOffer3Title,
        subtitle: l.homeOffer3Subtitle,
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
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
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
                    ),
                    // Vertically centered, pinned to the trailing edge: right
                    // in English, auto-mirrored to the left in Arabic. Spanning
                    // top:0/bottom:0 lets Center balance it within the card so
                    // the circle is fully visible instead of clipped at the
                    // bottom-right corner.
                    PositionedDirectional(
                      end: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(child: _OfferIconArt(icon: offer.icon)),
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
                padding: const EdgeInsetsDirectional.only(end: 5),
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

/// Live in-place search results shown directly under the home search bar.
/// Filters the catalog as the user types; if nothing matches, offers a
/// one-tap "request this item" path so the search never dead-ends.
class _SearchResultsPanel extends ConsumerWidget {
  const _SearchResultsPanel({required this.query, required this.onClose});

  final String query;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final products = ref.watch(productsProvider);
    final requestCost = ref.watch(adminSettingsProvider).requestCostTokens;
    final q = query.toLowerCase();

    final matches = products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q),
        )
        .toList();

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              l.searchEmptyQueryTitle(query),
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.searchEmptyQuerySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showItemRequestSheet(
                context,
                ref,
                query,
                requestCost,
                onDone: onClose,
              ),
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: Text(l.searchAskShoppersToCheck),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2),
            child: Text(
              l.homeSearchResultsCount(matches.length),
              style: GoogleFonts.fredoka(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
          ...matches.map(
            (product) => GestureDetector(
              onTap: () => context.push('/product/${product.id}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EEE4)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: SoukProductVisual(
                        product: product,
                        fit: BoxFit.cover,
                        borderRadius: 12,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 3),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SoukPrice(product.lowestPrice, size: 14.5),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Always offer the request path, even when results exist.
          Center(
            child: TextButton.icon(
              onPressed: () => _showItemRequestSheet(
                context,
                ref,
                query,
                requestCost,
                onDone: onClose,
              ),
              icon: const Icon(Icons.add_comment_outlined, size: 16),
              label: Text(l.searchAskShoppersToCheck),
              style: TextButton.styleFrom(foregroundColor: AppTheme.forestDeep),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet that lets a shopper ask the community to check a price.
/// Prefilled with whatever they typed in the search bar.
void _showItemRequestSheet(
  BuildContext context,
  WidgetRef ref,
  String initialQuery,
  int requestCost, {
  VoidCallback? onDone,
}) {
  final formKey = GlobalKey<FormState>();
  String productName = initialQuery;
  String selectedStore = 'Carrefour';

  const List<String> stores = [
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

  ref.read(navbarVisibleProvider.notifier).hide();

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      final l = AppLocalizations.of(context)!;
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
                l.searchRequestPriceCheckTitle,
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.searchRequestPriceCheckDescription(requestCost),
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                initialValue: productName,
                decoration: InputDecoration(
                  labelText: l.searchItemNameLabel,
                  hintText: l.searchItemNameHint,
                ),
                onChanged: (val) => productName = val,
                validator: (val) => val == null || val.trim().isEmpty
                    ? l.searchEnterProductName
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStore,
                decoration: InputDecoration(
                  labelText: l.searchChooseSupermarket,
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
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final notifier = ref.read(myRequestsProvider.notifier);
                    final messenger = ScaffoldMessenger.of(context);
                    await notifier.addPriceRequest(
                      productName: productName.trim(),
                      storeName: selectedStore,
                      requestCostTokens: requestCost,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    final err = notifier.lastError;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(err ?? l.searchRequestPosted),
                        backgroundColor: err != null
                            ? Colors.red.shade700
                            : AppTheme.forestDeep,
                      ),
                    );
                    if (err == null) onDone?.call();
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
                child: Text(
                  l.searchAskForThisPrice,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    ref.read(navbarVisibleProvider.notifier).show();
  });
}
