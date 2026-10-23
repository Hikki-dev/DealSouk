import 'package:flutter/material.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';
import 'package:dealsouk/core/theme/theme.dart';

enum DsButtonStyle {
  /// Filled teal. The one main action on a screen.
  primary,

  /// Outlined teal.
  secondary,

  /// Filled saffron. Rewards and "share a price".
  accent,

  /// Text only.
  ghost,

  /// Filled red. Reject, delete.
  danger,

  /// White with a grey outline and the Google logo (Google's sign-in rules).
  google,

  /// Black with the Apple logo (Apple's sign-in rules).
  apple,
}

/// The app's button. 52px tall (44px when [compact]) with a 48px minimum
/// touch target, a visible focus ring and a ripple.
class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = DsButtonStyle.primary,
    this.icon,
    this.leading,
    this.loading = false,
    this.expanded = true,
    this.compact = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final DsButtonStyle style;
  final IconData? icon;

  /// A custom leading widget (for brand logos). Wins over [icon].
  final Widget? leading;
  final bool loading;

  /// Fill the available width. Set false inside a Row.
  final bool expanded;
  final bool compact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = _colors(enabled);
    final height = compact ? 48.0 : 52.0;

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        else if (leading != null)
          leading!
        else if (icon != null)
          Icon(icon, size: 22, color: fg),
        if (loading || leading != null || icon != null)
          const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.display(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height,
          minWidth: expanded ? double.infinity : 64,
        ),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border == null
                ? BorderSide.none
                : BorderSide(color: border, width: 2),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(14),
            focusColor: fg.withValues(alpha: 0.12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 16 : 24,
                vertical: compact ? 10 : 12,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color?) _colors(bool enabled) {
    if (!enabled && !loading) {
      return (const Color(0xFFD9D3C6), const Color(0xFF5A5A52), null);
    }
    switch (style) {
      case DsButtonStyle.primary:
        return (AppTheme.forestDeep, Colors.white, null);
      case DsButtonStyle.secondary:
        return (Colors.white, AppTheme.maroon, AppTheme.forestDeep);
      case DsButtonStyle.accent:
        return (AppTheme.limeAccent, AppTheme.ink, null);
      case DsButtonStyle.ghost:
        return (Colors.transparent, AppTheme.maroon, null);
      case DsButtonStyle.danger:
        return (AppTheme.redAccent, Colors.white, null);
      case DsButtonStyle.google:
        return (Colors.white, const Color(0xFF1F1F1F), const Color(0xFF747775));
      case DsButtonStyle.apple:
        return (Colors.black, Colors.white, null);
    }
  }
}

/// A 48px square icon button with a hairline ring, used for back, close,
/// notifications and map controls.
class DsIconButton extends StatelessWidget {
  const DsIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.filled = false,
    this.color,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  /// Teal fill with a white icon (for the barcode scanner).
  final bool filled;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? AppTheme.forestDeep : Colors.white;
    final fg = filled ? Colors.white : (color ?? AppTheme.ink);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: filled
              ? BorderSide.none
              : const BorderSide(color: AppTheme.line),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 24, color: fg),
          ),
        ),
      ),
    );
  }
}
