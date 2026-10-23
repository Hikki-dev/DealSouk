import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';

/// Meaning of a [DsTag]. Always paired with text, never colour alone.
enum DsTone { neutral, good, warn, bad, teal }

/// A small status label: "Fresh", "Stale 72h+", "Photo verified".
class DsTag extends StatelessWidget {
  const DsTag(this.label, {super.key, this.tone = DsTone.neutral, this.icon});

  final String label;
  final DsTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      DsTone.neutral => (AppTheme.sand2, AppTheme.ink),
      DsTone.good => (AppTheme.goodLight, AppTheme.goodText),
      DsTone.warn => (AppTheme.warnLight, AppTheme.warnText),
      DsTone.bad => (AppTheme.badLight, AppTheme.badText),
      DsTone.teal => (AppTheme.emeraldLight, AppTheme.maroon),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A selectable filter chip. 48px tall so it is easy to hit.
class DsChip extends StatelessWidget {
  const DsChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppTheme.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppTheme.forestDeep : Colors.white,
        shape: StadiumBorder(
          side: selected
              ? BorderSide.none
              : const BorderSide(color: AppTheme.line),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppFonts.body(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of [DsChip]s that scrolls sideways.
class DsChipRow extends StatelessWidget {
  const DsChipRow({super.key, required this.chips, this.padding});

  final List<Widget> chips;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

/// Price shown as a small "AED" and a large figure, in the shopper's language.
///
/// English: `AED 9.50`. Arabic: `٩٫٥٠ د.إ` with Arabic-Indic digits. [best]
/// colours it green for the cheapest price; [muted] greys out stale prices.
class DsPrice extends StatelessWidget {
  const DsPrice(
    this.amount, {
    super.key,
    this.size = 22,
    this.best = false,
    this.muted = false,
    this.showCurrency = true,
    this.color,
  });

  final double amount;
  final double size;
  final bool best;
  final bool muted;
  final bool showCurrency;
  final Color? color;

  /// Formats [amount] with two decimals for [locale] (Arabic-Indic for `ar`).
  static String format(double amount, String locale) =>
      NumberFormat('0.00', locale).format(amount);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fg =
        color ??
        (best
            ? AppTheme.good
            : muted
            ? AppTheme.textLight
            : AppTheme.ink);
    final figure = Text(
      format(amount, locale),
      maxLines: 1,
      style: AppFonts.display(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: fg,
        letterSpacing: -0.2,
      ),
    );
    if (!showCurrency) return figure;
    final cur = Text(
      locale == 'ar' ? 'د.إ' : 'AED',
      style: AppFonts.body(
        fontSize: (size * 0.6).clamp(12, 18),
        fontWeight: FontWeight.w600,
        color: color?.withValues(alpha: 0.85) ?? AppTheme.textLight,
      ),
    );
    final gap = SizedBox(width: lerpDouble(3, 5, size / 44)!);
    // Row is mirrored in RTL, so list the figure first there to put it on the
    // right and the currency to its left.
    return Semantics(
      label: '${locale == 'ar' ? 'درهم' : 'AED'} ${format(amount, locale)}',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: rtl ? [figure, gap, cur] : [cur, gap, figure],
        ),
      ),
    );
  }
}
