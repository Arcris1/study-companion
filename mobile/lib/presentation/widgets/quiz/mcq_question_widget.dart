import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/quiz_question.dart';

class McqQuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final String? selectedAnswer;
  final String? correctAnswer; // non-null when showing results
  final ValueChanged<String> onSelect;

  const McqQuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    this.correctAnswer,
    required this.onSelect,
  });

  bool get isReview => correctAnswer != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Quiz-specific semantic colors
    final correctColor = isDark ? AppColors.successDark : AppColors.quizCorrect;
    final correctBg = isDark ? AppColors.quizCorrectBgDark : AppColors.quizCorrectBgLight;
    final incorrectColor = isDark ? AppColors.errorDark : AppColors.quizIncorrect;
    final incorrectBg = isDark ? AppColors.quizIncorrectBgDark : AppColors.quizIncorrectBgLight;
    final warningColor = isDark ? AppColors.warningDark : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(question.options.length, (index) {
          final option = question.options[index];
          final letter = String.fromCharCode(65 + index); // A, B, C, D
          final isSelected = selectedAnswer == option;
          final isCorrect = isReview && option == correctAnswer;
          final isWrong = isReview && isSelected && option != correctAnswer;

          // Determine state colors
          Color borderColor;
          Color fillColor;
          Color badgeBg;
          Color badgeText;
          double borderWidth;
          Widget? trailingIcon;

          if (isCorrect) {
            borderColor = correctColor;
            fillColor = correctBg;
            badgeBg = correctColor;
            badgeText = Colors.white;
            borderWidth = 2;
            trailingIcon = _AnimatedIcon(
              icon: Icons.check_circle,
              color: correctColor,
              show: true,
            );
          } else if (isWrong) {
            borderColor = incorrectColor;
            fillColor = incorrectBg;
            badgeBg = incorrectColor;
            badgeText = Colors.white;
            borderWidth = 2;
            trailingIcon = _AnimatedIcon(
              icon: Icons.cancel,
              color: incorrectColor,
              show: true,
            );
          } else if (isSelected) {
            borderColor = theme.colorScheme.primary;
            fillColor = theme.colorScheme.primary.withValues(alpha: 0.08);
            badgeBg = theme.colorScheme.primary;
            badgeText = Colors.white;
            borderWidth = 2;
            trailingIcon = _AnimatedIcon(
              icon: Icons.check_circle,
              color: theme.colorScheme.primary,
              show: true,
            );
          } else {
            borderColor = theme.colorScheme.outline.withValues(alpha: 0.3);
            fillColor = Colors.transparent;
            badgeBg = theme.colorScheme.surfaceContainerHighest;
            badgeText = theme.colorScheme.onSurfaceVariant;
            borderWidth = 1;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: Spacing.borderRadiusSm,
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isReview ? null : () => onSelect(option),
                  borderRadius: Spacing.borderRadiusSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Letter badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: badgeBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: badgeText,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ?trailingIcon,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        // Explanation card (review mode)
        if (isReview && question.explanation != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              borderRadius: Spacing.borderRadiusSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: warningColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.explanation!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated icon that scales in with overshoot curve.
class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool show;

  const _AnimatedIcon({
    required this.icon,
    required this.color,
    required this.show,
  });

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    } else if (!widget.show && oldWidget.show) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(widget.icon, color: widget.color, size: 20),
        );
      },
    );
  }
}
