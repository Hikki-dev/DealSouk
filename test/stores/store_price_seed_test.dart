import 'package:dealsouk/features/stores/data/store_price_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('static Dubai store ids have device-demo fallback prices', () {
    // Protects device demo flow: static map stores should not show a broken
    // price sheet when the backend is unavailable or not seeded yet.
    final carrefourPrices = fallbackPricesForStore('carr-moe');
    final luluPrices = fallbackPricesForStore('lulu-albarsha');

    expect(carrefourPrices, isNotEmpty);
    expect(luluPrices, isNotEmpty);
    expect(carrefourPrices.first.priceAed, greaterThan(0));
    expect(carrefourPrices.first.updatedAtLabel, contains('Updated'));
  });
}
