import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/state/state.dart';
import '../../core/models/models.dart';
import '../../core/services/products_service.dart';
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
  bool _isFavorite = false;
  bool _compareExpanded = true;
  List<StoreProductPrice> _storePrices = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final prices = await productsService.getPrices(widget.productId);
        if (mounted) setState(() => _storePrices = prices);
      } catch (_) {}
    });
  }

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
                              Text(
                                'Best price seen at ${product.lowestPriceStore}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w700,
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
                            onToggle: () => setState(
                              () => _compareExpanded = !_compareExpanded,
                            ),
                            child: sortedPrices.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      'No price comparison data available.',
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
                                                  color: isCheapest
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sp.storeName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    sp.updatedAtLabel,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 10.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isCheapest)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                margin: const EdgeInsets.only(
                                                  right: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.forestDeep,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                            IconButton(
                                              icon: Icon(
                                                Icons.outlined_flag_rounded,
                                                color: flagCount > 0
                                                    ? Colors.redAccent
                                                    : Colors.grey.shade400,
                                                size: 20,
                                              ),
                                              tooltip: 'Flag incorrect price',
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
                                                final newCount = flagCount + 1;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      newCount >= 3
                                                          ? 'Price report flagged 3 times! Hidden and sent to Admin Queue.'
                                                          : 'Price report flagged ($newCount/3). Auto-hides at 3.',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 4),
                                            SoukPrice(sp.price, size: 14.5),
                                          ],
                                        ),
                                      );
                                    }).toList(),
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
