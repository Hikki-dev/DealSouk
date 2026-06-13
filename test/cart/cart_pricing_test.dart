import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/cart/domain/cart_item.dart';
import 'package:dealsouk/features/cart/domain/cart_pricing.dart';
import 'package:dealsouk/features/products/domain/product.dart';

void main() {
  Product product(String id, String name) => Product(
    id: id,
    name: name,
    brand: 'Seed',
    packSize: '1 pc',
    category: 'Grocery',
    lowestPrice: 0,
    lowestPriceStore: '',
    updatedAtLabel: '',
  );

  test('cart best-price calculation selects cheapest complete basket', () {
    // Protects PRD grocery cart requirement: shoppers see the cheapest basket,
    // not just the cheapest single item.
    final milk = product('milk', 'Milk');
    final rice = product('rice', 'Rice');

    final result = calculateCheapestBasket(
      items: [
        CartItem(product: milk, quantity: 2),
        CartItem(product: rice, quantity: 1),
      ],
      quotes: const [
        StorePriceQuote(
          storeId: 'carrefour',
          storeName: 'Carrefour',
          productId: 'milk',
          priceAed: 5,
        ),
        StorePriceQuote(
          storeId: 'carrefour',
          storeName: 'Carrefour',
          productId: 'rice',
          priceAed: 14,
        ),
        StorePriceQuote(
          storeId: 'union',
          storeName: 'Union Coop',
          productId: 'milk',
          priceAed: 6,
        ),
        StorePriceQuote(
          storeId: 'union',
          storeName: 'Union Coop',
          productId: 'rice',
          priceAed: 9,
        ),
        StorePriceQuote(
          storeId: 'partial',
          storeName: 'Missing Rice Store',
          productId: 'milk',
          priceAed: 1,
        ),
      ],
    );

    expect(result?.storeName, 'Union Coop');
    expect(result?.totalAed, 21);
  });
}
