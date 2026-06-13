import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final double borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const PlatformCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.borderRadius = 20.0,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isIos =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    final double alphaMultiplier = isIos ? 0.65 : 0.72;
    final double borderAlpha = isIos ? 0.25 : 0.4;

    Gradient? glassGradient;
    if (gradient is LinearGradient) {
      final lg = gradient as LinearGradient;
      glassGradient = LinearGradient(
        colors: lg.colors
            .map((c) => c.withValues(alpha: alphaMultiplier))
            .toList(),
        begin: lg.begin,
        end: lg.end,
        stops: lg.stops,
        tileMode: lg.tileMode,
        transform: lg.transform,
      );
    } else if (gradient is RadialGradient) {
      final rg = gradient as RadialGradient;
      glassGradient = RadialGradient(
        colors: rg.colors
            .map((c) => c.withValues(alpha: alphaMultiplier))
            .toList(),
        center: rg.center,
        radius: rg.radius,
        stops: rg.stops,
        tileMode: rg.tileMode,
        focal: rg.focal,
        focalRadius: rg.focalRadius,
        transform: rg.transform,
      );
    } else if (gradient is SweepGradient) {
      final sg = gradient as SweepGradient;
      glassGradient = SweepGradient(
        colors: sg.colors
            .map((c) => c.withValues(alpha: alphaMultiplier))
            .toList(),
        center: sg.center,
        startAngle: sg.startAngle,
        endAngle: sg.endAngle,
        stops: sg.stops,
        tileMode: sg.tileMode,
        transform: sg.transform,
      );
    }

    final baseCard = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: glassGradient == null
                ? (color?.withValues(alpha: alphaMultiplier) ??
                      Colors.white.withValues(alpha: alphaMultiplier))
                : null,
            gradient: glassGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                border ??
                Border.all(
                  color: Colors.white.withValues(alpha: borderAlpha),
                  width: 1.5,
                ),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: baseCard);
    }

    return baseCard;
  }
}
