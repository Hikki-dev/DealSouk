import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/features/cart/domain/cart_item.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/responsive_container.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final savedItems = ref.watch(cartProvider);
    final priceDrops = _findPriceDrops(savedItems, ref.watch(productsProvider));
    final storeTotals = _buildStoreTotals(savedItems);
    final sortedStores = storeTotals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final bestStoreName = sortedStores.isNotEmpty
        ? sortedStores.first.key
        : l.cartNoStoreYet;

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textDark,
          elevation: 0,
          leading: IconButton(
            icon: const DirectionalIcon(Icons.arrow_back_ios_new_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.go('/'),
          ),
          title: Text(
            l.cartMyList,
            style: AppFonts.display(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            if (savedItems.isNotEmpty)
              IconButton(
                tooltip: l.cartClearSavedPrices,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.redAccent,
                ),
                onPressed: () {
                  ref.read(cartProvider.notifier).clearCart();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.cartSavedPricesCleared)),
                  );
                },
              ),
          ],
        ),
        body: savedItems.isEmpty
            ? _EmptySavedPrices(onBrowse: () => context.push('/search'))
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  if (priceDrops.isNotEmpty) ...[
                    _PriceDropBanner(drops: priceDrops),
                    const SizedBox(height: 14),
                  ],
                  _BestStoreBanner(sortedStores: sortedStores),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: l.cartItemsYouAreChecking,
                    actionLabel: l.cartAddMore,
                    onAction: () => context.push('/search'),
                  ),
                  const SizedBox(height: 10),
                  ...savedItems.map(
                    (item) => _SavedPriceCard(
                      item: item,
                      onRemove: () => ref
                          .read(cartProvider.notifier)
                          .removeFromCart(item.product.id),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _StoreComparison(stores: sortedStores),
                  const SizedBox(height: 18),
                  _PlainLanguageNote(storeName: bestStoreName),
                ],
              ),
      ),
    );
  }

  // FR-24: detect cart items whose best available price is now lower than when
  // the shopper saved them, surfaced as an in-app banner (not a push) on open.
  List<_PriceDrop> _findPriceDrops(List<CartItem> items, List products) {
    final drops = <_PriceDrop>[];
    for (final item in items) {
      final added = item.priceAtAdd;
      if (added == null || added <= 0) continue;
      final match = products.where((p) => p.id == item.product.id);
      final current = match.isNotEmpty
          ? match.first.lowestPrice as double
          : item.product.lowestPrice;
      if (current > 0 && current < added) {
        drops.add(_PriceDrop(item: item, oldPrice: added, newPrice: current));
      }
    }
    return drops;
  }

  Map<String, double> _buildStoreTotals(List<CartItem> items) {
    final totals = <String, double>{};
    for (final item in items) {
      final product = item.product;
      if (product.lowestPrice <= 0 || product.lowestPriceStore.isEmpty) {
        continue;
      }
      totals.update(
        product.lowestPriceStore,
        (value) => value + (product.lowestPrice * item.quantity),
        ifAbsent: () => product.lowestPrice * item.quantity,
      );
    }
    return totals;
  }
}

class _PriceDrop {
  final CartItem item;
  final double oldPrice;
  final double newPrice;

  const _PriceDrop({
    required this.item,
    required this.oldPrice,
    required this.newPrice,
  });

  double get saving => oldPrice - newPrice;
}

class _PriceDropBanner extends StatelessWidget {
  final List<_PriceDrop> drops;

