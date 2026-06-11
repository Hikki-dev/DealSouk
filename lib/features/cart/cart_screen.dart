import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/state.dart';
import '../../core/models/models.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/souk_widgets.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cartItems = ref.watch(cartProvider);

    // Calculate dynamic basket prices across major stores
    final stores = MockData.initialStores;
    final Map<String, double> storeTotals = {};

    for (var store in stores) {
      double total = 0.0;
      bool hasAllItems = true;

      for (var cartItem in cartItems) {
        final prices = MockData.productPrices[cartItem.product.id] ?? [];
        final storePrice = prices.firstWhere(
          (p) => p.storeId == store.id || p.storeName == store.name,
          orElse: () => StoreProductPrice(
            storeId: '',
            storeName: '',
            price: -1,
            updatedAtLabel: '',
          ),
        );

        if (storePrice.price > 0) {
          total += storePrice.price * cartItem.quantity;
        } else {
          hasAllItems = false;
        }
      }

      if (hasAllItems && cartItems.isNotEmpty) {
        storeTotals[store.name] = total;
      }
    }

    // Sort stores by price ascending to find the cheapest basket option
    final sortedBaskets = storeTotals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Overall cheapest basket store
    final String cheapestStoreName = sortedBaskets.isNotEmpty
        ? sortedBaskets.first.key
        : 'N/A';
    final double cheapestStorePrice = sortedBaskets.isNotEmpty
        ? sortedBaskets.first.value
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.forestDeep,
      body: Column(
        children: [
          // ── Dark forest header ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 10,
              16,
              14,
            ),
            child: Row(
              children: [
                const SizedBox(width: 38),
                const Expanded(
                  child: Text(
                    'Best Basket',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                cartItems.isNotEmpty
                    ? GestureDetector(
                        onTap: () =>
                            ref.read(cartProvider.notifier).clearCart(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.redAccent,
                            size: 18,
                          ),
                        ),
                      )
                    : const SizedBox(width: 38),
              ],
            ),
          ),

          // ── White rounded sheet ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              clipBehavior: Clip.antiAlias,
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_basket_outlined,
                              size: 52,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your basket is empty',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search for products to compare prices\nacross 5 Dubai supermarkets.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/search'),
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Browse Products'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.forestDeep,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.forestDeep.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.limeAccent.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Text(
                                        'Cheapest full basket',
                                        style: TextStyle(
                                          color: AppTheme.limeAccent,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      cheapestStoreName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Across ${cartItems.length} item${cartItems.length == 1 ? '' : 's'} in Dubai',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.62,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SoukPrice(
                                cheapestStorePrice,
                                size: 25,
                                color: AppTheme.limeAccent,
                              ),
                            ],
                          ),
                        ),
                        // Cart Items list
                        ...cartItems.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.025),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Product image
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: SoukProductVisual(
                                      product: item.product,
                                      fit: BoxFit.cover,
                                      borderRadius: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Product details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.limeAccent
                                                .withValues(alpha: 0.32),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.verified_rounded,
                                                size: 12,
                                                color: AppTheme.forestDeep,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'Best ${item.product.lowestPriceStore} • AED ${item.product.lowestPrice.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    color: AppTheme.forestDeep,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final prices =
                                                MockData.productPrices[item
                                                    .product
                                                    .id] ??
                                                [];
                                            final sorted = [...prices]
                                              ..sort(
                                                (a, b) =>
                                                    a.price.compareTo(b.price),
                                              );
                                            if (sorted.length >= 2) {
                                              final second = sorted[1];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 1,
                                                ),
                                                child: Text(
                                                  'Also at ${second.storeName}: AED ${second.price.toStringAsFixed(2)} • ${second.updatedAtLabel}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade500,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Stepper and Subtotal
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SoukPrice(
                                        item.product.lowestPrice *
                                            item.quantity,
                                        size: 15,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _stepperButton(
                                            icon: Icons.remove,
                                            onPressed: () {
                                              ref
                                                  .read(cartProvider.notifier)
                                                  .updateQuantity(
                                                    item.product.id,
                                                    item.quantity - 1,
                                                  );
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          _stepperButton(
                                            icon: Icons.add,
                                            onPressed: () {
                                              ref
                                                  .read(cartProvider.notifier)
                                                  .updateQuantity(
                                                    item.product.id,
                                                    item.quantity + 1,
                                                  );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // Best Basket Optimizer Panel
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.compare_arrows_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Store comparison',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          Text(
                                            'Best AED total for this exact basket',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 12),

                              // Store price comparison rows
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: sortedBaskets.map((basket) {
                                    final isCheapest =
                                        basket.key == cheapestStoreName;
                                    final saving =
                                        basket.value - cheapestStorePrice;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCheapest
                                            ? AppTheme.emeraldPrimary
                                                  .withValues(alpha: 0.06)
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isCheapest
                                              ? AppTheme.emeraldPrimary
                                                    .withValues(alpha: 0.3)
                                              : Colors.grey.shade200,
                                          width: isCheapest ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  basket.key,
                                                  style: TextStyle(
                                                    fontWeight: isCheapest
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    fontSize: 13,
                                                    color: isCheapest
                                                        ? AppTheme
                                                              .emeraldPrimary
                                                        : AppTheme.textDark,
                                                  ),
                                                ),
                                                if (isCheapest)
                                                  const Text(
                                                    'Best deal for your basket',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme
                                                          .emeraldPrimary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'AED ${basket.value.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: isCheapest
                                                      ? AppTheme.emeraldPrimary
                                                      : Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (!isCheapest && saving > 0)
                                                Text(
                                                  '+AED ${saving.toStringAsFixed(2)} more',
                                                  style: TextStyle(
                                                    color: Colors.red.shade400,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Continue / Checkout — lime pill CTA
                        GestureDetector(
                          onTap: () {
                            _showCheckoutDialog(
                              context,
                              cheapestStoreName,
                              cheapestStorePrice,
                            );
                          },
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppTheme.limeAccent,
                              borderRadius: BorderRadius.circular(27),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.limeAccent.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Save basket at $cheapestStoreName',
                                style: const TextStyle(
                                  color: AppTheme.forestDeep,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: Icon(icon, size: 12),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, String store, double price) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Basket Saved'),
            ],
          ),
          content: Text(
            'Your grocery list for $store is optimized at AED ${price.toStringAsFixed(2)}!\n\nThis is a DealSouk prototype demo. Ready to submit prices to earn tokens?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Cart'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/submit-price');
              },
              child: const Text('Submit a Price'),
            ),
          ],
        );
      },
    );
  }
}
