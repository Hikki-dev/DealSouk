import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/models.dart';
import '../../core/state/state.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedItems = ref.watch(cartProvider);
    final storeTotals = _buildStoreTotals(savedItems);
    final sortedStores = storeTotals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final bestStoreName = sortedStores.isNotEmpty
        ? sortedStores.first.key
        : 'No store yet';
    final bestTotal = sortedStores.isNotEmpty ? sortedStores.first.value : 0.0;
    final nextBest = sortedStores.length > 1
        ? sortedStores[1].value
        : bestTotal;
    final savings = (nextBest - bestTotal).clamp(0.0, 9999.0);

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go('/'),
          ),
          title: Text(
            'Saved Prices',
            style: GoogleFonts.fredoka(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            if (savedItems.isNotEmpty)
              IconButton(
                tooltip: 'Clear saved prices',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.redAccent,
                ),
                onPressed: () {
                  ref.read(cartProvider.notifier).clearCart();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved prices cleared')),
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
                  _BestStoreBanner(
                    storeName: bestStoreName,
                    total: bestTotal,
                    savings: savings,
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'Items you are checking',
                    actionLabel: 'Add more',
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

  Map<String, double> _buildStoreTotals(List<CartItem> items) {
    final totals = <String, double>{};
    for (final item in items) {
      final product = item.product;
      if (product.lowestPrice <= 0 || product.lowestPriceStore.isEmpty) {
        continue;
      }
      totals.update(
        product.lowestPriceStore,
        (value) => value + product.lowestPrice,
        ifAbsent: () => product.lowestPrice,
      );
    }
    return totals;
  }
}

class _EmptySavedPrices extends StatelessWidget {
  final VoidCallback onBrowse;

  const _EmptySavedPrices({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
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
              'No saved prices yet',
              style: GoogleFonts.fredoka(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search an item and save it here to see which nearby store is worth visiting.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
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
              label: const Text('Find prices nearby'),
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

class _BestStoreBanner extends StatelessWidget {
  final String storeName;
  final double total;
  final double savings;

  const _BestStoreBanner({
    required this.storeName,
    required this.total,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          const Icon(Icons.place_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best nearby option',
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (savings > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'About AED ${savings.toStringAsFixed(2)} less than the next option',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SoukPrice(total, size: 18, color: Colors.white),
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
          style: GoogleFonts.fredoka(
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

class _SavedPriceCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const _SavedPriceCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
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
                  'Best seen at ${product.lowestPriceStore}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SoukPrice(product.lowestPrice, size: 14.5),
              IconButton(
                tooltip: 'Remove',
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

class _StoreComparison extends StatelessWidget {
  final List<MapEntry<String, double>> stores;

  const _StoreComparison({required this.stores});

  @override
  Widget build(BuildContext context) {
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
            'Nearby store comparison',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...stores.map((store) {
            final isBest = store == stores.first;
            final extra = store.value - stores.first.value;
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
                    child: Text(
                      store.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isBest ? FontWeight.bold : FontWeight.w700,
                        fontSize: 13,
                        color: isBest
                            ? AppTheme.textDark
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Text(
                    isBest ? 'Best' : '+AED ${extra.toStringAsFixed(2)}',
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
              'DealSouk does not sell groceries. This list only helps you decide where to check prices nearby.',
              style: GoogleFonts.nunito(
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
