import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF3949AB);
  static const Color lightBlue = Color(0xFF5C6BC0);
  static const Color surfaceBlue = Color(0xFF0D1541);
  static const Color darkBackground = Color(0xFF080E2B);

  static const Color accentYellow = Color(0xFFFFD54F);
  static const Color brightYellow = Color(0xFFFFE082);
  static const Color deepYellow = Color(0xFFFFC107);

  static const Color white = Color(0xFFFFFFFF);
  static const Color softWhite = Color(0xFFF5F5F7);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentYellow,
        surface: surfaceBlue,
        onPrimary: white,
        onSecondary: darkBackground,
        onSurface: softWhite,
        tertiary: brightYellow,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: white,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: white,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: softWhite,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: softWhite,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: grey,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: grey,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        iconTheme: IconThemeData(color: white),
      ),
      iconTheme: const IconThemeData(color: softWhite),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentYellow,
        inactiveTrackColor: accentBlue.withValues(alpha: 0.3),
        thumbColor: accentYellow,
        overlayColor: accentYellow.withValues(alpha: 0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceBlue,
        selectedItemColor: accentYellow,
        unselectedItemColor: grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
