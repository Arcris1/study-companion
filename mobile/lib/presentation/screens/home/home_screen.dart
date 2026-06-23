import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../providers/notebook_provider.dart';
import '../../../domain/entities/notebook.dart';
import '../../../core/openai/openai_client.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/notebook_card_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notebooks = ref.watch(notebooksProvider);
    final hasApiKey = OpenAiClient.instance.hasKey;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: notebooks.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(Spacing.screenPaddingH),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: Spacing.listItemGap,
                mainAxisSpacing: Spacing.listItemGap,
                childAspectRatio: 0.9,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => const NotebookCardSkeleton(),
            ),
          ),
          error: (e, _) => ErrorStateWidget(message: e.toString()),
          data: (list) {
            if (list.isEmpty) {
              return Column(
                children: [
                  _GreetingHeader(
                    isDark: isDark,
                    hasModel: hasApiKey,
                    onSettingsTap: () => context.push(AppRoutes.settings),
                    onModelWarningTap: () =>
                        context.push(AppRoutes.apiKeySetup),
                  ),
                  Expanded(
                    child: EmptyStateWidget(
                      icon: Icons.menu_book,
                      title: 'No notebooks yet',
                      subtitle: 'Create your first notebook to start studying',
                      actionLabel: 'Create Notebook',
                      onAction: () => context.push(AppRoutes.createNotebook),
                    ),
                  ),
                ],
              );
            }

            // Count totals for stats
            final totalNotes =
                list.fold<int>(0, (sum, nb) => sum + nb.noteCount);

            return CustomScrollView(
              slivers: [
                // Greeting
                SliverToBoxAdapter(
                  child: _GreetingHeader(
                    isDark: isDark,
                    hasModel: hasApiKey,
                    onSettingsTap: () => context.push(AppRoutes.settings),
                    onModelWarningTap: () =>
                        context.push(AppRoutes.apiKeySetup),
                  ),
                ),

                // Quick stats row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.screenPaddingH,
                    ),
                    child: Row(
                      children: [
                        _StatCard(
                          icon: Icons.menu_book_rounded,
                          value: list.length.toString(),
                          label: 'Notebooks',
                          accentColor: AppColors.primary,
                          isDark: isDark,
                        ),
                        const SizedBox(width: Spacing.listItemGap),
                        _StatCard(
                          icon: Icons.description_rounded,
                          value: totalNotes.toString(),
                          label: 'Notes',
                          accentColor: AppColors.info,
                          isDark: isDark,
                        ),
                        const SizedBox(width: Spacing.listItemGap),
                        _StatCard(
                          icon: Icons.quiz_rounded,
                          value: '—',
                          label: 'Quizzes',
                          accentColor: AppColors.success,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: Spacing.sectionGap)),

                // Quick action row
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenPaddingH),
                      children: [
                        _QuickActionChip(icon: Icons.calendar_today_rounded, label: 'Daily Plan', color: const Color(0xFF3B82F6), onTap: () => context.push(AppRoutes.planner)),
                        const SizedBox(width: 8),
                        _QuickActionChip(icon: Icons.insights_rounded, label: 'Analytics', color: const Color(0xFF10B981), onTap: () => context.push(AppRoutes.analytics)),
                        const SizedBox(width: 8),
                        _QuickActionChip(icon: Icons.search_rounded, label: 'Search', color: const Color(0xFFF59E0B), onTap: () => context.push(AppRoutes.search)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 400.ms),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: Spacing.sectionGap)),

                // Section header with accent line
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.screenPaddingH,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Notebooks',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${list.length} total',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isDark
                                ? AppColors.onSurfaceVariantDark
                                : AppColors.onSurfaceVariantLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: Spacing.listItemGap)),

                // 2-column notebook grid with staggered animation
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.screenPaddingH,
                  ),
                  sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: Spacing.listItemGap,
                        mainAxisSpacing: Spacing.listItemGap,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notebook = list[index];
                          final color = _parseColor(notebook.color);
                          return AnimationConfiguration.staggeredGrid(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            columnCount: 2,
                            child: ScaleAnimation(
                              scale: 0.92,
                              child: FadeInAnimation(
                                child: _NotebookCard(
                                  title: notebook.title,
                                  noteCount: notebook.noteCount,
                                  color: color,
                                  isDark: isDark,
                                  onTap: () =>
                                      context.push('/notebook/${notebook.id}'),
                                  onEdit: () =>
                                      _editNotebook(context, ref, notebook),
                                  onDelete: () =>
                                      _deleteNotebook(context, ref, notebook),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: list.length,
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                    child: SizedBox(height: Spacing.xxl + 80)),
              ],
            );
          },
        ),
      ),

      // Bottom nav bar
      bottomNavigationBar: _BottomNavBar(
        isDark: isDark,
        onCreateNotebook: () => context.push(AppRoutes.createNotebook),
        onSettingsTap: () => context.push(AppRoutes.settings),
      ),
    );
  }

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _editNotebook(
      BuildContext context, WidgetRef ref, Notebook notebook) async {
    final result = await showDialog<({String title, String description})>(
      context: context,
      builder: (_) => _EditNotebookDialog(
        initialTitle: notebook.title,
        initialDescription: notebook.description ?? '',
      ),
    );
    if (result == null || result.title.trim().isEmpty) return;
    await ref.read(notebooksProvider.notifier).update(
          notebook.copyWith(
            title: result.title.trim(),
            description: result.description.trim(),
          ),
        );
  }

  Future<void> _deleteNotebook(
      BuildContext context, WidgetRef ref, Notebook notebook) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notebook?'),
        content: Text(
          'Delete "${notebook.title}"? This permanently removes all its notes, '
          'quizzes, flashcards and chats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(notebooksProvider.notifier).delete(notebook.id);
  }
}

