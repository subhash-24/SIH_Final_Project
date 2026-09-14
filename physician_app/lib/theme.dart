import 'package:flutter/material.dart';

/// Arogya-Saathi Clinical Trust Design System for Physician App
/// Conforms directly with Stitch project tokens (Project ID: 12057284309403324037)
class AppTheme {
  // Institutional Color Palette
  static const Color primary = Color(0xFF0F6B68); // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF00514F);
  static const Color primaryContainer = Color(0xFFE0F2F1);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF186B4C); // Forest / Slate
  static const Color secondaryContainer = Color(0xFFA2F0C9);
  static const Color onSecondaryContainer = Color(0xFF003924);

  static const Color tertiary = Color(0xFF8C5200); // Amber Clinical
  static const Color tertiaryContainer = Color(0xFFFFDCBD);
  static const Color onTertiaryContainer = Color(0xFF2C1600);

  static const Color background = Color(0xFFF7F8F6); // Neutral Canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceLow = Color(0xFFF0F4F2);
  static const Color surfaceContainer = Color(0xFFE7EEEC);
  static const Color surfaceHigh = Color(0xFFD6EDEB);

  static const Color outline = Color(0xFF6F7978);
  static const Color outlineVariant = Color(0xFFBEC9C7);
  static const Color border = Color(0xFFE2E7E5);

  static const Color textPrimary = Color(0xFF0A1F1E);
  static const Color textSecondary = Color(0xFF3F4948);
  static const Color textMuted = Color(0xFF6F7978);

  // Safety & Triage Severity
  static const Color urgent = Color(0xFFBA1A1A); // Deep Crimson
  static const Color urgentBg = Color(0xFFFFDAD6);
  static const Color urgentBorder = Color(0xFFFFB4AB);

  static const Color warning = Color(0xFF8C5200);
  static const Color warningBg = Color(0xFFFFDCBD);

  static const Color success = Color(0xFF186B4C);
  static const Color successBg = Color(0xFFA2F0C9);

  // Theme Data Definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        error: urgent,
        onPrimary: onPrimary,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Color(0x0A000000),
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: urgent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Reusable Clinical Trust UI Components

  /// Clinical Chip / Badge
  static Widget buildBadge({
    required String label,
    Color bg = surfaceContainer,
    Color fg = textSecondary,
    IconData? icon,
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUrgent ? urgentBg : bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isUrgent ? urgentBorder : border,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: isUrgent ? urgent : fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUrgent ? urgent : fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Clinical Source Tag (e.g. PATIENT REPORTED, OCR EXTRACTED, EHR SYNC)
  static Widget buildSourceTag(String source) {
    final clean = source.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        clean,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textMuted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
