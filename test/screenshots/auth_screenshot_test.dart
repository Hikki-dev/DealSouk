import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:dealsouk/features/auth/presentation/welcome_screen.dart';
import 'harness.dart';

void main() {
  testWidgets('welcome phone', (tester) async {
    await shoot(
      tester,
      const WelcomeScreen(),
      name: 'welcome_phone',
      overrides: [fakeAuth()],
    );
  });

  testWidgets('welcome phone Arabic comfort text', (tester) async {
    await shoot(
      tester,
      const WelcomeScreen(),
      name: 'welcome_phone_ar',
      locale: const Locale('ar'),
      textScale: 1.6,
      overrides: [fakeAuth()],
    );
  });

  testWidgets('welcome desktop', (tester) async {
    await shoot(
      tester,
      const WelcomeScreen(),
      name: 'welcome_desktop',
      size: Sizes.desktop,
      overrides: [fakeAuth()],
    );
  });
}
