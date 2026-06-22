import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/enums/note_status.dart';
import 'package:intl/intl.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: Spacing.borderRadiusMd,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x33000000)
                  : const Color(0x0A000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main card content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: note.status == NoteStatus.ready ? onTap : null,
                borderRadius: Spacing.borderRadiusMd,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: source icon, title, status, delete
                      Row(
                        children: [
                          // Source type icon badge
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _sourceColor.withValues(alpha: 0.12),
                              borderRadius: Spacing.borderRadiusSm,
                            ),
                            child: Center(
                              child: Icon(
                                _sourceIcon,
                                size: 16,
                                color: _sourceColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Title
                          Expanded(
                            child: Text(
                              note.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status indicator
                          if (note.status.isLoading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          if (note.status == NoteStatus.error)
                            Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                          // Delete button
                          if (onDelete != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: onDelete,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Content preview
                      Text(
                        note.rawText.isEmpty ? 'No content' : note.rawText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: note.rawText.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Bottom metadata row
                      Row(
                        children: [
                          // Chunk count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: Spacing.borderRadiusPill,
                            ),
                            child: Text(
                              '${note.chunkCount} chunks',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: 'JetBrains Mono',
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Date
                          Text(
                            DateFormat.yMMMd().format(note.updatedAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Processing overlay
            if (note.status.isLoading)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: note.status.isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: Spacing.borderRadiusMd,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.status.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData get _sourceIcon {
    switch (note.sourceType) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      case 'md':
        return Icons.article_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  Color get _sourceColor {
    switch (note.sourceType) {
      case 'pdf':
        return AppColors.error; // red
      case 'txt':
        return AppColors.info; // blue
      case 'md':
        return AppColors.success; // green
      default:
        return AppColors.warning; // amber
    }
  }
}
