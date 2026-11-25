import 'package:flutter/material.dart';

/// DHANFLOW Dark Fintech Color Palette
/// Design principle: Deep navy bg, elevated cards, semantic accent colors
class AppColors {
  AppColors._();

  // ── BACKGROUNDS (CRED-inspired obsidian dark palette) ───────
  static const Color bgPrimary = Color(0xFF07090F);    // Deep obsidian
  static const Color bgCard    = Color(0xFF10141E);    // Elevated obsidian card
  static const Color bgCard2   = Color(0xFF151B28);    // Modal / deeper sheet
  static const Color bgHover   = Color(0xFF1B2333);    // Input / hover well

  // ── BORDERS ────────────────────────────────────────────────
  static const Color border      = Color(0xFF20293A);  // Hairline metallic border
  static const Color borderLight = Color(0xFF313E54);  // Focused rim

  // ── ACCENT COLORS (Semantic) ────────────────────────────────
  static const Color accentGreen  = Color(0xFF10B981); // Cleared / assets / positive
  static const Color accentAmber  = Color(0xFFF59E0B); // Active / gold / warning
  static const Color accentRose   = Color(0xFFEF4444); // Liabilities / debt / danger
  static const Color accentBlue   = Color(0xFF3B82F6); // Info / loans
  static const Color accentPurple = Color(0xFF8B5CF6); // EMI / special

  // ── ACCENT DIMS (Chip / Badge backgrounds) ──────────────────
  static const Color greenDim  = Color(0xFF064E3B);
  static const Color amberDim  = Color(0xFF451A03);
  static const Color roseDim   = Color(0xFF450A0A);
  static const Color blueDim   = Color(0xFF1E3A8A);
  static const Color purpleDim = Color(0xFF2E1065);

  // ── TYPOGRAPHY ─────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF9FAFB); // Main text
  static const Color textSecondary = Color(0xFF9CA3AF); // Secondary / muted
  static const Color textTertiary  = Color(0xFF6B7280); // Timestamps / labels

  // ── UTILIZATION BAR THRESHOLDS ─────────────────────────────
  static Color utilizationColor(double pct) {
    if (pct <= 0) return accentGreen;
    if (pct < 30) return accentGreen;
    if (pct < 60) return accentAmber;
    if (pct < 90) return accentRose;
    return const Color(0xFFB91C1C); // Critical — deep rose
  }
}

/// App text styles for consistent typography
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle kpi = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle amount = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
}

/// App dimensions and spacing
class AppDimens {
  AppDimens._();
  
  static const double paddingPage   = 16.0;
  static const double cardRadius    = 16.0;
  static const double chipRadius    = 20.0;
  static const double buttonRadius  = 10.0;
  static const double gapXS         = 4.0;
  static const double gapSM         = 8.0;
  static const double gapMD         = 12.0;
  static const double gapLG         = 16.0;
  static const double gapXL         = 24.0;
  
  // KPI card min height
  static const double kpiCardHeight = 90.0;
}