  const _PriceDropBanner({required this.drops});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final best = drops.reduce((a, b) => a.saving >= b.saving ? a : b);
    final headline = drops.length == 1
        ? l.cartPriceDroppedOn(best.item.product.name)
        : l.cartItemsCheaperNow(drops.length);
    final detail = l.cartPriceDropDetail(
      best.newPrice.toStringAsFixed(2),
      best.item.product.lowestPriceStore,
      best.oldPrice.toStringAsFixed(2),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.limeAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.forestDeep.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.trending_down_rounded,
            color: AppTheme.forestDeep,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: AppFonts.display(
                    color: AppTheme.forestDeep,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySavedPrices extends StatelessWidget {
  final VoidCallback onBrowse;

  const _EmptySavedPrices({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 62,
                color: AppTheme.forestDeep,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.cartNoSavedPricesYet,
              style: AppFonts.display(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.cartEmptyStateSubtitle,
              textAlign: TextAlign.center,
              style: AppFonts.body(
                color: AppTheme.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.search_rounded),
              label: Text(l.cartFindPricesNearby),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestStoreBanner extends ConsumerWidget {
  final List<MapEntry<String, double>> sortedStores;

  const _BestStoreBanner({required this.sortedStores});

  double _getStoreDistance(WidgetRef ref, String storeName) {
    final storesList = ref.read(storesProvider);
    final match = storesList.where(
      (s) =>
          s.name.toLowerCase().contains(storeName.toLowerCase()) ||
          storeName.toLowerCase().contains(s.name.toLowerCase()),
    );
    if (match.isNotEmpty) {
      return match.first.distance;
    }
    return (storeName.hashCode % 15 + 8) / 10.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    if (sortedStores.isEmpty) return const SizedBox.shrink();

    // Cheapest Basket Option
    final cheapestStoreName = sortedStores.first.key;
    final cheapestTotal = sortedStores.first.value;
    final cheapestDistance = _getStoreDistance(ref, cheapestStoreName);

    // Closest Option
    final storeInfos = sortedStores.map((entry) {
      final name = entry.key;
      final total = entry.value;
      final dist = _getStoreDistance(ref, name);
      return (name: name, total: total, distance: dist);
    }).toList();

    storeInfos.sort((a, b) => a.distance.compareTo(b.distance));
    final closest = storeInfos.first;

    final isSameStore = cheapestStoreName == closest.name;
    final savings = closest.total - cheapestTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.forestDeep, AppTheme.forestMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forestDeep.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                l.cartShoppingListOptions,
                style: AppFonts.display(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.cartCheapestBasket,
                      style: AppFonts.body(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      l.cartStoreWithDistance(
                        cheapestStoreName,
                        cheapestDistance.toStringAsFixed(1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SoukPrice(cheapestTotal, size: 14, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.cartClosestOption,
                      style: AppFonts.body(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      l.cartStoreWithDistance(
                        closest.name,
                        closest.distance.toStringAsFixed(1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SoukPrice(closest.total, size: 14, color: Colors.white),
            ],
          ),

          if (!isSameStore && savings > 0) ...[
            const Divider(color: Colors.white30, height: 20),
            Row(
              children: [
                const Icon(
                  Icons.savings_rounded,
                  color: AppTheme.limeAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.cartSaveAtStore(
                      savings.toStringAsFixed(2),
                      cheapestStoreName,
                    ),
                    style: AppFonts.body(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isSameStore) ...[
            const Divider(color: Colors.white30, height: 20),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppTheme.limeAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.cartClosestIsCheapest,
                    style: AppFonts.body(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppFonts.display(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _SavedPriceCard extends ConsumerWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const _SavedPriceCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final product = item.product;
    final coreName = product.name.split('(').first.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE2BF), width: 1.1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: SoukProductVisual(
              product: product,
              fit: BoxFit.contain,
              borderRadius: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coreName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.cartBestSeenAt(product.lowestPriceStore),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(product.id, item.quantity - 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 14,
                          color: AppTheme.forestDeep,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(cartProvider.notifier)
                            .updateQuantity(product.id, item.quantity + 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 14,
                          color: AppTheme.forestDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SoukPrice(product.lowestPrice * item.quantity, size: 14.5),
              IconButton(
                tooltip: l.cartRemove,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: Colors.grey.shade500,
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreComparison extends ConsumerWidget {
  final List<MapEntry<String, double>> stores;

  const _StoreComparison({required this.stores});

  double _getStoreDistance(WidgetRef ref, String storeName) {
    final storesList = ref.read(storesProvider);
    final match = storesList.where(
      (s) =>
          s.name.toLowerCase().contains(storeName.toLowerCase()) ||
          storeName.toLowerCase().contains(s.name.toLowerCase()),
    );
    if (match.isNotEmpty) {
      return match.first.distance;
    }
    return (storeName.hashCode % 15 + 8) / 10.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE2BF), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.cartNearbyStoreComparison,
            style: AppFonts.display(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...stores.map((store) {
            final isBest = store == stores.first;
            final extra = store.value - stores.first.value;
            final distance = _getStoreDistance(ref, store.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(
                    isBest ? Icons.check_circle_rounded : Icons.store_rounded,
                    color: isBest ? AppTheme.forestDeep : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isBest
                                ? FontWeight.bold
                                : FontWeight.w700,
                            fontSize: 13,
                            color: isBest
                                ? AppTheme.textDark
                                : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          l.cartKmAway(distance.toStringAsFixed(1)),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isBest
                        ? l.cartBest
                        : l.cartExtraAmount(extra.toStringAsFixed(2)),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isBest ? AppTheme.forestDeep : AppTheme.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SoukPrice(store.value, size: 13),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PlainLanguageNote extends StatelessWidget {
  final String storeName;

  const _PlainLanguageNote({required this.storeName});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.creamCircle),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.forestDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.cartPlainLanguageNote,
              style: AppFonts.body(
                fontSize: 12.5,
                color: AppTheme.maroon,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
