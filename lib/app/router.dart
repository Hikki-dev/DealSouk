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

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(WidgetRef ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/welcome',
    redirect: (context, state) {
      return resolveRouteRedirect(
        matchedLocation: state.matchedLocation,
        isAuthUnknown: authState.status == AuthStatus.unknown,
        isUnauthenticated: authState.status == AuthStatus.unauthenticated,
        isGuest: authState.isGuest,
        isAdmin: authState.isAdmin,
      );
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      ShellRoute(
        builder: (ctx, st, child) => ShellLayout(child: child),
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
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/scan-barcode',
        builder: (context, state) => BarcodeScanScreen(
          returnScannedCode: state.uri.queryParameters['return'] == '1',
        ),
      ),
      GoRoute(
        path: '/submit-price',
        builder: (context, state) {
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
}

// Keep a simple static router for app.dart to reference;
// the redirect logic gets auth state via the provider listener below.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/welcome',
    refreshListenable: GoRouterRefreshStream(
      Stream.fromFuture(Future.value(authState)),
    ),
    redirect: (context, state) {
      return resolveRouteRedirect(
        matchedLocation: state.matchedLocation,
        isAuthUnknown: authState.status == AuthStatus.unknown,
        isUnauthenticated: authState.status == AuthStatus.unauthenticated,
        isGuest: authState.isGuest,
        isAdmin: authState.isAdmin,
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

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
