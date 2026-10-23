import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/features/cart/domain/cart_item.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/products/presentation/product_widgets.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

/// "My list": the items the shopper is price-checking, which nearby store has
/// the cheapest basket, and a store-by-store comparison. DealSouk does not sell
/// groceries, so there is no checkout.
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

    void clear() {
      ref.read(cartProvider.notifier).clearCart();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.cartSavedPricesCleared)));
    }

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.cartMyList,
              style: AppFonts.display(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
          if (savedItems.isNotEmpty)
            TextButton(onPressed: clear, child: Text(l.cartClearSavedPrices)),
        ],
      ),
    );

    final items = _ItemsSection(items: savedItems);
    final best = _BestStoreCard(
      sortedStores: sortedStores,
      itemCount: savedItems.length,
    );
    final compare = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StoreComparison(stores: sortedStores),
        const SizedBox(height: 16),
        Text(
          l.cartPlainLanguageNote,
          style: AppFonts.body(
            fontSize: 14,
            height: 1.4,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );

    Widget body;
    if (savedItems.isEmpty) {
      body = DsEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: l.cartNoSavedPricesYet,
        message: l.cartEmptyStateSubtitle,
        primaryLabel: l.cartFindPricesNearby,
        onPrimary: () => context.push('/search'),
      );
    } else {
      final drops = priceDrops.isEmpty
          ? const <Widget>[]
          : [_PriceDropBanner(drops: priceDrops), const SizedBox(height: 14)];
      body = SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              ...drops,
              if (context.isExpanded)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: items),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [best, const SizedBox(height: 20), compare],
                      ),
                    ),
                  ],
                )
              else ...[
                best,
                const SizedBox(height: 20),
                items,
                const SizedBox(height: 20),
                compare,
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(bottom: false, child: body),
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
    return DsBanner(
      '$headline $detail',
      tone: DsBannerTone.warn,
      icon: Icons.trending_down_rounded,
    );
  }
}

// ── Summary: cheapest vs closest ─────────────────────────────────────────────

class _BestStoreCard extends ConsumerWidget {
  final List<MapEntry<String, double>> sortedStores;
  final int itemCount;

  const _BestStoreCard({required this.sortedStores, required this.itemCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    if (sortedStores.isEmpty) return const SizedBox.shrink();

    final cheapest = sortedStores.first;
    final cheapestKm = storeDistanceKm(ref, cheapest.key);
    final infos = [
      for (final e in sortedStores)
        (name: e.key, total: e.value, distance: storeDistanceKm(ref, e.key)),
    ]..sort((a, b) => a.distance.compareTo(b.distance));
    final closest = infos.first;
    final isSame = cheapest.key == closest.name;
    final savings = closest.total - cheapest.value;

    final note = !isSame && savings > 0
        ? l.cartSaveAtStore(savings.toStringAsFixed(2), cheapest.key)
        : isSame
        ? l.cartClosestIsCheapest
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.forestDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.cartCheapestBasket,
            style: AppFonts.body(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cheapest.key,
                      style: AppFonts.display(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l.cartKmAway(cheapestKm.toStringAsFixed(1)),
                      style: AppFonts.body(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DsPrice(cheapest.value, size: 34, color: Colors.white),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSame ? Icons.star_rounded : Icons.savings_rounded,
                    color: AppTheme.limeAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note,
                      style: AppFonts.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Items ────────────────────────────────────────────────────────────────────

class _ItemsSection extends ConsumerWidget {
  final List<CartItem> items;

  const _ItemsSection({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(
          l.cartItemsYouAreChecking,
          actionLabel: l.cartAddMore,
          onAction: () => context.push('/search'),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SavedPriceCard(
              item: item,
              onRemove: () => ref
                  .read(cartProvider.notifier)
                  .removeFromCart(item.product.id),
            ),
          ),
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
    final name = coreProductName(product);
    final notifier = ref.read(cartProvider.notifier);

    return DsCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          DsProductThumb(imageUrl: product.imageUrl, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  l.cartBestSeenAt(product.lowestPriceStore),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    DsIconButton(
                      icon: Icons.remove_rounded,
                      semanticLabel: '−',
                      size: 48,
                      onPressed: () => notifier.updateQuantity(
                        product.id,
                        item.quantity - 1,
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: AppFonts.display(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    DsIconButton(
                      icon: Icons.add_rounded,
                      semanticLabel: '+',
                      size: 48,
                      onPressed: () => notifier.updateQuantity(
                        product.id,
                        item.quantity + 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DsPrice(
                product.lowestPrice * item.quantity,
                size: 20,
                best: true,
              ),
              DsIconButton(
                icon: Icons.delete_outline_rounded,
                semanticLabel: l.cartRemove,
                color: AppTheme.redAccent,
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Store comparison ─────────────────────────────────────────────────────────

class _StoreComparison extends ConsumerWidget {
  final List<MapEntry<String, double>> stores;

  const _StoreComparison({required this.stores});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    if (stores.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(l.cartNearbyStoreComparison),
        const SizedBox(height: 8),
        for (final store in stores)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _comparisonRow(context, ref, l, store),
          ),
      ],
    );
  }

  Widget _comparisonRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    MapEntry<String, double> store,
  ) {
    final isBest = store == stores.first;
    final extra = store.value - stores.first.value;
    final distance = storeDistanceKm(ref, store.key);
    return DsCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          DsStoreLogo(store.key, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  l.cartKmAway(distance.toStringAsFixed(1)),
                  style: AppFonts.body(fontSize: 14, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isBest)
                DsTag(l.cartBest, tone: DsTone.good)
              else
                DsTag(
                  l.cartExtraAmount(extra.toStringAsFixed(2)),
                  tone: DsTone.bad,
                ),
              const SizedBox(height: 4),
              DsPrice(store.value, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
