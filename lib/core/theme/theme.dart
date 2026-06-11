import 'package:flutter/material.dart';

class AppTheme {
  // ── Forest & Lime palette (reference design) ──
  static const Color forestDeep = Color(0xFF0C3B2E);    // Dark forest green — headers, nav, primary
  static const Color forestMid = Color(0xFF155D44);     // Lighter forest for gradients
  static const Color limeAccent = Color(0xFFC6E86B);    // Lime — CTAs, highlights
  static const Color cream = Color(0xFFFBF3E0);         // Cream — category band, bottom nav
  static const Color creamCircle = Color(0xFFF3E2BF);   // Darker cream — category circles
  static const Color redAccent = Color(0xFFC0392B);     // "See more" / section accents
  static const Color maroon = Color(0xFF6E1E2A);        // Section headings ("You might need")

  // Legacy names kept so existing screens restyle automatically
  static const Color emeraldPrimary = forestDeep;
  static const Color emeraldLight = Color(0xFFE4EFE7);
  static const Color amberAccent = Color(0xFFFFA000);   // Warm orange/yellow for deals/tokens
  static const Color amberLight = Color(0xFFFFF8E1);
  static const Color background = Color(0xFFFAF8F3);    // Warm off-white
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1A2E24);      // Near-black green for readability
  static const Color textLight = Color(0xFF6B7280);     // Gray for helper texts

  static ThemeData get lightTheme {
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
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: forestDeep,
        disabledColor: Colors.grey.shade200,
        labelStyle: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: TextStyle(fontSize: 16, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
