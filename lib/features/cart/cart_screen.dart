import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/state.dart';
import '../../core/models/models.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';

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
          orElse: () => StoreProductPrice(storeId: '', storeName: '', price: -1, updatedAtLabel: ''),
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
    final String cheapestStoreName = sortedBaskets.isNotEmpty ? sortedBaskets.first.key : 'N/A';
    final double cheapestStorePrice = sortedBaskets.isNotEmpty ? sortedBaskets.first.value : 0.0;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Souk Basket',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (cartItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).clearCart();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )
              ],
            ),
          ),

          // Main cart content
          Expanded(
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
                          child: Icon(Icons.shopping_basket_outlined, size: 52, color: Colors.grey.shade300),
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
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/search'),
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Browse Products'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Cart Items list
                      ...cartItems.map((item) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                // Category Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(item.product.category),
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Product details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle, size: 10, color: AppTheme.emeraldPrimary),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              'Best: AED ${item.product.lowestPrice.toStringAsFixed(2)} at ${item.product.lowestPriceStore}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.emeraldPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Builder(builder: (context) {
                                        final prices = MockData.productPrices[item.product.id] ?? [];
                                        final sorted = [...prices]..sort((a, b) => a.price.compareTo(b.price));
                                        if (sorted.length >= 2) {
                                          final second = sorted[1];
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 1),
                                            child: Text(
                                              'Also at: AED ${second.price.toStringAsFixed(2)} at ${second.storeName}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }),
                                    ],
                                  ),
                                ),

                                // Stepper and Subtotal
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'AED ${(item.product.lowestPrice * item.quantity).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _stepperButton(
                                          icon: Icons.remove,
                                          onPressed: () {
                                            ref.read(cartProvider.notifier).updateQuantity(
                                                  item.product.id,
                                                  item.quantity - 1,
                                                );
                                          },
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                            ref.read(cartProvider.notifier).updateQuantity(
                                                  item.product.id,
                                                  item.quantity + 1,
                                                );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                )
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
                              color: Colors.black.withOpacity(0.04),
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
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.compare_arrows_rounded, color: theme.colorScheme.primary, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Basket Price Comparison',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Full basket cost across Dubai stores',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: sortedBaskets.map((basket) {
                                  final isCheapest = basket.key == cheapestStoreName;
                                  final saving = basket.value - cheapestStorePrice;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isCheapest
                                          ? AppTheme.emeraldPrimary.withOpacity(0.06)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCheapest
                                            ? AppTheme.emeraldPrimary.withOpacity(0.3)
                                            : Colors.grey.shade200,
                                        width: isCheapest ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                basket.key,
                                                style: TextStyle(
                                                  fontWeight: isCheapest ? FontWeight.w700 : FontWeight.w500,
                                                  fontSize: 13,
                                                  color: isCheapest ? AppTheme.emeraldPrimary : AppTheme.textDark,
                                                ),
                                              ),
                                              if (isCheapest)
                                                const Text(
                                                  'Best deal for your basket',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppTheme.emeraldPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'AED ${basket.value.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: isCheapest ? AppTheme.emeraldPrimary : Colors.black87,
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
                      
                      // Continue / Checkout Buttons
                      ElevatedButton(
                        onPressed: () {
                          _showCheckoutDialog(context, cheapestStoreName, cheapestStorePrice);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text('Save Basket & Continue to $cheapestStoreName'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onPressed}) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dairy & eggs':
        return Icons.egg_alt_outlined;
      case 'pantry':
        return Icons.breakfast_dining_outlined;
      case 'meat & seafood':
        return Icons.kebab_dining_outlined;
      case 'beverages':
        return Icons.local_drink_outlined;
      case 'household':
        return Icons.clean_hands_outlined;
      default:
        return Icons.shopping_basket_outlined;
    }
  }
}
