import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/animations.dart';
import '../../../core/utils/session_tracker.dart';
import '../../providers/notebook_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/list_item_skeleton.dart';
import '../../widgets/note/note_card.dart';

class NotebookDetailScreen extends ConsumerStatefulWidget {
  final int notebookId;

  const NotebookDetailScreen({super.key, required this.notebookId});

  @override
  ConsumerState<NotebookDetailScreen> createState() =>
      _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends ConsumerState<NotebookDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  late final SessionTracker _tracker;
  int _activeTab = 0;
  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // FIX: listen to tab changes so FAB responds to active tab
    _tabController.addListener(_onTabChanged);

    // Track study time for this notebook (powers the Analytics dashboard).
    // Pauses when the app is backgrounded so idle time isn't counted.
    _tracker = ref.read(sessionTrackerProvider);
    WidgetsBinding.instance.addObserver(this);
    _tracker.start(widget.notebookId, 'study');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tracker.start(widget.notebookId, 'study');
    } else if (state == AppLifecycleState.paused) {
      _tracker.stop();
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _activeTab = _tabController.index;
        _fabExpanded = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tracker.stop(); // save the session for this notebook visit
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notebooks = ref.watch(notebooksProvider);
    final notebook =
        notebooks.value?.where((n) => n.id == widget.notebookId).firstOrNull;
    final notebookColor = _parseColor(notebook?.color ?? '#7C3AED');
    final notebookTitle = notebook?.title ?? 'Notebook';
    final noteCountLabel = notebook != null ? '${notebook.noteCount} notes' : '';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // ── Gradient header ──────────────────────────────────
                SliverAppBar(
                  expandedHeight: 140,
                  pinned: true,
                  backgroundColor: notebookColor,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    notebookTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  actions: [
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'weaknesses',
                          child: Row(
                            children: [
                              Icon(Icons.analytics_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Weaknesses'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Notebook'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Delete Notebook'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'weaknesses') {
                          context.push('/weakness/${widget.notebookId}');
                        } else if (value == 'edit') {
                          if (notebook == null) return;
                          final titleController = TextEditingController(text: notebook.title);
                          final descController = TextEditingController(text: notebook.description ?? '');
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Edit Notebook'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: titleController,
                                    decoration: const InputDecoration(labelText: 'Title'),
                                    autofocus: true,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: descController,
                                    decoration: const InputDecoration(labelText: 'Description'),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Save')),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            final title = titleController.text.trim();
                            if (title.isNotEmpty) {
                              ref.read(notebooksProvider.notifier).update(
                                notebook.copyWith(
                                  title: title,
                                  description: descController.text.trim().isEmpty
                                      ? null
                                      : descController.text.trim(),
                                ),
                              );
                            }
                          }
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Notebook?'),
                              content: const Text(
                                  'This will delete all notes, quizzes, and chat sessions in this notebook.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            ref
                                .read(notebooksProvider.notifier)
                                .delete(widget.notebookId);
                            context.pop();
                          }
                        }
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            notebookColor,
                            notebookColor.withValues(alpha: 0.7),
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: Spacing.screenPaddingH,
                            bottom: 16,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notebookTitle,
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                noteCountLabel,
                                style:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Chip tab selector ────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ChipTabHeaderDelegate(
                    tabController: _tabController,
                    isDark: isDark,
                    activeTab: _activeTab,
                    onTabChanged: (i) {
                      _tabController.animateTo(i);
                    },
                  ),
                ),
              ];
            },

            // ── Tab content ─────────────────────────────────────────
            body: TabBarView(
              controller: _tabController,
              children: [
                // Notes tab
                _buildNotesTab(isDark, theme),

                // Quizzes tab
                _buildQuizzesTab(isDark, theme),

                // Chat tab
                _buildChatTab(isDark, theme),

                // Flashcards tab
                _buildFlashcardsTab(isDark, theme),
              ],
            ),
          ),

          // ── Speed dial FAB ──────────────────────────────────────────
          _SpeedDialFab(
            isExpanded: _fabExpanded,
            activeTab: _activeTab,
            isDark: isDark,
            onToggle: () => setState(() => _fabExpanded = !_fabExpanded),
            onDismiss: () => setState(() => _fabExpanded = false),
            notebookId: widget.notebookId,
            ref: ref,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(bool isDark, ThemeData theme) {
    final notes = ref.watch(notesProvider(widget.notebookId));
    return notes.when(
      loading: () => const ListItemSkeleton(),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
      data: (list) {
        if (list.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.note_add,
            title: 'No notes yet',
            subtitle: 'Import a PDF or create notes manually',
            actionLabel: 'Add Note',
            onAction: () =>
                context.push('/notebook/${widget.notebookId}/import'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.screenPaddingH),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final note = list[index];
            return NoteCard(
              note: note,
              onTap: () => context.push('/note/${note.id}'),
              onDelete: () {
                ref
                    .read(notesProvider(widget.notebookId).notifier)
                    .delete(note.id);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ref.invalidate(chatSessionsProvider(widget.notebookId));
                    ref.invalidate(quizzesProvider(widget.notebookId));
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuizzesTab(bool isDark, ThemeData theme) {
    return Consumer(
      builder: (context, ref, _) {
        final quizzes = ref.watch(quizzesProvider(widget.notebookId));
        return quizzes.when(
          loading: () => const ListItemSkeleton(),
          error: (e, _) => ErrorStateWidget(message: e.toString()),
          data: (list) {
            if (list.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.quiz,
                title: 'No quizzes yet',
                subtitle: 'Generate AI-powered quizzes from your notes',
                actionLabel: 'Create Quiz',
                onAction: () => context
                    .push('/notebook/${widget.notebookId}/quiz-config'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(Spacing.screenPaddingH),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final quiz = list[index];
                final diffColor = _difficultyColor(quiz.difficulty.label);

                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.cardPadding),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: Spacing.borderRadiusMd,
                      boxShadow: isDark
                          ? AppShadows.level1Dark
                          : AppShadows.level1,
                    ),
                    child: InkWell(
                      onTap: () => context.push('/quiz/${quiz.id}/history'),
                      borderRadius: Spacing.borderRadiusMd,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  diffColor.withValues(alpha: 0.12),
                              borderRadius: Spacing.borderRadiusSm,
                            ),
                            child: Icon(Icons.quiz_rounded,
                                size: 20, color: diffColor),
                          ),
                          const SizedBox(width: Spacing.listItemGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(quiz.title,
                                    style:
                                        theme.textTheme.titleSmall),
                                Text(
                                  '${quiz.questionCount} questions - ${quiz.questionType.label}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: isDark
                                        ? AppColors
                                            .onSurfaceVariantDark
                                        : AppColors
                                            .onSurfaceVariantLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Difficulty pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm,
                              vertical: Spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  diffColor.withValues(alpha: 0.15),
                              borderRadius: Spacing.borderRadiusPill,
                            ),
                            child: Text(
                              quiz.difficulty.label,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                color: diffColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.onSurfaceVariantDark
                                    : AppColors.onSurfaceVariantLight),
                            tooltip: 'Delete',
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            onPressed: () {
                              ref.read(quizzesProvider(widget.notebookId).notifier).delete(quiz.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatTab(bool isDark, ThemeData theme) {
    return Consumer(
      builder: (context, ref, _) {
        final sessions = ref.watch(chatSessionsProvider(widget.notebookId));
        return sessions.when(
          loading: () => const ListItemSkeleton(),
          error: (e, _) => ErrorStateWidget(message: e.toString()),
          data: (list) {
            if (list.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.chat,
                title: 'No chat sessions',
                subtitle: 'Ask AI questions about your notes',
                actionLabel: 'Start Chat',
                onAction: () async {
                  final repo = ref.read(chatRepositoryProvider);
                  final session = await repo.createSession(
                      widget.notebookId, 'New Chat');
                  if (context.mounted) {
                    context.push(
                        '/notebook/${widget.notebookId}/chat/${session.id}');
                  }
                },
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(Spacing.screenPaddingH),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final session = list[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.cardPadding),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: Spacing.borderRadiusMd,
                      boxShadow: isDark
                          ? AppShadows.level1Dark
                          : AppShadows.level1,
                    ),
                    child: InkWell(
                      onTap: () => context.push(
                          '/notebook/${widget.notebookId}/chat/${session.id}'),
                      borderRadius: Spacing.borderRadiusMd,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceContainerDark
                                  : AppColors.surfaceContainerLight,
                              borderRadius: Spacing.borderRadiusSm,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: Spacing.listItemGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(session.title,
                                    style:
                                        theme.textTheme.titleSmall),
                                Text(
                                  '${session.messageCount} messages',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: isDark
                                        ? AppColors
                                            .onSurfaceVariantDark
                                        : AppColors
                                            .onSurfaceVariantLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.onSurfaceVariantDark
                                    : AppColors.onSurfaceVariantLight),
                            tooltip: 'Delete',
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            onPressed: () async {
                              await ref.read(chatRepositoryProvider).deleteSession(session.id);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  ref.invalidate(chatSessionsProvider(widget.notebookId));
                                }
                              });
                            },
                          ),
                          Icon(Icons.chevron_right,
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariantLight),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFlashcardsTab(bool isDark, ThemeData theme) {
    return Consumer(
      builder: (context, ref, _) {
        final decks = ref.watch(flashcardDecksProvider(widget.notebookId));
        return decks.when(
          loading: () => const ListItemSkeleton(),
          error: (e, _) => ErrorStateWidget(message: e.toString()),
          data: (list) {
            if (list.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.style_rounded,
                title: 'No flashcard decks yet',
                subtitle: 'Create AI-powered flashcards for spaced repetition',
                actionLabel: 'Create Deck',
                onAction: () => context
                    .push('/notebook/${widget.notebookId}/flashcards'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(Spacing.screenPaddingH),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final deck = list[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.cardPadding),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: Spacing.borderRadiusMd,
                      boxShadow: isDark
                          ? AppShadows.level1Dark
                          : AppShadows.level1,
                    ),
                    child: InkWell(
                      onTap: () => context.push('/flashcard-deck/${deck.id}/study'),
                      borderRadius: Spacing.borderRadiusMd,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: Spacing.borderRadiusSm,
                            ),
                            child: const Icon(
                              Icons.style_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: Spacing.listItemGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(deck.title,
                                    style:
                                        theme.textTheme.titleSmall),
                                Text(
                                  '${deck.cardCount} cards',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: isDark
                                        ? AppColors
                                            .onSurfaceVariantDark
                                        : AppColors
                                            .onSurfaceVariantLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (deck.dueCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.sm,
                                vertical: Spacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: Spacing.borderRadiusPill,
                              ),
                              child: Text(
                                '${deck.dueCount} due',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: Spacing.xs),
                          Icon(Icons.chevron_right,
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariantLight),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _difficultyColor(String label) {
    switch (label.toLowerCase()) {
      case 'easy':
        return AppColors.difficultyEasy;
      case 'medium':
        return AppColors.difficultyMedium;
      case 'hard':
        return AppColors.difficultyHard;
      default:
        return AppColors.primary;
    }
  }
}

// ─── Chip tab header delegate ───────────────────────────────────────────────

class _ChipTabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isDark;
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  _ChipTabHeaderDelegate({
    required this.tabController,
    required this.isDark,
    required this.activeTab,
    required this.onTabChanged,
  });

  static const _tabs = [
    (icon: Icons.description_rounded, label: 'Notes'),
    (icon: Icons.quiz_rounded, label: 'Quizzes'),
    (icon: Icons.chat_rounded, label: 'Chat'),
    (icon: Icons.style_rounded, label: 'Flashcards'),
  ];

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenPaddingH,
        vertical: Spacing.listItemGap,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          final isActive = activeTab == i;

          return Padding(
            padding: EdgeInsets.only(right: i < _tabs.length - 1 ? Spacing.sm : 0),
            child: GestureDetector(
              onTap: () => onTabChanged(i),
              child: AnimatedContainer(
                duration: AppAnimations.durationMedium,
                curve: AppAnimations.easeOut,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerLight),
                  borderRadius: Spacing.borderRadiusPill,
                  boxShadow: isActive
                      ? (isDark ? AppShadows.level1Dark : AppShadows.level1)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 16,
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariantLight),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                ? AppColors.onSurfaceVariantDark
                                : AppColors.onSurfaceVariantLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ChipTabHeaderDelegate oldDelegate) =>
      activeTab != oldDelegate.activeTab || isDark != oldDelegate.isDark;
}

// ─── Speed dial FAB ─────────────────────────────────────────────────────────

class _SpeedDialFab extends StatelessWidget {
  final bool isExpanded;
  final int activeTab;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDismiss;
  final int notebookId;
  final WidgetRef ref;

  const _SpeedDialFab({
    required this.isExpanded,
    required this.activeTab,
    required this.isDark,
    required this.onToggle,
    required this.onDismiss,
    required this.notebookId,
    required this.ref,
  });

  List<_FabAction> _actionsForTab(BuildContext context) {
    switch (activeTab) {
      case 0: // Notes
        return [
          _FabAction(
            icon: Icons.upload_file_rounded,
            label: 'Import File',
            onTap: () => context.push('/notebook/$notebookId/import'),
          ),
          _FabAction(
            icon: Icons.edit_rounded,
            label: 'Write Note',
            onTap: () => context.push('/notebook/$notebookId/import'),
          ),
        ];
      case 1: // Quizzes
        return [
          _FabAction(
            icon: Icons.auto_awesome_rounded,
            label: 'Create Quiz',
            onTap: () => context.push('/notebook/$notebookId/quiz-config'),
          ),
        ];
      case 2: // Chat
        return [
          _FabAction(
            icon: Icons.chat_rounded,
            label: 'New Chat',
            onTap: () async {
              final repo = ref.read(chatRepositoryProvider);
              final session =
                  await repo.createSession(notebookId, 'New Chat');
              if (context.mounted) {
                context.push('/notebook/$notebookId/chat/${session.id}');
              }
            },
          ),
        ];
      case 3: // Flashcards
        return [
          _FabAction(
            icon: Icons.style_rounded,
            label: 'Create Deck',
            onTap: () => context.push('/notebook/$notebookId/flashcards'),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForTab(context);

    return Positioned(
      right: Spacing.screenPaddingH,
      bottom: Spacing.fabBottomMargin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sub-action buttons
          ...List.generate(actions.length, (i) {
            final action = actions[actions.length - 1 - i];
            return AnimatedSlide(
              duration: Duration(
                  milliseconds: 200 + (i * 50)),
              curve: AppAnimations.easeOut,
              offset: isExpanded ? Offset.zero : const Offset(0, 0.5),
              child: AnimatedOpacity(
                duration: Duration(
                    milliseconds: 200 + (i * 50)),
                opacity: isExpanded ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label chip
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
                          action.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.onSurfaceDark
                                : AppColors.onSurfaceLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      // Mini FAB
                      GestureDetector(
                        onTap: () {
                          onDismiss();
                          action.onTap();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            shape: BoxShape.circle,
                            boxShadow: isDark
                                ? AppShadows.level2Dark
                                : AppShadows.level2,
                          ),
                          child: Icon(
                            action.icon,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Main FAB
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? AppShadows.level3Dark
                    : AppShadows.level3,
              ),
              child: AnimatedRotation(
                turns: isExpanded ? 0.125 : 0,
                duration: AppAnimations.durationMedium,
                curve: AppAnimations.overshoot,
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FabAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
