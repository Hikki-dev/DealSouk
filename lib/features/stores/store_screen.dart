import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/mock_data/mock_data.dart';
import '../../core/models/models.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/souk_widgets.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stores = MockData.initialStores;

    return Scaffold(
      backgroundColor: const Color(0xFF5C1F66),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 10,
              16,
              14,
            ),
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
                const Expanded(
                  child: Text(
                    'Map',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _CircleButton(icon: Icons.tune_rounded, onTap: () {}),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
                children: [
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search nearby Dubai stores',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.filter_list_rounded,
                          color: AppTheme.forestDeep,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.forestDeep,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: AppTheme.limeAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.near_me_rounded,
                                color: AppTheme.forestDeep,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dubai Marina proximity',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'GPS demo active • network location fallback ready',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 145,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFEAF5EF),
                                        Color(0xFFDDE9F4),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -20,
                                  bottom: 20,
                                  child: Container(
                                    width: 220,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -30,
                                  top: 18,
                                  child: Container(
                                    width: 210,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                                ...stores
                                    .take(5)
                                    .map(
                                      (store) => Positioned(
                                        left:
                                            20 +
                                            (store.xOffset * 250).clamp(0, 260),
                                        top:
                                            18 +
                                            (store.yOffset * 90).clamp(0, 95),
                                        child: GestureDetector(
                                          onTap: () => _StoreChoiceCard(
                                            store: store,
                                          )._showStorePrices(context, store),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppTheme.redAccent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.storefront_outlined,
                                              color: Colors.white,
                                              size: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...stores.map((store) => _StoreChoiceCard(store: store)),
                ],
              ),
            ),
          ),
        ],
      ),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.forestDeep, size: 18),
      ),
    );
  }
}

class _StoreChoiceCard extends StatelessWidget {
  final Store store;

  const _StoreChoiceCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final prices = MockData.productPrices.values
        .expand((items) => items)
        .where(
          (price) => price.storeId == store.id || price.storeName == store.name,
        )
        .toList();
    final sampleTotal = prices
        .take(3)
        .fold<double>(0, (sum, item) => sum + item.price);

    return GestureDetector(
      onTap: () => _showStorePrices(context, store),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.forestDeep,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                store.name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
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
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${store.branch} • ${store.distance} km • ${store.pricesCount} live prices',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.limeAccent.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Compare',
                    style: TextStyle(
                      color: AppTheme.forestDeep,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
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
        });
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                store.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.forestDeep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${store.branch} • Crowd-sourced prices',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: pricingList.length,
                  itemBuilder: (context, index) {
                    final product = pricingList[index]['product'] as Product;
                    final price = pricingList[index]['price'] as double;
                    final updated = pricingList[index]['updated'] as String;
                    return ListTile(
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
                      ),
                      subtitle: Text(updated),
                      trailing: SoukPrice(price, size: 14),
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
