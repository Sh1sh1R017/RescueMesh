import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Functional, utilitarian color palette
  static const Color neutralBase = Color(0xFF1A1C1E); // Near-black background
  static const Color surfaceColor = Color(0xFF2D3033); // Slightly lighter for contrast
  static const Color surfaceVariantColor = Color(0xFF3F4347); // For dividers and borders
  
  static const Color textPrimaryColor = Color(0xFFE2E2E2);
  static const Color textSecondaryColor = Color(0xFF9E9E9E);
  
  // Single alert color, only used for critical states
  static const Color criticalColor = Color(0xFFD32F2F); 

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: neutralBase,
      colorScheme: const ColorScheme.dark(
        primary: textPrimaryColor, // Default primary is neutral text
        onPrimary: neutralBase,
        secondary: surfaceVariantColor,
        surface: surfaceColor,
        background: neutralBase,
        error: criticalColor,
        onSurface: textPrimaryColor,
      ),
      
      // Structural typography. Regular weight by default, bold reserved for emphasis.
      textTheme: TextTheme(
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: textPrimaryColor),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimaryColor),
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimaryColor),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondaryColor),
        labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondaryColor),
        
        // Monospace/Condensed for system data (Node IDs, Timestamps, Logs)
        labelMedium: GoogleFonts.robotoMono(
          fontSize: 12, 
          fontWeight: FontWeight.w500, 
          color: textSecondaryColor,
        ),
      ),
      
      // Intentional shape rounding
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Tight 4px radius for data density
          side: const BorderSide(color: surfaceVariantColor, width: 1), // Harsh border
        ),
      ),
      
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: textSecondaryColor,
      ),
      
      dividerTheme: const DividerThemeData(
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
            borderRadius: BorderRadius.circular(8), // 8px for primary interactive elements
            side: const BorderSide(color: surfaceVariantColor, width: 1),
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: surfaceVariantColor, width: 1),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: neutralBase,
        elevation: 0,
        centerTitle: false, // Left aligned utility style
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimaryColor),
      ),
    );
  }
}
