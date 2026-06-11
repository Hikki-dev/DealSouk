import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/state.dart';
import '../../core/models/models.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/souk_widgets.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  final int _selectedStoreIndex = 0;
  bool _isFavorite = false;
  bool _showFullDescription = false;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => Product(
        id: 'unknown',
        name: 'Product Not Found',
        brand: 'Generic',
        packSize: 'N/A',
        category: 'Dairy & Sweet',
        lowestPrice: 0.0,
        lowestPriceStore: 'Unknown',
        updatedAtLabel: '',
      ),
    );

    final storePrices = MockData.productPrices[widget.productId] ?? [];
    final sortedPrices = List<StoreProductPrice>.from(storePrices)
      ..sort((a, b) => a.price.compareTo(b.price));

    final safeIndex = sortedPrices.isEmpty
        ? 0
        : _selectedStoreIndex.clamp(0, sortedPrices.length - 1);
    final selectedPrice = sortedPrices.isNotEmpty
        ? sortedPrices[safeIndex].price
        : product.lowestPrice;

    // Split product name like "Beef Mixed Cut Bone (Cut Bone)"
    final parts = product.name.split('(');
    final coreName = parts[0].trim();
    final subName = parts.length > 1 ? '(${parts[1]}' : '';
    final displayUnit = product.category == 'Meat' ? '50 gm' : product.packSize;

    return ResponsiveContainer(
      child: Container(
        color: AppTheme.forestDeep,
        child: Column(
          children: [
            // ── Dark Green Curved Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 10,
                16,
                0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.forestDeep,
                        size: 17,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Product Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
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
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: AppTheme.forestDeep,
                            size: 17,
                          ),
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
                                border: Border.all(
                                  color: AppTheme.forestDeep,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$cartCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
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

            const SizedBox(height: 16),

            // ── White Rounded Sheet Body ──
            Expanded(
              child: ClipPath(
                clipper: const ArcBottomClipper(
                  depth: -20,
                ), // inverse curve to make a dome shape top
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      // Large Centered Product Image
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: product.imageUrl.isNotEmpty
                                ? Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          categoryIcon(product.category),
                                          size: 118,
                                          color: Colors.grey.shade300,
                                        ),
                                  )
                                : Icon(
                                    categoryIcon(product.category),
                                    size: 118,
                                    color: Colors.grey.shade300,
                                  ),
                          ),
                        ),
                      ),

                      // Details Block
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Favorite
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$coreName\nIn $displayUnit',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.forestDeep,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          product.packSize,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        if (subName.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              subName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(
                                        () => _isFavorite = !_isFavorite,
                                      );
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1.5,
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: Icon(
                                        _isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 20,
                                        color: _isFavorite
                                            ? AppTheme.redAccent
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Price + crowd verification tag
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SoukPrice(selectedPrice, size: 28),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFB85ADD),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.bolt,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          'Live price available',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF8E5E9D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Trust Badges and Rating
                              Row(
                                children: [
                                  _TrustBadge(
                                    icon: Icons.eco_outlined,
                                    color: const Color(0xFF8A1455),
                                    bgColor: const Color(0xFFF4DCEB),
                                  ),
                                  const SizedBox(width: 8),
                                  _TrustBadge(
                                    icon: Icons.workspace_premium_outlined,
                                    color: const Color(0xFFB45B14),
                                    bgColor: const Color(0xFFFFE4C9),
                                  ),
                                  const SizedBox(width: 8),
                                  _TrustBadge(
                                    icon: Icons.discount_outlined,
                                    color: const Color(0xFF1565C0),
                                    bgColor: const Color(0xFFE3F2FD),
                                  ),
                                  const Spacer(),
                                  // Rating
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFC107),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    '4.5 Rating',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF78909C),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Description with "Read more" toggle
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _showFullDescription
                                          ? '100% community price confidence. If you spot a missing, poor, or outdated shelf price, request an update or submit a newer label to earn tokens across Dubai stores...'
                                          : '100% community price confidence. If you spot a missing, poor, or outdated shelf price...',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade500,
                                        height: 1.5,
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(
                                            () => _showFullDescription =
                                                !_showFullDescription,
                                          );
                                        },
                                        child: Text(
                                          _showFullDescription
                                              ? ' Read less'
                                              : 'Read more',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.forestDeep,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),

                      // ── Bottom Floating Bar: Stepper & Leaf Green Add to cart ──
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
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Custom green stepper pill container
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEDF1E4,
                                ), // soft green container
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_quantity > 1) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: AppTheme.forestDeep,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.forestDeep,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _quantity++);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: AppTheme.forestDeep,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Leaf-green Add to cart button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  for (int i = 0; i < _quantity; i++) {
                                    ref
                                        .read(cartProvider.notifier)
                                        .addToCart(product);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$_quantity × ${product.name} added to cart',
                                      ),
                                      action: SnackBarAction(
                                        label: 'VIEW CART',
                                        textColor: AppTheme.limeAccent,
                                        onPressed: () => context.go('/cart'),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF99C24D,
                                    ), // leaf green
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        color: AppTheme.forestDeep,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add to cart',
                                        style: TextStyle(
                                          color: AppTheme.forestDeep,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w900,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _TrustBadge({
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 16),
    );
  }
}
