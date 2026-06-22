import 'package:flutter/material.dart';

/// All gradient definitions from the design spec.
class AppGradients {
  AppGradients._();

  // ─── Primary gradient (brand, buttons, user bubbles) ───────────────
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
  );

  // ─── Onboarding gradients ──────────────────────────────────────────
  static const LinearGradient onboarding1 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5), Color(0xFF312E81)],
  );

  static const LinearGradient onboarding2 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6D28D9), Color(0xFF4338CA), Color(0xFF1E1B4B)],
  );

  static const LinearGradient onboarding3 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5B21B6), Color(0xFF3730A3), Color(0xFF1E1B4B)],
  );

  // ─── Success gradient (quiz A-grade background) ────────────────────
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  // ─── Surface gradient (subtle card sheen, light mode only) ─────────
  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F7FF)],
  );

  // ─── AI shimmer gradient (loading/generating states) ───────────────
  static const LinearGradient aiShimmer = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA), Color(0xFF7C3AED)],
  );
}
