import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/souk_widgets.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String _selectedChain = 'All';

  static const List<String> _chains = ['All', 'Carrefour', 'Lulu', 'Spinneys', 'Union Coop', 'Nesto'];

  @override
  Widget build(BuildContext context) {
    final stores = MockData.initialStores;
    final filtered = _selectedChain == 'All'
        ? stores
        : stores.where((s) => s.name.toLowerCase().contains(_selectedChain.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.canPop() ? context.pop() : context.go('/'),
                  ),
                  Expanded(
                    child: Text(
                      'Store Map',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        color: AppTheme.forestDeep,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.tune_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Chain filter chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _chains.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chain = _chains[index];
                  final isSelected = chain == _selectedChain;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedChain = chain),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.forestDeep : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.forestDeep : const Color(0xFFE8EEE4),
                        ),
                      ),
                      child: Text(
                        chain,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.forestDeep,
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Search Bar
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search nearby Dubai stores',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.filter_list_rounded, color: AppTheme.forestDeep, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Proximity Map Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.forestDeep, AppTheme.maroon],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.forestDeep.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dubai Marina proximity',
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'GPS demo active • showing nearby comparison',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                // Mock Map Grid
                                Container(
                                  decoration: const BoxDecoration(color: Color(0xFFF1F6F2)),
                                  child: GridPaper(
                                    color: Colors.green.withValues(alpha: 0.04),
                                    divisions: 2,
                                    interval: 80,
                                    subdivisions: 1,
                                    child: Container(),
                                  ),
                                ),
                                Positioned(top: 50, left: 0, right: 0, child: Container(height: 12, color: Colors.white)),
                                Positioned(left: 120, top: 0, bottom: 0, child: Container(width: 12, color: Colors.white)),
                                Positioned(
                                  left: -20, bottom: 20,
                                  child: Container(
                                    width: 220, height: 58,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -30, top: 18,
                                  child: Container(
                                    width: 210, height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.72),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                // Store dots (grey if stale)
                                ...filtered.take(5).map((store) {
                                  final isStale = store.lastUpdatedHoursAgo > 48;
                                  return Positioned(
                                    left: 20 + (store.xOffset * 220).clamp(0, 240),
                                    top: 18 + (store.yOffset * 100).clamp(0, 110),
                                    child: GestureDetector(
                                      onTap: () => _showStorePrices(context, store),
                                      child: Opacity(
                                        opacity: isStale ? 0.4 : 1.0,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 34, height: 34,
                                              decoration: BoxDecoration(
                                                color: (isStale ? Colors.grey : AppTheme.redAccent).withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Container(
                                              width: 24, height: 24,
                                              decoration: BoxDecoration(
                                                color: isStale ? Colors.grey : AppTheme.redAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Nearby Supermarkets',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),

                  ...filtered.map((store) => _StoreChoiceCard(
                    store: store,
                    onTap: () => _showStorePrices(context, store),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStorePrices(BuildContext context, Store store) {
    final pricingList = <Map<String, dynamic>>[];
    for (final product in MockData.initialProducts) {
      final prices = MockData.productPrices[product.id] ?? [];
      final match = prices.where(
        (price) => price.storeId == store.id || price.storeName == store.name,
      );
      if (match.isNotEmpty) {
        pricingList.add({
          'product': product,
          'price': match.first.price,
          'updated': match.first.updatedAtLabel,
          'hoursAgo': match.first.submittedHoursAgo,
        });
      }
    }

    final isStale = store.lastUpdatedHoursAgo > 48;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42, height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.forestDeep,
                              ),
                            ),
                            Text(
                              '${store.branch} • ${store.distance} km away',
                              style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (isStale)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, color: Colors.grey.shade500, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Stale (${store.lastUpdatedHoursAgo}h ago)',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: pricingList.length,
                      itemBuilder: (context, index) {
                        final product = pricingList[index]['product'] as Product;
                        final price = pricingList[index]['price'] as double;
                        final updated = pricingList[index]['updated'] as String;
                        final hoursAgo = pricingList[index]['hoursAgo'] as int;
                        final isOutdated = hoursAgo > 72;
                        return Opacity(
                          opacity: isOutdated ? 0.55 : 1.0,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: SizedBox(
                              width: 44,
                              height: 44,
                              child: SoukProductVisual(
                                product: product,
                                fit: BoxFit.cover,
                                borderRadius: 12,
                              ),
                            ),
                            title: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            subtitle: Text(
                              isOutdated ? 'Unverified — may be outdated' : updated,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: isOutdated ? Colors.amber.shade700 : Colors.grey.shade500,
                              ),
                            ),
                            trailing: SoukPrice(price, size: 14),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/submit-price?store=${store.name}');
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.forestDeep,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Submit Price Here',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8EEE4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.forestDeep, size: 18),
      ),
    );
  }
}

class _StoreChoiceCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const _StoreChoiceCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isStale = store.lastUpdatedHoursAgo > 48;
    final prices = MockData.productPrices.values
        .expand((items) => items)
        .where((price) => price.storeId == store.id || price.storeName == store.name)
        .toList();
    final sampleTotal = prices.take(3).fold<double>(0, (sum, item) => sum + item.price);

    return Opacity(
      opacity: isStale ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isStale ? Colors.grey.shade300 : const Color(0xFFE8EEE4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isStale ? Colors.grey.shade400 : AppTheme.forestDeep,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  store.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        color: AppTheme.textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${store.branch} • ${store.distance} km • ${store.pricesCount} prices',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isStale) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Stale',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SoukPrice(
                    sampleTotal == 0 ? store.distance * 10 : sampleTotal,
                    size: 14,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.limeAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Compare',
                      style: GoogleFonts.nunito(color: AppTheme.forestDeep, fontSize: 9.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
