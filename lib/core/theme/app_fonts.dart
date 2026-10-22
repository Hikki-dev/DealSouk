import 'package:flutter/material.dart';

/// Bundled Readex Pro (Latin + Arabic in one family), so text never waits on a
/// network font fetch and Arabic no longer falls back to a system font.
class AppFonts {
  AppFonts._();

  static const String family = 'ReadexPro';

  /// Headings and prices.
  static TextStyle display({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: family,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
  );

  /// Body copy and labels.
  static TextStyle body({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) => display(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
  );
}
