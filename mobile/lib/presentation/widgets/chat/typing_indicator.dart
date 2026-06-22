import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  final String? streamingText;

  const TypingIndicator({super.key, this.streamingText});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dotController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleBg = isDark
        ? AppColors.surfaceVariantDark
        : theme.colorScheme.surface;
    final borderColor = isDark
        ? AppColors.outlineVariantDark
        : AppColors.outlineVariantLight;

    const bubbleRadius = BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
    );

    // Streaming text state
    if (widget.streamingText != null && widget.streamingText!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Avatar
            _buildAvatar(theme, isDark),
            const SizedBox(width: 8),
            // Bubble with streaming text
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(right: 64),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  border: Border.all(color: borderColor, width: 1),
                  borderRadius: bubbleRadius,
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
                child: AnimatedBuilder(
                  animation: _cursorController,
                  builder: (context, child) {
                    return RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: widget.streamingText!),
                          TextSpan(
                            text: '|',
                            style: TextStyle(
                              color: theme.colorScheme.primary.withValues(
                                alpha: _cursorController.value,
                              ),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Bouncing dots state
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          _buildAvatar(theme, isDark),
          const SizedBox(width: 8),
          // Dots bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleBg,
              border: Border.all(color: borderColor, width: 1),
              borderRadius: bubbleRadius,
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
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    // Stagger: 200ms between each dot
                    final delay = i * 0.2;
                    final t = (_dotController.value - delay) % 1.0;
                    // Bounce: dot goes up (-6px) then returns
                    // Active bounce window is 0.0 to 0.4 of cycle
                    double offsetY = 0;
                    if (t >= 0 && t <= 0.4) {
                      // Sine-based bounce for smooth up and down
                      final normalized = t / 0.4;
                      offsetY = -6.0 *
                          (normalized < 0.5
                              ? normalized * 2
                              : (1 - normalized) * 2);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.translate(
                        offset: Offset(0, offsetY),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, bool isDark) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
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
    );
  }
}
