import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dealsouk/core/widgets/avatar_image.dart';
import 'package:dealsouk/core/util/greeting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/util/geo_utils.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/presentation/discover_strings.dart';
import 'package:dealsouk/features/products/presentation/product_widgets.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/products/presentation/request_sheet.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/features/requests/presentation/request_board_view.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/saved/presentation/saved_providers.dart';
import 'package:dealsouk/features/stores/domain/store.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/features/tokens/domain/daily_challenge.dart';
import 'package:dealsouk/features/tokens/presentation/tokens_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.bootstrap = true});

  /// Loads products, location and the home-area prompt on start. Screenshot
  /// tests turn this off and supply data through provider overrides.
  final bool bootstrap;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Live in-place search: typing in the search bar filters the catalog
  // instantly and swaps the home content for results.
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
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Home Area',
                  style: AppFonts.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select your preferred home area to compare supermarket prices near you.',
                  style: AppFonts.body(
                    fontSize: 15,
                    color: AppTheme.textLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _dubaiAreas.length,
                    itemBuilder: (context, index) {
                      final area = _dubaiAreas[index];
                      return ListTile(
                        minVerticalPadding: 14,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppTheme.forestDeep,
                        ),
                        title: Text(
                          area,
                          style: AppFonts.body(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          // Persist the choice locally FIRST so the user is
                          // never trapped in this non-dismissible sheet if the
                          // network sync fails (backend cold start, auth).
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('home_area_chosen_v1', true);
                          await prefs.setString('home_area_v1', area);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          // Best-effort DB sync after the sheet is gone; the
                          // value is cached and reconciles on the next profile
                          // call if this fails.
                          try {
                            await ref
                                .read(userProfileProvider.notifier)
                                .updateHomeArea(area);
                          } catch (_) {}
                        },
                      );
                    },
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

  @override
  void initState() {
    super.initState();
    if (!widget.bootstrap) return;
    Future.microtask(() async {
      ref.read(productsProvider.notifier).fetch();
      ref.read(cartProvider.notifier).loadPersistedCart();
      ref.read(dailyChallengeProvider.notifier).fetchToday();
      ref.read(priceRequestsProvider.notifier).fetchBoard();
      ref.read(myRequestsProvider.notifier).fetchMyRequests();

      // Check onboarding home area prompt
      await _checkHomeAreaSelection();

      // Request location permission and obtain user coordinates to calculate
      // distances.
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
              // Abroad: fetch Dubai stores around the centre so the catalog
              // stays populated.
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

  List<Product> _feed(List<Product> products, FilterState filterState) {
    final filtered = products.where((p) {
      return filterState.selectedCategory == 'All' ||
          p.category.toLowerCase() ==
              filterState.selectedCategory.toLowerCase();
    }).toList();
    return filterByFreshness(filtered, filterState.freshnessFilter)
      ..sort((a, b) {
        if (_sortBy == 'name') return a.name.compareTo(b.name);
        if (_sortBy == 'price') return a.lowestPrice.compareTo(b.lowestPrice);
        return (a.hoursAgo ?? kNoFreshnessHours).compareTo(
          b.hoursAgo ?? kNoFreshnessHours,
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final products = ref.watch(productsProvider);
    final productsLoad = ref.watch(productsLoadProvider);
    final filterState = ref.watch(filterProvider);
    final tokens = ref.watch(userTokensProvider);
    final profile = ref.watch(userProfileProvider);
    final dailyChallenge = ref.watch(dailyChallengeProvider);
    final settings = ref.watch(adminSettingsProvider);
    final savedCount = ref.watch(savedProductsProvider).length;
    final stores = ref.watch(storesProvider);

    final firstName = profile.name.split(' ').first;
    final greeting = switch (dayPartForHour(DateTime.now().hour)) {
      DayPart.morning => l.greeting,
      DayPart.afternoon => l.greetingAfternoon,
      DayPart.evening => l.greetingEvening,
    };
    final greetingLine = l.homeGreetingLine(greeting, firstName);
    final searching = _searchQuery.trim().isNotEmpty;
    final feed = _feed(products, filterState);

    final sections = _Sections(
      l: l,
      feed: feed,
      allProducts: products,
      load: productsLoad,
      filter: filterState,
      storeList: stores,
      onRetry: () => ref.read(productsProvider.notifier).fetch(),
    );

    final rewards = _RewardsCard(
      tokens: tokens,
      submissionsToday: profile.submissionsToday,
      dailyCap: settings.dailySubmissionCap,
    );
    final challenge = _DailyChallengeCard(challenge: dailyChallenge);
    final share = _ShareCard();

    Widget body;
    if (context.isExpanded) {
      body = SingleChildScrollView(
        child: PageContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: DsPhotoBanner(
                        asset: DsPhotos.marina,
                        height: 280,
                        radius: 20,
                        decodeWidth: 1400,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                greetingLine,
                                style: AppFonts.display(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.homeFindNearbyPrices,
                              style: AppFonts.body(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          challenge,
                          const SizedBox(height: 14),
                          share,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                DsSectionHeader(l.homeCategories),
                const SizedBox(height: 8),
                _CategoryChips(),
                const SizedBox(height: 20),
                sections.bestPrices(context, ref, columns: true),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _PhotoPromo(index: 1, l: l)),
                    const SizedBox(width: 24),
                    Expanded(child: _PhotoPromo(index: 2, l: l)),
                  ],
                ),
                const SizedBox(height: 28),
                sections.stores(context, ref, columns: true),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: rewards),
                    const SizedBox(width: 24),
                    const Expanded(child: RequestBoardView()),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final wide = context.isMedium;
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: PageContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _Header(
                      greeting: greetingLine,
                      subtitle: l.homeFindNearbyPrices,
                      avatarUrl: profile.avatarUrl,
                      initial: firstName,
                      savedCount: savedCount,
                    ),
                    const SizedBox(height: 14),
                    _SearchBar(
                      controller: _searchController,
                      focus: _searchFocus,
                      searching: searching,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onClear: _clearSearch,
                      onFilter: () => _showFilterBottomSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (searching)
            SliverToBoxAdapter(
              child: PageContainer(
                child: _SearchResultsPanel(
                  query: _searchQuery.trim(),
                  onClose: _clearSearch,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: PageContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 14),
                    const _OfferCarousel(),
                    const SizedBox(height: 14),
                    share,
                    const SizedBox(height: 16),
                    _CategoryRow(),
                    const SizedBox(height: 20),
                    sections.bestPrices(context, ref, columns: wide),
                    const SizedBox(height: 16),
                    challenge,
                    const SizedBox(height: 12),
                    rewards,
                    const SizedBox(height: 16),
                    const RequestBoardView(),
                    const SizedBox(height: 16),
                    DsBanner(
                      l.homeHowItWorks,
                      icon: Icons.help_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    sections.stores(context, ref, columns: wide),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(backgroundColor: AppTheme.background, body: body);
  }

  void _showFilterBottomSheet(BuildContext context) {
    ref.read(navbarVisibleProvider.notifier).hide();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final l = AppLocalizations.of(context)!;
            final s = DiscoverStrings.of(context);
            final filterState = ref.watch(filterProvider);
            const categories = [
              'All',
              'Fresh',
              'Fruits',
              'Snacks',
              'Dairy & Sweet',
              'Bakery',
            ];
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: StatefulBuilder(
                  builder: (context, setSheet) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.filters,
                        style: AppFonts.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.category,
                        style: AppFonts.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in categories)
                            DsChip(
                              label: c == 'All' ? s.all : c,
                              selected: filterState.selectedCategory == c,
                              onTap: () => ref
                                  .read(filterProvider.notifier)
                                  .setCategory(c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.freshness,
                        style: AppFonts.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final f in freshnessFilters)
                            DsChip(
                              label: freshnessFilterLabel(l, f),
                              selected: filterState.freshnessFilter == f,
                              onTap: () => ref
                                  .read(filterProvider.notifier)
                                  .setFreshnessFilter(f),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.sortBy,
                        style: AppFonts.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DsSegmented(
                        labels: [s.sortFreshest, 'A–Z', s.sortLowest],
                        selected: const [
                          'freshness',
                          'name',
                          'price',
                        ].indexOf(_sortBy),
                        onChanged: (i) {
                          setSheet(() {});
                          setState(
                            () => _sortBy = const [
                              'freshness',
                              'name',
                              'price',
                            ][i],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      DsButton(
                        label: 'Apply',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
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

// ── Sections shared by the phone and desktop layouts ────────────────────────

class _Sections {
  _Sections({
    required this.l,
    required this.feed,
    required this.allProducts,
    required this.load,
    required this.filter,
    required this.storeList,
    required this.onRetry,
  });

  final AppLocalizations l;
  final List<Product> feed;
  final List<Product> allProducts;
  final ProductsLoadState load;
  final FilterState filter;
  final List<Store> storeList;
  final VoidCallback onRetry;

  /// "Best prices near you": freshness chips and the product list or grid.
  Widget bestPrices(
    BuildContext context,
    WidgetRef ref, {
    required bool columns,
  }) {
    final shown = feed.take(columns ? 4 : 8).toList();
    final chips = DsChipRow(
      chips: [
        for (final f in freshnessFilters)
          DsChip(
            label: freshnessFilterLabel(l, f),
            selected: filter.freshnessFilter == f,
            onTap: () =>
                ref.read(filterProvider.notifier).setFreshnessFilter(f),
          ),
      ],
    );
    final title = Semantics(
      header: true,
      child: Text(
        l.homeBestPricesNearYou,
        style: AppFonts.display(
          fontSize: columns ? 24 : 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
    );

    Widget content;
    if (feed.isEmpty &&
        allProducts.isEmpty &&
        load == ProductsLoadState.error) {
      content = DsEmptyState(
        icon: Icons.cloud_off_rounded,
        tone: DsEmptyTone.error,
        title: l.homeLoadError,
        message: l.homeLoadErrorHint,
        primaryLabel: l.retry,
        onPrimary: onRetry,
      );
    } else if (feed.isEmpty && allProducts.isEmpty) {
      content = const Column(
        children: [
          DsListRowSkeleton(),
          SizedBox(height: 12),
          DsListRowSkeleton(),
          SizedBox(height: 12),
          DsListRowSkeleton(),
        ],
      );
    } else if (feed.isEmpty) {
      content = DsEmptyState(
        icon: Icons.search_off_rounded,
        title: l.homeNoPricesMatch,
        message: l.homeNoPricesHint,
        primaryLabel: l.homeFindAnItem,
        onPrimary: () => context.push('/search'),
      );
    } else if (columns) {
      content = AdaptiveGrid(
        minTileWidth: 230,
        mainAxisExtent: 340,
        children: [for (final p in shown) ProductTileCard(product: p)],
      );
    } else {
      content = Column(
        children: [
          for (final p in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductRowCard(product: p),
            ),
          TextButton(
            onPressed: () {
              ref.read(filterProvider.notifier).reset();
              context.push('/search');
            },
            child: Text(l.homeSeeAll),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.sizeOf(context).width >= Breakpoints.expanded)
          Row(
            children: [
              Expanded(child: title),
              SizedBox(width: 420, child: chips),
            ],
          )
        else ...[
          title,
          const SizedBox(height: 10),
          chips,
        ],
        const SizedBox(height: 14),
        content,
      ],
    );
  }

  /// Nearby supermarkets.
  Widget stores(BuildContext context, WidgetRef ref, {required bool columns}) {
    if (storeList.isEmpty) return const SizedBox.shrink();
    final pos = ref.read(userLocationProvider);
    final cards = [
      for (final s in storeList.take(columns ? 4 : 3))
        _StoreCard(store: s, pos: pos),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(
          l.homeFeaturedStores,
          actionLabel: l.homeSeeAll,
          onAction: () => context.go('/stores'),
        ),
        const SizedBox(height: 8),
        if (columns)
          AdaptiveGrid(minTileWidth: 260, mainAxisExtent: 92, children: cards)
        else
          for (final c in cards)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: c),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.pos});

  final Store store;
  final Position? pos;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Real distance from live GPS, falling back to the backend's value.
    final km = pos != null
        ? haversineKm(pos!.latitude, pos!.longitude, store.lat, store.lng)
        : store.distance;
    final dist = km >= 100 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    return DsCard(
      onTap: () => context.go('/stores'),
      semanticLabel: store.name,
      child: Row(
        children: [
          DsStoreLogo(store.name, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.homeStoreDistancePrices(dist, store.pricesCount),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 13, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header, search and promotions ────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.subtitle,
    required this.avatarUrl,
    required this.initial,
    required this.savedCount,
  });

  final String greeting;
  final String subtitle;
  final String avatarUrl;
  final String initial;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final photo = avatarImageProvider(avatarUrl);
    return Row(
      children: [
        photo != null
            ? CircleAvatar(radius: 24, backgroundImage: photo)
            : DsAvatar(initial, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  greeting,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            DsIconButton(
              icon: Icons.bookmark_border_rounded,
              semanticLabel: l.searchMyList,
              color: AppTheme.forestDeep,
              onPressed: () => context.go('/saved'),
            ),
            if (savedCount > 0)
              PositionedDirectional(
                end: -2,
                top: -2,
                child: DsCountBadge(savedCount),
              ),
          ],
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focus,
    required this.searching,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = DiscoverStrings.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            textField: true,
            label: l.homeSearchHint,
            child: TextField(
              controller: controller,
              focusNode: focus,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              style: AppFonts.body(fontSize: 17, color: AppTheme.ink),
              decoration: InputDecoration(
                hintText: l.homeSearchHint,
                hintMaxLines: 1,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search_rounded, size: 24),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: onClear,
                      )
                    : IconButton(
                        tooltip: s.filters,
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: AppTheme.forestDeep,
                        ),
                        onPressed: onFilter,
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.line,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.forestDeep,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        DsIconButton(
          icon: Icons.qr_code_scanner_rounded,
          semanticLabel: l.searchScanBarcode,
          filled: true,
          size: 56,
          onPressed: () => context.push('/scan-barcode'),
        ),
      ],
    );
  }
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

  static const _count = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    // No auto-advance for people who asked the system to reduce motion.
    if (MediaQuery.disableAnimationsOf(context)) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Guard against firing on a disposed PageController (H-17).
      if (!mounted || !_pageController.hasClients) return;
      _pageController.animateToPage(
        (_currentIndex + 1) % _count,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
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
    final offers = [
      (l.homeOffer1Title, l.homeOffer1Subtitle, DsPhotos.shelf),
      (l.homeOffer2Title, l.homeOffer2Subtitle, DsPhotos.creek),
      (l.homeOffer3Title, l.homeOffer3Subtitle, DsPhotos.market),
    ];
    return Stack(
      children: [
        SizedBox(
          height:
              176 *
              (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.8),
          child: PageView.builder(
            controller: _pageController,
            itemCount: offers.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final o = offers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: DsPhotoBanner(
                  asset: o.$3,
                  fadeFromStart: true,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                  childAlignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: 0.78,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.$1.replaceAll('\n', ' '),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.display(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          o.$2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.body(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        PositionedDirectional(
          start: 20,
          bottom: 12,
          child: Row(
            children: [
              for (var i = 0; i < offers.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _currentIndex == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoPromo extends StatelessWidget {
  const _PhotoPromo({required this.index, required this.l});

  final int index;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final title = index == 1 ? l.homeOffer2Title : l.homeOffer3Title;
    final sub = index == 1 ? l.homeOffer2Subtitle : l.homeOffer3Subtitle;
    return DsPhotoBanner(
      asset: index == 1 ? DsPhotos.shelf : DsPhotos.market,
      height: 150,
      fadeFromStart: true,
      padding: const EdgeInsets.all(24),
      childAlignment: AlignmentDirectional.centerStart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.replaceAll('\n', ' '),
            style: AppFonts.display(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(sub, style: AppFonts.body(fontSize: 15, color: Colors.white)),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = DiscoverStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warnLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.seenPrice,
                  style: AppFonts.display(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.seenPriceHint,
                  style: AppFonts.body(fontSize: 13, color: AppTheme.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DsButton(
            label: s.share,
            style: DsButtonStyle.accent,
            compact: true,
            expanded: false,
            onPressed: () => context.push('/submit-price'),
          ),
        ],
      ),
    );
  }
}

// ── Categories ──────────────────────────────────────────────────────────────

class _CategoryInfo {
  final IconData icon;
  final String label;
  final String category;
  final Color color;

  const _CategoryInfo(this.icon, this.label, this.category, this.color);
}

List<_CategoryInfo> _categories(AppLocalizations l) => [
  _CategoryInfo(
    Icons.eco_rounded,
    l.homeCategoryFresh,
    'Fresh',
    const Color(0xFFDDF1EC),
  ),
  _CategoryInfo(
    Icons.apple_rounded,
    l.homeCategoryFruits,
    'Fruits',
    const Color(0xFFFCE7D2),
  ),
  _CategoryInfo(
    Icons.cookie_rounded,
    l.homeCategorySnack,
    'Snacks',
    const Color(0xFFF9E0DC),
  ),
  _CategoryInfo(
    Icons.shopping_basket_rounded,
    l.homeCategoryGrocery,
    'Dairy & Sweet',
    const Color(0xFFEFE6D6),
  ),
  _CategoryInfo(
    Icons.water_drop_rounded,
    l.homeCategoryOils,
    'Bakery',
    const Color(0xFFE2E8F5),
  ),
];

/// Phone: five round shortcuts that open Search on that category.
class _CategoryRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in _categories(l))
          Expanded(
            child: Semantics(
              button: true,
              label: c.label,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ref.read(filterProvider.notifier).setCategory(c.category);
                  context.push('/search');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: c.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Icon(
                          c.icon,
                          color: AppTheme.forestDeep,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          c.label,
                          style: AppFonts.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Desktop: chips that filter the feed in place.
class _CategoryChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final s = DiscoverStrings.of(context);
    final selected = ref.watch(filterProvider).selectedCategory;
    return DsChipRow(
      chips: [
        DsChip(
          label: s.all,
          selected: selected == 'All',
          onTap: () => ref.read(filterProvider.notifier).setCategory('All'),
        ),
        for (final c in _categories(l))
          DsChip(
            label: c.label,
            selected: selected == c.category,
            onTap: () =>
                ref.read(filterProvider.notifier).setCategory(c.category),
          ),
      ],
    );
  }
}

// ── Rewards and challenge ───────────────────────────────────────────────────

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({
    required this.tokens,
    required this.submissionsToday,
    required this.dailyCap,
  });

  final int tokens;
  final int submissionsToday;
  final int dailyCap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: AppTheme.forestDeep,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/leaderboard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.limeAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.homeEarnRewardsToday,
                      style: AppFonts.display(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.homePriceSharesLeft(
                        (dailyCap - submissionsToday).clamp(0, dailyCap),
                      ),
                      style: AppFonts.body(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: tokens.toDouble()),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '${value.round()}',
                  style: AppFonts.display(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final progress = challenge.targetCount == 0
        ? 0.0
        : challenge.progressCount / challenge.targetCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warnLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.homeDailyChallenge,
                    style: AppFonts.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ),
              DsTag(
                challenge.completed
                    ? l.homeChallengeDoneBadge(challenge.bonusTokens)
                    : l.homeRewardBonusValue(challenge.bonusTokens),
                tone: DsTone.warn,
                icon: Icons.token_rounded,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            challenge.description,
            style: AppFonts.body(
              fontSize: 15,
              height: 1.35,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (challenge.completed)
            DsBanner(l.homeCompletedRewardClaimed, tone: DsBannerTone.good)
          else ...[
            DsProgressBar(value: progress, color: AppTheme.limeAccent),
            const SizedBox(height: 6),
            Text(
              l.homeProgressPrices(
                challenge.progressCount,
                challenge.targetCount,
              ),
              style: AppFonts.body(fontSize: 13, color: AppTheme.ink),
            ),
            const SizedBox(height: 12),
            DsButton(
              label: l.homeStartChallengeNow,
              style: DsButtonStyle.accent,
              onPressed: () => context.push('/submit-price'),
            ),
          ],
        ],
      ),
    );
  }
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

    void ask() =>
        showItemRequestSheet(context, ref, query, requestCost, onDone: onClose);

    if (matches.isEmpty) {
      return DsEmptyState(
        icon: Icons.search_off_rounded,
        title: l.searchEmptyQueryTitle(query),
        message: l.searchEmptyQuerySubtitle,
        primaryLabel: l.searchAskShoppersToCheck,
        onPrimary: ask,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l.homeSearchResultsCount(matches.length),
              style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
            ),
          ),
          for (final p in matches)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductRowCard(product: p),
            ),
          DsButton(
            label: l.searchAskShoppersToCheck,
            style: DsButtonStyle.secondary,
            icon: Icons.add_comment_outlined,
            onPressed: ask,
          ),
        ],
      ),
    );
  }
}
