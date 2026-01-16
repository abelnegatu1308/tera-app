import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFFFFA000); // Orange/Amber
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFFFF6F00);

  static const Color darkScaffoldBackgroundColor = Color(0xFF0A0D18);
  static const Color darkCardBackgroundColor = Color(0xFF1C2230);
  static const Color errorColor = Color(0xFFD32F2F);

  static ThemeData get darkTheme {
    const bgColor = darkScaffoldBackgroundColor;
    const seedColor = primaryColor;

    return _buildTheme(
      Brightness.dark,
      seedColor,
      bgColor,
      darkCardBackgroundColor,
    );
  }

  static ThemeData get lightTheme {
    const bgColor = Color(0xFFF5F6F9);
    const seedColor = primaryColor;
    const cardColor = Colors.white;

    return _buildTheme(Brightness.light, seedColor, bgColor, cardColor);
  }

  static ThemeData _buildTheme(
    Brightness brightness,
    Color seedColor,
    Color bgColor,
    Color cardColor,
  ) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        secondary: secondaryColor,
        background: bgColor,
        surface: cardColor,
        error: errorColor,
        brightness: brightness,
        onSurface: textColor,
        onBackground: textColor,
      ),
      scaffoldBackgroundColor: bgColor,
      cardColor: cardColor,
      fontFamily: GoogleFonts.roboto().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        titleSmall: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.roboto(fontSize: 16, color: textColor),
        bodyMedium: GoogleFonts.roboto(fontSize: 14, color: textColor),
        bodySmall: GoogleFonts.roboto(fontSize: 12, color: secondaryTextColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
        prefixIconColor: secondaryTextColor,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
