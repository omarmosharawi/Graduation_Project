// =============================================================================
// APP THEME - REward Application
// =============================================================================
// This file defines the visual theme for the entire application, based on
// the Figma design specifications.
//
// Color Palette:
// - Primary: Deep Forest Green (#1E3A34)
// - Secondary: Light Mint Green
// - Background: Light Gray (#F5F5F5)
// - Surface: White (#FFFFFF)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// -----------------------------------------------------------------------------
/// Color Constants
/// -----------------------------------------------------------------------------
/// These colors are extracted from the Figma design and used throughout the app.

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ---------------------------------------------------------------------------
  // Primary Colors
  // ---------------------------------------------------------------------------
  /// Deep Forest Green - Main brand color used for primary actions, headers
  static const Color primary = Color(0xFF1E3A34);

  /// Light variant of primary for hover/pressed states
  static const Color primaryLight = Color(0xFF2D5A50);

  /// Dark variant of primary for emphasis
  static const Color primaryDark = Color(0xFF0F1D1A);

  // ---------------------------------------------------------------------------
  // Secondary Colors
  // ---------------------------------------------------------------------------
  /// Light Mint Green - Used for secondary buttons, highlights, accents
  static const Color secondary = Color(0xFF4CAF50);

  /// Lighter mint for backgrounds and cards
  static const Color secondaryLight = Color(0xFFE8F5E9);

  /// Soft mint for subtle accents
  static const Color accent = Color(0xFFA5D6A7);

  // ---------------------------------------------------------------------------
  // Neutral Colors
  // ---------------------------------------------------------------------------
  /// Main background color - Light gray
  static const Color background = Color(0xFFF5F5F5);

  /// Card and surface background - Pure white
  static const Color surface = Color(0xFFFFFFFF);

  /// Border and divider color
  static const Color border = Color(0xFFE0E0E0);

  // ---------------------------------------------------------------------------
  // Text Colors
  // ---------------------------------------------------------------------------
  /// Primary text - Dark gray for main content
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary text - Medium gray for subtitles
  static const Color textSecondary = Color(0xFF757575);

  /// Hint text - Light gray for placeholders
  static const Color textHint = Color(0xFF9E9E9E);

  /// Text on primary color backgrounds - White
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Status Colors
  // ---------------------------------------------------------------------------
  /// Success state - Green checkmark, completed actions
  static const Color success = Color(0xFF4CAF50);

  /// Error state - Red for validation errors, failed actions
  static const Color error = Color(0xFFE53935);

  /// Warning state - Orange for cautions
  static const Color warning = Color(0xFFFFA726);

  /// Info state - Blue for information
  static const Color info = Color(0xFF29B6F6);

  // ---------------------------------------------------------------------------
  // Category Colors (for rewards/offers)
  // ---------------------------------------------------------------------------
  static const Color groceries = Color(0xFF66BB6A);
  static const Color beauty = Color(0xFFEC407A);
  static const Color restaurants = Color(0xFFFF7043);
  static const Color entertainment = Color(0xFF42A5F5);
}

/// -----------------------------------------------------------------------------
/// App Theme Configuration
/// -----------------------------------------------------------------------------
/// Main theme class that provides light and dark theme configurations.

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------------------
  /// The main theme used throughout the application.
  /// Based on Material 3 design principles with our custom color palette.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary,
        ),
      ),

      // Text Theme - Using Inter font for modern, clean look
      textTheme: _buildTextTheme(),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondaryLight,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.surface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text Theme Builder
  // ---------------------------------------------------------------------------
  /// Builds the typography scale using Inter font family.
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display styles - Large headers
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),

      // Headline styles - Section headers
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),

      // Title styles - Card titles, list items
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),

      // Body styles - Main content
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),

      // Label styles - Buttons, chips
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// -----------------------------------------------------------------------------
/// Spacing Constants
/// -----------------------------------------------------------------------------
/// Consistent spacing values used throughout the app for margins and padding.

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;  // Extra small spacing
  static const double sm = 8.0;  // Small spacing
  static const double md = 16.0; // Medium spacing (default)
  static const double lg = 24.0; // Large spacing
  static const double xl = 32.0; // Extra large spacing
  static const double xxl = 48.0; // Double extra large spacing
}

/// -----------------------------------------------------------------------------
/// Border Radius Constants
/// -----------------------------------------------------------------------------
/// Consistent border radius values for cards, buttons, and containers.

class AppRadius {
  AppRadius._();

  static const double sm = 8.0;  // Small radius for inputs
  static const double md = 12.0; // Medium radius for buttons
  static const double lg = 16.0; // Large radius for cards
  static const double xl = 20.0; // Extra large for modals
  static const double full = 100.0; // Fully rounded (pills)
}
