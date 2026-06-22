import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/notebook_provider.dart';
import '../../widgets/analytics/stat_card.dart';
import '../../widgets/analytics/weekly_bar_chart.dart';
import '../../widgets/analytics/performance_line_chart.dart';

enum _AnalyticsPeriod { thisWeek, thisMonth, allTime }

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  _AnalyticsPeriod _selectedPeriod = _AnalyticsPeriod.thisWeek;
  int? _selectedNotebookId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = ref.watch(overallStatsProvider);
    final weeklyActivity = ref.watch(weeklyActivityProvider);
    final notebooks = ref.watch(notebooksProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(overallStatsProvider);
            ref.invalidate(weeklyActivityProvider);
            if (_selectedNotebookId != null) {
              ref.invalidate(quizPerformanceProvider(_selectedNotebookId!));
            }
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: Spacing.screenPaddingH,
                    right: Spacing.screenPaddingH,
                    top: Spacing.screenPaddingV,
                    bottom: Spacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            'Study Analytics',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.onBackgroundDark
                                  : AppColors.onBackgroundLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),

                      // Period selector
                      _PeriodSelector(
                        selected: _selectedPeriod,
                        isDark: isDark,
                        onChanged: (period) {
                          setState(() => _selectedPeriod = period);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: Spacing.md)),

              // Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.screenPaddingH,
                  ),
                  child: stats.when(
                    loading: () => const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    error: (e, _) => Text('Error: $e'),
                    data: (s) => Column(
                      children: [
                        Row(
                          children: [
                            StatCard(
                              icon: Icons.timer_rounded,
                              value: _formatMinutes(s.totalStudyMinutes),
                              label: 'Total Time',
                              accentColor: AppColors.primary,
                              isDark: isDark,
                            ),
                            const SizedBox(width: Spacing.listItemGap),
                            StatCard(
                              icon: Icons.local_fire_department_rounded,
                              value: '${s.streakDays}',
                              label: 'Day Streak',
                              accentColor: AppColors.warning,
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.listItemGap),
                        Row(
                          children: [
                            StatCard(
                              icon: Icons.bolt_rounded,
                              value: '${s.sessionsThisWeek}',
                              label: 'This Week',
                              accentColor: AppColors.info,
                              isDark: isDark,
                            ),
                            const SizedBox(width: Spacing.listItemGap),
                            StatCard(
                              icon: Icons.school_rounded,
                              value: s.averageQuizScore > 0
                                  ? '${s.averageQuizScore.toInt()}%'
                                  : '--',
                              label: 'Avg Score',
                              accentColor: AppColors.success,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: Spacing.sectionGap)),

              // Weekly bar chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.screenPaddingH,
                  ),
                  child: weeklyActivity.when(
                    loading: () => const SizedBox(
                      height: 240,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    error: (e, _) => Text('Error: $e'),
                    data: (data) => WeeklyBarChart(
                      data: data,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: Spacing.sectionGap)),

              // Quiz performance chart section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.screenPaddingH,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notebook selector for quiz performance
                      notebooks.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (list) {
                          if (list.isEmpty) return const SizedBox.shrink();

                          // Auto-select first notebook if none selected
                          if (_selectedNotebookId == null && list.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedNotebookId = list.first.id;
                                });
                              }
                            });
                          }

                          return SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: Spacing.sm),
                              itemBuilder: (context, index) {
                                final nb = list[index];
                                final isSelected =
                                    _selectedNotebookId == nb.id;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedNotebookId = nb.id;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Spacing.space12,
                                      vertical: Spacing.space6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? AppColors
                                                  .surfaceContainerDark
                                              : AppColors
                                                  .surfaceContainerLight),
                                      borderRadius:
                                          Spacing.borderRadiusPill,
                                    ),
                                    child: Text(
                                      nb.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? AppColors
                                                    .onSurfaceVariantDark
                                                : AppColors
                                                    .onSurfaceVariantLight),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: Spacing.md),

                      // Quiz performance line chart
                      if (_selectedNotebookId != null)
                        ref
                            .watch(
                                quizPerformanceProvider(_selectedNotebookId!))
                            .when(
                              loading: () => const SizedBox(
                                height: 260,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              error: (e, _) => Text('Error: $e'),
                              data: (data) => PerformanceLineChart(
                                data: data,
                                isDark: isDark,
                              ),
                            )
                      else
                        PerformanceLineChart(
                          data: const [],
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: Spacing.sectionGap)),

              // Summary stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.screenPaddingH,
                  ),
                  child: stats.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (s) => _SummarySection(
                      isDark: isDark,
                      notesCreated: s.totalNotesCreated,
                      quizzesTaken: s.totalQuizzesTaken,
                      flashcardsReviewed: s.totalFlashcardsReviewed,
                    ),
                  ),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                  child: SizedBox(height: Spacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}

// ─── Period Selector ──────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _AnalyticsPeriod selected;
  final bool isDark;
  final ValueChanged<_AnalyticsPeriod> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _AnalyticsPeriod.values.map((period) {
        final isSelected = selected == period;
        final label = switch (period) {
          _AnalyticsPeriod.thisWeek => 'This Week',
          _AnalyticsPeriod.thisMonth => 'This Month',
          _AnalyticsPeriod.allTime => 'All Time',
        };

        return Padding(
          padding: const EdgeInsets.only(right: Spacing.sm),
          child: GestureDetector(
            onTap: () => onChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.space12,
                vertical: Spacing.space6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight),
                borderRadius: Spacing.borderRadiusPill,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariantLight),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Summary Section ──────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  final bool isDark;
  final int notesCreated;
  final int quizzesTaken;
  final int flashcardsReviewed;

  const _SummarySection({
    required this.isDark,
    required this.notesCreated,
    required this.quizzesTaken,
    required this.flashcardsReviewed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Text(
            'Activity Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          _SummaryRow(
            icon: Icons.description_rounded,
            label: 'Notes Created',
            value: notesCreated.toString(),
            color: AppColors.info,
            isDark: isDark,
          ),
          const SizedBox(height: Spacing.space12),
          _SummaryRow(
            icon: Icons.quiz_rounded,
            label: 'Quizzes Taken',
            value: quizzesTaken.toString(),
            color: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(height: Spacing.space12),
          _SummaryRow(
            icon: Icons.style_rounded,
            label: 'Flashcards Reviewed',
            value: flashcardsReviewed.toString(),
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: Spacing.borderRadiusSm,
          ),
          child: Center(
            child: Icon(icon, size: 16, color: color),
          ),
        ),
        const SizedBox(width: Spacing.space12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.onSurfaceVariantDark
                  : AppColors.onSurfaceVariantLight,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.onSurfaceDark
                : AppColors.onSurfaceLight,
          ),
        ),
      ],
    );
  }
}
