import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/state.dart';
import 'responsive_container.dart';

class ShellLayout extends ConsumerWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final adminSubs = ref.watch(adminSubmissionsProvider);

    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final adminCount = adminSubs.length;

    // Determine selected index based on current location
    final String location = GoRouterState.of(context).uri.toString();
    int selectedIndex = 0;
    if (location.startsWith('/stores')) {
      selectedIndex = 1;
    } else if (location.startsWith('/cart')) {
      selectedIndex = 2;
    } else if (location.startsWith('/leaderboard')) {
      selectedIndex = 3;
    } else if (location.startsWith('/admin')) {
      selectedIndex = 4;
    }

    // Dynamic max width: give the Admin moderation deck more horizontal space
    final double maxWidth = selectedIndex == 4 ? 960 : 600;

    return ResponsiveContainer(
      maxWidth: maxWidth,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/stores');
              break;
            case 2:
              context.go('/cart');
              break;
            case 3:
              context.go('/leaderboard');
              break;
            case 4:
              context.go('/admin');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Stores',
          ),
          NavigationDestination(
            icon: Badge(
              label: cartCount > 0 ? Text('$cartCount') : null,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              label: cartCount > 0 ? Text('$cartCount') : null,
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Badge(
              label: adminCount > 0 ? Text('$adminCount') : null,
              isLabelVisible: adminCount > 0,
              backgroundColor: Colors.red,
              child: const Icon(Icons.admin_panel_settings_outlined),
            ),
            selectedIcon: Badge(
              label: adminCount > 0 ? Text('$adminCount') : null,
              isLabelVisible: adminCount > 0,
              backgroundColor: Colors.red,
              child: const Icon(Icons.admin_panel_settings),
            ),
            label: 'Admin',
          ),
        ],
      ),
      child: child,
    );
  }
}
