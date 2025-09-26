// lib/src/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF0F4C75);
  static const Color emergencyRed = Color(0xFFE63946);
  static const Color softGrey = Color(0xFFF5F5F5);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryTeal,
    scaffoldBackgroundColor: softGrey,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryTeal,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
  );
}
