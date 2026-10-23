// DealSouk integration / end-to-end tests.
//
// Run on a connected device or emulator:
//   flutter test integration_test
//
// For the auth-dependent flows, start the Firebase Auth Emulator first and use a
// registered test phone number (fixed OTP) — see docs/Automated test plan.md §5.
// These drive the REAL app against a backend, so point API_BASE_URL at a staging
// instance:
//   flutter test integration_test \
//     --dart-define=API_BASE_URL=https://dealsouk-staging.onrender.com
//
// The boot test below is runnable today (the app degrades to mock/offline mode if
// Firebase isn't configured). The remaining groups are scaffolds for the golden
// flows in the test plan — fill them in as the emulator harness lands.

import 'package:dealsouk/app/app.dart';
import 'package:dealsouk/features/auth/presentation/welcome_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('app boot', () {
    testWidgets('cold boot lands on the Welcome screen (NFR-01)', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: DealSoukApp()));
      await tester.pump(const Duration(seconds: 1));
      // Unauthenticated users see the Welcome screen.
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  // ── Golden flows (fill in with the Firebase Auth Emulator) ─────────────────
  //
  // group('auth flow (FR-01/02)', () {
  //   testWidgets('phone OTP test number → Home', (tester) async { ... });
  // });
  //
  // group('submit flow (FR-31/36)', () {
  //   testWidgets('submit price → token estimate → appears in feed', ...);
  // });
  //
  // group('cart flow (FR-19/21)', () {
  //   testWidgets('add items → best price → total basket cost', ...);
  // });
  //
  // group('map flow (NFR-04)', () {
  //   testWidgets('map loads real stores < 2s → tap → prices', ...);
  // });
  //
  // group('offline flow (NFR-22)', () {
  //   testWidgets('airplane → submit queued → reconnect → flushed', ...);
  // });
  //
  // group('RTL flow (NFR-20)', () {
  //   testWidgets('switch to Arabic → layout flips RTL + Arabic strings', ...);
  // });
}
