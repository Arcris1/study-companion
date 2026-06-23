import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.isUser;

    if (isUser) {
      return _buildUserBubble(context, theme, isDark);
    } else {
      return _buildAiBubble(context, theme, isDark);
    }
  }

  Widget _buildUserBubble(BuildContext context, ThemeData theme, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
        margin: const EdgeInsets.only(left: 64, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
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
        child: Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context, ThemeData theme, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bubbleBg = isDark
        ? AppColors.surfaceVariantDark
        : theme.colorScheme.surface;
    final borderColor = isDark
        ? AppColors.outlineVariantDark
        : AppColors.outlineVariantLight;

    final hasSources = message.sourceChunks != null &&
        message.sourceChunks!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              border: Border.all(
                color: isDark
                    ? AppColors.outlineDark
                    : AppColors.outlineLight,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
              margin: const EdgeInsets.only(right: 64),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleBg,
                border: Border.all(color: borderColor, width: 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),

                  // Source citations
                  if (hasSources) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: borderColor,
                      ),
                    ),
                    Text(
                      'Sources',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(
                        message.sourceChunks!.length.clamp(0, 3),
                        (index) => _SourceChip(
                          index: index,
                          content: message.sourceChunks![index],
                          theme: theme,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatefulWidget {
  final int index;
  final String content;
  final ThemeData theme;
  final bool isDark;

  const _SourceChip({
    required this.index,
    required this.content,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_SourceChip> createState() => _SourceChipState();
}

class _SourceChipState extends State<_SourceChip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final chipBg = widget.theme.colorScheme.surfaceContainerHighest;
    // Sources are stored as "<note title>\n<snippet>".
    final parts = widget.content.split('\n');
    final title = parts.first.trim();
    final snippet = parts.length > 1 ? parts.sublist(1).join('\n').trim() : '';
    final hasSnippet = snippet.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap:
              hasSnippet ? () => setState(() => _expanded = !_expanded) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: Spacing.borderRadiusPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_rounded,
                  size: 12,
                  color: widget.theme.colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    title,
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      color: widget.theme.colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSnippet) ...[
                  const SizedBox(width: 2),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: widget.theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
        // Expandable supporting snippet
        if (hasSnippet)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxWidth: 240),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: Spacing.borderRadiusSm,
                ),
                child: Text(
                  snippet,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: widget.theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
      ],
    );
  }
}
