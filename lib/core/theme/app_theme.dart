import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Figma "Lively Noir Edition" color palette ──────────────────
  static const Color primaryColor = Color(0xFF8B7EF6);
  static const Color primaryLight = Color(0xFFA89EFF);
  static const Color secondaryColor = Color(0xFF00D4AA);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color overdueColor = Color(0xFFFF4757);
  static const Color urgentColor = Color(0xFFFFB347);
  static const Color safeColor = Color(0xFF2ED573);
  static const Color surfaceColor = Color(0xFF161616);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color scaffoldBg = Color(0xFF000000);
  static const Color inputFill = Color(0xFF1E1E1E);
  static const Color borderColor = Color(0xFF2D2D2D);

  // ── Figma-matched badge / accent colors ────────────────────────
  static const Color highBadgeBg = Color(0x33FF6B6B);
  static const Color highBadgeText = Color(0xFFFF6B6B);
  static const Color mediumBadgeBg = Color(0x33FFB347);
  static const Color mediumBadgeText = Color(0xFFFFB347);
  static const Color lowBadgeBg = Color(0x332ED573);
  static const Color lowBadgeText = Color(0xFF2ED573);
  static const Color urgentBadgeBg = Color(0x33FF4757);
  static const Color urgentBadgeText = Color(0xFFFF4757);
  static const Color generalBadgeBg = Color(0x338B7EF6);
  static const Color generalBadgeText = Color(0xFF8B7EF6);
  static const Color assignmentBadgeBg = Color(0x3300D4AA);
  static const Color assignmentBadgeText = Color(0xFF00D4AA);

  // ── Figma text colors ──────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color textTertiary = Color(0x66FFFFFF);  // 40% white

  // ── Typography helpers (Unbounded = headings, Inter = body) ────
  static TextStyle unbounded({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.unbounded(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get darkTheme {
    final interTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        outline: borderColor,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scaffoldBg,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.unbounded(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        labelStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
        hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.3)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.06),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: cardColor,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.4),
        indicatorColor: primaryColor,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 8,
      ),
      textTheme: interTextTheme.copyWith(
        headlineLarge: GoogleFonts.unbounded(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.unbounded(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.unbounded(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.unbounded(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
