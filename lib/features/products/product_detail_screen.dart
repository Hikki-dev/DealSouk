import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/state.dart';
import '../../core/models/models.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

const _storeColors = [
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
];

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedStoreIndex = 0;

  void _showChooseStoreSheet(BuildContext context, List<StoreProductPrice> sortedPrices) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose store',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                const SizedBox(height: 16),
                ...List.generate(sortedPrices.length, (i) {
                  final sp = sortedPrices[i];
                  final isSelected = i == _selectedStoreIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedStoreIndex = i);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.limeAccent.withOpacity(0.25) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.forestDeep : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _storeColors[i % _storeColors.length].withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.store, size: 16, color: _storeColors[i % _storeColors.length]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sp.storeName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sp.updatedAtLabel,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          if (i == 0)
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.limeAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Cheapest',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.forestDeep),
                              ),
                            ),
                          SoukPrice(sp.price, size: 15),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = ref.watch(productsProvider);
    final userTokens = ref.watch(userTokensProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => Product(
        id: 'unknown',
        name: 'Product Not Found',
        brand: 'Generic',
        packSize: 'N/A',
        category: 'Dairy & Eggs',
        lowestPrice: 0.0,
        lowestPriceStore: 'Unknown',
        updatedAtLabel: '',
      ),
    );

    final storePrices = MockData.productPrices[widget.productId] ?? [];
    final sortedPrices = List<StoreProductPrice>.from(storePrices)
      ..sort((a, b) => a.price.compareTo(b.price));

    final safeIndex = sortedPrices.isEmpty ? 0 : _selectedStoreIndex.clamp(0, sortedPrices.length - 1);
    final selectedPrice = sortedPrices.isNotEmpty ? sortedPrices[safeIndex].price : product.lowestPrice;

    final similarProducts =
        products.where((p) => p.id != product.id && p.category == product.category).toList();
    final similar = (similarProducts.isEmpty
            ? products.where((p) => p.id != product.id).toList()
            : similarProducts)
        .take(3)
        .toList();

    return ResponsiveContainer(
      child: Container(
        color: AppTheme.forestDeep,
        child: Column(
          children: [
            // ── Dark green header ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.forestDeep, size: 17),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Product Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/cart'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.forestDeep, size: 17),
                        ),
                        if (cartCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 17,
                              height: 17,
                              decoration: BoxDecoration(
                                color: AppTheme.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.forestDeep, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '$cartCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── White rounded sheet ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Grab handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              // Large product image
                              Center(
                                child: SizedBox(
                                  height: 190,
                                  child: product.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            product.imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Icon(
                                              categoryIcon(product.category),
                                              size: 80,
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        )
                                      : Icon(categoryIcon(product.category), size: 80, color: Colors.grey.shade300),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Name + heart
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${product.name}\nIn ${product.packSize}',
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.forestDeep,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          product.brand,
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Icon(Icons.favorite_border_rounded, size: 19, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Price + crowd-sourced badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SoukPrice(selectedPrice, size: 26),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF9C27B0),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Crowd-sourced price',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF9C27B0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Store dots + rating
                              if (sortedPrices.isNotEmpty)
                                Row(
                                  children: [
                                    ...List.generate(sortedPrices.length.clamp(0, 5), (i) {
                                      final isSelected = i == safeIndex;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedStoreIndex = i),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          width: isSelected ? 30 : 22,
                                          height: isSelected ? 30 : 22,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: _storeColors[i % _storeColors.length],
                                            shape: BoxShape.circle,
                                            border: isSelected
                                                ? Border.all(color: AppTheme.forestDeep, width: 2.5)
                                                : null,
                                          ),
                                        ),
                                      );
                                    }),
                                    GestureDetector(
                                      onTap: () => _showChooseStoreSheet(context, sortedPrices),
                                      child: Text(
                                        sortedPrices[safeIndex].storeName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.forestDeep,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 18),
                                    const SizedBox(width: 3),
                                    const Text(
                                      '4.5 Rating',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF78909C)),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),

                              // Description
                              Text(
                                '100% crowd-sourced price data. Prices are submitted by Dubai shoppers and verified by moderators. Spotted a different price? Submit it and earn tokens, or request an update below... ',
                                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, height: 1.5),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (userTokens >= 10) {
                                    ref.read(userTokensProvider.notifier).deductTokens(10);
                                    ref.read(userTransactionsProvider.notifier).addTransaction(
                                          -10,
                                          'Requested update for ${product.name}',
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Update requested. 10 tokens spent. Balance: ${userTokens - 10} tokens.'),
                                        backgroundColor: theme.colorScheme.primary,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Requires 10 tokens. Earn tokens by submitting grocery prices!'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Request price update (−10 tokens)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.forestDeep,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Divider(color: Colors.grey.shade100),

                              // ── Compare Supermarkets (PRD core) ──
                              Theme(
                                data: theme.copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  initiallyExpanded: true,
                                  title: const Text(
                                    'Compare supermarkets',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                  ),
                                  children: List.generate(sortedPrices.length, (i) {
                                    final sp = sortedPrices[i];
                                    final isCheapest = i == 0;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _storeColors[i % _storeColors.length],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sp.storeName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: isCheapest ? FontWeight.w700 : FontWeight.w500,
                                                    color: AppTheme.textDark,
                                                  ),
                                                ),
                                                Text(
                                                  sp.updatedAtLabel,
                                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isCheapest)
                                            Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.limeAccent,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Cheapest',
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.forestDeep),
                                              ),
                                            ),
                                          SoukPrice(sp.price, size: 14, color: isCheapest ? AppTheme.forestDeep : const Color(0xFF78909C)),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              Divider(color: Colors.grey.shade100),

                              // ── Price trend (collapsible like reference) ──
                              Theme(
                                data: theme.copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Price trend (30 days)',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.limeAccent.withOpacity(0.4),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                '-4.2% overall',
                                                style: TextStyle(color: AppTheme.forestDeep, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            height: 100,
                                            child: CustomPaint(
                                              size: const Size(double.infinity, 100),
                                              painter: PriceTrendPainter(AppTheme.forestDeep),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('1 Month Ago', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text('15 Days Ago', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text('Today', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(color: Colors.grey.shade100),
                              const SizedBox(height: 8),

                              // ── Similar products ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Similar products',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/search'),
                                    child: const Text(
                                      'See more',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 0.62,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                children: similar.map((p) => ProductGridCard(product: p)).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Bottom bar: stepper + lime Add to cart ──
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Quantity stepper (outline pill)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_quantity > 1) setState(() => _quantity--);
                                  },
                                  child: const SizedBox(
                                    width: 40,
                                    height: 46,
                                    child: Icon(Icons.remove, size: 17, color: AppTheme.forestDeep),
                                  ),
                                ),
                                SizedBox(
                                  width: 26,
                                  child: Text(
                                    '$_quantity',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _quantity++),
                                  child: const SizedBox(
                                    width: 40,
                                    height: 46,
                                    child: Icon(Icons.add, size: 17, color: AppTheme.forestDeep),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Lime "Add to cart"
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                for (int i = 0; i < _quantity; i++) {
                                  ref.read(cartProvider.notifier).addToCart(product);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$_quantity × ${product.name} added to cart'),
                                    action: SnackBarAction(
                                      label: 'VIEW CART',
                                      textColor: AppTheme.limeAccent,
                                      onPressed: () => context.go('/cart'),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.limeAccent,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.limeAccent.withOpacity(0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_rounded, color: AppTheme.forestDeep, size: 19),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add to cart',
                                      style: TextStyle(
                                        color: AppTheme.forestDeep,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriceTrendPainter extends CustomPainter {
  final Color primaryColor;

  PriceTrendPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;

    for (double i = 0; i <= size.height; i += size.height / 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.3),
          primaryColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width * 0.25, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.4)
      ..lineTo(size.width, size.height * 0.75);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(Offset(0, size.height * 0.2), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.3), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.4), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.75), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
