import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
class AppTheme {
  static ThemeData themeData() => ThemeData(
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    applyElevationOverlayColor: false,

    // Apply Google Fonts Inter everywhere
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),

    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, // transparent app bar
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        // Status bar
        statusBarColor: Colors.transparent, // fully transparent
        statusBarIconBrightness: Brightness.light, // white icons (Android)
        statusBarBrightness: Brightness.dark, // white icons (iOS)

        // Navigation bar
        systemNavigationBarColor: Colors.black, // or AppColors.bg
        systemNavigationBarIconBrightness: Brightness.light, // white icons
      ),
    ),
  );
}


class AppColors {
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFFDAE3F1);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFF616161);

  static const List<Color> backgroundGradient = [
    // Color(0xFF1D4ED8), // Royal Blue
    // Color(0xFF9333EA), // Magenta Purple
    // Color(0xFFF97316), // Warm Orange

    // Color(0xFF2563EB), // Ocean Blue
    // Color(0xFF4ADE80), // Mint Green
    // Color(0xFFC084FC), // Lavender

    Color(0xFF224CD3), // Strong Blue
    Color(0xFF06B6D4), // Bright Cyan
    Color(0xFFA21CAF), // Neon Purple

    // Color(0xFF0EA5E9), // Sky Blue
    // Color(0xFF14B8A6), // Aqua Green
    // Color(0xFF84CC16), // Lime Green

    // Color(0xFF2563EB), // Blue
    // Color(0xFF06B6D4), // Teal
    // Color(0xFFA855F7), // Violet
  ];
}
