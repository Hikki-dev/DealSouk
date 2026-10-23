import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';
import 'package:dealsouk/core/widgets/souk_widgets.dart' show DirectionalIcon;

/// One destination in the main navigation.
class DsNavDestination {
  const DsNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final int badge;
}

/// Bottom navigation for phones: five labelled items, a clear selected pill
/// and a hairline top border. Always labelled, so nothing is icon-only.
class DsBottomNav extends StatelessWidget {
  const DsBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DsNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _BottomItem(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final DsNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.forestDeep : AppTheme.textLight;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.badge > 0
          ? '${destination.label}, ${destination.badge}'
          : destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56,
                    height: 30,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.emeraldLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                  if (destination.badge > 0)
                    PositionedDirectional(
                      end: 4,
                      top: -4,
                      child: DsCountBadge(destination.badge),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.body(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red count bubble on a nav item.
class DsCountBadge extends StatelessWidget {
  const DsCountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.redAccent,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppFonts.body(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Left navigation rail for tablets and narrow desktop windows.
class DsRail extends StatelessWidget {
  const DsRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DsNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: BorderDirectional(end: BorderSide(color: AppTheme.line)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            const DsBrandMark(size: 44),
            const SizedBox(height: 18),
            for (var i = 0; i < destinations.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _RailItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final DsNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.maroon : AppTheme.textLight;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppTheme.emeraldLight : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 76,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 24,
                      color: color,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (destination.badge > 0)
                  PositionedDirectional(
                    end: 12,
                    top: 6,
                    child: DsCountBadge(destination.badge),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "DS" mark in a teal circle.
class DsBrandMark extends StatelessWidget {
  const DsBrandMark({super.key, this.size = 40, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onDark ? Colors.white : AppTheme.forestDeep,
      ),
      child: Text(
        'DS',
        style: AppFonts.display(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: onDark ? AppTheme.forestDeep : Colors.white,
        ),
      ),
    );
  }
}

/// Top navigation bar for desktop windows: brand, four links with an
/// underline on the current one, a search field, language and profile.
class DsTopNav extends StatelessWidget {
  const DsTopNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.searchHint,
    required this.onSearch,
    required this.languageLabel,
    required this.onToggleLanguage,
    required this.profileInitial,
    required this.profileLabel,
    this.profilePhotoUrl,
  });

  /// The four content destinations. Profile sits at the far end as an avatar.
  final List<DsNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String searchHint;
  final VoidCallback onSearch;
  final String languageLabel;
  final VoidCallback onToggleLanguage;
  final String profileInitial;
  final String profileLabel;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.line)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 72,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1344),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const DsBrandMark(size: 40),
                              const SizedBox(width: 10),
                              Text(
                                'DealSouk',
                                style: AppFonts.display(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      for (var i = 0; i < destinations.length; i++)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 20),
                          child: _TopLink(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            onTap: () => onSelected(i),
                          ),
                        ),
                      const Spacer(),
                      SizedBox(
                        width: 340,
                        child: Semantics(
                          button: true,
                          label: searchHint,
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: onSearch,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.line,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      searchHint,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.body(
                                        fontSize: 15,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Center(
                        child: Semantics(
                          button: true,
                          label: languageLabel,
                          excludeSemantics: true,
                          child: Material(
                            color: Colors.white,
                            shape: const StadiumBorder(
                              side: BorderSide(color: AppTheme.line),
                            ),
                            child: InkWell(
                              onTap: onToggleLanguage,
                              customBorder: const StadiumBorder(),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                  minWidth: 64,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Center(
                                  widthFactor: 1,
                                  heightFactor: 1,
                                  child: Text(
                                    languageLabel,
                                    style: AppFonts.body(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        button: true,
                        label: profileLabel,
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => context.go('/profile'),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.limeAccent,
                              border: selectedIndex == destinations.length
                                  ? Border.all(
                                      color: AppTheme.forestDeep,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: Text(
                              profileInitial,
                              style: AppFonts.display(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopLink extends StatelessWidget {
  const _TopLink({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final DsNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.forestDeep : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                destination.label,
                style: AppFonts.body(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.maroon : AppTheme.textLight,
                ),
              ),
              if (destination.badge > 0) ...[
                const SizedBox(width: 8),
                DsCountBadge(destination.badge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Top bar for pushed screens: a 48px back button, a bold title and actions,
/// on the sand background. Replaces the old teal AppBar.
class DsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DsAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
    this.backIcon = Icons.arrow_back_rounded,
    this.closeInstead = false,
  });

  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBack;
  final IconData backIcon;

  /// Shows a close (X) instead of a back arrow, for modal-style flows.
  final bool closeInstead;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop() || context.canPop();
    return Material(
      color: AppTheme.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showBack && (canPop || onBack != null)) ...[
                  Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    excludeSemantics: true,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppTheme.line),
                      ),
                      child: InkWell(
                        onTap:
                            onBack ??
                            () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                Navigator.of(context).maybePop();
                              }
                            },
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: closeInstead
                              ? const Icon(Icons.close_rounded, size: 24)
                              : DirectionalIcon(backIcon, size: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
