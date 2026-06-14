import 'package:dealsouk/core/widgets/souk_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SoukPrice (UI-05: AED, 2 decimal places)', () {
    testWidgets('renders currency + two decimals', (tester) async {
      await tester.pumpWidget(_wrap(const SoukPrice(7.9)));
      expect(find.text('AED 7.90'), findsOneWidget);
    });

    testWidgets('rounds/pads to exactly two decimals', (tester) async {
      await tester.pumpWidget(_wrap(const SoukPrice(32.5)));
      expect(find.text('AED 32.50'), findsOneWidget);
    });

    testWidgets('can hide the currency prefix', (tester) async {
      await tester.pumpWidget(
        _wrap(const SoukPrice(5.75, showCurrency: false)),
      );
      expect(find.text('5.75'), findsOneWidget);
      expect(find.text('AED 5.75'), findsNothing);
    });

    testWidgets('supports a custom currency', (tester) async {
      await tester.pumpWidget(_wrap(const SoukPrice(10, currency: 'USD')));
      expect(find.text('USD 10.00'), findsOneWidget);
    });
  });
}
