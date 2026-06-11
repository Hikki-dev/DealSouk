import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/state.dart';
import '../../core/models/models.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _couponApplied = false;
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    final sortedBaskets = storeTotals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final String cheapestStoreName = sortedBaskets.isNotEmpty
        ? sortedBaskets.first.key
        : 'N/A';
    final double cheapestStorePrice = sortedBaskets.isNotEmpty
        ? sortedBaskets.first.value
        : 0.0;

    // Calculate second cheapest store for savings comparison
    final double nextCheapestPrice = sortedBaskets.length > 1 ? sortedBaskets[1].value : cheapestStorePrice;
    final double optimizerSavings = nextCheapestPrice - cheapestStorePrice;

    // Billing Summary Calculations
    final double subtotal = cheapestStorePrice;
    const double deliveryFee = 5.00;
    final double couponDiscount = _couponApplied ? (subtotal * 0.10) : 0.0;
    final double grandTotal = (subtotal + deliveryFee - couponDiscount).clamp(0.0, 9999.0);

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
            onPressed: () => context.go('/'),
          ),
          title: Text(
            'Best Basket',
            style: GoogleFonts.fredoka(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            if (cartItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.redAccent, size: 24),
                onPressed: () {
                  ref.read(cartProvider.notifier).clearCart();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Basket cleared')),
                  );
                },
              ),
          ],
        ),
        body: cartItems.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9F4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: AppTheme.forestDeep,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your basket is empty',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search and add fresh groceries to compare\nprices across major Dubai stores.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: Colors.grey.shade500,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/search'),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Browse Products'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      children: [
                        // Dynamic Optimization Banner (DealSouk Core)
                        Container(
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
                                color: AppTheme.forestDeep.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Optimized at $cheapestStoreName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You are saving AED ${optimizerSavings.toStringAsFixed(2)} compared to Spinneys',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SoukPrice(cheapestStorePrice, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // List Title
                        Text(
                          'Your Items',
                          style: GoogleFonts.fredoka(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Cart Items
                        ...cartItems.map((item) {
                          // Split name
                          final parts = item.product.name.split('(');
                          final coreName = parts[0].trim();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100, width: 1.2),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: SoukProductVisual(
                                    product: item.product,
                                    fit: BoxFit.contain,
                                    borderRadius: 12,
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
                                          fontSize: 13.5,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Best at ${item.product.lowestPriceStore}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SoukPrice(
                                      item.product.lowestPrice * item.quantity,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(height: 6),
                                    // Stepper container
                                    Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.cream,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => ref
                                                .read(cartProvider.notifier)
                                                .updateQuantity(item.product.id, item.quantity - 1),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 6),
                                              child: Icon(
                                                Icons.remove,
                                                size: 14,
                                                color: AppTheme.forestDeep,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.forestDeep,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => ref
                                                .read(cartProvider.notifier)
                                                .updateQuantity(item.product.id, item.quantity + 1),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 6),
                                              child: Icon(
                                                Icons.add,
                                                size: 14,
                                                color: AppTheme.forestDeep,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 18),

                        // Coupon input banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.confirmation_num_outlined, color: AppTheme.forestDeep),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter coupon: SOUK10',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    filled: false,
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_couponController.text.trim().toUpperCase() == 'SOUK10') {
                                    setState(() {
                                      _couponApplied = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: AppTheme.forestDeep,
                                        content: Text('Coupon SOUK10 applied! 10% Discount added.', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: AppTheme.redAccent,
                                        content: Text('Invalid coupon. Try SOUK10'),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _couponApplied ? Colors.grey.shade200 : AppTheme.forestDeep,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _couponApplied ? 'Applied' : 'Apply',
                                    style: TextStyle(
                                      color: _couponApplied ? Colors.black54 : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Supermarket Cost Optimizer comparisons list
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Compare Store Totals',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...sortedBaskets.map((basket) {
                                final isCheapest = basket.key == cheapestStoreName;
                                final extra = basket.value - cheapestStorePrice;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCheapest ? Icons.check_circle_rounded : Icons.store_rounded,
                                        color: isCheapest ? AppTheme.forestDeep : Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          basket.key,
                                          style: TextStyle(
                                            fontWeight: isCheapest ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 12.5,
                                            color: isCheapest ? Colors.black : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      if (extra > 0)
                                        Text(
                                          '+AED ${extra.toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.bold),
                                        )
                                      else
                                        const Text(
                                          'Best option',
                                          style: TextStyle(fontSize: 11, color: AppTheme.forestDeep, fontWeight: FontWeight.bold),
                                        ),
                                      const SizedBox(width: 14),
                                      SoukPrice(basket.value, size: 13, color: isCheapest ? AppTheme.forestDeep : Colors.black87),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Summary Cost Table
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Summary',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow('Basket Subtotal', subtotal),
                              _buildSummaryRow('Estimated Delivery', deliveryFee),
                              if (_couponApplied)
                                _buildSummaryRow('Promo Discount (10%)', -couponDiscount, isDiscount: true),
                              _buildSummaryRow('Optimizer Savings', -optimizerSavings, isDiscount: true),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Cost',
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                  SoukPrice(grandTotal, size: 17.5, color: Colors.black),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sticky Bottom checkout container
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _showCheckoutDialog(context, cheapestStoreName, grandTotal);
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.forestDeep,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.forestDeep.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Checkout Now (AED ${grandTotal.toStringAsFixed(2)})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double val, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            isDiscount
                ? '-AED ${val.abs().toStringAsFixed(2)}'
                : 'AED ${val.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDiscount ? AppTheme.forestDeep : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, String store, double price) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppTheme.forestDeep, size: 28),
              SizedBox(width: 10),
              Text('Optimized Checkout'),
            ],
          ),
          content: Text(
            'Your basket order has been optimized at $store for a final price of AED ${price.toStringAsFixed(2)}!\n\nThis completes the checkout flow for the DealSouk prototype. You can now submit shelf prices to earn rewards.',
            style: GoogleFonts.nunito(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/submit-price');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.forestDeep, foregroundColor: Colors.white),
              child: const Text('Earn Tokens Now'),
            ),
          ],
        );
      },
    );
  }
}
