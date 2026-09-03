import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'page_transitions.dart';

class DynamicTheme {
  static Color hexToColor(String hexString, {Color fallback = const Color(0xFF45BAE6)}) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static const _smoothTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SmoothPageTransitionsBuilder(),
      TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
      TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
      TargetPlatform.windows: SmoothPageTransitionsBuilder(),
      TargetPlatform.linux: SmoothPageTransitionsBuilder(),
    },
  );

  static ThemeData buildDarkTheme(String hexColor) {
    final primaryColor = hexToColor(hexColor);

    const backgroundColor = Color(0xFF0B0F19);
    const surfaceColor = Color(0xFF151C2C);
    const surfaceBorderColor = Color(0xFF232D42);
    const cardColor = Color(0xFF1A2234);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: _smoothTransitions,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor.withValues(alpha: 0.8),
        surface: surfaceColor,
        error: const Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSurface: const Color(0xFFF1F5F9),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
        titleMedium: TextStyle(color: const Color(0xFFF1F5F9), fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: const Color(0xFFE2E8F0), fontSize: 16),
        bodyMedium: TextStyle(color: const Color(0xFF94A3B8), fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorderColor, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
        labelStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }

  static ThemeData buildLightTheme(String hexColor) {
    final primaryColor = hexToColor(hexColor);

    const backgroundColor = Color(0xFFF8FAFC);
    const surfaceColor = Color(0xFFFFFFFF);
    const surfaceBorderColor = Color(0xFFE2E8F0);
    const cardColor = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: _smoothTransitions,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor.withValues(alpha: 0.8),
        surface: surfaceColor,
        error: const Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSurface: const Color(0xFF0F172A),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 32),
        titleLarge: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 22),
        titleMedium: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: const TextStyle(color: Color(0xFF334155), fontSize: 16),
        bodyMedium: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorderColor, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
        labelStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}
