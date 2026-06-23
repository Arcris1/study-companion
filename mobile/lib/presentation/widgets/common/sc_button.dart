import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

enum ScButtonVariant { primary, secondary, outlined, ghost, gradient }

enum ScButtonSize { small, medium, pill }

class ScButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expanded;
  final ScButtonVariant variant;
  final ScButtonSize size;

  /// Legacy support: if [outlined] is true and no variant is specified,
  /// the button uses [ScButtonVariant.outlined].
  final bool outlined;

  const ScButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
    this.expanded = true,
    this.variant = ScButtonVariant.primary,
    this.size = ScButtonSize.medium,
  });

  @override
  State<ScButton> createState() => _ScButtonState();
}

class _ScButtonState extends State<ScButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  ScButtonVariant get _effectiveVariant =>
      widget.outlined ? ScButtonVariant.outlined : widget.variant;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onPressed == null && !widget.isLoading;

  double get _height {
    switch (widget.size) {
      case ScButtonSize.small:
        return 36;
      case ScButtonSize.medium:
      case ScButtonSize.pill:
        return 48;
    }
  }

  double get _horizontalPadding {
    switch (widget.size) {
      case ScButtonSize.small:
        return 16;
      case ScButtonSize.medium:
      case ScButtonSize.pill:
        return 24;
    }
  }

  double get _borderRadius {
    switch (widget.size) {
      case ScButtonSize.small:
      case ScButtonSize.medium:
        return 8;
      case ScButtonSize.pill:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final variant = _effectiveVariant;
    final opacity = _isDisabled ? 0.4 : 1.0;

    // Resolve colors per variant
    Color bgColor;
    Color textColor;
    Color? borderColor;
    List<BoxShadow>? shadows;
    Gradient? gradient;

    switch (variant) {
      case ScButtonVariant.primary:
        bgColor = isDark ? AppColors.primaryLight : theme.colorScheme.primary;
        textColor = Colors.white;
        shadows = _isDisabled
            ? null
            : [
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ];
        break;
      case ScButtonVariant.secondary:
        bgColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
        break;
      case ScButtonVariant.outlined:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.primaryLight : theme.colorScheme.primary;
        borderColor = isDark ? AppColors.primaryLight : theme.colorScheme.primary;
        break;
      case ScButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.primaryLight : theme.colorScheme.primary;
        break;
      case ScButtonVariant.gradient:
        bgColor = Colors.transparent;
        textColor = Colors.white;
        gradient = _isDisabled
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
              );
        if (_isDisabled) {
          bgColor = theme.colorScheme.surfaceContainerHighest;
          textColor = theme.colorScheme.onSurfaceVariant;
        }
        shadows = _isDisabled
            ? null
            : [
                BoxShadow(
                  color: const Color(0x0F000000),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.primaryGradientStart.withValues(alpha: 0.08),
               blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ];
        break;
    }

    final textStyle = widget.size == ScButtonSize.small
        ? theme.textTheme.labelMedium
        : theme.textTheme.labelLarge;

    final iconSize = 18.0;

    // Build content
    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ScButtonVariant.outlined ||
                    variant == ScButtonVariant.ghost
                ? theme.colorScheme.primary
                : textColor,
          ),
        ),
      );
    } else {
      final labelWidget = Text(
        widget.label,
        style: textStyle?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

      if (widget.icon != null) {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: iconSize, color: textColor),
            const SizedBox(width: 8),
            // Flexible so the label ellipsizes instead of overflowing when the
            // button sits in a tight container.
            Flexible(child: labelWidget),
          ],
        );
      } else {
        content = labelWidget;
      }
    }

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: _height,
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          decoration: BoxDecoration(
            color: gradient == null ? bgColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(_borderRadius),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.5)
                : null,
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isDisabled || widget.isLoading ? null : widget.onPressed,
              onTapDown: _isDisabled || widget.isLoading
                  ? null
                  : (_) {
                      _pressController.forward();
                    },
              onTapUp: _isDisabled || widget.isLoading
                  ? null
                  : (_) {
                      _pressController.reverse();
                    },
              onTapCancel: _isDisabled || widget.isLoading
                  ? null
                  : () {
                      _pressController.reverse();
                    },
              borderRadius: BorderRadius.circular(_borderRadius),
              splashColor: textColor.withValues(alpha: 0.1),
              highlightColor: textColor.withValues(alpha: 0.05),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );

    // Shimmer overlay for gradient loading
    if (widget.isLoading && variant == ScButtonVariant.gradient && !_isDisabled) {
      button = _GradientShimmerButton(
        height: _height,
        borderRadius: _borderRadius,
        horizontalPadding: _horizontalPadding,
        child: Center(child: content),
      );
    }

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class _GradientShimmerButton extends StatefulWidget {
  final double height;
  final double borderRadius;
  final double horizontalPadding;
  final Widget child;

  const _GradientShimmerButton({
    required this.height,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.child,
  });

  @override
  State<_GradientShimmerButton> createState() => _GradientShimmerButtonState();
}

class _GradientShimmerButtonState extends State<_GradientShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _shimmerController.value, 0),
              end: Alignment(1.0 + 2.0 * _shimmerController.value, 0),
              colors: const [
                AppColors.primary,
                AppColors.primaryLight,
                AppColors.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0F000000),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.primaryGradientStart.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
