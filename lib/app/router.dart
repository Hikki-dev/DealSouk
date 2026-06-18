import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/app/route_guard.dart';
import 'package:dealsouk/features/auth/presentation/auth_providers.dart';
import 'package:dealsouk/core/widgets/shell_layout.dart';
import 'package:dealsouk/features/auth/presentation/welcome_screen.dart';
import 'package:dealsouk/features/home/presentation/home_screen.dart';
import 'package:dealsouk/features/products/presentation/search_screen.dart';
import 'package:dealsouk/features/products/presentation/barcode_scan_screen.dart';
import 'package:dealsouk/features/products/presentation/product_detail_screen.dart';
import 'package:dealsouk/features/stores/presentation/store_screen.dart';
import 'package:dealsouk/features/cart/presentation/cart_screen.dart';
import 'package:dealsouk/features/submissions/presentation/submit_price_screen.dart';
import 'package:dealsouk/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:dealsouk/features/admin/presentation/admin_screen.dart';
import 'package:dealsouk/features/profile/presentation/profile_screen.dart';
import 'package:dealsouk/features/auth/presentation/unauthorized_screen.dart';
import 'package:dealsouk/features/legal/presentation/privacy_policy_screen.dart';
import 'package:dealsouk/features/saved/presentation/saved_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

// A ChangeNotifier driven by Riverpod's ref.listen so GoRouter re-evaluates
// redirects on every auth state change (not just on the first build).
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (prev, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      return resolveRouteRedirect(
        matchedLocation: state.matchedLocation,
        isAuthUnknown: authState.status == AuthStatus.unknown,
        isUnauthenticated: authState.status == AuthStatus.unauthenticated,
        isGuest: authState.isGuest,
        isAdmin: authState.isAdmin,
        // Browser QA convenience only — never relaxes the guard in release.
        allowGuestProfile: kDebugMode,
      );
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellLayout(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/stores',
            builder: (context, state) => const StoreScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
      GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/scan-barcode',
        builder: (context, state) => BarcodeScanScreen(
          returnScannedCode: state.uri.queryParameters['return'] == '1',
        ),
      ),
      GoRoute(
        path: '/submit-price',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SubmitPriceScreen(
            requestId: extra?['requestId'] as String?,
            prefilledProductName: extra?['productName'] as String?,
            prefilledStoreName: extra?['storeName'] as String?,
          );
        },
      ),
    ],
  );
});
