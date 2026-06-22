import 'package:flutter/material.dart';

/// Shadow definitions from the design spec.
class AppShadows {
  AppShadows._();

  // ─── Light Mode Shadows ────────────────────────────────────────────

  /// Level 1 - Cards at rest
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 2 - Hovered cards, elevated elements
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x0F000000), // 6% black
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x147C3AED), // 8% primary
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Level 3 - Modals, dialogs, FAB
  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0D000000), // 5% black
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 4 - Bottom navigation, floating elements
  static const List<BoxShadow> level4 = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 32,
      offset: Offset(0, -4),
    ),
  ];

  // ─── Dark Mode Shadows ─────────────────────────────────────────────

  /// Level 1 dark - Cards at rest
  static const List<BoxShadow> level1Dark = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 2 dark - Hovered cards, elevated elements
  static const List<BoxShadow> level2Dark = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A7C3AED), // 4% primary glow
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Level 3 dark - Modals, dialogs, FAB
  static const List<BoxShadow> level3Dark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A7C3AED),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 4 dark - Bottom navigation, floating elements
  static const List<BoxShadow> level4Dark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 32,
      offset: Offset(0, -4),
    ),
  ];
}
