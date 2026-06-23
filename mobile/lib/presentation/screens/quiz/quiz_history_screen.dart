import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/shadows.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';

class QuizHistoryScreen extends ConsumerWidget {
  final int quizId;

  const QuizHistoryScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final attemptsAsync = ref.watch(quizAttemptsProvider(quizId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz History', style: theme.textTheme.titleLarge),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/quiz/$quizId'),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(
          attemptsAsync.maybeWhen(
            data: (a) => a.isEmpty ? 'Take quiz' : 'Retake quiz',
            orElse: () => 'Take quiz',
          ),
        ),
      ),
      body: attemptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (attempts) {
          if (attempts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'No attempts yet',
              subtitle: 'Take the quiz to see your history here',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              Spacing.screenPaddingH,
              Spacing.md,
              Spacing.screenPaddingH,
              Spacing.md + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: attempts.length,
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final gradeColor = AppColors.gradeColor(attempt.percentage);
              final isFirst = index == 0;
              final isLast = index == attempts.length - 1;

              return _TimelineAttemptCard(
                grade: attempt.grade,
                gradeColor: gradeColor,
                score: attempt.score,
                totalQuestions: attempt.totalQuestions,
                percentage: attempt.percentage,
                completedAt: attempt.completedAt,
                isFirst: isFirst,
                isLast: isLast,
                isDark: isDark,
                onTap: () => context.push(
                  '/quiz/$quizId/results/${attempt.id}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TimelineAttemptCard extends StatelessWidget {
  final String grade;
  final Color gradeColor;
  final int score;
  final int totalQuestions;
  final double percentage;
  final DateTime completedAt;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final VoidCallback onTap;

  const _TimelineAttemptCard({
    required this.grade,
    required this.gradeColor,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.completedAt,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = isDark
        ? AppColors.outlineVariantDark
        : AppColors.outlineVariantLight;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline indicator ─────────────────────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),

                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gradeColor,
                  ),
                ),

                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(width: Spacing.space12),

          // ── Card ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(Spacing.cardPadding),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: Spacing.borderRadiusMd,
                    boxShadow:
                        isDark ? AppShadows.level1Dark : AppShadows.level1,
                  ),
                  child: Row(
                    children: [
                      // Grade badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gradeColor.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Text(
                            grade,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.space12),

                      // Score & date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$score/$totalQuestions correct (${percentage.toStringAsFixed(0)}%)',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: Spacing.xxs),
                            Text(
                              DateFormat.yMMMd()
                                  .add_jm()
                                  .format(completedAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
