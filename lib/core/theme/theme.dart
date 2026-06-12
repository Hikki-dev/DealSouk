import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warm, approachable palette for everyday grocery price discovery.
  static const Color forestDeep = Color(0xFF7A4A1D);
  static const Color forestMid = Color(0xFFC46A2D);
  static const Color limeAccent = Color(0xFFF5A524);
  static const Color cream = Color(0xFFFFF3E0);
  static const Color creamCircle = Color(0xFFFFD8A8);
  static const Color redAccent = Color(0xFFD94F35);
  static const Color maroon = Color(0xFF5D2E12);

  // Legacy names kept so existing screens restyle automatically
  static const Color emeraldPrimary = forestDeep;
  static const Color emeraldLight = Color(0xFFFFF3E0);
  static const Color amberAccent = Color(
    0xFFFFA000,
  ); // Warm yellow for deals/tokens
  static const Color amberLight = Color(0xFFFFF8E1);
  static const Color background = Color(0xFFFFFAF2);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF212121); // Near black
  static const Color textLight = Color(0xFF757575); // Grey text

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);
    final roundedTextTheme = GoogleFonts.nunitoTextTheme(base.textTheme)
        .copyWith(
          headlineLarge: GoogleFonts.fredoka(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          headlineMedium: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          titleLarge: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          titleMedium: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
          bodyLarge: GoogleFonts.nunito(fontSize: 16, color: textDark),
          bodyMedium: GoogleFonts.nunito(fontSize: 14, color: textLight),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: forestDeep,
        primaryContainer: emeraldLight,
        secondary: amberAccent,
        secondaryContainer: amberLight,
        tertiary: limeAccent,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: textDark,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: forestDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: forestDeep,
        disabledColor: Colors.grey.shade200,
        labelStyle: const TextStyle(
          color: textDark,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      textTheme: roundedTextTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestDeep,
          side: const BorderSide(color: forestDeep, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: forestDeep, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textLight),
        hintStyle: const TextStyle(color: textLight),
      ),
    );
  }
}
