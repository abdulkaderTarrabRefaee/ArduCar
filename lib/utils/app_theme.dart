import 'package:flutter/material.dart';

/// Application theme configuration
///
/// Provides a modern dark theme with cyan/teal accent colors
/// optimized for the Arduino car controller interface

class AppTheme {
  /// Primary color - Cyan
  static const Color primaryColor = Color(0xFF00BCD4);

  /// Secondary color - Teal
  static const Color secondaryColor = Color(0xFF00897B);

  /// Error/Stop color - Red
  static const Color errorColor = Color(0xFFFF5252);

  /// Success/Go color - Green
  static const Color successColor = Color(0xFF4CAF50);

  /// Warning color - Orange
  static const Color warningColor = Color(0xFFFF9800);

  /// Surface color - Dark grey
  static const Color surfaceColor = Color(0xFF1E1E1E);

  /// Background color - Darker grey
  static const Color backgroundColor = Color(0xFF121212);

  /// Card color - Slightly lighter than surface
  static const Color cardColor = Color(0xFF2C2C2C);

  /// Get the dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
      ),

      // Background color
      scaffoldBackgroundColor: backgroundColor,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // OutlinedButton theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // TextButton theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // FloatingActionButton theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: primaryColor,
        size: 24,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.white24,
        thickness: 1,
        space: 16,
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: Colors.white24,
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.white24,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
      ),
    );
  }

  /// Get gradient background for special elements
  static LinearGradient get primaryGradient {
    return LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Get gradient for stop/emergency button
  static LinearGradient get dangerGradient {
    return LinearGradient(
      colors: [errorColor, Colors.red.shade700],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Get gradient for success/go button
  static LinearGradient get successGradient {
    return LinearGradient(
      colors: [successColor, Colors.green.shade700],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
