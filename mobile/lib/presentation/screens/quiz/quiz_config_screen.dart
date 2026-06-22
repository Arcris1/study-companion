import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_config.dart';
import '../../../core/openai/openai_client.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/animations.dart';
import '../../../domain/enums/difficulty_level.dart';
import '../../../domain/enums/question_type.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/quiz_generation_provider.dart';
import '../../widgets/common/sc_button.dart';
import '../../widgets/common/loading_overlay.dart';

class QuizConfigScreen extends ConsumerWidget {
  final int notebookId;

  const QuizConfigScreen({super.key, required this.notebookId});

  IconData _iconForType(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return Icons.format_list_bulleted_rounded;
      case QuestionType.trueFalse:
        return Icons.toggle_on_rounded;
      case QuestionType.fillBlank:
        return Icons.text_fields_rounded;
      case QuestionType.essay:
        return Icons.article_rounded;
    }
  }

  Color _difficultyColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return AppColors.difficultyEasy;
      case DifficultyLevel.medium:
        return AppColors.difficultyMedium;
      case DifficultyLevel.hard:
        return AppColors.difficultyHard;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = ref.watch(quizConfigProvider);

    return LoadingOverlay(
      isLoading: config.isGenerating,
      message: 'Generating quiz...',
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create Quiz', style: theme.textTheme.titleLarge),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Spacing.screenPaddingH,
            Spacing.lg,
            Spacing.screenPaddingH,
            Spacing.lg + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Question Type Picker ──────────────────────────────
              Text('Question Type', style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.space12),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: Spacing.space12,
                crossAxisSpacing: Spacing.space12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: QuestionType.values.map((type) {
                  final selected = config.questionType == type;
                  return _QuestionTypeCard(
                    type: type,
                    icon: _iconForType(type),
                    selected: selected,
                    isDark: isDark,
                    onTap: () => ref
                        .read(quizConfigProvider.notifier)
                        .setQuestionType(type),
                  );
                }).toList(),
              ),

              const SizedBox(height: Spacing.lg),

              // ── Difficulty Picker ─────────────────────────────────
              Text('Difficulty', style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.space12),
              Row(
                children: DifficultyLevel.values.map((level) {
                  final selected = config.difficulty == level;
                  final color = _difficultyColor(level);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: level != DifficultyLevel.hard
                            ? Spacing.sm
                            : 0,
                      ),
                      child: _DifficultyPill(
                        level: level,
                        color: color,
                        selected: selected,
                        isDark: isDark,
                        onTap: () => ref
                            .read(quizConfigProvider.notifier)
                            .setDifficulty(level),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: Spacing.lg),

              // ── Question Count Stepper ────────────────────────────
              Text('Number of Questions', style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.space12),
              _QuestionCountStepper(
                count: config.questionCount,
                min: AppConfig.minQuizQuestions,
                max: AppConfig.maxQuizQuestions,
                isDark: isDark,
                onChanged: (v) => ref
                    .read(quizConfigProvider.notifier)
                    .setQuestionCount(v),
              ),

              // Error text
              if (config.error != null) ...[
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: isDark ? AppColors.errorDark : AppColors.error,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        config.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.errorDark : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: Spacing.space40),

              // ── Generate Button ───────────────────────────────────
              ScButton(
                label: config.isGenerating ? 'Generating...' : 'Generate Quiz',
                icon: Icons.auto_awesome_rounded,
                isLoading: config.isGenerating,
                variant: ScButtonVariant.gradient,
                onPressed: config.isGenerating
                    ? null
                    : () => _generateQuiz(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateQuiz(BuildContext context, WidgetRef ref) async {
    // Cache ALL refs before async work
    final config = ref.read(quizConfigProvider);
    final configNotifier = ref.read(quizConfigProvider.notifier);
    final quizzesNotifier = ref.read(quizzesProvider(notebookId).notifier);

    if (!OpenAiClient.instance.hasKey) {
      configNotifier.setError('No OpenAI API key set. Add your key in Settings > AI.');
      return;
    }

    configNotifier.setGenerating(true);
    try {
      final quiz = await quizzesNotifier.generate(
        title: '${config.questionType.label} Quiz - ${config.difficulty.label}',
        questionType: config.questionType,
        difficulty: config.difficulty,
        questionCount: config.questionCount,
      );
      configNotifier.setGenerating(false);
      if (context.mounted) {
        context.pop();
        context.push('/quiz/${quiz.id}');
      }
    } catch (e) {
      configNotifier.setError('Failed to generate quiz: $e');
    }
  }
}

// ─── Question Type Card ──────────────────────────────────────────────────────

class _QuestionTypeCard extends StatelessWidget {
  final QuestionType type;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _QuestionTypeCard({
    required this.type,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = selected
        ? AppColors.primary
        : theme.colorScheme.onSurfaceVariant;
    final labelColor = selected
        ? AppColors.primary
        : theme.colorScheme.onSurfaceVariant;
    final bgFill = selected
        ? AppColors.primary.withValues(alpha: 0.08)
        : Colors.transparent;
    final borderColor = selected
        ? AppColors.primary
        : (isDark
            ? AppColors.outlineVariantDark
            : AppColors.outlineVariantLight);
    final borderWidth = selected ? 2.0 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.durationFast,
        curve: AppAnimations.easeOut,
        decoration: BoxDecoration(
          color: bgFill,
          borderRadius: Spacing.borderRadiusMd,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: selected
              ? (isDark ? AppShadows.level1Dark : AppShadows.level1)
              : null,
        ),
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppAnimations.durationFast,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight),
                borderRadius: Spacing.borderRadiusSm,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              type.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: labelColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Difficulty Pill ─────────────────────────────────────────────────────────

class _DifficultyPill extends StatelessWidget {
  final DifficultyLevel level;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _DifficultyPill({
    required this.level,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.durationFast,
        curve: AppAnimations.easeOut,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? color
              : (isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight),
          borderRadius: Spacing.borderRadiusPill,
          boxShadow: selected
              ? (isDark ? AppShadows.level1Dark : AppShadows.level1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              level.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Question Count Stepper ──────────────────────────────────────────────────

class _QuestionCountStepper extends StatelessWidget {
  final int count;
  final int min;
  final int max;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _QuestionCountStepper({
    required this.count,
    required this.min,
    required this.max,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atMin = count <= min;
    final atMax = count >= max;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minus button
            GestureDetector(
              onTap: atMin ? null : () => onChanged(count - 1),
              child: AnimatedOpacity(
                opacity: atMin ? 0.3 : 1.0,
                duration: AppAnimations.durationFast,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight,
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Count display
            SizedBox(
              width: 48,
              child: AnimatedSwitcher(
                duration: AppAnimations.durationFast,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: AppAnimations.easeOut,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Text(
                  '$count',
                  key: ValueKey(count),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),

            // Plus button
            GestureDetector(
              onTap: atMax ? null : () => onChanged(count + 1),
              child: AnimatedOpacity(
                opacity: atMax ? 0.3 : 1.0,
                duration: AppAnimations.durationFast,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: atMax ? null : AppGradients.primary,
                    color: atMax
                        ? (isDark
                            ? AppColors.surfaceContainerDark
                            : AppColors.surfaceContainerLight)
                        : null,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: atMax
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          '$min - $max questions',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
