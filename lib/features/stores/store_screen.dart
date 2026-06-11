import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/theme/theme.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  Store? selectedStore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stores = MockData.initialStores;

    // Purple header variant — matches the reference's "Store profile" screen.
    const purpleDeep = Color(0xFF5C1F66);

    return Scaffold(
      backgroundColor: purpleDeep,
      body: Column(
        children: [
          // ── Purple header ──
          Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 14),
            child: Row(
              children: [
                const SizedBox(width: 70),
                const Expanded(
                  child: Text(
                    'Dubai Supermarkets',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Mock GPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ),
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
              child: Column(
                children: [
          // Custom Mock Map Screen
          Container(
            height: 220,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blue.shade100, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapWidth = constraints.maxWidth;
                  final mapHeight = constraints.maxHeight;

                  return Stack(
                    children: [
                      // Map Grid Lines & Dubai landmarks
                      CustomPaint(
                        size: Size(mapWidth, mapHeight),
                        painter: MapBackgroundPainter(),
                      ),

                      // Dubai Landmarks Text Labels
                      Positioned(
                        top: 20,
                        right: mapWidth * 0.1 + 10,
                        child: Text(
                          'Deira / Creek',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.withOpacity(0.7)),
                        ),
                      ),
                      Positioned(
                        top: 90,
                        left: mapWidth * 0.45,
                        child: Text(
                          'Al Wasl',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.withOpacity(0.7)),
                        ),
                      ),
                      Positioned(
                        bottom: 90,
                        left: mapWidth * 0.25,
                        child: Text(
                          'Al Barsha',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.withOpacity(0.7)),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: mapWidth * 0.08,
                        child: Text(
                          'JLT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.withOpacity(0.7)),
                        ),
                      ),

                      // Store pins on map
                      ...stores.map((store) {
                        final isHighlighted = selectedStore?.id == store.id;
                        // Position pins relative to layout constraints (40px padding buffer for pin width/height)
                        final pinLeft = store.xOffset * (mapWidth - 40) + 20;
                        final pinTop = store.yOffset * (mapHeight - 40) + 20;

                        return Positioned(
                          left: pinLeft,
                          top: pinTop,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedStore = store;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isHighlighted ? AppTheme.emeraldPrimary : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                                border: Border.all(
                                  color: isHighlighted ? Colors.white : AppTheme.emeraldPrimary,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.store,
                                size: isHighlighted ? 20 : 16,
                                color: isHighlighted ? Colors.white : AppTheme.emeraldPrimary,
                              ),
                            ),
                          ),
                        );
                      }),

                      // Dynamic map card overlay
                      if (selectedStore != null)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          selectedStore!.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${selectedStore!.branch} • ${selectedStore!.distance} km away',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      _showStorePricesDialog(context, selectedStore!);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    child: const Text('View Prices'),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        selectedStore = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Stores List Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Nearby Branches',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable List under the map
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                final isSelected = selectedStore?.id == store.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? AppTheme.emeraldPrimary : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        selectedStore = store;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.emeraldLight
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.store,
                              color: isSelected
                                  ? AppTheme.emeraldPrimary
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  store.branch,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: store.freshness == 'Fresh'
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        store.freshness,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: store.freshness == 'Fresh'
                                              ? Colors.green.shade800
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${store.pricesCount} prices tracked',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${store.distance} km',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  _showStorePricesDialog(context, store);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                child: const Text('View Prices'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStorePricesDialog(BuildContext context, Store store) {
    // Find all products and their prices at this store
    final List<Map<String, dynamic>> pricingList = [];
    final products = MockData.initialProducts;

    for (var product in products) {
      final prices = MockData.productPrices[product.id];
      if (prices != null) {
        final storePrice = prices.firstWhere((p) => p.storeId == store.id || p.storeName == store.name, orElse: () => StoreProductPrice(storeId: '', storeName: '', price: 0, updatedAtLabel: ''));
        if (storePrice.price > 0) {
          pricingList.add({
            'product': product,
            'price': storePrice.price,
            'updated': storePrice.updatedAtLabel,
          });
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${store.branch} • ${store.distance} km',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Available Grocery Prices',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: pricingList.isEmpty
                    ? const Center(child: Text('No price entries found for this store.'))
                    : ListView.builder(
                        itemCount: pricingList.length,
                        itemBuilder: (context, index) {
                          final item = pricingList[index];
                          final Product product = item['product'];
                          final double price = item['price'];
                          final String updated = item['updated'];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${product.brand} • ${product.packSize} • $updated',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            trailing: Text(
                              'AED ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emeraldPrimary,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sea Background Accent
    final seaPaint = Paint()..color = Colors.blue.shade100.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.2, size.height), seaPaint);

    // Grid lines for design
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Sheikh Zayed Road (major artery line)
    final roadPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.9)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.9,
        size.height * 0.1,
      );

    canvas.drawPath(path, roadPaint);

    // Dotted lines in the middle of SZR
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