// Self-disposing edit dialog (owns its controllers — avoids the
// dispose-during-route-teardown race).
class _EditNotebookDialog extends StatefulWidget {
  final String initialTitle;
  final String initialDescription;
  const _EditNotebookDialog({
    required this.initialTitle,
    required this.initialDescription,
  });

  @override
  State<_EditNotebookDialog> createState() => _EditNotebookDialogState();
}

class _EditNotebookDialogState extends State<_EditNotebookDialog> {
  late final TextEditingController _titleCtrl =
      TextEditingController(text: widget.initialTitle);
  late final TextEditingController _descCtrl =
      TextEditingController(text: widget.initialDescription);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop((
      title: _titleCtrl.text,
      description: _descCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Notebook'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _descCtrl,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

// ─── Greeting header ────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final bool isDark;
  final bool hasModel;
  final VoidCallback onSettingsTap;
  final VoidCallback onModelWarningTap;

  const _GreetingHeader({
    required this.isDark,
    required this.hasModel,
    required this.onSettingsTap,
    required this.onModelWarningTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.screenPaddingH,
        right: Spacing.screenPaddingH,
        top: Spacing.screenPaddingV,
        bottom: Spacing.screenPaddingV,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, Student!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.onBackgroundDark
                        : AppColors.onBackgroundLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
                    .slideX(begin: -0.05, end: 0, duration: 600.ms),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Ready to study?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                    .slideX(begin: -0.05, end: 0, duration: 600.ms, delay: 200.ms),
              ],
            ),
          ),
          if (!hasModel)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: IconButton(
                icon: Icon(Icons.warning_amber_rounded,
                    color: isDark ? AppColors.errorDark : AppColors.error),
                tooltip: 'No AI model loaded',
                onPressed: onModelWarningTap,
              ),
            ),
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 24,
                color: isDark
                    ? AppColors.onSurfaceVariantDark
                    : AppColors.onSurfaceVariantLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: Spacing.borderRadiusMd,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(Spacing.cardPadding),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: Spacing.borderRadiusMd,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.4),
              ),
              boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: accentColor),
                const SizedBox(height: Spacing.xs),
                if (int.tryParse(value) != null)
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: int.parse(value)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) => Text(
                      val.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurfaceLight,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.onSurfaceDark
                          : AppColors.onSurfaceLight,
                    ),
                  ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight,
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

// ─── Notebook card ──────────────────────────────────────────────────────────

class _NotebookCard extends StatelessWidget {
  final String title;
  final int noteCount;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NotebookCard({
    required this.title,
    required this.noteCount,
    required this.color,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: Spacing.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacing.borderRadiusMd,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: Spacing.borderRadiusMd,
            boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color accent bar at top
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Spacing.radiusMd),
                    topRight: Radius.circular(Spacing.radiusMd),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container + overflow menu
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: Spacing.borderRadiusSm,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 18,
                                color: color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              tooltip: 'Options',
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.onSurfaceVariantDark
                                    : AppColors.onSurfaceVariantLight,
                              ),
                              onSelected: (v) {
                                if (v == 'edit') {
                                  onEdit();
                                } else if (v == 'delete') {
                                  onDelete();
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 12),
                                    Text('Edit'),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete_outline_rounded, size: 18),
                                    SizedBox(width: 12),
                                    Text('Delete'),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: Spacing.listItemGap),

                      // Title
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: Spacing.xs),

                      // Note count
                      Text(
                        '$noteCount notes',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariantLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick action chip ──────────────────────────────────────────────────────

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: color.withValues(alpha: isDark ? 0.15 : 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom navigation bar ──────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCreateNotebook;
  final VoidCallback onSettingsTap;

  const _BottomNavBar({
    required this.isDark,
    required this.onCreateNotebook,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: isDark ? AppShadows.level4Dark : AppShadows.level4,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Spacing.bottomNavHeight,
          child: Row(
            children: [
              // Home
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: true,
                isDark: isDark,
                onTap: () {},
              ),
              // Search
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                isActive: false,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.search),
              ),
              // Center FAB
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -8),
                    child: GestureDetector(
                      onTap: onCreateNotebook,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            ...AppShadows.level2,
                            const BoxShadow(
                              color: Color(0x337C3AED),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          semanticLabel: 'Create notebook',
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Activity
              _NavItem(
                icon: Icons.insights_rounded,
                label: 'Activity',
                isActive: false,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.analytics),
              ),
              // Settings
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isActive: false,
                isDark: isDark,
                onTap: onSettingsTap,
                iconSemanticLabel: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;
  final String? iconSemanticLabel;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    this.iconSemanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = (isDark
            ? AppColors.onSurfaceVariantDark
            : AppColors.onSurfaceVariantLight)
        .withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              semanticLabel: iconSemanticLabel,
              size: 24,
              color: isActive ? activeColor : inactiveColor,
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
