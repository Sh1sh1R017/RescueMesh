import 'package:flutter/material.dart';

class AppTheme {
  // High contrast colors for disaster scenarios
  static const Color primaryColor = Color(0xFFD32F2F); // High alert red
  static const Color secondaryColor = Color(0xFFFFA000); // Warning amber
  static const Color backgroundColor = Color(0xFF121212); // Battery saving dark mode
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color(0xFFB0B0B0);
  
  static const Color safeColor = Color(0xFF388E3C); // Green for safe/resolved
  static const Color infoColor = Color(0xFF1976D2); // Blue for info/resources

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: primaryColor,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
        bodyLarge: TextStyle(fontSize: 18, color: textColor),
        bodyMedium: TextStyle(fontSize: 16, color: textSecondaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60), // Large tap targets
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
