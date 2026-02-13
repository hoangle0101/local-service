import 'package:flutter/material.dart';

/// Upwork-inspired color palette
class AppColors {
  AppColors._();

  // Primary - Upwork Green
  static const Color primary = Color(0xFF14A800);
  static const Color primaryLight = Color(0xFF33A78F);
  static const Color primaryDark = Color(0xFF108600);

  // Secondary - Professional Blue
  static const Color secondary = Color(0xFF1F57C3);
  static const Color secondaryLight = Color(0xFF4777BF);
  static const Color secondaryDark = Color(0xFF19469C);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Semantic
  static const Color success = Color(0xFF14A800);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF0C6400);

  static const Color warning = Color(0xFFFFBE00);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB38600);

  static const Color error = Color(0xFFD93025);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);

  static const Color info = Color(0xFF1F57C3);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E3A8A);

  // Background
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF1F57C3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF33A78F), Color(0xFF14A800), Color(0xFF108600)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF4777BF), Color(0xFF1F57C3), Color(0xFF19469C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
