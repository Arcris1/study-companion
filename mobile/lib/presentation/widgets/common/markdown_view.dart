import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';

/// Renders Markdown text styled to match the app theme. Used to show a
/// formatted preview of `.md` notes and AI summaries (instead of raw source).
class MarkdownView extends StatelessWidget {
  final String data;
  final bool selectable;

  const MarkdownView({super.key, required this.data, this.selectable = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final onSurface =
        isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;
    final onVariant = isDark
        ? AppColors.onSurfaceVariantDark
        : AppColors.onSurfaceVariantLight;
    final container = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceContainerLight;
    final outline = isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: onSurface),
        h1: theme.textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold, color: onSurface, height: 1.3),
        h2: theme.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: onSurface, height: 1.3),
        h3: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600, color: onSurface),
        h4: theme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600, color: onSurface),
        h5: theme.textTheme.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600, color: onSurface),
        h6: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600, color: onVariant),
        strong: const TextStyle(fontWeight: FontWeight.w700),
        em: const TextStyle(fontStyle: FontStyle.italic),
        blockquote:
            theme.textTheme.bodyMedium?.copyWith(color: onVariant, height: 1.6),
        blockquotePadding: const EdgeInsets.all(Spacing.sm),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: Spacing.borderRadiusSm,
          border: Border(
            left: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
        ),
        code: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 13,
          backgroundColor: container,
          color: onSurface,
        ),
        codeblockPadding: const EdgeInsets.all(Spacing.sm),
        codeblockDecoration: BoxDecoration(
          color: container,
          borderRadius: Spacing.borderRadiusSm,
        ),
        listBullet:
            theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: onSurface),
        a: TextStyle(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        ),
        tableHead: TextStyle(fontWeight: FontWeight.w700, color: onSurface),
        tableBody: theme.textTheme.bodySmall?.copyWith(color: onSurface),
        tableBorder: TableBorder.all(color: outline, width: 1),
        tableCellsPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: outline, width: 1)),
        ),
      ),
    );
  }
}
