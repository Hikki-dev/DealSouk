import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/state.dart';
import '../theme/theme.dart';
import 'responsive_container.dart';

class ShellLayout extends ConsumerWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    final String location = GoRouterState.of(context).uri.toString();
    int selectedIndex = -1;
    if (location == '/' || location.isEmpty) {
      selectedIndex = 0;
    } else if (location.startsWith('/stores')) {
      selectedIndex = 1;
    } else if (location.startsWith('/cart')) {
      selectedIndex = 2;
    } else if (location.startsWith('/leaderboard')) {
      selectedIndex = 3;
    } else if (location.startsWith('/profile')) {
      selectedIndex = 4;
    }

    final double bottomPad = MediaQuery.of(context).padding.bottom;

    // Floating pill navigation bar matching the mockup
    return ResponsiveContainer(
      maxWidth: 600,
      extendBody: true,
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SoukNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              selected: selectedIndex == 0,
              onTap: () => context.go('/'),
            ),
            _SoukNavItem(
              icon: Icons.map_outlined,
              selectedIcon: Icons.map_rounded,
              selected: selectedIndex == 1,
              onTap: () => context.go('/stores'),
            ),
            _SoukNavItem(
              icon: Icons.shopping_basket_outlined,
              selectedIcon: Icons.shopping_basket_rounded,
              selected: selectedIndex == 2,
              badge: cartCount,
              onTap: () => context.go('/cart'),
            ),
            _SoukNavItem(
              icon: Icons.emoji_events_outlined,
              selectedIcon: Icons.emoji_events_rounded,
              selected: selectedIndex == 3,
              onTap: () => context.go('/leaderboard'),
            ),
            _SoukNavItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              selected: selectedIndex == 4,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _SoukNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _SoukNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 40 : 0,
              height: selected ? 40 : 0,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), // Soft green active pill background
                shape: BoxShape.circle,
              ),
            ),
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? AppTheme.forestDeep : Colors.grey.shade400,
              size: 22,
            ),
            if (badge > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
