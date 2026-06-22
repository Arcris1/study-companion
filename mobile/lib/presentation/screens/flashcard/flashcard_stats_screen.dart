import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../domain/entities/flashcard.dart';
import '../../providers/flashcard_provider.dart';
import '../../widgets/common/error_state_widget.dart';

class FlashcardStatsScreen extends ConsumerWidget {
  final int deckId;

  const FlashcardStatsScreen({super.key, required this.deckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardsAsync = ref.watch(allFlashcardsProvider(deckId));
    final dueAsync = ref.watch(dueFlashcardsProvider(deckId));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Deck Statistics', style: theme.textTheme.titleLarge),
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (cards) {
          final dueCards = dueAsync.value ?? [];
          final newCount = cards.where((c) => c.statusLabel == 'New').length;
          final learningCount =
              cards.where((c) => c.statusLabel == 'Learning').length;
          final masteredCount =
              cards.where((c) => c.statusLabel == 'Mastered').length;
          final totalCards = cards.length;

          // Due this week: cards due within next 7 days
          final weekFromNow = DateTime.now().add(const Duration(days: 7));
          final dueThisWeek = cards.where((c) {
            if (c.nextReviewAt == null) return true; // new cards
            return c.nextReviewAt!.isBefore(weekFromNow);
          }).length;

          // Total reviews from all cards
          final totalReviews =
              cards.fold<int>(0, (sum, c) => sum + c.repetitions);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Spacing.screenPaddingH,
              Spacing.screenPaddingH,
              Spacing.screenPaddingH,
              Spacing.screenPaddingH + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary cards ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Due Today',
                        value: '${dueCards.length}',
                        icon: Icons.today_rounded,
                        color: AppColors.warning,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: _StatCard(
                        label: 'Due This Week',
                        value: '$dueThisWeek',
                        icon: Icons.date_range_rounded,
                        color: AppColors.info,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Cards',
                        value: '$totalCards',
                        icon: Icons.style_rounded,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: _StatCard(
                        label: 'Total Reviews',
                        value: '$totalReviews',
                        icon: Icons.repeat_rounded,
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: Spacing.sectionGap),

                // ── Cards by Status ───────────────────────────────────
                Text(
                  'Cards by Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.md),

                _StatusRow(
                  label: 'New',
                  count: newCount,
                  total: totalCards,
                  color: AppColors.info,
                  isDark: isDark,
                ),
                const SizedBox(height: Spacing.sm),
                _StatusRow(
                  label: 'Learning',
                  count: learningCount,
                  total: totalCards,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                const SizedBox(height: Spacing.sm),
                _StatusRow(
                  label: 'Mastered',
                  count: masteredCount,
                  total: totalCards,
                  color: AppColors.success,
                  isDark: isDark,
                ),

                const SizedBox(height: Spacing.sectionGap),

                // ── Card list ─────────────────────────────────────────
                Text(
                  'All Cards',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.md),

                ...cards.map((card) => _CardItem(
                      card: card,
                      isDark: isDark,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: Spacing.borderRadiusSm,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.onSurfaceVariantDark
                  : AppColors.onSurfaceVariantLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Row with Progress Bar ──────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final bool isDark;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total > 0 ? count / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: Spacing.borderRadiusMd,
        boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '$count / $total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: Spacing.borderRadiusPill,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card Item ─────────────────────────────────────────────────────────────────

class _CardItem extends StatelessWidget {
  final Flashcard card;
  final bool isDark;

  const _CardItem({
    required this.card,
    required this.isDark,
  });

  Color get _statusColor {
    switch (card.statusLabel) {
      case 'New':
        return AppColors.info;
      case 'Learning':
        return AppColors.warning;
      case 'Mastered':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
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
                Expanded(
                  child: Text(
                    card.front,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: Spacing.borderRadiusPill,
                  ),
                  child: Text(
                    card.statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (card.nextReviewAt != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                card.isDue
                    ? 'Due now'
                    : 'Next review: ${_formatDate(card.nextReviewAt!)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: card.isDue
                      ? AppColors.warning
                      : (isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariantLight),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return 'In ${diff.inDays} days';
    return '${date.month}/${date.day}/${date.year}';
  }
}
