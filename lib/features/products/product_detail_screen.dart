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

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;
  bool _compareExpanded = true;
  bool _trendExpanded = false;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => Product(
        id: 'unknown',
        name: 'Product Not Found',
        brand: 'Generic',
        packSize: 'N/A',
        category: 'Fresh',
        lowestPrice: 0.0,
        lowestPriceStore: 'Unknown',
        updatedAtLabel: '',
      ),
    );

    final storePrices = MockData.productPrices[widget.productId] ?? [];
    final sortedPrices = List<StoreProductPrice>.from(storePrices)
      ..sort((a, b) => a.price.compareTo(b.price));

    final selectedPrice = sortedPrices.isNotEmpty
        ? sortedPrices.first.price
        : product.lowestPrice;

    // Filter recommended products (other products of same category or any other product)
    final recommended = products.where((p) => p.id != product.id).toList();

    // Split name
    final parts = product.name.split('(');
    final coreName = parts[0].trim();

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Details',
            style: GoogleFonts.fredoka(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite ? AppTheme.redAccent : Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Large Hero Product Image Container
                    Container(
                      width: double.infinity,
                      height: 230,
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F9F4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Hero(
                        tag: 'product_img_${product.id}',
                        child: SoukProductVisual(product: product, fit: BoxFit.contain),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Product Name & Brand info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coreName,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${product.brand} • ${product.packSize}',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 3. Price & Stepper aligned side-by-side
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SoukPrice(
                                    selectedPrice,
                                    size: 26,
                                    color: AppTheme.forestDeep,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Best price at ${product.lowestPriceStore}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              // Custom Stepper
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cream,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16, color: AppTheme.forestDeep),
                                      onPressed: () {
                                        if (_quantity > 1) {
                                          setState(() => _quantity--);
                                        }
                                      },
                                    ),
                                    Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.forestDeep,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16, color: AppTheme.forestDeep),
                                      onPressed: () {
                                        setState(() => _quantity++);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 4. Crowdsourced Price Comparison (Collapsible)
                          _buildCollapsibleCard(
                            title: 'Compare Store Prices',
                            icon: Icons.storefront_rounded,
                            isExpanded: _compareExpanded,
                            onToggle: () => setState(() => _compareExpanded = !_compareExpanded),
                            child: sortedPrices.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('No price comparison data available.'),
                                  )
                                : Column(
                                    children: sortedPrices.map((sp) {
                                      final isCheapest = sp.price == selectedPrice;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCheapest
                                              ? const Color(0xFFF1F8E9)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isCheapest
                                                ? const Color(0xFFC8E6C9)
                                                : Colors.grey.shade100,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: isCheapest
                                                  ? AppTheme.forestDeep
                                                  : Colors.grey.shade200,
                                              child: Text(
                                                sp.storeName.substring(0, 1),
                                                style: TextStyle(
                                                  color: isCheapest ? Colors.white : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sp.storeName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    sp.updatedAtLabel,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade500,
                                                      fontSize: 10.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isCheapest)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                margin: const EdgeInsets.only(right: 10),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.forestDeep,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'BEST PRICE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            SoukPrice(sp.price, size: 14.5),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 14),

                          // 5. Price Trend Chart (Collapsible, Custom Painter)
                          _buildCollapsibleCard(
                            title: '4-Week Price Trend',
                            icon: Icons.trending_down_rounded,
                            isExpanded: _trendExpanded,
                            onToggle: () => setState(() => _trendExpanded = !_trendExpanded),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Price variation trend in Dubai (AED)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 120,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: PriceTrendPainter([
                                      selectedPrice + 0.50,
                                      selectedPrice + 0.35,
                                      selectedPrice + 0.20,
                                      selectedPrice
                                    ]),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('3w ago', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text('2w ago', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text('1w ago', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text('Current', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 6. Recommended Products Slider
                          Text(
                            'You may also like',
                            style: GoogleFonts.fredoka(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: recommended.length,
                              itemBuilder: (context, index) {
                                final item = recommended[index];
                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 14),
                                  child: ProductGridCard(product: item),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 7. Sticky Bottom Price & Buy Bar
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
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Price Total',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SoukPrice(
                        selectedPrice * _quantity,
                        size: 20,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      for (int i = 0; i < _quantity; i++) {
                        ref.read(cartProvider.notifier).addToCart(product);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.forestDeep,
                          content: Text(
                            '$_quantity × $coreName added to cart',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          action: SnackBarAction(
                            label: 'VIEW CART',
                            textColor: Colors.white,
                            onPressed: () => context.go('/cart'),
                          ),
                        ),
                      );
                      setState(() {
                        _quantity = 1;
                      });
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        color: AppTheme.forestDeep,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.forestDeep.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Add to Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: AppTheme.forestDeep, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class PriceTrendPainter extends CustomPainter {
  final List<double> prices;

  PriceTrendPainter(this.prices);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.forestDeep
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.forestDeep.withValues(alpha: 0.15),
          AppTheme.forestDeep.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final minVal = prices.reduce((a, b) => a < b ? a : b);
    final maxVal = prices.reduce((a, b) => a > b ? a : b);
    final delta = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final dx = size.width / (prices.length - 1);

    for (int i = 0; i < prices.length; i++) {
      final x = i * dx;
      final normalizedY = (prices[i] - minVal) / delta;
      final y = size.height - (normalizedY * (size.height - 30) + 15);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == prices.length - 1) {
        fillPath.lineTo(x, size.height);
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points & labels
    final pointPaint = Paint()
      ..color = AppTheme.forestDeep
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < prices.length; i++) {
      final x = i * dx;
      final normalizedY = (prices[i] - minVal) / delta;
      final y = size.height - (normalizedY * (size.height - 30) + 15);

      canvas.drawCircle(Offset(x, y), 5.5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5.5, borderPaint);

      // Draw price text above node
      textPainter.text = TextSpan(
        text: prices[i].toStringAsFixed(2),
        style: GoogleFonts.nunito(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: AppTheme.forestDeep,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 20));
    }
  }

  @override
  bool shouldRepaint(covariant PriceTrendPainter oldDelegate) =>
      oldDelegate.prices != prices;
}
