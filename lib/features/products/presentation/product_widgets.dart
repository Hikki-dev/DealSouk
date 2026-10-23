import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/design.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/util/geo_utils.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/presentation/discover_strings.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

// Sentinel age (hours) for products with no fresh price; sorts/filters last.
const int kNoFreshnessHours = 1 << 30;

/// Keeps products whose cheapest price is no older than [freshness]
/// ('All', 'Under 6h', 'Under 24h', 'Under 72h').
List<Product> filterByFreshness(List<Product> products, String freshness) {
  if (freshness == 'All') return [...products];
  final maxHours = switch (freshness) {
    'Under 6h' => 6,
    'Under 24h' => 24,
    'Under 72h' => 72,
    _ => kNoFreshnessHours,
  };
  return products
      .where((p) => (p.hoursAgo ?? kNoFreshnessHours) <= maxHours)
      .toList();
}

/// Labels for the freshness filter values stored in `FilterState`.
String freshnessFilterLabel(AppLocalizations l, String filter) =>
    switch (filter) {
      'Under 6h' => l.homeFreshnessUnder6h,
      'Under 24h' => l.homeFreshnessUnder24h,
      'Under 72h' => l.homeFreshnessUnder72h,
      _ => l.homeFreshnessAll,
    };

const freshnessFilters = ['All', 'Under 6h', 'Under 24h', 'Under 72h'];

/// The product name without a trailing "(Local shop)" style qualifier.
String coreProductName(Product p) => p.name.split('(').first.trim();

/// Distance in km from the shopper to the store named [storeName].
///
/// Uses live GPS when known, then the store's backend distance, then a stable
/// placeholder so the line is never blank.
double storeDistanceKm(WidgetRef ref, String storeName) {
  final pos = ref.read(userLocationProvider);
  final stores = ref.read(storesProvider);
  final match = stores.where(
    (s) => s.name.toLowerCase().contains(storeName.toLowerCase()),
  );
  if (match.isNotEmpty) {
    final store = match.first;
    if (pos != null) {
      return haversineKm(pos.latitude, pos.longitude, store.lat, store.lng);
    }
    return store.distance;
  }
  return (storeName.hashCode % 15 + 8) / 10.0;
}

String freshnessLabel(AppLocalizations l, int? hoursAgo) {
  if (hoursAgo == null) return l.homeNoRecentPrice;
  if (hoursAgo < 1) return l.homeUpdatedJustNow;
  if (hoursAgo < 24) return l.homeUpdatedHoursAgo('$hoursAgo');
  return l.homeUpdatedDaysAgo('${hoursAgo ~/ 24}');
}

/// Green under a day, amber under three days, red after that. Always text too.
class FreshnessTag extends StatelessWidget {
  const FreshnessTag(this.hoursAgo, {super.key});

  final int? hoursAgo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final h = hoursAgo;
    final tone = h == null
        ? DsTone.neutral
        : h < 24
        ? DsTone.good
        : h < 72
        ? DsTone.warn
        : DsTone.bad;
    final s = DiscoverStrings.of(context);
    // Short form for the small tag; full sentences are used elsewhere.
    final label = h == null
        ? l.homeNoRecentPrice
        : h < 1
        ? s.justNow()
        : h < 24
        ? s.hoursAgo(h)
        : s.daysAgo(h ~/ 24);
    return DsTag(label, tone: tone, icon: Icons.schedule_rounded);
  }
}

/// A heart that adds the product to "My list" and shows its saved state.
class ProductListButton extends ConsumerWidget {
  const ProductListButton(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final inList = ref
        .watch(cartProvider)
        .any((item) => item.product.id == product.id);
    return DsIconButton(
      icon: inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      semanticLabel: inList
          ? l.productRemoveFromFavourites
          : l.productSavePrice,
      color: inList ? AppTheme.redAccent : AppTheme.forestDeep,
      onPressed: () {
        final n = ref.read(cartProvider.notifier);
        inList ? n.removeFromCart(product.id) : n.addToCart(product);
      },
    );
  }
}

/// Horizontal product card for single-column lists (phones, search results).
class ProductRowCard extends ConsumerWidget {
  const ProductRowCard({
    super.key,
    required this.product,
    this.showListButton = false,
  });

  final Product product;
  final bool showListButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final km = storeDistanceKm(ref, product.lowestPriceStore);
    final name = coreProductName(product);
    return DsCard(
      padding: const EdgeInsets.all(12),
      semanticLabel: '$name, ${product.lowestPriceStore}',
      onTap: () => context.push('/product/${product.id}'),
      child: Row(
        children: [
          DsProductThumb(
            imageUrl: product.imageUrl,
            size: 72,
            semanticLabel: name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.lowestPriceStore} · ${l.homeKmAway(km.toStringAsFixed(1))}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 13, color: AppTheme.textLight),
                ),
                const SizedBox(height: 6),
                FreshnessTag(product.hoursAgo),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: DsPrice(
              product.lowestPrice,
              size: 24,
              best: (product.hoursAgo ?? 999) < 24,
            ),
          ),
          if (showListButton) ProductListButton(product),
        ],
      ),
    );
  }
}

/// Vertical product card for grids on tablets and desktops.
class ProductTileCard extends ConsumerWidget {
  const ProductTileCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final km = storeDistanceKm(ref, product.lowestPriceStore);
    final name = coreProductName(product);
    return DsCard(
      padding: const EdgeInsets.all(12),
      semanticLabel: '$name, ${product.lowestPriceStore}',
      onTap: () => context.push('/product/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox.expand(
              child: DsProductThumb(
                imageUrl: product.imageUrl,
                radius: 12,
                padding: 6,
                semanticLabel: name,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
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
            '${product.lowestPriceStore} · ${l.homeKmAway(km.toStringAsFixed(1))}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.body(fontSize: 13, color: AppTheme.textLight),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(child: FreshnessTag(product.hoursAgo)),
              const SizedBox(width: 8),
              DsPrice(
                product.lowestPrice,
                size: 22,
                best: (product.hoursAgo ?? 999) < 24,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SaveToListButton(product),
        ],
      ),
    );
  }
}

class _SaveToListButton extends ConsumerWidget {
  const _SaveToListButton(this.product);

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final inList = ref
        .watch(cartProvider)
        .any((item) => item.product.id == product.id);
    return DsButton(
      label: inList ? l.productRemoveFromFavourites : l.productSavePrice,
      style: DsButtonStyle.secondary,
      compact: true,
      icon: inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      onPressed: () {
        final n = ref.read(cartProvider.notifier);
        inList ? n.removeFromCart(product.id) : n.addToCart(product);
      },
    );
  }
}
