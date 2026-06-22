import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/study_plan.dart';
import '../../providers/planner_provider.dart';
import '../../providers/notebook_provider.dart';
import '../../widgets/common/sc_button.dart';

class DailyPlannerScreen extends ConsumerStatefulWidget {
  const DailyPlannerScreen({super.key});

  @override
  ConsumerState<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends ConsumerState<DailyPlannerScreen> {
  int _availableMinutes = 60;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final planAsync = ref.watch(todayPlanProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Daily Planner',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: Spacing.md),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: Spacing.md),
              ScButton(
                label: 'Retry',
                variant: ScButtonVariant.outlined,
                expanded: false,
                onPressed: () => ref.read(todayPlanProvider.notifier).load(),
              ),
            ],
          ),
        ),
        data: (plan) {
          if (plan == null) {
            return _buildNoPlan(theme, isDark);
          }
          return _buildPlanView(theme, isDark, plan);
        },
      ),
    );
  }

  Widget _buildNoPlan(ThemeData theme, bool isDark) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Spacing.screenPaddingH,
        Spacing.screenPaddingH,
        Spacing.screenPaddingH,
        Spacing.screenPaddingH + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        const SizedBox(height: Spacing.xxl),
        // Date header
        _DateHeader(theme: theme, isDark: isDark),
        const SizedBox(height: Spacing.sectionGap),

        // Empty state
        Container(
          padding: const EdgeInsets.all(Spacing.cardPaddingLarge),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: Spacing.borderRadiusLg,
            boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
          ),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: isDark
                    ? AppColors.onSurfaceVariantDark
                    : AppColors.onSurfaceVariantLight,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'No plan for today',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Generate a personalized study plan based on your progress and weak areas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sectionGap),

        // Time selector
        Text(
          'Available study time',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        _TimeSelector(
          minutes: _availableMinutes,
          isDark: isDark,
          theme: theme,
          onChanged: (v) => setState(() => _availableMinutes = v),
        ),
        const SizedBox(height: Spacing.sectionGap),

        // Generate button
        ScButton(
          label: 'Generate Study Plan',
          icon: Icons.auto_awesome_rounded,
          variant: ScButtonVariant.gradient,
          onPressed: _generatePlan,
        ),
      ],
    );
  }

  Widget _buildPlanView(ThemeData theme, bool isDark, StudyPlan plan) {
    final completedCount = plan.completedCount;
    final totalTasks = plan.tasks.length;
    final progress = plan.progress;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Spacing.screenPaddingH,
        Spacing.screenPaddingH,
        Spacing.screenPaddingH,
        Spacing.screenPaddingH + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        // Date header
        _DateHeader(theme: theme, isDark: isDark),
        const SizedBox(height: Spacing.md),

        // Progress card
        Container(
          padding: const EdgeInsets.all(Spacing.cardPaddingLarge),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: Spacing.borderRadiusLg,
            boxShadow: isDark ? AppShadows.level2Dark : AppShadows.level2,
          ),
          child: Row(
            children: [
              // Progress ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '$completedCount of $totalTasks tasks done',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (progress >= 1.0) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'All done! Great work!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sectionGap),

        // Tasks header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _regeneratePlan,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Regenerate'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),

        // Task list
        ...plan.tasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: _TaskCard(
              task: task,
              isDark: isDark,
              theme: theme,
              onToggle: () {
                ref.read(todayPlanProvider.notifier).toggleTask(plan.id, index);
              },
            ),
          );
        }),

        const SizedBox(height: Spacing.lg),
      ],
    );
  }

  Future<void> _generatePlan() async {
    final notebooks = ref.read(notebooksProvider).value ?? [];
    final recentNotebooks =
        notebooks.take(5).map((n) => n.title).toList();

    ref.read(todayPlanProvider.notifier).generatePlan(
          availableMinutes: _availableMinutes,
          dueFlashcardDecks: [], // Could be populated from flashcard provider
          weakTopics: [], // Could be populated from weakness provider
          recentNotebooks: recentNotebooks,
        );
  }

  Future<void> _regeneratePlan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate Plan?'),
        content:
            const Text('This will replace your current plan for today.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _generatePlan();
    }
  }
}

class _DateHeader extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _DateHeader({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayNames[now.weekday - 1],
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${monthNames[now.month - 1]} ${now.day}, ${now.year}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark
                ? AppColors.onSurfaceVariantDark
                : AppColors.onSurfaceVariantLight,
          ),
        ),
      ],
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final int minutes;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<int> onChanged;

  const _TimeSelector({
    required this.minutes,
    required this.isDark,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [30, 45, 60, 90, 120];

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: presets.map((preset) {
        final isSelected = minutes == preset;
        return GestureDetector(
          onTap: () => onChanged(preset),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLight),
              borderRadius: Spacing.borderRadiusPill,
              boxShadow: isSelected
                  ? (isDark ? AppShadows.level1Dark : AppShadows.level1)
                  : null,
            ),
            child: Text(
              '${preset}m',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final StudyTask task;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.task,
    required this.isDark,
    required this.theme,
    required this.onToggle,
  });

  Color get _typeColor {
    switch (task.type) {
      case 'quiz_review':
        return AppColors.info;
      case 'flashcard_review':
        return AppColors.warning;
      case 'note_reading':
        return AppColors.success;
      case 'weak_area_focus':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? (isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerLight)
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: Spacing.borderRadiusMd,
        boxShadow: task.isCompleted
            ? null
            : (isDark ? AppShadows.level1Dark : AppShadows.level1),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: Spacing.borderRadiusMd,
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  border: task.isCompleted
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.outlineDark
                              : AppColors.outlineLight,
                          width: 2,
                        ),
                  borderRadius: Spacing.borderRadiusSm,
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: Spacing.listItemGap),

            // Type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: task.isCompleted ? 0.08 : 0.12),
                borderRadius: Spacing.borderRadiusSm,
              ),
              child: Icon(
                task.typeIcon,
                size: 18,
                color: task.isCompleted
                    ? _typeColor.withValues(alpha: 0.5)
                    : _typeColor,
              ),
            ),
            const SizedBox(width: Spacing.listItemGap),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted
                          ? (isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariantLight)
                          : null,
                    ),
                  ),
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceVariantDark
                            : AppColors.onSurfaceVariantLight,
                      ),
                    ),
                ],
              ),
            ),

            // Time estimate
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                borderRadius: Spacing.borderRadiusPill,
              ),
              child: Text(
                '${task.estimatedMinutes}m',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
