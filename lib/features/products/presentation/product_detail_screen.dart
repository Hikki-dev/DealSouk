import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dealsouk/features/products/presentation/products_providers.dart';
import 'package:dealsouk/features/stores/presentation/stores_providers.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/requests/presentation/requests_providers.dart';
import 'package:dealsouk/features/admin/presentation/admin_providers.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/features/products/domain/product.dart';
import 'package:dealsouk/features/products/domain/product_price_history.dart';
import 'package:dealsouk/features/products/domain/store_product_price.dart';
import 'package:dealsouk/features/products/data/products_service.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/responsive_container.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isFavorite = false;
  bool _compareExpanded = true;
  List<StoreProductPrice> _storePrices = [];
  List<ProductPriceHistory> _priceHistory = [];

  double _getStoreDistance(WidgetRef ref, String storeId, String storeName) {
    final stores = ref.read(storesProvider);
    final match = stores.where(
      (s) =>
          s.id == storeId ||
          s.name.toLowerCase().contains(storeName.toLowerCase()),
    );
    if (match.isNotEmpty) {
      return match.first.distance;
    }
    return (storeName.hashCode % 15 + 8) / 10.0;
  }

  String _formatFreshness(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('now')) return 'Updated just now';
    final matches = RegExp(r'(\d+)').firstMatch(lower);
    if (matches != null) {
      final numStr = matches.group(1);
      if (lower.contains('h')) {
        return 'Updated $numStr hours ago';
      } else if (lower.contains('d')) {
        return 'Updated $numStr days ago';
      }
    }
    return 'Updated $label';
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final prices = await productsService.getPrices(widget.productId);
        final history = await productsService.getHistory(widget.productId);
        if (mounted) {
          setState(() {
            _storePrices = prices;
            _priceHistory = history;
          });
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final auth = ref.watch(authProvider);
    final requestCost = ref.watch(adminSettingsProvider).requestCostTokens;

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

    final sortedPrices = List<StoreProductPrice>.from(_storePrices)
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
            ),
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
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F9F4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Hero(
                        tag: 'product_img_${product.id}',
                        child: SoukProductVisual(
                          product: product,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
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

                          // 3. Price and store clarity.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SoukPrice(
                                selectedPrice,
                                size: 26,
                                color: AppTheme.forestDeep,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Best price seen at ${product.lowestPriceStore}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      ref
                                          .read(priceRequestsProvider.notifier)
                                          .addPriceRequest(
                                            productName: product.name,
                                            storeName:
                                                product
                                                        .lowestPriceStore
                                                        .isNotEmpty &&
                                                    product.lowestPriceStore !=
                                                        '—'
                                                ? product.lowestPriceStore
                                                : 'Carrefour',
                                            requestCostTokens: requestCost,
                                            requesterName: 'Shopper',
                                          );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Request this price! Other shoppers will check it soon.',
                                          ),
                                          backgroundColor: AppTheme.forestDeep,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 14,
                                    ),
                                    label: const Text('Request this price'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.forestDeep,
                                      visualDensity: VisualDensity.compact,
                                      textStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 4. Crowdsourced Price Comparison (Collapsible)
                          _buildCollapsibleCard(
                            title: 'Compare Store Prices',
                            icon: Icons.storefront_rounded,
                            isExpanded: _compareExpanded,
                            onToggle: () => setState(
                              () => _compareExpanded = !_compareExpanded,
                            ),
                            child: sortedPrices.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'No fresh prices yet.',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ask another shopper to check this item before you make the trip.',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: sortedPrices.map((sp) {
                                      final key =
                                          '${product.id}_${sp.storeName}';
                                      final flaggedState = ref.watch(
                                        flaggedPricesProvider,
                                      );
                                      final flagCount = flaggedState[key] ?? 0;
                                      final isHidden = flagCount >= 3;

                                      if (isHidden) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.report_problem_rounded,
                                                color: Colors.orange.shade700,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Text(
                                                  'Price flagged & hidden (Pending admin audit)',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final isCheapest =
                                          sp.price == selectedPrice;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCheapest
                                              ? const Color(0xFFF1F8E9)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isCheapest
                                                ? const Color(0xFFC8E6C9)
                                                : Colors.grey.shade100,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: isCheapest
                                                      ? AppTheme.forestDeep
                                                      : Colors.grey.shade200,
                                                  child: Text(
                                                    sp.storeName.substring(
                                                      0,
                                                      1,
                                                    ),
                                                    style: TextStyle(
                                                      color: isCheapest
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${sp.storeName} • ${_getStoreDistance(ref, sp.storeId, sp.storeName).toStringAsFixed(1)} km away',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${_formatFreshness(sp.updatedAtLabel)} • Verified with photo',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade500,
                                                          fontSize: 10.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SoukPrice(
                                                      sp.price,
                                                      size: 14.5,
                                                    ),
                                                    if (isCheapest) ...[
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme
                                                              .forestDeep,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'BEST PRICE',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 7.5,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            const Divider(height: 1),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    ref
                                                        .read(
                                                          flaggedPricesProvider
                                                              .notifier,
                                                        )
                                                        .flagPrice(
                                                          product.id,
                                                          sp.storeName,
                                                          product.name,
                                                          sp.price,
                                                        );
                                                    final newCount =
                                                        flagCount + 1;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          newCount >= 3
                                                              ? 'Thanks. This price is hidden until an admin reviews it.'
                                                              : 'Thanks. We will hide this price after 3 unique reports.',
                                                        ),
                                                        duration:
                                                            const Duration(
                                                              seconds: 2,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  icon: Icon(
                                                    flagCount > 0
                                                        ? Icons
                                                              .check_circle_rounded
                                                        : Icons
                                                              .report_gmailerrorred_rounded,
                                                    size: 13,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    flagCount > 0
                                                        ? 'Reported'
                                                        : 'Report wrong price',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        flagCount > 0
                                                        ? Colors.green
                                                        : Colors.red.shade600,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
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
                          const SizedBox(height: 24),

                          _buildCollapsibleCard(
                            title: '90-Day Price History',
                            icon: Icons.show_chart_rounded,
                            isExpanded: true,
                            onToggle: () {},
                            child: _PriceHistoryPanel(history: _priceHistory),
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

            // 7. Sticky bottom save bar. DealSouk does not sell groceries.
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
                        'Best seen price',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SoukPrice(selectedPrice, size: 20, color: Colors.black),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (auth.isGuest) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Please sign in to save prices and compare grocery baskets.',
                            ),
                            action: SnackBarAction(
                              label: 'SIGN IN',
                              textColor: Colors.white,
                              onPressed: () {
                                ref.read(authProvider.notifier).signOut();
                                context.go('/welcome');
                              },
                            ),
                            backgroundColor: AppTheme.forestDeep,
                          ),
                        );
                        return;
                      }
                      ref.read(cartProvider.notifier).addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.forestDeep,
                          content: Text(
                            '$coreName saved for price comparison',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          action: SnackBarAction(
                            label: 'VIEW',
                            textColor: Colors.white,
                            onPressed: () => context.go('/cart'),
                          ),
                        ),
                      );
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
                          Icon(
                            Icons.bookmark_border_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Save Price',
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
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
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

class _PriceHistoryPanel extends StatelessWidget {
  const _PriceHistoryPanel({required this.history});

  final List<ProductPriceHistory> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'No approved price history yet. Once shoppers submit fresh prices, you will see the trend here.',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final minPrice = history
        .map((point) => point.priceAed)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = history
        .map((point) => point.priceAed)
        .reduce((a, b) => a > b ? a : b);
    final latest = history.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: CustomPaint(
            painter: _PriceHistoryPainter(
              history: history,
              minPrice: minPrice,
              maxPrice: maxPrice,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Lowest AED ${minPrice.toStringAsFixed(2)} • Highest AED ${maxPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'Latest AED ${latest.priceAed.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.forestDeep,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceHistoryPainter extends CustomPainter {
  const _PriceHistoryPainter({
    required this.history,
    required this.minPrice,
    required this.maxPrice,
  });

  final List<ProductPriceHistory> history;
  final double minPrice;
  final double maxPrice;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EEE4)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppTheme.forestDeep
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = AppTheme.limeAccent;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final range = (maxPrice - minPrice).abs() < 0.01
        ? 1.0
        : maxPrice - minPrice;
    final path = Path();
    for (var i = 0; i < history.length; i++) {
      final x = history.length == 1
          ? size.width
          : size.width * (i / (history.length - 1));
      final normalized = (history[i].priceAed - minPrice) / range;
      final y = size.height - (normalized * (size.height - 10)) - 5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PriceHistoryPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.maxPrice != maxPrice;
  }
}
