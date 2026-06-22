import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/quiz_question.dart';

class FillBlankQuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final TextEditingController controller;
  final String? correctAnswer;

  const FillBlankQuestionWidget({
    super.key,
    required this.question,
    required this.controller,
    this.correctAnswer,
  });

  bool get isReview => correctAnswer != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCorrect = isReview &&
        controller.text.trim().toLowerCase() == correctAnswer!.trim().toLowerCase();

    // Semantic colors
    final correctColor = isDark ? AppColors.successDark : AppColors.quizCorrect;
    final incorrectColor = isDark ? AppColors.errorDark : AppColors.quizIncorrect;
    final warningColor = isDark ? AppColors.warningDark : AppColors.warning;

    // Determine bottom border color
    Color borderColor;
    if (isReview) {
      borderColor = isCorrect ? correctColor : incorrectColor;
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.4);
    }

    // Check if question contains blank marker
    final hasInlineBlank = question.question.contains('___');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text with optional inline blank styling
        if (hasInlineBlank)
          _buildInlineBlankQuestion(context)
        else
          Text(
            question.question,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

        const SizedBox(height: 16),

        // Input field - bottom border only style
        TextField(
          controller: controller,
          enabled: !isReview,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          cursorColor: theme.colorScheme.primary,
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 12,
            ),
            // Bottom border only style
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: borderColor,
                width: 2,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isReview
                    ? (isCorrect ? correctColor : incorrectColor)
                    : theme.colorScheme.outline.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            // Suffix icon in review mode
            suffixIcon: isReview
                ? Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? correctColor : incorrectColor,
                    size: 20,
                  )
                : null,
          ),
        ),

        // Correct answer reveal (review, incorrect)
        if (isReview && !isCorrect) ...[
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            offset: Offset.zero,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Correct: $correctAnswer',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: correctColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],

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

  /// Renders question text with the blank marker styled with underline decoration.
  Widget _buildInlineBlankQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final parts = question.question.split('___');

    return RichText(
      text: TextSpan(
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i < parts.length - 1)
              TextSpan(
                text: '  _______  ',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                  decorationThickness: 2.5,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
