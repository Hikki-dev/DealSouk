import 'package:dealsouk/core/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/shell_layout.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart' show DirectionalIcon;
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/products/data/products_service.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/domain/product_price_history.dart';
import 'package:dealsouk/features/products/domain/store_product_price.dart';
import 'package:dealsouk/features/products/presentation/discover_strings.dart';
import 'package:dealsouk/features/products/presentation/product_widgets.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/saved/presentation/saved_providers.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  /// Test hook: skips the network fetch and shows these rows instead.
  final List<StoreProductPrice>? debugPrices;
  final List<ProductPriceHistory>? debugHistory;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.debugPrices,
    this.debugHistory,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  List<StoreProductPrice> _storePrices = [];
  List<ProductPriceHistory> _priceHistory = [];

  double _getStoreDistance(String storeId, String storeName) {
    final stores = ref.read(storesProvider);
    final match = stores.where(
      (s) =>
          s.id == storeId ||
          s.name.toLowerCase().contains(storeName.toLowerCase()),
    );
    if (match.isNotEmpty) {
      return match.first.distance;
    }
    return (storeName.hashCode % 15 + 8) / 10.0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.debugPrices != null) {
      _storePrices = widget.debugPrices!;
      _priceHistory = widget.debugHistory ?? [];
      return;
    }
    Future.microtask(() async {
      try {
        final prices = await productsService.getPrices(widget.productId);
        final history = await productsService.getHistory(widget.productId);
        if (mounted) {
          setState(() {
            _storePrices = prices;
            _priceHistory = history;
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _requestPrice(Product product) async {
    final l = AppLocalizations.of(context)!;
    final requestCost = ref.read(adminSettingsProvider).requestCostTokens;
    final notifier = ref.read(myRequestsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final storeName =
        product.lowestPriceStore.isNotEmpty && product.lowestPriceStore != '—'
        ? product.lowestPriceStore
        : 'Carrefour';
    await notifier.addPriceRequest(
      productName: product.name,
      storeName: storeName,
      requestCostTokens: requestCost,
    );
    final err = notifier.lastError;
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? l.productRequestPriceConfirmation),
        backgroundColor: err != null ? AppTheme.badText : AppTheme.forestDeep,
      ),
    );
  }

  void _savePrice(Product product, String coreName) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (auth.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.productSignInToSavePrices),
          action: SnackBarAction(
            label: l.productSignInAction,
            textColor: Colors.white,
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/welcome');
            },
          ),
          backgroundColor: AppTheme.forestDeep,
        ),
      );
      return;
    }
    ref.read(cartProvider.notifier).addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.forestDeep,
        content: Text(
          l.productSavedForComparison(coreName),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: l.productViewAction,
          textColor: Colors.white,
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  void _reportPrice(Product product, StoreProductPrice sp, int flagCount) {
    final l = AppLocalizations.of(context)!;
    ref
        .read(flaggedPricesProvider.notifier)
        .flagPrice(product.id, sp.storeName, product.name, sp.price);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          flagCount + 1 >= 3
              ? l.productReportHiddenMessage
              : l.productReportPendingMessage,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = DiscoverStrings.of(context);
    final products = ref.watch(productsProvider);
    final isSaved = ref.watch(savedProductsProvider).contains(widget.productId);

    final found = products.where((p) => p.id == widget.productId);
    final product = found.isNotEmpty
        ? found.first
        : Product(
            id: 'unknown',
            name: s.notFound,
            brand: '',
            packSize: '',
            category: 'Fresh',
            lowestPrice: 0.0,
            lowestPriceStore: '',
            updatedAtLabel: '',
          );

    final sortedPrices = List<StoreProductPrice>.from(_storePrices)
      ..sort((a, b) => a.price.compareTo(b.price));
    final selectedPrice = sortedPrices.isNotEmpty
        ? sortedPrices.first.price
        : product.lowestPrice;
    final recommended = products.where((p) => p.id != product.id).toList();
    final coreName = coreProductName(product);

    final heart = DsIconButton(
      icon: isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      semanticLabel: isSaved
          ? l.productRemoveFromFavourites
          : l.productAddToFavourites,
      color: AppTheme.redAccent,
      onPressed: () =>
          ref.read(savedProductsProvider.notifier).toggle(widget.productId),
    );

    if (product.id == 'unknown') {
      final empty = Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const DirectionalIcon(Icons.arrow_back_ios_new_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
          title: Text(l.productDetailsTitle),
        ),
        body: DsEmptyState(
          icon: Icons.search_off_rounded,
          title: s.notFound,
          primaryLabel: l.homeFindAnItem,
          onPrimary: () => context.go('/search'),
        ),
      );
      return empty;
    }

    final cheapest = sortedPrices.isNotEmpty ? sortedPrices.first : null;
    final cheapestStore = cheapest?.storeName ?? product.lowestPriceStore;
    final cheapestKm = cheapest != null
        ? _getStoreDistance(cheapest.storeId, cheapest.storeName)
        : storeDistanceKm(ref, product.lowestPriceStore);
    final cheapestHours = cheapest?.submittedHoursAgo ?? product.hoursAgo;

    final cheapestCard = _CheapestCard(
      label: s.cheapestNow,
      store: cheapestStore,
      distanceKm: cheapestKm,
      hoursAgo: cheapestHours,
      price: selectedPrice,
      showLogo: context.isWide,
    );

    final compare = _CompareSection(
      product: product,
      prices: sortedPrices,
      cheapestPrice: selectedPrice,
      distanceFor: _getStoreDistance,
      onReport: _reportPrice,
      table: context.isExpanded,
    );

    final history = DsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.productPriceHistory90Day,
            style: AppFonts.display(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          _PriceHistoryPanel(history: _priceHistory),
        ],
      ),
    );

    final alsoLike = recommended.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsSectionHeader(l.productYouMayAlsoLike),
              const SizedBox(height: 8),
              SizedBox(
                height: 330,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommended.length.clamp(0, 8),
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 220,
                    child: ProductTileCard(product: recommended[i]),
                  ),
                ),
              ),
            ],
          );

    final actionButtons = [
      DsButton(
        label: l.productSavePrice,
        icon: Icons.bookmark_border_rounded,
        expanded: false,
        onPressed: () => _savePrice(product, coreName),
      ),
      DsButton(
        label: l.productRequestThisPrice,
        style: DsButtonStyle.secondary,
        icon: Icons.refresh_rounded,
        expanded: false,
        onPressed: () => _requestPrice(product),
      ),
    ];

    final Widget page;
    if (context.isWide) {
      final imageWidth = context.isExpanded ? 380.0 : 280.0;
      page = Scaffold(
        backgroundColor: AppTheme.background,
        body: SingleChildScrollView(
          child: PageContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Breadcrumb(
                    home: l.home,
                    category: product.category,
                    name: coreName,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: imageWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: DsProductThumb(
                                imageUrl: product.imageUrl,
                                radius: 20,
                                padding: 16,
                                semanticLabel: coreName,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DsTag(
                              s.shopperPhoto,
                              tone: DsTone.teal,
                              icon: Icons.photo_camera_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _Title(
                                    name: coreName,
                                    product: product,
                                    storeCount: sortedPrices.length,
                                    big: true,
                                  ),
                                ),
                                heart,
                              ],
                            ),
                            const SizedBox(height: 16),
                            cheapestCard,
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: actionButtons,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l.productCompareStorePrices,
                              style: AppFonts.display(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            compare,
                            const SizedBox(height: 20),
                            history,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  alsoLike,
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      page = Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const DirectionalIcon(Icons.arrow_back_ios_new_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
          title: Text(l.productDetailsTitle),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: heart,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsProductThumb(
                  imageUrl: product.imageUrl,
                  size: 112,
                  radius: 18,
                  padding: 6,
                  semanticLabel: coreName,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Title(
                    name: coreName,
                    product: product,
                    storeCount: sortedPrices.length,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            cheapestCard,
            const SizedBox(height: 20),
            Text(
              l.productCompareStorePrices,
              style: AppFonts.display(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            compare,
            const SizedBox(height: 16),
            history,
            const SizedBox(height: 24),
            alsoLike,
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              border: Border(top: BorderSide(color: AppTheme.line)),
            ),
            // Large system text: stack the two buttons so labels never clip.
            child: MediaQuery.textScalerOf(context).scale(16) / 16 > 1.3
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DsButton(
                        label: l.productSavePrice,
                        onPressed: () => _savePrice(product, coreName),
                      ),
                      const SizedBox(height: 8),
                      DsButton(
                        label: l.productRequestThisPrice,
                        style: DsButtonStyle.secondary,
                        onPressed: () => _requestPrice(product),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DsButton(
                          label: l.productRequestThisPrice,
                          style: DsButtonStyle.secondary,
                          onPressed: () => _requestPrice(product),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: DsButton(
                          label: l.productSavePrice,
                          onPressed: () => _savePrice(product, coreName),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    // Tablets and desktops keep the navigation around the pushed page.
    return context.isWide
        ? ShellFrame(locationOverride: '/product', child: page)
        : page;
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.name,
    required this.product,
    required this.storeCount,
    this.big = false,
  });

  final String name;
  final Product product;
  final int storeCount;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final sub = [
      product.category,
      if (product.brand.isNotEmpty) product.brand,
      if (product.packSize.isNotEmpty) product.packSize,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            name,
            style: AppFonts.display(
              fontSize: big ? 34 : 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: AppFonts.body(fontSize: 15, color: AppTheme.textLight),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.home,
    required this.category,
    required this.name,
  });

  final String home;
  final String category;
  final String name;

  @override
  Widget build(BuildContext context) {
    final muted = AppFonts.body(fontSize: 14, color: AppTheme.textLight);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        InkWell(
          onTap: () => context.go('/'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(home, style: muted),
          ),
        ),
        Text('›', style: muted),
        Text(category, style: muted),
        Text('›', style: muted),
        Text(
          name,
          style: muted.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }
}

class _CheapestCard extends StatelessWidget {
  const _CheapestCard({
    required this.label,
    required this.store,
    required this.distanceKm,
    required this.hoursAgo,
    required this.price,
    required this.showLogo,
  });

  final String label;
  final String store;
  final double distanceKm;
  final int? hoursAgo;
  final double price;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.goodLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          if (showLogo && store.isNotEmpty) ...[
            DsStoreLogo(store, size: 56),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goodText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  store.isEmpty ? '—' : store,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l.homeKmAway(distanceKm.toStringAsFixed(1))} · ${freshnessLabel(l, hoursAgo)}',
                  style: AppFonts.body(fontSize: 14, color: AppTheme.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: DsPrice(price, size: 36, best: true),
          ),
        ],
      ),
    );
  }
}

class _CompareSection extends ConsumerWidget {
  const _CompareSection({
    required this.product,
    required this.prices,
    required this.cheapestPrice,
    required this.distanceFor,
    required this.onReport,
    required this.table,
  });

  final Product product;
  final List<StoreProductPrice> prices;
  final double cheapestPrice;
  final double Function(String storeId, String storeName) distanceFor;
  final void Function(Product, StoreProductPrice, int) onReport;
  final bool table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final s = DiscoverStrings.of(context);
    if (prices.isEmpty) {
      return DsBanner(
        '${l.productNoFreshPrices} ${l.productNoFreshPricesHint}',
        icon: Icons.info_outline_rounded,
      );
    }
    final flagged = ref.watch(flaggedPricesProvider);
    final rows = <Widget>[];
    for (final sp in prices) {
      final flagCount = flagged['${product.id}_${sp.storeName}'] ?? 0;
      if (flagCount >= 3) {
        rows.add(
          DsBanner(
            l.productPriceFlaggedHidden,
            tone: DsBannerTone.warn,
            icon: Icons.report_problem_rounded,
          ),
        );
        continue;
      }
      final isCheapest = sp.price == cheapestPrice;
      final km = distanceFor(sp.storeId, sp.storeName);
      final reportBtn = TextButton.icon(
        onPressed: () => onReport(product, sp, flagCount),
        icon: Icon(
          flagCount > 0
              ? Icons.check_circle_rounded
              : Icons.report_gmailerrorred_rounded,
          size: 18,
        ),
        label: Text(
          flagCount > 0 ? l.productReported : l.productReportWrongPrice,
        ),
        style: TextButton.styleFrom(
          foregroundColor: flagCount > 0 ? AppTheme.goodText : AppTheme.badText,
          minimumSize: const Size(48, 48),
          textStyle: AppFonts.body(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
      );
      if (table) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      DsStoreLogo(sp.storeName, size: 40),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sp.storeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                            ),
                            if (isCheapest) ...[
                              const SizedBox(height: 4),
                              DsTag(l.productBestPriceBadge, tone: DsTone.good),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${km.toStringAsFixed(1)} km',
                    style: AppFonts.body(fontSize: 15, color: AppTheme.ink),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FreshnessTag(sp.submittedHoursAgo),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: DsPrice(
                      sp.price,
                      size: 20,
                      best: isCheapest,
                      muted: sp.submittedHoursAgo >= 72,
                    ),
                  ),
                ),
                SizedBox(width: 190, child: reportBtn),
              ],
            ),
          ),
        );
      } else {
        rows.add(
          DsCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            selected: isCheapest,
            child: Column(
              children: [
                Row(
                  children: [
                    DsStoreLogo(sp.storeName, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sp.storeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.display(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.homeKmAway(km.toStringAsFixed(1)),
                            style: AppFonts.body(
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (isCheapest)
                                DsTag(
                                  l.productBestPriceBadge,
                                  tone: DsTone.good,
                                ),
                              FreshnessTag(sp.submittedHoursAgo),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: DsPrice(
                        sp.price,
                        size: 22,
                        best: isCheapest,
                        muted: sp.submittedHoursAgo >= 72,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: reportBtn,
                ),
              ],
            ),
          ),
        );
      }
    }

    if (!table) {
      return Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            rows[i],
          ],
        ],
      );
    }
    return DsCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            color: AppTheme.sand2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                for (final (flex, label) in [
                  (5, s.store),
                  (2, s.distance),
                  (3, s.updated),
                  (2, s.price),
                ])
                  Expanded(
                    flex: flex,
                    child: Align(
                      alignment: label == s.price
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Text(
                        label,
                        style: AppFonts.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ),
                // Room for the report button column.
                const SizedBox(width: 190),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppTheme.line),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _PriceHistoryPanel extends StatelessWidget {
  const _PriceHistoryPanel({required this.history});

  final List<ProductPriceHistory> history;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (history.isEmpty) {
      return Text(
        l.productNoPriceHistory,
        style: AppFonts.body(
          fontSize: 15,
          height: 1.4,
          color: AppTheme.textLight,
        ),
      );
    }

    final minPrice = history
        .map((point) => point.priceAed)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = history
        .map((point) => point.priceAed)
        .reduce((a, b) => a > b ? a : b);
    final latest = history.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: Semantics(
            label: l.productPriceRange(
              formatAed(minPrice),
              formatAed(maxPrice),
            ),
            child: CustomPaint(
              painter: _PriceHistoryPainter(
                history: history,
                minPrice: minPrice,
                maxPrice: maxPrice,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l.productPriceRange(formatAed(minPrice), formatAed(maxPrice)),
          style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
        ),
        Text(
          l.productLatestPrice('AED ${latest.priceAed.toStringAsFixed(2)}'),
          style: AppFonts.body(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.forestDeep,
          ),
        ),
      ],
    );
  }
}

class _PriceHistoryPainter extends CustomPainter {
  const _PriceHistoryPainter({
    required this.history,
    required this.minPrice,
    required this.maxPrice,
  });

  final List<ProductPriceHistory> history;
  final double minPrice;
  final double maxPrice;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.line
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppTheme.forestDeep
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = AppTheme.limeAccent;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final range = (maxPrice - minPrice).abs() < 0.01
        ? 1.0
        : maxPrice - minPrice;
    final path = Path();
    Offset? last;
    for (var i = 0; i < history.length; i++) {
      final x = history.length == 1
          ? size.width
          : size.width * (i / (history.length - 1));
      final normalized = (history[i].priceAed - minPrice) / range;
      final y = size.height - (normalized * (size.height - 16)) - 8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      last = Offset(x, y);
    }
    canvas.drawPath(path, linePaint);
    if (last != null) canvas.drawCircle(last, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PriceHistoryPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.maxPrice != maxPrice;
  }
}
