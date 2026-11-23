import 'package:flutter/material.dart';

class HydroColors {
  static const background = Color(0xFFF3F8F6);
  static const aqua = Color(0xFFE8F4F1);
  static const teal = Color(0xFF227175);
  static const blue = Color(0xFF78B9C5);
  static const navy = Color(0xFF263B45);
  static const muted = Color(0xFF52636E);
  static const outline = Color(0xFFD5E2DE);
  static const green = Color(0xFF218B52);
  static const yellow = Color(0xFFD79B1E);
  static const red = Color(0xFFBA1A1A);
}

class HydroTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: HydroColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: HydroColors.teal,
          primary: HydroColors.teal,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: HydroColors.background,
          foregroundColor: HydroColors.navy,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: HydroColors.outline),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: HydroColors.outline),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: HydroColors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
        ),
      );
}
