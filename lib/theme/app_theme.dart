import 'package:flutter/material.dart';

// Comprehensive theme configuration for DexCom app
// Colors: Blue, White, Green with Glucose-related themes

class AppTheme {
  // Color Palette
  static const Color primaryBlue = Color(0xFF2563EB); // Deep Blue
  static const Color lightBlue = Color(0xFF3B82F6); // Light Blue
  static const Color darkBlue = Color(0xFF1E40AF); // Dark Blue

  static const Color successGreen = Color(0xFF10B981); // Green (Normal Range)
  static const Color lightGreen = Color(0xFF6EE7B7); // Light Green
  static const Color darkGreen = Color(0xFF059669); // Dark Green

  static const Color warningOrange = Color(
    0xFFF59E0B,
  ); // Orange (Slightly High)
  static const Color dangerRed = Color(0xFEF5454B); // Red (High/Hyper)
  static const Color cautionYellow = Color(0xFFFCD34D); // Yellow (Caution)
  static const Color lowRed = Color(0xFFEF4444); // Red (Low/Hypo)

  static const Color white = Colors.white;
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFFD1D5DB);
  static const Color darkGray = Color(0xFF4B5563);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkCard = Color(0xFF2D3748);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: successGreen,
      surface: lightGray,
      error: dangerRed,
      outline: mediumGray,
    ),
    scaffoldBackgroundColor: lightGray,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: white,
      foregroundColor: darkBlue,
      centerTitle: false,
      iconTheme: IconThemeData(color: darkBlue),
      titleTextStyle: TextStyle(
        color: darkBlue,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightGray, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        backgroundColor: white,
        side: const BorderSide(color: lightBlue, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerRed, width: 1.5),
      ),
      prefixIconColor: lightBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: white,
      elevation: 0,
      surfaceTintColor: white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: successGreen,
      foregroundColor: white,
      elevation: 4,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: darkBlue,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: darkBlue,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: darkBlue,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: darkGray, fontSize: 16),
      bodyMedium: TextStyle(color: darkGray, fontSize: 14),
      labelSmall: TextStyle(color: mediumGray, fontSize: 12),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: lightBlue,
      secondary: lightGreen,
      surface: darkSurface,
      error: dangerRed,
      outline: darkGray,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: darkSurface,
      foregroundColor: lightBlue,
      centerTitle: false,
      iconTheme: IconThemeData(color: lightBlue),
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[800]!, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightBlue,
        foregroundColor: darkBackground,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightBlue,
        backgroundColor: darkCard,
        side: const BorderSide(color: lightBlue, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dangerRed, width: 1.5),
      ),
      prefixIconColor: lightBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: darkSurface,
      elevation: 0,
      surfaceTintColor: darkSurface,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: lightGreen,
      foregroundColor: darkBackground,
      elevation: 4,
    ),
    textTheme: TextTheme(
      headlineLarge: const TextStyle(
        color: white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: const TextStyle(
        color: white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: const TextStyle(
        color: lightBlue,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: Colors.grey[300], fontSize: 16),
      bodyMedium: TextStyle(color: Colors.grey[400], fontSize: 14),
      labelSmall: TextStyle(color: Colors.grey[600], fontSize: 12),
    ),
  );

  // Glucose Status Colors
  static Color getGlucoseStatusColor(double value) {
    if (value < 70) return lowRed; // Hypoglycemia
    if (value < 100) return successGreen; // Normal fasting
    if (value < 140) return lightGreen; // Normal range
    if (value < 180) return warningOrange; // Slightly high
    if (value < 250) return dangerRed; // High
    return dangerRed; // Very high
  }

  static String getGlucoseStatusText(double value) {
    if (value < 70) return 'Low';
    if (value < 100) return 'Normal';
    if (value < 140) return 'Good';
    if (value < 180) return 'Elevated';
    if (value < 250) return 'High';
    return 'Critical';
  }

  // Glucose Status Icon with Emoji
  static String getGlucoseStatusEmoji(double value) {
    if (value < 70) return '⚠️'; // Low
    if (value < 100) return '✅'; // Normal fasting
    if (value < 140) return '🎯'; // Good range
    if (value < 180) return '⚡'; // Elevated
    if (value < 250) return '🔴'; // High
    return '🆘'; // Critical
  }

  // Glucose Status Icon
  static IconData getGlucoseStatusIcon(double value) {
    if (value < 70) return Icons.warning_rounded; // Low
    if (value < 140) return Icons.check_circle_rounded; // Normal/Good
    if (value < 180) return Icons.info_rounded; // Elevated
    return Icons.error_rounded; // High/Critical
  }
}
