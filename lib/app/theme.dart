import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF050505);
  static const Color surfaceColor = Color(0xFF101010);
  static const Color accentColor = Color(0xFFECECEC);
  static const Color primaryText = Color(0xFFF4F4F4);
  static const Color secondaryText = Color(0xFFA3A3A3);
  static const Color highlightColor = Color(0xFFFFFFFF);

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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
        bodyMedium: TextStyle(color: secondaryText, fontSize: 14),
      ),
    );
  }
}
