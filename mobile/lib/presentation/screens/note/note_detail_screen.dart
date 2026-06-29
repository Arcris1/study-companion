import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/annotate_prefs.dart';
import '../../../core/utils/view_prefs.dart';
import '../../../core/utils/app_paths.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/animations.dart';
import '../../../core/ai/ai_config.dart';
import '../../../core/llm/llm_service.dart';
import '../../../core/openai/openai_client.dart';
import '../../../data/models/highlight_model.dart';
import '../../providers/highlight_provider.dart';
import '../../providers/note_annotation_provider.dart';
import '../../providers/note_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/markdown_view.dart';
import '../../widgets/common/sc_button.dart';
import '../../widgets/common/view_scale_sheet.dart';
import '../../widgets/note/processing_indicator.dart';

/// Palette for highlight color tags (ARGB ints, stored directly on the model).
const _highlightColors = <int>[
  0xFFFFD54F, // amber
  0xFF81C784, // green
  0xFF64B5F6, // blue
  0xFFF06292, // pink
  0xFFBA68C8, // purple
  0xFFFF8A65, // orange
];

final _noteProvider = FutureProvider.family((ref, int noteId) async {
  final repo = ref.read(noteRepositoryProvider);
  return repo.getById(noteId);
});

final _summaryProvider = FutureProvider.family((ref, int noteId) async {
  final repo = ref.read(noteRepositoryProvider);
  return repo.generateSummary(noteId);
});

