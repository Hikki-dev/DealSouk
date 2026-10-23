import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/design/breakpoints.dart';
import 'package:dealsouk/core/design/components/ds_nav.dart';
import 'package:dealsouk/core/design/components/ds_surfaces.dart';
import 'package:dealsouk/core/localization/locale_provider.dart';
import 'package:dealsouk/core/offline/connectivity_service.dart';
import 'package:dealsouk/core/offline/sync_service.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/tutorial_overlay.dart';
import 'package:dealsouk/features/cart/presentation/cart_providers.dart';
import 'package:dealsouk/features/profile/presentation/profile_providers.dart';
import 'package:dealsouk/l10n/app_localizations.dart';

/// The frame around the five main tabs.
///
/// * phones: bottom navigation
/// * tablets: a navigation rail on the leading edge
/// * desktop: a top bar with links, search, language and profile
///
/// Each tab screen draws its own content; wide screens centre it with a
/// `PageContainer`.
class ShellLayout extends StatefulWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
  // Session guard so the async check runs once per app launch; the real
  // "show once ever" gate is the persisted version in TutorialOverlay.
  static bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    if (!_tutorialChecked) {
      _tutorialChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (await TutorialOverlay.shouldShow() && mounted) {
          await TutorialOverlay.show(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellFrame(child: widget.child);
  }
}

/// Pure layout of the shell, separated from the one-time tutorial check so it
/// can be rendered in screenshot tests.
class ShellFrame extends ConsumerWidget {
  const ShellFrame({super.key, required this.child, this.locationOverride});

  final Widget child;

  /// Test hook: the route to treat as current. Null reads it from go_router.
  final String? locationOverride;

  static const _routes = ['/', '/stores', '/cart', '/leaderboard', '/profile'];

  static int indexForLocation(String location) {
    if (location == '/' || location.isEmpty) return 0;
    if (location.startsWith('/stores')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/leaderboard')) return 3;
    if (location.startsWith('/profile')) return 4;
    return -1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final savedCount = ref.watch(cartProvider).length;
    final isNavbarVisible = ref.watch(navbarVisibleProvider);
    // Watching here also constructs the SyncController, arming its auto-sync
    // listener for the whole authenticated session (NFR-22).
    final isOnline = ref.watch(isOnlineProvider);
    final pendingSync = ref.watch(syncControllerProvider);
    final showOfflineBanner = !isOnline || pendingSync > 0;
    final profile = ref.watch(userProfileProvider);
    final locale = ref.watch(localeProvider);

    final location =
        locationOverride ?? GoRouterState.of(context).uri.toString();
    final selected = indexForLocation(location);

    final destinations = [
      DsNavDestination(
        label: l.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        route: '/',
      ),
      DsNavDestination(
        label: l.map,
        icon: Icons.location_on_outlined,
        selectedIcon: Icons.location_on_rounded,
        route: '/stores',
      ),
      DsNavDestination(
        label: l.cart,
        icon: Icons.bookmark_border_rounded,
        selectedIcon: Icons.bookmark_rounded,
        route: '/cart',
        badge: savedCount,
      ),
      DsNavDestination(
        label: l.leaderboard,
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events_rounded,
        route: '/leaderboard',
      ),
      DsNavDestination(
        label: l.profile,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        route: '/profile',
      ),
    ];

    void go(int i) => context.go(_routes[i]);

    final banner = showOfflineBanner
        ? DsBanner(
            !isOnline ? l.offlineBanner : l.offlinePendingSync(pendingSync),
            tone: DsBannerTone.offline,
            icon: !isOnline ? Icons.cloud_off_rounded : Icons.sync_rounded,
          )
        : null;

    final cls = context.screenClass;
    final content = Stack(
      children: [
        child,
        if (banner != null)
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: banner,
              ),
            ),
          ),
      ],
    );

    switch (cls) {
      case ScreenClass.compact:
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: content,
          bottomNavigationBar: isNavbarVisible
              ? DsBottomNav(
                  destinations: destinations,
                  selectedIndex: selected,
                  onSelected: go,
                )
              : null,
        );
      case ScreenClass.medium:
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Row(
            children: [
              DsRail(
                destinations: destinations,
                selectedIndex: selected,
                onSelected: go,
              ),
              Expanded(child: content),
            ],
          ),
        );
      case ScreenClass.expanded:
        final name = profile.name.trim();
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              DsTopNav(
                destinations: destinations.take(4).toList(),
                selectedIndex: selected,
                onSelected: go,
                searchHint: l.homeSearchHint,
                onSearch: () => context.go('/search'),
                languageLabel: locale.languageCode == 'ar' ? 'EN' : 'عربي',
                onToggleLanguage: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(
                      Locale(locale.languageCode == 'ar' ? 'en' : 'ar'),
                    ),
                profileInitial: name.isEmpty ? '?' : name.characters.first,
                profileLabel: l.profile,
              ),
              Expanded(child: content),
            ],
          ),
        );
    }
  }
}
