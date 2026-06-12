import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/l10n/app_localizations_ar.dart';

void main() {
  test('Arabic locale smoke test exposes core shopping labels', () {
    // Protects PRD Arabic/RTL requirement: core labels must exist in Arabic,
    // not silently fall back to English-only copy.
    final l10n = AppLocalizationsAr();

    expect(l10n.appTitle, isNotEmpty);
    expect(l10n.home, 'الرئيسية');
    expect(l10n.nearbyStores, contains('السوبرماركت'));
    expect(l10n.earnTokens, contains('رموز'));
  });
}
