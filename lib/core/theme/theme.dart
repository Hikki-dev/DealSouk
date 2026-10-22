import 'package:flutter/material.dart';
import 'package:dealsouk/core/theme/app_fonts.dart';

class AppTheme {
  // Gulf teal, sand and saffron. Contrast checked against white / sand:
  // teal 6.1:1, textLight 5.6:1 on sand, redAccent 6.4:1.
  static const Color forestDeep = Color(0xFF0B6B6B); // primary teal
  static const Color forestMid = Color(0xFF1A8782);
  static const Color limeAccent = Color(0xFFF2A91B); // saffron
  static const Color cream = Color(0xFFFBF6EC); // sand, same as background
  static const Color creamCircle = Color(0xFFDCF0EE);
  static const Color redAccent = Color(0xFFB3341F);
  static const Color maroon = Color(0xFF084F52); // deep teal

  // Legacy names kept so existing screens restyle automatically
  static const Color emeraldPrimary = forestDeep;
  static const Color emeraldLight = Color(0xFFDCF0EE);
  static const Color amberAccent = Color(0xFFF2A91B); // deals / tokens (fills)
  static const Color amberLight = Color(0xFFFFF1CF);
  static const Color background = Color(0xFFFBF6EC);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1B2730);
  static const Color textLight = Color(0xFF56626B);

  /// Minimum touch target for every tappable control (ages 14 to 65).
  static const double minTap = 48;

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);
    final textTheme = base.textTheme
        .apply(
          fontFamily: AppFonts.family,
          bodyColor: textDark,
          displayColor: textDark,
        )
        .copyWith(
          headlineLarge: AppFonts.display(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          headlineMedium: AppFonts.display(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          titleLarge: AppFonts.display(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          titleMedium: AppFonts.body(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          bodyLarge: AppFonts.body(fontSize: 16, color: textDark),
          bodyMedium: AppFonts.body(fontSize: 15, color: textLight),
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.family,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      colorScheme: ColorScheme.light(
        primary: forestDeep,
        primaryContainer: emeraldLight,
        secondary: amberAccent,
        secondaryContainer: amberLight,
        tertiary: limeAccent,
        error: redAccent,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: textDark,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: forestDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppFonts.display(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE6DAC4)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: forestDeep,
        disabledColor: Colors.grey.shade200,
        labelStyle: AppFonts.body(
          color: textDark,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: AppFonts.body(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE6DAC4)),
        ),
      ),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppFonts.display(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: maroon,
          side: const BorderSide(color: forestDeep, width: 2),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppFonts.display(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: maroon,
          minimumSize: const Size(64, minTap),
          textStyle: AppFonts.display(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6DAC4), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6DAC4), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: forestDeep, width: 2.5),
        ),
        labelStyle: const TextStyle(color: textLight),
        hintStyle: const TextStyle(color: textLight),
      ),
    );
  }
}
