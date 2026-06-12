import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_provider.dart';
import '../widgets/shell_layout.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/products/search_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/stores/store_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/submissions/submit_price_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/profile/profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(WidgetRef ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/welcome',
    redirect: (context, state) {
      final status = authState.status;
      final onWelcome = state.matchedLocation == '/welcome';

      if (status == AuthStatus.unknown) return null;

      if (status == AuthStatus.unauthenticated) {
        return onWelcome ? null : '/welcome';
      }

      // Authenticated or guest — don't stay on welcome
      if (onWelcome) return '/';

      // Only real admins can reach /admin
      if (state.matchedLocation == '/admin' && !authState.isAdmin) return '/';

      // Guests can't submit prices or view profile
      if (authState.isGuest &&
          (state.matchedLocation.startsWith('/submit-price') ||
              state.matchedLocation == '/profile')) {
        return '/';
      }

      return null;
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
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProductDetailScreen(productId: id);
        },
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
      final status = authState.status;
      final onWelcome = state.matchedLocation == '/welcome';

      if (status == AuthStatus.unknown) return null;
      if (status == AuthStatus.unauthenticated) {
        return onWelcome ? null : '/welcome';
      }
      if (onWelcome) return '/';
      if (state.matchedLocation == '/admin' && !authState.isAdmin) return '/';
      if (authState.isGuest &&
          (state.matchedLocation.startsWith('/submit-price') ||
              state.matchedLocation == '/profile')) {
        return '/';
      }

      return null;
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
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
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

// Legacy static router kept for compatibility with existing imports
final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
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
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
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
      path: '/product/:id',
      builder: (_, state) =>
          ProductDetailScreen(productId: state.pathParameters['id'] ?? ''),
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
