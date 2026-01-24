import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Momentum's Custom Dark Theme
/// 
/// Based on Google Stitch designs:
/// - Dark near-black background
/// - Teal/cyan primary accent (#00D9B8)
/// - Yellow accent for active states (#D4E157)
/// - Outfit font for clean typography
class AppTheme {
  // Core brand colors
  static const Color tealPrimary = Color(0xFF00D9B8);
  static const Color tealLight = Color(0xFF4DFFDB);
  static const Color tealDark = Color(0xFF00A88A);
  
  static const Color yellowAccent = Color(0xFFD4E157);
  static const Color yellowDark = Color(0xFFC0CA33);
  
  // Dark theme surface colors
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A1F25);
  static const Color darkSurfaceContainer = Color(0xFF242A32);
  static const Color darkSurfaceContainerHigh = Color(0xFF2E353F);
  static const Color darkSurfaceContainerHighest = Color(0xFF38404B);
  static const Color darkBorder = Color(0xFF3A424D);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8C1);
  static const Color textMuted = Color(0xFF6B7785);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  
  // Contribution grid intensity colors
  static const List<Color> gridIntensity = [
    Color(0xFF1A2332), // Empty/Rest
    Color(0xFF1B4D43), // Low
    Color(0xFF1F7A6A), // Medium
    Color(0xFF25A693), // High
    Color(0xFF00D9B8), // Max
  ];
  
  // Light theme (kept minimal - app is dark-first)
  static ThemeData light({ColorScheme? dynamicScheme}) {
    // Force dark theme for Momentum's design language
    return dark(dynamicScheme: null);
  }
  
  // Theme Modes
  static const String themeTeal = 'teal';
  static const String themeYellow = 'yellow';
  static const String themeRed = 'red';
  static const String themeBlack = 'black';

  // Get theme based on key
  static ThemeData getTheme(String themeKey) {
    switch (themeKey) {
      case themeYellow:
        return _buildTheme(const Color(0xFFFFEB3B), const Color(0xFFFBC02D));
      case themeRed:
        return _buildTheme(const Color(0xFFE53935), const Color(0xFFC62828));
      case themeBlack:
        return _buildTheme(const Color(0xFFFFFFFF), const Color(0xFFB0B8C1), isMonochrome: true);
      case themeTeal:
      default:
        return _buildTheme(tealPrimary, tealDark);
    }
  }

  // Create the Momentum dark theme with dynamic primary
  static ThemeData _buildTheme(Color primary, Color primaryContainer, {bool isMonochrome = false}) {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: isMonochrome ? Colors.black : darkBackground,
      primaryContainer: primaryContainer,
      onPrimaryContainer: isMonochrome ? Colors.black : Colors.white,
      secondary: isMonochrome ? Colors.white : yellowAccent,
      onSecondary: darkBackground,
      secondaryContainer: isMonochrome ? const Color(0xFF333333) : yellowDark.withValues(alpha: 0.2),
      onSecondaryContainer: isMonochrome ? Colors.white : yellowAccent,
      tertiary: isMonochrome ? Colors.grey : tealLight,
      onTertiary: darkBackground,
      tertiaryContainer: isMonochrome ? Colors.grey.withValues(alpha: 0.3) : tealDark.withValues(alpha: 0.3),
      onTertiaryContainer: isMonochrome ? Colors.white : tealLight,
      error: error,
      onError: Colors.white,
      errorContainer: error.withValues(alpha: 0.2),
      onErrorContainer: error,
      surface: darkSurface,
      onSurface: textPrimary,
      surfaceContainerHighest: darkSurfaceContainerHigh,
      onSurfaceVariant: textSecondary,
      outline: darkBorder,
      outlineVariant: darkBorder.withValues(alpha: 0.5),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: darkBackground,
      inversePrimary: primaryContainer,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
      
      // App Bar - transparent, no elevation
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      
      // Cards - dark with subtle border
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkBorder.withValues(alpha: 0.3)),
        ),
        color: darkSurfaceContainer,
        margin: EdgeInsets.zero,
      ),
      
      // Primary button (teal)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isMonochrome ? Colors.black : darkBackground,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Elevated button (for secondary actions)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSurfaceContainer,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      
      // Input decoration (text fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Navigation bar (bottom)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary);
          }
          return IconThemeData(color: textMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: primary,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: darkBorder.withValues(alpha: 0.3),
        thickness: 1,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceContainer,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.outfit(color: textPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Icon theme
      iconTheme: IconThemeData(color: textSecondary),
      
      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tealPrimary,
        foregroundColor: darkBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceContainerHigh,
        contentTextStyle: GoogleFonts.outfit(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: darkBorder,
      ),
    );
  }
  
  // Build text theme with Outfit font
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.outfitTextTheme(base).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textSecondary,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: textMuted,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textMuted,
      ),
    );
  }
}
