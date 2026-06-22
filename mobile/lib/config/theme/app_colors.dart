import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Gradient (Brand) ───────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryGradientStart = Color(0xFF7C3AED);
  static const Color primaryGradientEnd = Color(0xFF4F46E5);

  // ─── Accent / Highlight ─────────────────────────────────────────────
  static const Color accent = Color(0xFFEC4899);
  static const Color highlight = Color(0xFFFBBF24);
  static const Color aiGlow = Color(0xFFA78BFA);

  // ─── Light Theme ────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F7FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF3F0FF);
  static const Color surfaceContainerLight = Color(0xFFEEEAFF);
  static const Color surfaceContainerHighLight = Color(0xFFE5E0F5);
  static const Color onBackgroundLight = Color(0xFF1A1625);
  static const Color onSurfaceLight = Color(0xFF1A1625);
  static const Color onSurfaceVariantLight = Color(0xFF6B6580);
  static const Color outlineLight = Color(0xFFD4D0E0);
  static const Color outlineVariantLight = Color(0xFFE8E5F0);

  // ─── Dark Theme ─────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0B1A);
  static const Color surfaceDark = Color(0xFF1A1528);
  static const Color surfaceVariantDark = Color(0xFF221C35);
  static const Color surfaceContainerDark = Color(0xFF2A2340);
  static const Color surfaceContainerHighDark = Color(0xFF332B4D);
  static const Color onBackgroundDark = Color(0xFFF0ECF9);
  static const Color onSurfaceDark = Color(0xFFF0ECF9);
  static const Color onSurfaceVariantDark = Color(0xFF9B93B0);
  static const Color outlineDark = Color(0xFF3D3555);
  static const Color outlineVariantDark = Color(0xFF2E2745);

  // ─── Semantic Colors ────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color successContainerDark = Color(0xFF064E3B);

  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color errorContainerDark = Color(0xFF7F1D1D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color warningContainerDark = Color(0xFF78350F);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF60A5FA);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color infoContainerDark = Color(0xFF1E3A5F);

  // ─── Quiz-Specific Colors ──────────────────────────────────────────
  static const Color quizCorrect = Color(0xFF10B981);
  static const Color quizCorrectBgLight = Color(0xFFD1FAE5);
  static const Color quizCorrectBgDark = Color(0xFF064E3B);
  static const Color quizIncorrect = Color(0xFFEF4444);
  static const Color quizIncorrectBgLight = Color(0xFFFEE2E2);
  static const Color quizIncorrectBgDark = Color(0xFF7F1D1D);
  static const Color quizUnanswered = Color(0xFF9CA3AF);
  static const Color quizUnansweredBgLight = Color(0xFFF3F4F6);
  static const Color quizUnansweredBgDark = Color(0xFF1F2937);

  // ─── Grade Colors ──────────────────────────────────────────────────
  static const Color gradeA = Color(0xFF10B981);
  static const Color gradeB = Color(0xFF3B82F6);
  static const Color gradeC = Color(0xFFF59E0B);
  static const Color gradeD = Color(0xFFF97316);
  static const Color gradeF = Color(0xFFEF4444);

  /// Returns the grade color for a given percentage score.
  static Color gradeColor(double percentage) {
    if (percentage >= 90) return gradeA;
    if (percentage >= 80) return gradeB;
    if (percentage >= 70) return gradeC;
    if (percentage >= 60) return gradeD;
    return gradeF;
  }

  // ─── Difficulty Colors ─────────────────────────────────────────────
  static const Color difficultyEasy = Color(0xFF10B981);
  static const Color difficultyMedium = Color(0xFFF59E0B);
  static const Color difficultyHard = Color(0xFFEF4444);

  // ─── Notebook Preset Colors (12 choices) ────────────────────────────
  static const List<Color> notebookPresets = [
    Color(0xFF7C3AED), // Purple (default)
    Color(0xFF4F46E5), // Indigo
    Color(0xFF3B82F6), // Blue
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFF84CC16), // Lime
    Color(0xFFF59E0B), // Amber
    Color(0xFFF97316), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFF6366F1), // Slate Indigo
  ];

  // ─── Study Context Colors ─────────────────────────────────────────
  static const Color focusBlue = Color(0xFF3B82F6);
  static const Color calmGreen = Color(0xFF10B981);
  static const Color motivationAmber = Color(0xFFF59E0B);
  static const Color energyOrange = Color(0xFFF97316);

  // ─── Legacy aliases (backward compat) ──────────────────────────────
  static const Color correct = quizCorrect;
  static const Color incorrect = quizIncorrect;
  static const Color unanswered = quizUnanswered;
}
