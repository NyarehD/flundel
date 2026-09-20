import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF0D0F12);
  static const Color surfaceColor = Color(0xFF161920);
  static const Color accentColor = Color(0xFF7C8BA1);
  static const Color primaryText = Color(0xFFECEFF4);
  static const Color secondaryText = Color(0xFF8892B0);
  static const Color highlightColor = Color(0xFFD8DEE9);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        surface: surfaceColor,
        primary: accentColor,
        onSurface: primaryText,
        secondary: secondaryText,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: primaryText,
          fontSize: 48,
          fontWeight: FontWeight.w200,
          letterSpacing: 2.0,
        ),
        titleLarge: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          color: secondaryText,
          fontSize: 14,
        ),
      ),
    );
  }
}
