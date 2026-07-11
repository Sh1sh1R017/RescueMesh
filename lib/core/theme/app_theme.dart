import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Dark Theme Palette ---
  static const Color darkNeutralBase = Color(0xFF1A1C1E);
  static const Color darkSurfaceColor = Color(0xFF2D3033);
  static const Color darkSurfaceVariantColor = Color(0xFF3F4347);
  static const Color darkTextPrimaryColor = Color(0xFFE2E2E2);
  static const Color darkTextSecondaryColor = Color(0xFF9E9E9E);
  
  // --- Light Theme Palette ---
  static const Color lightNeutralBase = Color(0xFFFDFCFF);
  static const Color lightSurfaceColor = Color(0xFFF1F3F5);
  static const Color lightSurfaceVariantColor = Color(0xFFE0E2E5);
  static const Color lightTextPrimaryColor = Color(0xFF1A1C1E);
  static const Color lightTextSecondaryColor = Color(0xFF5E6368);

  // Single alert color, used for critical states in both modes
  static const Color criticalColor = Color(0xFFD32F2F); 

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    neutralBase: darkNeutralBase,
    surfaceColor: darkSurfaceColor,
    surfaceVariantColor: darkSurfaceVariantColor,
    textPrimaryColor: darkTextPrimaryColor,
    textSecondaryColor: darkTextSecondaryColor,
  );

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    neutralBase: lightNeutralBase,
    surfaceColor: lightSurfaceColor,
    surfaceVariantColor: lightSurfaceVariantColor,
    textPrimaryColor: lightTextPrimaryColor,
    textSecondaryColor: lightTextSecondaryColor,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color neutralBase,
    required Color surfaceColor,
    required Color surfaceVariantColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: neutralBase,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: textPrimaryColor, 
        onPrimary: neutralBase,
        secondary: surfaceVariantColor,
        onSecondary: textPrimaryColor,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        background: neutralBase,
        onBackground: textPrimaryColor,
        error: criticalColor,
        onError: Colors.white,
      ),
      
      textTheme: TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textPrimaryColor),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimaryColor),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimaryColor),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondaryColor),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondaryColor),
        
        labelMedium: GoogleFonts.robotoMono(
          fontSize: 12, 
          fontWeight: FontWeight.w500, 
          color: textSecondaryColor,
        ),
      ),
      
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: surfaceVariantColor, width: 1),
        ),
      ),
      
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: textSecondaryColor,
      ),
      
      dividerTheme: DividerThemeData(
        color: surfaceVariantColor,
        thickness: 1,
        space: 1,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceColor,
          foregroundColor: textPrimaryColor,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: surfaceVariantColor, width: 1),
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: surfaceVariantColor, width: 1),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: neutralBase,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimaryColor),
      ),
    );
  }
}
