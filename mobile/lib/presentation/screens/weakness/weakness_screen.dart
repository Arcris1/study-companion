import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/weakness.dart';
import '../../providers/weakness_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';

class WeaknessScreen extends ConsumerWidget {
  final int notebookId;

  const WeaknessScreen({super.key, required this.notebookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weaknessAsync = ref.watch(weaknessProvider(notebookId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Weakness Analysis',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: weaknessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (weaknesses) {
          if (weaknesses.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.analytics_outlined,
              title: 'No data yet',
              subtitle:
                  'Complete some quizzes to see your strength and weakness analysis',
            );
          }

          final weakCount = weaknesses.where((w) => w.isWeak).length;

          return ListView(
            padding: const EdgeInsets.all(Spacing.screenPaddingH),
            children: [
              // Summary card
              _SummaryCard(
                isDark: isDark,
                theme: theme,
                totalTopics: weaknesses.length,
                weakCount: weakCount,
                strongCount: weaknesses.where((w) => w.accuracy >= 0.8).length,
              ),
              const SizedBox(height: Spacing.sectionGap),

              // Section header
              Text(
                'Topics by Strength',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Topic list
              ...weaknesses.map((weakness) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: _WeaknessCard(
                      weakness: weakness,
                      isDark: isDark,
                      theme: theme,
                      onFocusQuiz: weakness.isWeak
                          ? () => context.push(
                              '/focus-quiz/$notebookId/${Uri.encodeComponent(weakness.topic)}')
                          : null,
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final int totalTopics;
  final int weakCount;
  final int strongCount;

  const _SummaryCard({
    required this.isDark,
    required this.theme,
    required this.totalTopics,
    required this.weakCount,
    required this.strongCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: Spacing.borderRadiusLg,
        boxShadow: isDark ? AppShadows.level2Dark : AppShadows.level2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              _StatPill(
                label: 'Topics',
                value: '$totalTopics',
                color: Colors.white.withValues(alpha: 0.2),
                textColor: Colors.white,
              ),
              const SizedBox(width: Spacing.sm),
              _StatPill(
                label: 'Strong',
                value: '$strongCount',
                color: AppColors.success.withValues(alpha: 0.3),
                textColor: Colors.white,
              ),
              const SizedBox(width: Spacing.sm),
              _StatPill(
                label: 'Weak',
                value: '$weakCount',
                color: AppColors.error.withValues(alpha: 0.3),
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: Spacing.borderRadiusPill,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeaknessCard extends StatelessWidget {
  final Weakness weakness;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onFocusQuiz;

  const _WeaknessCard({
    required this.weakness,
    required this.isDark,
    required this.theme,
    this.onFocusQuiz,
  });

  Color get _strengthColor {
    if (weakness.accuracy >= 0.8) return AppColors.success;
    if (weakness.accuracy >= 0.6) return AppColors.warning;
    if (weakness.accuracy >= 0.4) return AppColors.error;
    return AppColors.gradeF;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (weakness.accuracy * 100).round();

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: Spacing.borderRadiusMd,
        boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Topic icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _strengthColor.withValues(alpha: 0.12),
                  borderRadius: Spacing.borderRadiusSm,
                ),
                child: Icon(
                  Icons.topic_rounded,
                  size: 20,
                  color: _strengthColor,
                ),
              ),
              const SizedBox(width: Spacing.listItemGap),

              // Topic name and stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weakness.topic,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${weakness.correctCount}/${weakness.questionCount} correct',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceVariantDark
                            : AppColors.onSurfaceVariantLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Strength badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _strengthColor.withValues(alpha: 0.15),
                  borderRadius: Spacing.borderRadiusPill,
                ),
                child: Text(
                  weakness.strengthLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _strengthColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacing.md),

          // Accuracy bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: Spacing.borderRadiusPill,
                  child: LinearProgressIndicator(
                    value: weakness.accuracy,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_strengthColor),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                '$pct%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Focus Quiz button for weak topics
          if (onFocusQuiz != null) ...[
            const SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onFocusQuiz,
                icon: const Icon(Icons.track_changes_rounded, size: 18),
                label: const Text('Focus Quiz'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _strengthColor,
                  side: BorderSide(color: _strengthColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: Spacing.borderRadiusSm,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
