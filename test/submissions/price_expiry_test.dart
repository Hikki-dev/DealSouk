import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/products/domain/price_freshness.dart';

void main() {
  test('72-hour price expiry filters out stale prices', () {
    // Protects PRD freshness rule: prices older than 72 hours must not be
    // treated as active shopper-facing prices.
    final now = DateTime.utc(2026, 6, 12, 12);
    final fresh = now.subtract(const Duration(hours: 71, minutes: 59));
    final stale = now.subtract(const Duration(hours: 72));

    expect(isFreshPrice(fresh, now), isTrue);
    expect(isFreshPrice(stale, now), isFalse);

    final active = freshOnly<DateTime>(
      prices: [fresh, stale],
      now: now,
      submittedAt: (price) => price,
    );

    expect(active, [fresh]);
  });
}
