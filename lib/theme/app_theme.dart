import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // =========================
  // Twenty.tn Brand Colors
  // =========================

  /// Primary Navy Blue
  static const Color primaryColor = Color(0xFF01284F);

  /// Mint Green
  static const Color secondaryColor = Color(0xFF63E1B6);

  /// Turquoise Accent
  static const Color accentColor = Color(0xFF3FCAC6);

  /// Background
  static const Color bgColor = Color(0xFFF7F9FB);

  /// White
  static const Color cardColor = Colors.white;

  /// Text
  static const Color textPrimary = Color(0xFF0B2B4C);
  static const Color textSecondary = Color(0xFF6A7688);

  /// Status
  static const Color successColor = Color(0xFF27C76F);
  static const Color errorColor = Color(0xFFE74C3C);

  /// Borders
  static const Color borderColor = Color(0xFFDCE7F2);
  static const Color dividerColor = Color(0xFFE8EEF5);

  /// Search
  static const Color searchBg = Colors.white;

  /// Icons & Hint
  static const Color iconColor = primaryColor;
  static const Color hintColor = Color(0xFF98A6B8);

  // =========================
  // Theme
  // =========================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: iconColor,
        size: 22,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(
          color: textPrimary,
        ),
        bodyMedium: const TextStyle(
          color: textSecondary,
        ),
        bodySmall: const TextStyle(
          color: textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: primaryColor,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderColor),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchBg,
        hintStyle: const TextStyle(
          color: hintColor,
          fontSize: 15,
        ),
        prefixIconColor: iconColor,
        suffixIconColor: iconColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: secondaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: errorColor,
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: Color(0x553FCAC6),
        selectionHandleColor: secondaryColor,
      ),
      splashColor: secondaryColor.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
    );
  }
}
