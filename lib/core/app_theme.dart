import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Renk Paleti
  static const Color spaceBackground = Color(0xFF020408);
  static const Color spaceCard = Color(0xFF0B121E);
  static const Color neonCyan = Color(0xFF00F2FF);
  static const Color neonPurple = Color(0xFFBC00FF);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color dangerRed = Color(0xFFFF3131);
  static const Color successGreen = Color(0xFF39FF14);
  static const Color textMain = Color(0xFFE0E6ED);
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: spaceBackground,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        surface: spaceCard,
        error: dangerRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rajdhani(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: neonCyan,
          letterSpacing: 2.0,
        ),
        displayMedium: GoogleFonts.rajdhani(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: neonCyan,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textMain,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: neonCyan,
          side: const BorderSide(color: neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // Glow (Parlama) Efekti için Decoration
  static BoxDecoration get neonBoxDecoration => BoxDecoration(
    color: spaceCard,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: neonCyan.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: neonCyan.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
  );
}
