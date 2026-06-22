import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/quiz_question.dart';

class TrueFalseQuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final String? selectedAnswer;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const TrueFalseQuestionWidget({
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
        Row(
          children: [
            Expanded(child: _buildOption(context, 'True')),
            const SizedBox(width: 12),
            Expanded(child: _buildOption(context, 'False')),
          ],
        ),
        if (isReview && question.explanation != null) ...[
          const SizedBox(height: 16),
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

  Widget _buildOption(BuildContext context, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = selectedAnswer == value;
    final isCorrect = isReview && value == correctAnswer;
    final isWrong = isReview && isSelected && value != correctAnswer;

    // Semantic colors
    final correctColor = isDark ? AppColors.successDark : AppColors.quizCorrect;
    final correctBg = isDark ? AppColors.quizCorrectBgDark : AppColors.quizCorrectBgLight;
    final incorrectColor = isDark ? AppColors.errorDark : AppColors.quizIncorrect;
    final incorrectBg = isDark ? AppColors.quizIncorrectBgDark : AppColors.quizIncorrectBgLight;

    Color borderColor;
    Color fillColor;
    Color labelColor;
    double borderWidth;

    if (isCorrect) {
      borderColor = correctColor;
      fillColor = correctBg;
      labelColor = correctColor;
      borderWidth = 2;
    } else if (isWrong) {
      borderColor = incorrectColor;
      fillColor = incorrectBg;
      labelColor = incorrectColor;
      borderWidth = 2;
    } else if (isSelected && !isReview) {
      borderColor = theme.colorScheme.primary;
      fillColor = theme.colorScheme.primary.withValues(alpha: 0.10);
      labelColor = theme.colorScheme.primary;
      borderWidth = 2;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.3);
      fillColor = Colors.transparent;
      labelColor = theme.colorScheme.onSurface;
      borderWidth = 1;
    }

    final iconData = value == 'True' ? Icons.check_rounded : Icons.close_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 64,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: Spacing.borderRadiusMd,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isReview ? null : () => onSelect(value),
          borderRadius: Spacing.borderRadiusMd,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    iconData,
                    size: 20,
                    color: labelColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
