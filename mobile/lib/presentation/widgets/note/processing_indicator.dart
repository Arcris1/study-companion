import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/enums/note_status.dart';

class ProcessingIndicator extends StatelessWidget {
  final NoteStatus status;

  const ProcessingIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _backgroundColor(theme),
          borderRadius: Spacing.borderRadiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(theme),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _textColor(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    switch (status) {
      case NoteStatus.importing:
      case NoteStatus.processing:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        );
      case NoteStatus.error:
        return Icon(
          Icons.error_outline_rounded,
          size: 12,
          color: theme.colorScheme.error,
        );
      case NoteStatus.ready:
        return Icon(
          Icons.check_circle_rounded,
          size: 12,
          color: AppColors.success,
        );
    }
  }

  Color _backgroundColor(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    switch (status) {
      case NoteStatus.error:
        return isDark ? AppColors.errorContainerDark : AppColors.errorContainer;
      case NoteStatus.ready:
        return isDark ? AppColors.successContainerDark : AppColors.successContainer;
      case NoteStatus.importing:
      case NoteStatus.processing:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  Color _textColor(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    switch (status) {
      case NoteStatus.error:
        return isDark ? AppColors.errorDark : AppColors.error;
      case NoteStatus.ready:
        return isDark ? AppColors.successDark : AppColors.success;
      case NoteStatus.importing:
      case NoteStatus.processing:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
