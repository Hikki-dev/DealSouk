import 'package:flutter/material.dart';

/// Screen size classes used across the app.
///
/// * [compact]  phones, below 600 logical px: bottom navigation, one column.
/// * [medium]   tablets and small windows, 600 to 1023: navigation rail.
/// * [expanded] laptops and desktops, 1024 and up: top navigation bar and
///   multi-column pages centred in a [PageContainer].
enum ScreenClass { compact, medium, expanded }

class Breakpoints {
  Breakpoints._();

  static const double medium = 600;
  static const double expanded = 1024;

  /// Content never gets wider than this on very large monitors.
  static const double maxContentWidth = 1200;

  static ScreenClass of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  static ScreenClass forWidth(double width) {
    if (width >= expanded) return ScreenClass.expanded;
    if (width >= medium) return ScreenClass.medium;
    return ScreenClass.compact;
  }
}

extension ScreenClassContext on BuildContext {
  ScreenClass get screenClass => Breakpoints.of(this);
  bool get isCompact => screenClass == ScreenClass.compact;
  bool get isMedium => screenClass == ScreenClass.medium;
  bool get isExpanded => screenClass == ScreenClass.expanded;

  /// True when the window is wide enough for side-by-side layouts.
  bool get isWide => screenClass != ScreenClass.compact;
}

/// Centres page content and caps its width on large screens, with side
/// padding that grows with the window. On phones it is just padding.
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;

  /// Overrides the default padding (16 on phones, 24 on tablets, 32 wide).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cls = context.screenClass;
    final pad =
        padding ??
        EdgeInsets.symmetric(
          horizontal: switch (cls) {
            ScreenClass.compact => 16,
            ScreenClass.medium => 24,
            ScreenClass.expanded => 32,
          },
        );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: pad, child: child),
      ),
    );
  }
}

/// Lays children out in equal columns that wrap, with a column count chosen
/// from the available width. Used for product and store grids.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.spacing = 16,
    this.maxColumns = 4,
    this.childAspectRatio,
    this.mainAxisExtent,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;
  final double? childAspectRatio;

  /// Fixed tile height. Wins over [childAspectRatio] when set.
  final double? mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = ((width + spacing) / (minTileWidth + spacing)).floor();
        columns = columns.clamp(1, maxColumns);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: mainAxisExtent != null
              ? (width - spacing * (columns - 1)) / columns / mainAxisExtent!
              : (childAspectRatio ?? 1),
          children: children,
        );
      },
    );
  }
}
