import 'package:flutter/material.dart';

/// ToolForge color palette — Premium OLED-optimized dark theme.
///
/// Pure blacks save battery on OLED panels; neon accents provide
/// high-contrast visual hierarchy against the dark surface.
class AppColors {
  AppColors._();

  // ── Background & Surface ──────────────────────────────────────────────
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceLight = Color(0xFF1A1A1A);
  static const Color surfaceBorder = Color(0xFF2A2A2A);
  static const Color cardSurface = Color(0xFF111111);

  // ── Accent: Neon Blue / Electric Purple ───────────────────────────────
  static const Color neonBlue = Color(0xFF00B4FF);
  static const Color electricPurple = Color(0xFF9D4EDD);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentPink = Color(0xFFFF006E);

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonBlue, electricPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [
      Color(0x3300B4FF), // neonBlue 20%
      Color(0x339D4EDD), // electricPurple 20%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [
      Color(0xFF0D0D0D),
      Color(0xFF151515),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);
  static const Color textDisabled = Color(0xFF4A4A4A);

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF1744);
  static const Color info = Color(0xFF00B0FF);

  // ── Shadows (for cards on OLED) ───────────────────────────────────────
  static List<BoxShadow> get neonGlow => [
        BoxShadow(
          color: neonBlue.withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: electricPurple.withValues(alpha: 0.10),
          blurRadius: 30,
          spreadRadius: 4,
        ),
      ];

  static List<BoxShadow> get subtleElevation => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