class NoteDetailScreen extends ConsumerStatefulWidget {
  final int noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _editController;
  bool _showSummary = false;
  bool _isEditing = false;
  int _activeTab = 0;
  String _selectedText = '';
  final ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });

    // If this note was last left in annotate mode, jump straight back to it
    // (replace so system-back from annotate returns to the notes list).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && AnnotatePrefs.instance.isAnnotate(widget.noteId)) {
        context.pushReplacement('/note/${widget.noteId}/annotate');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  /// Switches to the Content tab and scrolls to the approximate location of a
  /// highlighted passage. Anchoring can't be exact inside rendered Markdown, so
  /// we estimate the position from the text's character offset.
  void _jumpToHighlight(String text) {
    _tabController.animateTo(0);
    final note = ref.read(_noteProvider(widget.noteId)).value;
    final raw = note?.rawText ?? '';
    final idx = raw.toLowerCase().indexOf(text.trim().toLowerCase());

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || !_contentScrollController.hasClients) return;
      final max = _contentScrollController.position.maxScrollExtent;
      final ratio = (idx < 0 || raw.isEmpty) ? 0.0 : idx / raw.length;
      _contentScrollController.animateTo(
        (max * ratio).clamp(0.0, max),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jumped to where this was highlighted (approximate)'),
      ),
    );
  }

  /// Custom text-selection toolbar: our "Ask AI" action plus the platform
  /// defaults (Copy, Select all, …).
  Widget _selectionToolbar(
    BuildContext context,
    SelectableRegionState selState,
  ) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selState.contextMenuAnchors,
      buttonItems: [
        ContextMenuButtonItem(
          label: 'Ask AI',
          onPressed: () {
            final text = _selectedText.trim();
            selState.hideToolbar();
            if (text.isNotEmpty) _askAiAboutSelection(text);
          },
        ),
        ContextMenuButtonItem(
          label: 'Highlight',
          onPressed: () {
            final text = _selectedText.trim();
            selState.hideToolbar();
            if (text.isNotEmpty) _saveHighlightFlow(text);
          },
        ),
        ...selState.contextMenuButtonItems,
      ],
    );
  }

  void _askAiAboutSelection(
    String selection, {
    void Function(String answer)? onSaveAnswer,
  }) {
    if (!OpenAiClient.instance.hasKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No OpenAI API key set. Add your key in Settings > AI.',
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AskAiSheet(selection: selection, onSaveAnswer: onSaveAnswer),
    );
  }

  Future<void> _saveHighlightFlow(String text) async {
    final result = await showModalBottomSheet<({int color, String? note})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HighlightEditorSheet(quote: text),
    );
    if (result == null) return;

    ref
        .read(highlightDatasourceProvider)
        .save(
          HighlightModel(
            noteId: widget.noteId,
            text: text,
            colorValue: result.color,
            note: (result.note != null && result.note!.trim().isNotEmpty)
                ? result.note!.trim()
                : null,
            createdAt: DateTime.now(),
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(highlightsProvider(widget.noteId));
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to Highlights')));
    }
  }

  Widget _buildHighlightsTab(ThemeData theme, bool isDark, int noteId) {
    final async = ref.watch(highlightsProvider(noteId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
      data: (highlights) {
        if (highlights.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.highlight_alt_rounded,
            title: 'No highlights yet',
            subtitle:
                'Select text in the Content tab, then tap "Highlight" to save it here with a color and an optional note.',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            Spacing.screenPaddingH,
            Spacing.md,
            Spacing.screenPaddingH,
            Spacing.lg + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: highlights.length,
          separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
          itemBuilder: (context, index) {
            final h = highlights[index];
            return _HighlightCard(
              highlight: h,
              isDark: isDark,
              onGoToSource: () => _jumpToHighlight(h.text),
              onAskAi: () => _askAiAboutSelection(
                (h.note != null && h.note!.isNotEmpty)
                    ? '${h.text}\n\n(My note: ${h.note})'
                    : h.text,
                onSaveAnswer: (answer) {
                  h.aiAnswer = answer;
                  ref.read(highlightDatasourceProvider).save(h);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) ref.invalidate(highlightsProvider(noteId));
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI answer saved to highlight'),
                      ),
                    );
                  }
                },
              ),
              onDelete: () {
                ref.read(highlightDatasourceProvider).delete(h.id);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) ref.invalidate(highlightsProvider(noteId));
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final noteAsync = ref.watch(_noteProvider(widget.noteId));
    final annotation = ref.watch(noteAnnotationProvider(widget.noteId)).asData?.value;
    final hasAnnotations = annotation != null && !annotation.isEmpty;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      floatingActionButton: (_activeTab == 0 && !_isEditing)
          ? FloatingActionButton(
              tooltip: 'Annotate — draw, highlight, sidenotes',
              onPressed: () async {
                await AnnotatePrefs.instance.setAnnotate(widget.noteId, true);
                if (context.mounted) {
                  context.pushReplacement('/note/${widget.noteId}/annotate');
                }
              },
              child: const Icon(Icons.draw_rounded),
            )
          : null,
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Note not found'));
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // ── Sticky header ─────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  title: Text(
                    note.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    if (_activeTab == 0 && note.sourceType != 'pdf')
                      IconButton(
                        tooltip: 'Text size',
                        icon: const Icon(Icons.format_size_rounded),
                        onPressed: () => showViewScaleSheet(
                          context,
                          title: 'Text size',
                          value: ViewPrefs.instance.readScale,
                          min: ViewPrefs.minRead,
                          max: ViewPrefs.maxRead,
                          onChanged: (v) async {
                            await ViewPrefs.instance.setReadScale(v);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    if (_activeTab == 0)
                      IconButton(
                        tooltip: 'Fullscreen reading',
                        icon: const Icon(Icons.fullscreen_rounded),
                        onPressed: () =>
                            context.push('/note/${widget.noteId}/read'),
                      ),
                    if (_activeTab == 0 && note.sourceType != 'pdf')
                      IconButton(
                        tooltip: hasAnnotations
                            ? 'Locked (has annotations)'
                            : 'Edit',
                        icon: Icon(
                          _isEditing
                              ? Icons.check_rounded
                              : (hasAnnotations
                                  ? Icons.lock_outline_rounded
                                  : Icons.edit_rounded),
                        ),
                        onPressed: () async {
                          if (hasAnnotations && !_isEditing) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Editing is locked while this note has annotations. Clear them in Annotate to edit the text.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (_isEditing) {
                            // Save changes
                            final currentNote = ref
                                .read(_noteProvider(widget.noteId))
                                .value;
                            if (currentNote != null) {
                              final updatedNote = currentNote.copyWith(
                                rawText: _editController.text,
                                updatedAt: DateTime.now(),
                              );
                              await ref
                                  .read(noteRepositoryProvider)
                                  .update(updatedNote);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  ref.invalidate(_noteProvider(widget.noteId));
                                }
                              });
                            }
                            setState(() => _isEditing = false);
                          } else {
                            // Enter edit mode
                            final currentNote = ref
                                .read(_noteProvider(widget.noteId))
                                .value;
                            if (currentNote != null) {
                              _editController.text = currentNote.rawText;
                            }
                            setState(() => _isEditing = true);
                          }
                        },
                      ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.screenPaddingH,
                        vertical: Spacing.sm,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _TabChip(
                              icon: Icons.description_rounded,
                              label: 'Content',
                              isActive: _activeTab == 0,
                              isDark: isDark,
                              onTap: () => _tabController.animateTo(0),
                            ),
                            const SizedBox(width: Spacing.sm),
                            _TabChip(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Summary',
                              isActive: _activeTab == 1,
                              isDark: isDark,
                              onTap: () => _tabController.animateTo(1),
                            ),
                            const SizedBox(width: Spacing.sm),
                            _TabChip(
                              icon: Icons.highlight_rounded,
                              label: 'Highlights',
                              isActive: _activeTab == 2,
                              isDark: isDark,
                              onTap: () => _tabController.animateTo(2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AiIndexBanner(
                    noteId: widget.noteId,
                    canOcr: note.sourceType == 'pdf' ||
                        note.sourceType == 'image',
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // ── Content tab ─────────────────────────────────────
                note.sourceType == 'pdf'
                    ? _PdfContent(path: note.sourcePath)
                    : SingleChildScrollView(
                  controller: _contentScrollController,
                  padding: const EdgeInsets.all(Spacing.screenPaddingH),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler:
                          TextScaler.linear(ViewPrefs.instance.readScale),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      // Source image (for image notes) shown above its text.
                      if (note.sourceType == 'image')
                        _ImageHeader(path: note.sourcePath),
                      // Status + chunk count row
                      Row(
                        children: [
                          ProcessingIndicator(status: note.status),
                          const Spacer(),
                          Text(
                            '${note.chunkCount} chunks',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariantLight,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: Spacing.md),

                      // Note content. Markdown notes render as a formatted
                      // preview in view mode; editing shows the raw source.
                      _isEditing
                          ? TextField(
                              controller: _editController,
                              maxLines: null,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.7,
                                color: isDark
                                    ? AppColors.onSurfaceDark
                                    : AppColors.onSurfaceLight,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          : SelectionArea(
                              onSelectionChanged: (content) {
                                _selectedText = content?.plainText ?? '';
                              },
                              contextMenuBuilder: _selectionToolbar,
                              child: (note.sourceType == 'md' ||
                                      note.sourceType == 'image')
                                  ? MarkdownView(
                                      data: note.rawText,
                                      selectable: false,
                                    )
                                  : Text(
                                      note.rawText,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            height: 1.7,
                                            color: isDark
                                                ? AppColors.onSurfaceDark
                                                : AppColors.onSurfaceLight,
                                          ),
                                    ),
                            ),
                    ],
                      ),
                    ),
                    ),
                  ),
                ),

                // ── Summary tab ─────────────────────────────────────
                _buildSummaryTab(theme, isDark),

                // ── Highlights tab ──────────────────────────────────
                _buildHighlightsTab(theme, isDark, note.id),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryTab(ThemeData theme, bool isDark) {
    final noteAsync = ref.watch(_noteProvider(widget.noteId));
    final note = noteAsync.value;

    if (note == null) return const SizedBox.shrink();

    // State 3: Summary already exists
    if (note.summary != null && note.summary!.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.screenPaddingH),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Generated badge
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'AI Generated',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.md),

            MarkdownView(data: note.summary!),
              ],
            ),
          ),
        ),
      );
    }

    // State 1: Generate prompt
    if (!_showSummary) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(Spacing.xl),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            borderRadius: Spacing.borderRadiusLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient-masked sparkle icon
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.primary.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: Spacing.md),

              Text(
                'AI Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppColors.onSurfaceDark
                      : AppColors.onSurfaceLight,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: Spacing.sm),

              Text(
                'Generate a concise summary of your notes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.onSurfaceVariantDark
                      : AppColors.onSurfaceVariantLight,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacing.sectionGap),

              ScButton(
                label: 'Generate Summary',
                icon: Icons.auto_awesome_rounded,
                variant: ScButtonVariant.gradient,
                expanded: true,
                onPressed: () => setState(() => _showSummary = true),
              ),
            ],
          ),
        ),
      );
    }

    // State 2: Generating
    final summaryAsync = ref.watch(_summaryProvider(widget.noteId));
    return summaryAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.screenPaddingH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shimmer skeleton bars
              ..._shimmerBars(isDark, [1.0, 0.85, 0.92, 0.78, 0.6]),

              const SizedBox(height: Spacing.md),

              // Pulsing label
              _PulsingText(text: 'Analyzing your notes...', isDark: isDark),
            ],
          ),
        ),
      ),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
      data: (summary) {
        // State 3: Reveal with animation
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppAnimations.durationSlow,
          curve: AppAnimations.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - value)),
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.screenPaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Generated badge
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI Generated',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Spacing.md),

                MarkdownView(data: summary),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _shimmerBars(bool isDark, List<double> widthFactors) {
    return widthFactors.map((factor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: FractionallySizedBox(
          widthFactor: factor,
          alignment: Alignment.centerLeft,
          child: _ShimmerBar(isDark: isDark),
        ),
      );
    }).toList();
  }
}

