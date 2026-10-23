import 'package:flutter/material.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';

/// A flat white card with a hairline border. Replaces the old blurred-glass
/// cards: cheaper to paint and clearer to read.
class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.selected = false,
    this.color,
    this.borderless = false,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? color;
  final bool borderless;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: selected
          ? const BorderSide(color: AppTheme.forestDeep, width: 2.5)
          : borderless
          ? BorderSide.none
          : const BorderSide(color: AppTheme.line),
    );
    final body = Padding(padding: padding, child: child);
    final card = Material(
      color: color ?? Colors.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
    if (onTap == null || semanticLabel == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: card,
    );
  }
}

enum DsBannerTone { info, warn, offline, good }

/// A full-width notice: offline, price dropped, privacy hint.
class DsBanner extends StatelessWidget {
  const DsBanner(
    this.message, {
    super.key,
    this.tone = DsBannerTone.info,
    this.icon,
    this.action,
  });

  final String message;
  final DsBannerTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, ic) = switch (tone) {
      DsBannerTone.info => (
        AppTheme.emeraldLight,
        AppTheme.maroon,
        Icons.info_outline_rounded,
      ),
      DsBannerTone.warn => (
        AppTheme.warnLight,
        AppTheme.warnText,
        Icons.error_outline_rounded,
      ),
      DsBannerTone.offline => (
        const Color(0xFF2B3640),
        Colors.white,
        Icons.cloud_off_rounded,
      ),
      DsBannerTone.good => (
        AppTheme.goodLight,
        AppTheme.goodText,
        Icons.check_circle_outline_rounded,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: tone == DsBannerTone.offline,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon ?? ic, color: fg, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
      ),
    );
  }
}

/// A grey placeholder block that shimmers while content loads. Shows a still
/// block when the system asks to reduce motion.
class DsSkeleton extends StatefulWidget {
  const DsSkeleton({super.key, this.width, this.height = 16, this.radius = 10});

  final double? width;
  final double height;
  final double radius;

  @override
  State<DsSkeleton> createState() => _DsSkeletonState();
}

class _DsSkeletonState extends State<DsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1 + 2 * t - 0.5, 0),
                end: Alignment(-1 + 2 * t + 0.5, 0),
                colors: const [
                  Color(0xFFEDE4D2),
                  Color(0xFFF7F0E2),
                  Color(0xFFEDE4D2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A product-row shaped skeleton (image, two lines, price).
class DsListRowSkeleton extends StatelessWidget {
  const DsListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const DsCard(
      child: Row(
        children: [
          DsSkeleton(width: 64, height: 64, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsSkeleton(height: 16),
                SizedBox(height: 8),
                DsSkeleton(width: 120, height: 12),
              ],
            ),
          ),
          SizedBox(width: 12),
          DsSkeleton(width: 56, height: 24),
        ],
      ),
    );
  }
}

/// Segmented control (tabs inside a screen).
class DsSegmented extends StatelessWidget {
  const DsSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.sand2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: labels[i],
                excludeSemantics: true,
                child: Material(
                  color: i == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  elevation: i == selected ? 1 : 0,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: BorderRadius.circular(11),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.body(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: i == selected
                                  ? AppTheme.ink
                                  : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A rounded progress bar (tokens toward a voucher, challenge progress).
class DsProgressBar extends StatelessWidget {
  const DsProgressBar({
    super.key,
    required this.value,
    this.color = AppTheme.limeAccent,
    this.trackColor,
    this.height = 10,
  });

  final double value;
  final Color color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color,
          backgroundColor: trackColor ?? AppTheme.sand2,
        ),
      ),
    );
  }
}

/// Step indicator for the four-step price submission.
class DsStepBar extends StatelessWidget {
  const DsStepBar({super.key, required this.total, required this.current});

  final int total;

  /// Zero-based index of the active step.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i <= current ? AppTheme.forestDeep : AppTheme.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

/// Section heading with an optional trailing action ("See all").
class DsSectionHeader extends StatelessWidget {
  const DsSectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppFonts.display(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
