import 'package:go_router/go_router.dart';
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

final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    // Welcome Screen outside Shell Layout
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),

    // Shell Layout wrapping Core Tabs
    ShellRoute(
      builder: (context, state, child) {
        return ShellLayout(child: child);
      },
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

    // Standalone Screens
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
          bounty: extra?['bounty'] as int?,
        );
      },
    ),
  ],
);
