import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Animation duration and curve tokens from the design spec.
class AppAnimations {
  AppAnimations._();

  // ─── Duration Tokens ───────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationEmphasis = Duration(milliseconds: 800);
  static const Duration durationSpring = Duration(milliseconds: 600);

  // ─── Easing Curves ─────────────────────────────────────────────────
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve overshoot = Curves.easeOutBack;

  // ─── Page Transition Helpers ───────────────────────────────────────

  /// Forward navigation: slide in from right + fade (300ms, easeOutCubic).
  static CustomTransitionPage<T> slideForward<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: durationMedium,
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideIn = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: easeOut));

        final fadeIn = CurvedAnimation(parent: animation, curve: easeOut);

        return SlideTransition(
          position: slideIn,
          child: FadeTransition(opacity: fadeIn, child: child),
        );
      },
    );
  }

  /// Modal / bottom sheet style: slide up from bottom + fade (300ms, easeOutCubic).
  static CustomTransitionPage<T> slideUp<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: durationMedium,
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideUp = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: easeOut));

        final fadeIn = CurvedAnimation(parent: animation, curve: easeOut);

        return SlideTransition(
          position: slideUp,
          child: FadeTransition(opacity: fadeIn, child: child),
        );
      },
    );
  }

  /// Cross-fade transition for tab switches (200ms, easeInOut).
  static CustomTransitionPage<T> crossFade<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: easeInOut),
          child: child,
        );
      },
    );
  }
}
