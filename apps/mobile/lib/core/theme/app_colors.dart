import 'package:flutter/material.dart';

/// Modern Minimalist color palette
/// Focuses on clarity, purposeful whitespace, and premium slates.
class AppColors {
  // Primary & Accent (New Color Palette)
  static const Color primary = Color(0xFF02B150); // New Grab Green
  static const Color primaryDark = Color(0xFF363A45); // Dark Slate
  static const Color accent = Color(0xFF7BDCB5); // Light Green/Teal
  static const Color secondary = Color(0xFF00B2FF); // New Primary Blue
  static const Color secondaryLight = Color(0xFFE5F7FF); // Light Blue

  // Semantic Colors (Clean)
  static const Color success = Color(0xFF02B150); // New Success Green
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF00B2FF); // Info Blue

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF020617);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color shelf = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFF1F5F9);

  // Text Colors (High contrast for readability)
  static const Color textPrimary = Color(0xFF363A45); // Dark Slate from palette
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border & Divider Colors (Subtle)
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderMedium = Color(0xFFCBD5E1); // Slate 300
  static const Color divider = Color(0xFFF1F5F9); // Slate 100

  // Interactive States
  static const Color disabled = Color(0xFFE2E8F0);
  static const Color disabledText = Color(0xFF94A3B8);

  // Deprecated / Compatibility (Mapping old names to new ones if needed)
  static const Color primaryLight = Color(0xFFCCFBF1); // Teal 100
  static const Color backgroundPrimary = background;
  static const Color backgroundSecondary = shelf;
  static const Color backgroundTertiary = surface;

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}
