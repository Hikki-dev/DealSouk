import 'package:dealsouk/features/cart/domain/cart_item.dart';

class StorePriceQuote {
  final String storeId;
  final String storeName;
  final String productId;
  final double priceAed;

  const StorePriceQuote({
    required this.storeId,
    required this.storeName,
    required this.productId,
    required this.priceAed,
  });
}

class StoreBasketTotal {
  final String storeId;
  final String storeName;
  final double totalAed;

  const StoreBasketTotal({
    required this.storeId,
    required this.storeName,
    required this.totalAed,
  });
}

StoreBasketTotal? calculateCheapestBasket({
  required List<CartItem> items,
  required List<StorePriceQuote> quotes,
}) {
  if (items.isEmpty) return null;

  final totalsByStore = <String, StoreBasketTotal>{};
  for (final quote in quotes) {
    final item = items
        .where((i) => i.product.id == quote.productId)
        .firstOrNull;
    if (item == null) continue;

    final existing = totalsByStore[quote.storeId];
    final lineTotal = quote.priceAed * item.quantity;
    totalsByStore[quote.storeId] = StoreBasketTotal(
      storeId: quote.storeId,
      storeName: quote.storeName,
      totalAed: (existing?.totalAed ?? 0) + lineTotal,
    );
  }

  final requiredProductIds = items.map((i) => i.product.id).toSet();
  final completeStoreIds = quotes
      .fold<Map<String, Set<String>>>({}, (acc, quote) {
        acc.putIfAbsent(quote.storeId, () => {}).add(quote.productId);
        return acc;
      })
      .entries
      .where((entry) => entry.value.containsAll(requiredProductIds))
      .map((entry) => entry.key)
      .toSet();

  final completeTotals = totalsByStore.values
      .where((total) => completeStoreIds.contains(total.storeId))
      .toList();
  if (completeTotals.isEmpty) return null;

  completeTotals.sort((a, b) => a.totalAed.compareTo(b.totalAed));
  return completeTotals.first;
}
