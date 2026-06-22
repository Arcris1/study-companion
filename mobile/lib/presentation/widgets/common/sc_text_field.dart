import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';

class ScTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final Widget? prefix;
  final String? errorText;
  final bool enabled;
  final int? maxLength;
  final TextStyle? textStyle;

  const ScTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.suffix,
    this.prefix,
    this.errorText,
    this.enabled = true,
    this.maxLength,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fillColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    final focusBorderColor = isDark
        ? AppColors.primaryLight
        : theme.colorScheme.primary;

    final isMultiline = maxLines > 1;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      enabled: enabled,
      maxLength: maxLength,
      style: textStyle ??
          theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            height: isMultiline ? 1.6 : null,
          ),
      cursorColor: theme.colorScheme.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixIcon: suffix,
        prefixIcon: prefix,
        counterText: '',
        floatingLabelBehavior: FloatingLabelBehavior.auto,

        // Label styles
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        floatingLabelStyle: theme.textTheme.labelSmall?.copyWith(
          color: focusBorderColor,
          fontWeight: FontWeight.w500,
        ),

        // Hint style
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),

        // Error style
        errorStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),

        // Fill
        filled: true,
        fillColor: fillColor,

        // Padding
        contentPadding: isMultiline
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        // Borders
        border: OutlineInputBorder(
          borderRadius: Spacing.borderRadiusSm,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Spacing.borderRadiusSm,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Spacing.borderRadiusSm,
          borderSide: BorderSide(
            color: focusBorderColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Spacing.borderRadiusSm,
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Spacing.borderRadiusSm,
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: Spacing.borderRadiusSm,
          borderSide: BorderSide.none,
        ),

        // Icon styling
        prefixIconColor: theme.colorScheme.onSurfaceVariant,
        suffixIconColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
