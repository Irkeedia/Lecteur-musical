import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Palette Deep Navy ──────────────────────────────────────
  static const Color deepNavy = Color(0xFF0B1023);
  static const Color darkBackground = Color(0xFF0D1428);
  static const Color surface = Color(0xFF111B33);
  static const Color surfaceLight = Color(0xFF162040);
  static const Color surfaceElevated = Color(0xFF1C2A50);
  static const Color cardDark = Color(0xFF141E38);

  // Accent : Bleu → Violet → Rose (comme le mockup)
  static const Color accentBlue = Color(0xFF4A6CF7);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFD946EF);
  static const Color accentMagenta = Color(0xFFEC4899);

  // Accent actif (pill active sur chanson en cours)
  static const Color activePill = Color(0xFF3B52CC);
  static const Color activePillLight = Color(0xFF5468E0);

  // Texte
  static const Color white = Color(0xFFFFFFFF);
  static const Color softWhite = Color(0xFFE8E8F0);
  static const Color grey = Color(0xFF9CA3AF);
  static const Color greyMuted = Color(0xFF6B7280);
  static const Color greyDark = Color(0xFF374151);

  // Glow
  static const Color glowPurple = Color(0xFF8B5CF6);
  static const Color glowPink = Color(0xFFD946EF);
  static const Color glowBlue = Color(0xFF3B82F6);

  // ─── Gradients ──────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, accentPurple],
  );

  static const LinearGradient pillGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [activePill, activePillLight],
  );

  static const LinearGradient glowGradientPurplePink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentPink],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF111B38), deepNavy],
  );

  static const LinearGradient heroOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xCC0D1428),
      Color(0xFF0D1428),
    ],
    stops: [0.0, 0.7, 1.0],
  );

  // ─── Ombres ─────────────────────────────────────────────────
  static List<BoxShadow> glowShadow(Color color, {double blur = 30}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.5),
      blurRadius: blur,
      spreadRadius: -4,
    ),
  ];

  // ─── Theme Data ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentPurple,
        surface: surface,
        onPrimary: white,
        onSecondary: white,
        onSurface: softWhite,
        tertiary: accentPink,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: white,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: white,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: softWhite,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: softWhite,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: grey,
          ),
          bodySmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: greyMuted,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: greyMuted,
            letterSpacing: 1.2,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: white),
      ),
      iconTheme: const IconThemeData(color: softWhite, size: 22),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentBlue,
        inactiveTrackColor: greyDark.withValues(alpha: 0.5),
        thumbColor: white,
        overlayColor: accentBlue.withValues(alpha: 0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
