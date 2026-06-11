import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/state.dart';
import '../theme/theme.dart';
import 'responsive_container.dart';
import 'souk_widgets.dart';

class ShellLayout extends ConsumerWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final adminSubs = ref.watch(adminSubmissionsProvider);

    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final adminCount = adminSubs.length;

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

    final double maxWidth = selectedIndex == 4 ? 960 : 600;
    final double bottomPad = MediaQuery.of(context).padding.bottom;

    // Cream bar with scalloped top trim — the reference design's signature nav.
    return ResponsiveContainer(
      maxWidth: maxWidth,
      extendBody: true,
      bottomNavigationBar: ClipPath(
        clipper: const ScallopClipper.up(scallopRadius: 8),
        child: Container(
          color: AppTheme.cream,
          padding: EdgeInsets.fromLTRB(12, 16, 12, bottomPad + 8),
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
                icon: Icons.storefront_outlined,
                selectedIcon: Icons.storefront_rounded,
                selected: selectedIndex == 1,
                onTap: () => context.go('/stores'),
              ),
              _SoukNavItem(
                icon: Icons.shopping_cart_outlined,
                selectedIcon: Icons.shopping_cart_rounded,
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
                icon: Icons.admin_panel_settings_outlined,
                selectedIcon: Icons.admin_panel_settings_rounded,
                selected: selectedIndex == 4,
                badge: adminCount,
                badgeColor: AppTheme.redAccent,
                onTap: () => context.go('/admin'),
              ),
            ],
          ),
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
  final Color badgeColor;
  final VoidCallback onTap;

  const _SoukNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    this.badge = 0,
    this.badgeColor = AppTheme.forestDeep,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppTheme.forestDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.forestDeep.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? AppTheme.limeAccent : AppTheme.forestDeep.withOpacity(0.55),
              size: 22,
            ),
            if (badge > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.cream, width: 1.5),
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