// ─── Tab chip ───────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : (isDark
                        ? AppColors.onSurfaceVariantDark
                        : AppColors.onSurfaceVariantLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
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
    );
  }
}

// ─── Shimmer bar ────────────────────────────────────────────────────────────

class _ShimmerBar extends StatefulWidget {
  final bool isDark;
  const _ShimmerBar({required this.isDark});

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: Spacing.borderRadiusSm,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: [
                widget.isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                widget.isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                widget.isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Pulsing text ───────────────────────────────────────────────────────────

class _PulsingText extends StatefulWidget {
  final String text;
  final bool isDark;
  const _PulsingText({required this.text, required this.isDark});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Opacity(
          opacity: 0.6 + 0.4 * _controller.value,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}

// ─── Ask-AI-about-selection bottom sheet ─────────────────────────────────────

// Banner that lets the user build the AI (RAG) index on demand. Hidden once
// the note is indexed or has no text. Indexing is never done at import time.
class _AiIndexBanner extends ConsumerStatefulWidget {
  final int noteId;
  final bool canOcr;
  const _AiIndexBanner({required this.noteId, this.canOcr = false});

  @override
  ConsumerState<_AiIndexBanner> createState() => _AiIndexBannerState();
}

class _AiIndexBannerState extends ConsumerState<_AiIndexBanner> {
  bool _indexing = false;
  bool _ocring = false;
  int _done = 0;
  int _total = 0;

  Future<void> _run(Future<void> Function(void Function(int, int)) op,
      {required bool ocr}) async {
    setState(() {
      _indexing = !ocr;
      _ocring = ocr;
      _done = 0;
      _total = 0;
    });
    try {
      await op((d, t) {
        if (mounted) {
          setState(() {
            _done = d;
            _total = t;
          });
        }
      });
      ref.invalidate(noteIndexProvider(widget.noteId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _indexing = false;
          _ocring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateAsync = ref.watch(noteIndexProvider(widget.noteId));
    return stateAsync.maybeWhen(
      data: (s) {
        if (_ocring) {
          return _bar(theme,
              progress: true,
              text: _total > 0
                  ? 'Extracting text (OCR)… $_done / $_total'
                  : 'Extracting text (OCR)…');
        }
        if (_indexing) {
          return _bar(theme,
              progress: true,
              text: _total > 0
                  ? 'Building AI index… $_done / $_total'
                  : 'Building AI index…');
        }
        if (s.total == 0) {
          if (widget.canOcr) {
            return _bar(theme,
                icon: Icons.document_scanner_rounded,
                text: 'No text yet — extract it with AI (OCR)',
                action: 'Extract text (OCR)',
                onAction: () => _run(
                    (p) => ref
                        .read(noteRepositoryProvider)
                        .ocrNote(widget.noteId, onProgress: p),
                    ocr: true));
          }
          return const SizedBox.shrink();
        }
        if (s.embedded == 0) {
          return _bar(theme,
              icon: Icons.auto_awesome_rounded,
              text: 'Not indexed — build the AI index to chat about this note',
              action: 'Build AI Index',
              onAction: () => _run(
                  (p) => ref
                      .read(noteRepositoryProvider)
                      .indexNote(widget.noteId, onProgress: p),
                  ocr: false));
        }
        return const SizedBox.shrink();
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _bar(ThemeData theme,
      {bool progress = false,
      IconData? icon,
      required String text,
      String? action,
      VoidCallback? onAction}) {
    final fg = theme.colorScheme.onPrimaryContainer;
    return Material(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        child: Row(
          children: [
            if (progress)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else if (icon != null)
              Icon(icon, size: 18, color: fg),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(text,
                  style: theme.textTheme.bodySmall?.copyWith(color: fg)),
            ),
            if (action != null)
              TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

// Source image shown above an image note's extracted text.
class _ImageHeader extends StatelessWidget {
  final String? path;
  const _ImageHeader({this.path});

  @override
  Widget build(BuildContext context) {
    final resolved = AppPaths.resolve(path);
    if (resolved == null || !File(resolved).existsSync()) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: ClipRRect(
        borderRadius: Spacing.borderRadiusSm,
        child: Image.file(File(resolved), fit: BoxFit.contain),
      ),
    );
  }
}

// Inline rendered PDF for the Content tab. Rendered as a normal ListView of
// page images so it scrolls smoothly inside the NestedScrollView (the full
// PdfViewer's own scroll fights the outer scroll). Pinch-zoom is available in
// the fullscreen reader.
class _PdfContent extends StatelessWidget {
  final String? path;
  const _PdfContent({this.path});

  @override
  Widget build(BuildContext context) {
    final p = AppPaths.resolve(path);
    if (p == null || !File(p).existsSync()) {
      return const Center(child: Text('PDF file unavailable'));
    }
    return PdfDocumentViewBuilder.file(
      p,
      builder: (context, document) {
        if (document == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: document.pages.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PdfPageView(document: document, pageNumber: index + 1),
          ),
        );
      },
    );
  }
}

class _AskAiSheet extends ConsumerStatefulWidget {
  final String selection;

  /// When provided, a "Save answer" button appears once the answer finishes,
  /// passing the answer text back to be persisted (e.g. onto a highlight).
  final void Function(String answer)? onSaveAnswer;
  const _AskAiSheet({required this.selection, this.onSaveAnswer});

  @override
  ConsumerState<_AskAiSheet> createState() => _AskAiSheetState();
}

class _AskAiSheetState extends ConsumerState<_AskAiSheet> {
  final StringBuffer _buffer = StringBuffer();
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final prompt =
        '''<|begin_of_turn|>system
${AiConfig.instance.systemPrompt(AiOp.askAi)}<|end_of_turn|>
<|begin_of_turn|>user
Explain this passage from my notes:

"${widget.selection}"<|end_of_turn|>
<|begin_of_turn|>assistant
''';
    try {
      await for (final token
          in ref
              .read(llmServiceProvider)
              .generateStream(
                prompt,
                maxTokens: AiConfig.instance.tokenLimit(AiOp.askAi),
              )) {
        if (!mounted) return;
        setState(() => _buffer.write(token));
      }
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e.toString().replaceFirst('LlmException: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final answer = _buffer.toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Grab handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.screenPaddingH,
                  0,
                  Spacing.screenPaddingH,
                  Spacing.sm,
                ),
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppGradients.primary.createShader(b),
                      blendMode: BlendMode.srcIn,
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text('Ask AI', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    if (!_done && _error == null)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              // Quoted selection
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.screenPaddingH,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: Spacing.borderRadiusSm,
                    border: Border(
                      left: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    widget.selection,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              const Divider(height: 1),
              // Answer
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(Spacing.screenPaddingH),
                  child: _error != null
                      ? Text(_error!, style: TextStyle(color: AppColors.error))
                      : answer.isEmpty
                      ? Text(
                          'Thinking…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : MarkdownView(data: answer, selectable: true),
                ),
              ),
              // Save-answer footer (only when a save handler was provided)
              if (widget.onSaveAnswer != null && _done && answer.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.screenPaddingH,
                      Spacing.sm,
                      Spacing.screenPaddingH,
                      Spacing.md,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: () {
                          widget.onSaveAnswer!(answer);
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                        label: const Text('Save answer to highlight'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Highlight card (Highlights tab) ─────────────────────────────────────────

class _HighlightCard extends StatelessWidget {
  final HighlightModel highlight;
  final bool isDark;
  final VoidCallback onGoToSource;
  final VoidCallback onAskAi;
  final VoidCallback onDelete;

  const _HighlightCard({
    required this.highlight,
    required this.isDark,
    required this.onGoToSource,
    required this.onAskAi,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(highlight.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: Spacing.borderRadiusMd,
        boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quoted text — tap to jump to its source in Content.
                    GestureDetector(
                      onTap: onGoToSource,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        highlight.text,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (highlight.note != null &&
                        highlight.note!.isNotEmpty) ...[
                      const SizedBox(height: Spacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              highlight.note!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (highlight.aiAnswer != null &&
                        highlight.aiAnswer!.isNotEmpty) ...[
                      const SizedBox(height: Spacing.sm),
                      _CollapsibleAiAnswer(
                        answer: highlight.aiAnswer!,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: onGoToSource,
                          icon: const Icon(Icons.my_location_rounded, size: 15),
                          label: const Text('Source'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onAskAi,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: const Text('Ask AI'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          tooltip: 'Delete',
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Collapsible saved AI answer (hidden by default) ─────────────────────────

class _CollapsibleAiAnswer extends StatefulWidget {
  final String answer;
  final bool isDark;
  const _CollapsibleAiAnswer({required this.answer, required this.isDark});

  @override
  State<_CollapsibleAiAnswer> createState() => _CollapsibleAiAnswerState();
}

class _CollapsibleAiAnswerState extends State<_CollapsibleAiAnswer> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: Spacing.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: Spacing.borderRadiusSm,
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  'AI answer',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _expanded ? 'Hide' : 'Show',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.primary),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: MarkdownView(data: widget.answer, selectable: true),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// ─── Highlight editor sheet (color + optional note) ──────────────────────────

class _HighlightEditorSheet extends StatefulWidget {
  final String quote;
  const _HighlightEditorSheet({required this.quote});

  @override
  State<_HighlightEditorSheet> createState() => _HighlightEditorSheetState();
}

class _HighlightEditorSheetState extends State<_HighlightEditorSheet> {
  final _noteController = TextEditingController();
  int _colorIndex = 0;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Spacing.screenPaddingH,
            Spacing.md,
            Spacing.screenPaddingH,
            Spacing.lg + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text('New Highlight', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: Color(
                    _highlightColors[_colorIndex],
                  ).withValues(alpha: 0.22),
                  borderRadius: Spacing.borderRadiusSm,
                ),
                child: Text(
                  widget.quote,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurfaceLight,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Color',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: List.generate(_highlightColors.length, (i) {
                  final selected = i == _colorIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: Spacing.sm),
                    child: GestureDetector(
                      onTap: () => setState(() => _colorIndex = i),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(_highlightColors[i]),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.black54,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _noteController,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Add a thought about this passage…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Spacing.md),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop((
                    color: _highlightColors[_colorIndex],
                    note: _noteController.text,
                  )),
                  child: const Text('Save highlight'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
